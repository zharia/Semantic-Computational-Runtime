/**
 * SCR Topology / WFC — Hierarchical Wave Function Collapse
 * ─────────────────────────────────────────────────────────────────────────────
 * Application-layer implementation of SCR-LIB-TOPOLOGY-WFC (lib/303_Topology/WFC/).
 *
 * Implements:
 *   SCR::WFC::BiomeTile            — 9-state biome vocabulary
 *   SCR::WFC::FeatureTile          — 14-state feature vocabulary
 *   SCR::WFC::AdjacencyTable       — normative adjacency constraint table
 *   SCR::WFC::WFCCell              — superposition + Shannon entropy
 *   SCR::WFC::WFCGrid              — 2D grid + AC-3 propagation
 *   SCR::WFC::HierarchicalSolver   — two-scale biome→feature solve
 *
 * Semantic invariants (from 101_definition.md):
 *   - AdjacencyConstraintTable is never violated in a valid solution
 *   - Identical (seed, dims, island_geom) → identical solve
 *   - Hierarchy: feature assignment never contradicts biome assignment
 *   - Contradiction state reports failure; does NOT silently ignore constraints
 */

#ifndef SCR_HIERARCHICAL_WFC_HPP
#define SCR_HIERARCHICAL_WFC_HPP

#include <vector>
#include <array>
#include <queue>
#include <random>
#include <cmath>
#include <cassert>
#include <iostream>
#include <functional>
#include <bitset>
#include <optional>
#include <algorithm>

namespace SCR::WFC {

// ─── Biome Tile Vocabulary (Scale 0 — normative, from 101_definition.md) ────
enum class BiomeTile : uint8_t {
    DEEP_OCEAN       = 0,
    SHALLOW_WATER    = 1,
    BEACH            = 2,
    COASTAL_JUNGLE   = 3,
    DENSE_RAINFOREST = 4,
    VOLCANIC_SLOPE   = 5,
    CALDERA_RIM      = 6,
    CALDERA_LAKE     = 7,
    LAVA_RIVER       = 8,
    COUNT            = 9
};
constexpr int BIOME_COUNT = 9;

// ─── Feature Tile Vocabulary (Scale 1 — normative, from 101_definition.md) ──
enum class FeatureTile : uint8_t {
    NONE             = 0,
    PALM_CLUSTER     = 1,
    PALM_SOLO        = 2,
    BAMBOO_GROVE     = 3,
    CANOPY_TREE      = 4,
    CANOPY_CLUSTER   = 5,
    SHRUB            = 6,
    FERN_CARPET      = 7,
    BASALT_BOULDER   = 8,
    PUMICE_BOULDER   = 9,
    OBSIDIAN_SHARD   = 10,
    SULFUR_VENT      = 11,
    ASH_FLAT         = 12,
    LAVA_POOL        = 13,
    COUNT            = 14
};
constexpr int FEATURE_COUNT = 14;

// ─── AdjacencyTable for BiomeTiles ───────────────────────────────────────────
// Encodes the normative adjacency contract from 101_definition.md.
// adj_biome[A][B] == true means biome A and biome B may share a face.

class BiomeAdjacencyTable {
public:
    bool adj[BIOME_COUNT][BIOME_COUNT];

    BiomeAdjacencyTable(){
        for(auto& row:adj) for(auto& v:row) v=false;
        auto allow=[&](BiomeTile a,BiomeTile b){
            adj[(int)a][(int)b]=true; adj[(int)b][(int)a]=true;
        };
        // Normative adjacency rules (from 101_definition.md §5):
        allow(BiomeTile::DEEP_OCEAN,       BiomeTile::SHALLOW_WATER);
        allow(BiomeTile::SHALLOW_WATER,    BiomeTile::BEACH);
        allow(BiomeTile::BEACH,            BiomeTile::COASTAL_JUNGLE);
        allow(BiomeTile::COASTAL_JUNGLE,   BiomeTile::DENSE_RAINFOREST);
        allow(BiomeTile::DENSE_RAINFOREST, BiomeTile::VOLCANIC_SLOPE);
        allow(BiomeTile::VOLCANIC_SLOPE,   BiomeTile::CALDERA_RIM);
        allow(BiomeTile::VOLCANIC_SLOPE,   BiomeTile::LAVA_RIVER);
        allow(BiomeTile::CALDERA_RIM,      BiomeTile::CALDERA_LAKE);
        allow(BiomeTile::CALDERA_RIM,      BiomeTile::LAVA_RIVER);
        // Self-adjacency (same biome tiles may always be adjacent)
        for(int i=0;i<BIOME_COUNT;i++) adj[i][i]=true;
    }

    bool permitted(BiomeTile a, BiomeTile b) const {
        return adj[(int)a][(int)b];
    }

    static const BiomeAdjacencyTable& instance(){
        static BiomeAdjacencyTable t; return t;
    }
};

// ─── Feature validity per biome ───────────────────────────────────────────────
// Which FeatureTile states are valid within each biome.
// This enforces the Hierarchy invariant: features never contradict biome.

inline bool featureValidForBiome(FeatureTile f, BiomeTile b) {
    using F=FeatureTile; using B=BiomeTile;
    switch(f){
        case F::NONE:           return true; // always valid
        case F::PALM_CLUSTER:
        case F::PALM_SOLO:      return b==B::BEACH||b==B::COASTAL_JUNGLE;
        case F::BAMBOO_GROVE:   return b==B::COASTAL_JUNGLE||b==B::DENSE_RAINFOREST;
        case F::CANOPY_TREE:    return b==B::DENSE_RAINFOREST||b==B::COASTAL_JUNGLE;
        case F::CANOPY_CLUSTER: return b==B::DENSE_RAINFOREST;
        case F::SHRUB:          return b==B::BEACH||b==B::COASTAL_JUNGLE||b==B::DENSE_RAINFOREST;
        case F::FERN_CARPET:    return b==B::COASTAL_JUNGLE||b==B::DENSE_RAINFOREST;
        case F::BASALT_BOULDER: return b==B::VOLCANIC_SLOPE||b==B::CALDERA_RIM;
        case F::PUMICE_BOULDER: return b==B::VOLCANIC_SLOPE;
        case F::OBSIDIAN_SHARD: return b==B::CALDERA_RIM;
        case F::SULFUR_VENT:    return b==B::CALDERA_RIM;
        case F::ASH_FLAT:       return b==B::CALDERA_RIM||b==B::VOLCANIC_SLOPE;
        case F::LAVA_POOL:      return b==B::CALDERA_LAKE||b==B::LAVA_RIVER;
        default:                return false;
    }
}

// ─── WFC Cell ────────────────────────────────────────────────────────────────
// Holds a superposition of possible tile states and computes Shannon entropy.

template<typename TileEnum, int N>
struct WFCCell {
    std::bitset<N> possible;   // which tile states are still possible
    float weights[N];          // frequency prior per tile

    WFCCell() { possible.set(); for(auto& w:weights) w=1.f; }

    /** Shannon entropy H = -Σ p·log₂(p) over remaining possible tiles. */
    float entropy(uint32_t noise_salt=0) const {
        float sum=0,hval=0;
        for(int i=0;i<N;i++) if(possible[i]){ sum+=weights[i]; }
        if(sum<=0) return -1.f; // contradiction
        for(int i=0;i<N;i++) if(possible[i]){
            float p=weights[i]/sum;
            hval-=p*std::log2(p);
        }
        // Add tiny noise to break ties deterministically (seeded)
        float jitter=float(noise_salt*2654435761u>>20)*.0001f;
        return hval+jitter;
    }

    bool isCollapsed() const { return possible.count()==1; }
    bool isContradiction() const { return possible.none(); }

    int collapsedTile() const {
        for(int i=0;i<N;i++) if(possible[i]) return i;
        return -1;
    }

    /** Collapse: choose one tile according to weighted distribution. */
    void collapse(std::mt19937& rng){
        float sum=0;
        for(int i=0;i<N;i++) if(possible[i]) sum+=weights[i];
        std::uniform_real_distribution<float> ud(0,sum);
        float r=ud(rng);
        float acc=0;
        for(int i=0;i<N;i++){
            if(!possible[i]) continue;
            acc+=weights[i];
            if(acc>=r){ possible.reset(); possible.set(i); return; }
        }
        // Fallback: collapse to first
        for(int i=0;i<N;i++) if(possible[i]){ possible.reset(); possible.set(i); return; }
    }
};

using BiomeCell   = WFCCell<BiomeTile,  BIOME_COUNT>;
using FeatureCell = WFCCell<FeatureTile,FEATURE_COUNT>;

// ─── WFCGrid — 2D grid of WFCCells with AC-3 propagation ─────────────────────

template<typename TileEnum, int N>
class WFCGrid {
public:
    int w, h;
    std::vector<WFCCell<TileEnum,N>> cells;
    std::mt19937 rng;

    WFCGrid(int w_,int h_,uint32_t seed):w(w_),h(h_),cells(w_*h_),rng(seed){}

    WFCCell<TileEnum,N>& cell(int x,int z)       { return cells[z*w+x]; }
    const WFCCell<TileEnum,N>& cell(int x,int z) const { return cells[z*w+x]; }

    bool inBounds(int x,int z) const { return x>=0&&x<w&&z>=0&&z<h; }

    /** Constrain cell (x,z) to only the given tile. Used for hard initial constraints. */
    void pin(int x,int z,TileEnum tile){
        if(!inBounds(x,z)) return;
        auto& c=cell(x,z);
        c.possible.reset();
        c.possible.set((int)tile);
    }

    /** Set weight (frequency prior) for a tile in cell (x,z). */
    void setWeight(int x,int z,TileEnum tile,float w_){
        if(!inBounds(x,z)) return;
        cell(x,z).weights[(int)tile]=w_;
    }

    /** Propagate adjacency constraints using AC-3. Returns false on contradiction. */
    bool propagateBiome(const BiomeAdjacencyTable& adj){
        std::queue<std::pair<int,int>> q;
        for(int z=0;z<h;z++) for(int x=0;x<w;x++) q.push({x,z});

        while(!q.empty()){
            auto [cx,cz]=q.front(); q.pop();
            auto& cc=cell(cx,cz);
            if(cc.isContradiction()) return false;

            static const int dx[]={1,-1,0,0};
            static const int dz[]={0,0,1,-1};
            for(int d=0;d<4;d++){
                int nx=cx+dx[d], nz=cz+dz[d];
                if(!inBounds(nx,nz)) continue;
                auto& nc=cell(nx,nz);
                bool changed=false;

                for(int ni=0;ni<BIOME_COUNT;ni++){
                    if(!nc.possible[ni]) continue;
                    // Check if any tile in cc permits ni
                    bool any_compat=false;
                    for(int ci=0;ci<BIOME_COUNT&&!any_compat;ci++)
                        if(cc.possible[ci] && adj.adj[ci][ni]) any_compat=true;
                    if(!any_compat){ nc.possible.reset(ni); changed=true; }
                }
                if(nc.isContradiction()) return false;
                if(changed) q.push({nx,nz});
            }
        }
        return true;
    }

    /**
     * Main WFC solve loop (biome version).
     * Selects lowest-entropy uncollapsed cell, collapses it, propagates.
     * Returns false if contradiction encountered.
     */
    bool solveBiome(){
        const auto& adj=BiomeAdjacencyTable::instance();
        while(true){
            // Find minimum entropy cell
            float min_h=1e9f; int bx=-1,bz=-1;
            for(int z=0;z<h;z++) for(int x=0;x<w;x++){
                auto& c=cell(x,z);
                if(c.isCollapsed()||c.isContradiction()) continue;
                float e=c.entropy(unsigned(x*73856093^z*19349663));
                if(e<min_h){min_h=e;bx=x;bz=z;}
            }
            if(bx<0) break; // all collapsed
            cell(bx,bz).collapse(rng);
            if(!propagateBiome(adj)) return false;
        }
        return true;
    }

    /** Check all adjacency constraints (semantic invariant verification). */
    bool verifyBiomeConstraints() const {
        const auto& adj=BiomeAdjacencyTable::instance();
        static const int dx[]={1,-1,0,0};
        static const int dz[]={0,0,1,-1};
        for(int z=0;z<h;z++) for(int x=0;x<w;x++){
            int ci=cell(x,z).collapsedTile();
            if(ci<0) return false; // not collapsed
            for(int d=0;d<4;d++){
                int nx=x+dx[d],nz=z+dz[d];
                if(!inBounds(nx,nz)) continue;
                int ni=cell(nx,nz).collapsedTile();
                if(ni<0) return false;
                if(!adj.adj[ci][ni]){ return false; }
            }
        }
        return true;
    }
};

using BiomeGrid = WFCGrid<BiomeTile,BIOME_COUNT>;

// ─── HierarchicalSolver ───────────────────────────────────────────────────────
// Scale-0: Biome assignment on coarse grid (dim/COARSE_TILE × dim/COARSE_TILE)
// Scale-1: Feature assignment per column, constrained by Scale-0 biome

class HierarchicalSolver {
public:
    int map_w, map_h;      // voxel column dimensions
    int coarse;            // coarse tile size in voxel columns

    // Results
    std::vector<BiomeTile>   biome_map;    // [map_w * map_h] per-column biome
    std::vector<FeatureTile> feature_map;  // [map_w * map_h] per-column feature

    HierarchicalSolver(int w,int h,int coarse_tile=6)
        :map_w(w),map_h(h),coarse(coarse_tile),
         biome_map(w*h,BiomeTile::DEEP_OCEAN),
         feature_map(w*h,FeatureTile::NONE){}

    BiomeTile&   biome(int x,int z)   { return biome_map[z*map_w+x]; }
    FeatureTile& feature(int x,int z) { return feature_map[z*map_w+x]; }
    const BiomeTile&   biome(int x,int z)   const { return biome_map[z*map_w+x]; }
    const FeatureTile& feature(int x,int z) const { return feature_map[z*map_w+x]; }

    /**
     * Solve Scale-0 biome grid.
     * Hard constraints are derived from the island geomorphology:
     *   - center → CALDERA_LAKE
     *   - near center ring → CALDERA_RIM
     *   - edge of island → DEEP_OCEAN
     * WFC fills the rest coherently.
     *
     * @param cx,cz: island center in voxel units
     * @param r_island: island radius (voxels)
     * @param r_caldera: caldera radius (voxels)
     * @param lava_river_fn: returns true if (x,z) is in the lava river channel
     * @param seed: RNG seed
     */
    bool solveBiomes(float cx, float cz, float r_island, float r_caldera,
                     std::function<bool(int,int)> lava_river_fn, uint32_t seed)
    {
        int gw=(map_w+coarse-1)/coarse;
        int gh=(map_h+coarse-1)/coarse;
        BiomeGrid grid(gw,gh,seed);

        // ── Set frequency priors per biome (influences tile selection probability) ──
        static const float priors[BIOME_COUNT] = {
            /* DEEP_OCEAN       */ 3.f,
            /* SHALLOW_WATER    */ 1.f,
            /* BEACH            */ 0.8f,
            /* COASTAL_JUNGLE   */ 1.2f,
            /* DENSE_RAINFOREST */ 1.5f,
            /* VOLCANIC_SLOPE   */ 1.2f,
            /* CALDERA_RIM      */ 0.6f,
            /* CALDERA_LAKE     */ 0.3f,
            /* LAVA_RIVER       */ 0.2f,
        };
        for(int z=0;z<gh;z++) for(int x=0;x<gw;x++)
            for(int t=0;t<BIOME_COUNT;t++)
                grid.cell(x,z).weights[t]=priors[t];

        // ── Apply hard geomorphological constraints ─────────────────────────────
        for(int gz=0;gz<gh;gz++) for(int gx=0;gx<gw;gx++){
            float vx=float(gx*coarse)+coarse*.5f;
            float vz=float(gz*coarse)+coarse*.5f;
            float r=std::sqrt((vx-cx)*(vx-cx)+(vz-cz)*(vz-cz));

            // Caldera lake center
            if(r<r_caldera*.55f){
                grid.pin(gx,gz,BiomeTile::CALDERA_LAKE); continue;
            }
            // Caldera rim ring
            if(r<r_caldera*1.2f){
                grid.pin(gx,gz,BiomeTile::CALDERA_RIM); continue;
            }
            // Lava river channel
            if(lava_river_fn((int)vx,(int)vz) && r>r_caldera*1.1f && r<r_island*.95f){
                grid.pin(gx,gz,BiomeTile::LAVA_RIVER); continue;
            }
            // Deep ocean beyond island edge
            if(r>r_island*1.32f){
                grid.pin(gx,gz,BiomeTile::DEEP_OCEAN); continue;
            }
            // Shallow water at island fringe
            if(r>r_island*1.02f){
                grid.pin(gx,gz,BiomeTile::SHALLOW_WATER); continue;
            }
            // Weight inner tiles by radius (guides WFC without hard constraints)
            float normalized_r = r / r_island;
            auto& c=grid.cell(gx,gz);
            if(normalized_r<0.12f) {
                // Volcanic slope immediately outside caldera rim
                c.weights[(int)BiomeTile::VOLCANIC_SLOPE]=8.f;
            } else if(normalized_r<0.25f){
                c.weights[(int)BiomeTile::VOLCANIC_SLOPE]=6.f;
                c.weights[(int)BiomeTile::DENSE_RAINFOREST]=2.f;
            } else if(normalized_r<0.45f){
                c.weights[(int)BiomeTile::DENSE_RAINFOREST]=8.f;
                c.weights[(int)BiomeTile::VOLCANIC_SLOPE]=2.f;
                c.weights[(int)BiomeTile::COASTAL_JUNGLE]=1.f;
            } else if(normalized_r<0.65f){
                c.weights[(int)BiomeTile::COASTAL_JUNGLE]=6.f;
                c.weights[(int)BiomeTile::DENSE_RAINFOREST]=4.f;
                c.weights[(int)BiomeTile::BEACH]=1.f;
            } else if(normalized_r<0.85f){
                c.weights[(int)BiomeTile::BEACH]=5.f;
                c.weights[(int)BiomeTile::COASTAL_JUNGLE]=3.f;
                c.weights[(int)BiomeTile::SHALLOW_WATER]=2.f;
            } else {
                c.weights[(int)BiomeTile::BEACH]=3.f;
                c.weights[(int)BiomeTile::SHALLOW_WATER]=5.f;
            }
        }

        // ── Initial propagation then solve ─────────────────────────────────────
        if(!grid.propagateBiome(BiomeAdjacencyTable::instance())) {
            std::cerr<<"[WFC] Initial biome constraint propagation contradiction.\n"; return false;
        }
        if(!grid.solveBiome()){
            std::cerr<<"[WFC] Biome WFC solve contradiction — retry with seed+1.\n";
            return solveBiomes(cx,cz,r_island,r_caldera,lava_river_fn,seed+1);
        }

        // ── Verify adjacency invariant ─────────────────────────────────────────
        bool ok=grid.verifyBiomeConstraints();
        if(!ok) std::cerr<<"[WFC] Biome adjacency constraint violated (bug).\n";

        // ── Up-sample coarse grid to per-column biome_map ─────────────────────
        for(int z=0;z<map_h;z++) for(int x=0;x<map_w;x++){
            int gx=std::min(x/coarse,gw-1), gz=std::min(z/coarse,gh-1);
            int ti=grid.cell(gx,gz).collapsedTile();
            biome(x,z)=(ti>=0)?BiomeTile(ti):BiomeTile::DEEP_OCEAN;
        }

        std::cout<<"[WFC] Biome solve complete. Constraint invariant: "<<(ok?"PASS":"FAIL")<<"\n";
        return true;
    }

    /**
     * Solve Scale-1 feature assignment.
     * Uses a weighted random selection per column based on biome and noise value.
     * Simpler than full WFC (no inter-column propagation) because features are
     * locally determined given the biome context.
     *
     * @param noise_fn: returns ∈[-1,1] value for position (x, z)
     * @param seed: RNG seed
     */
    void solveFeatures(std::function<float(float,float)> noise_fn, uint32_t seed){
        std::mt19937 rng(seed);

        for(int z=0;z<map_h;z++) for(int x=0;x<map_w;x++){
            BiomeTile b=biome(x,z);
            float n=noise_fn(float(x),float(z)); // ∈[-1,1]

            using F=FeatureTile;
            FeatureTile ft=F::NONE;

            switch(b){
            case BiomeTile::BEACH:
                if     (n>0.70f) ft=F::PALM_CLUSTER;
                else if(n>0.50f) ft=F::PALM_SOLO;
                else if(n>0.25f) ft=F::SHRUB;
                break;
            case BiomeTile::COASTAL_JUNGLE:
                if     (n>0.60f) ft=F::PALM_CLUSTER;
                else if(n>0.35f) ft=F::CANOPY_TREE;
                else if(n>0.10f) ft=F::BAMBOO_GROVE;
                else if(n>-.10f) ft=F::SHRUB;
                else if(n>-.35f) ft=F::FERN_CARPET;
                break;
            case BiomeTile::DENSE_RAINFOREST:
                if     (n>0.55f) ft=F::CANOPY_CLUSTER;
                else if(n>0.20f) ft=F::CANOPY_TREE;
                else if(n>-.05f) ft=F::BAMBOO_GROVE;
                else if(n>-.30f) ft=F::FERN_CARPET;
                else             ft=F::SHRUB;
                break;
            case BiomeTile::VOLCANIC_SLOPE:
                if     (n>0.60f) ft=F::BASALT_BOULDER;
                else if(n>0.35f) ft=F::PUMICE_BOULDER;
                else if(n>0.05f) ft=F::ASH_FLAT;
                break;
            case BiomeTile::CALDERA_RIM:
                if     (n>0.65f) ft=F::OBSIDIAN_SHARD;
                else if(n>0.35f) ft=F::SULFUR_VENT;
                else if(n>-.10f) ft=F::ASH_FLAT;
                else if(n>-.50f) ft=F::BASALT_BOULDER;
                break;
            case BiomeTile::CALDERA_LAKE:
            case BiomeTile::LAVA_RIVER:
                ft=F::LAVA_POOL;
                break;
            default:
                ft=F::NONE;
            }

            // Hierarchy invariant: feature must be valid for biome
            // (redundant given switch above, but enforced here for contract)
            if(!featureValidForBiome(ft,b)) ft=F::NONE;
            feature(x,z)=ft;
        }
    }
};

} // namespace SCR::WFC
#endif // SCR_HIERARCHICAL_WFC_HPP
