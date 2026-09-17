#ifndef CAVE_PROCEDURAL_ISLAND_HPP
#define CAVE_PROCEDURAL_ISLAND_HPP

#include <vector>
#include <cmath>
#include <random>
#include <algorithm>
#include <iostream>
#include <functional>

#include "spatial_semantics.hpp"
#include "semantic_materials.hpp"

namespace SCR::Island {

// ─── Permutation-table Perlin noise (same fast impl as cave) ─────────────────
class FastNoise3D {
    std::vector<int> p;
    static float fade(float t) { return t*t*t*(t*(t*6-15)+10); }
    static float lerp(float t, float a, float b) { return a+t*(b-a); }
    static float grad(int h, float x, float y, float z) {
        int hh=h&15; float u=hh<8?x:y; float v=hh<4?y:hh==12||hh==14?x:z;
        return ((hh&1)?-u:u)+((hh&2)?-v:v);
    }
public:
    FastNoise3D(unsigned seed=1337) {
        p.resize(512); std::vector<int> pm(256);
        for(int i=0;i<256;i++) pm[i]=i;
        std::mt19937 g(seed); std::shuffle(pm.begin(),pm.end(),g);
        for(int i=0;i<256;i++){p[i]=pm[i];p[256+i]=pm[i];}
    }
    float noise(float x,float y,float z) const {
        int X=(int)std::floor(x)&255,Y=(int)std::floor(y)&255,Z=(int)std::floor(z)&255;
        x-=std::floor(x); y-=std::floor(y); z-=std::floor(z);
        float u=fade(x),v=fade(y),w=fade(z);
        int A=p[X]+Y,AA=p[A]+Z,AB=p[A+1]+Z,B=p[X+1]+Y,BA=p[B]+Z,BB=p[B+1]+Z;
        return lerp(w,lerp(v,lerp(u,grad(p[AA],x,y,z),grad(p[BA],x-1,y,z)),
                           lerp(u,grad(p[AB],x,y-1,z),grad(p[BB],x-1,y-1,z))),
                    lerp(v,lerp(u,grad(p[AA+1],x,y,z-1),grad(p[BA+1],x-1,y,z-1)),
                         lerp(u,grad(p[AB+1],x,y-1,z-1),grad(p[BB+1],x-1,y-1,z-1))));
    }
    float fbm(float x,float y,float z,int oct=4,float lac=2.f,float gain=.5f) const {
        float s=0,f=1,a=1,ma=0;
        for(int i=0;i<oct;i++){s+=noise(x*f,y*f,z*f)*a;ma+=a;f*=lac;a*=gain;}
        return s/ma;
    }
};

/**
 * VoxelIsland: Procedural Volcanic Island.
 *
 * Altitude Biome Zones:
 *   0–7   m   : Ocean / Seafloor (sand, basalt shelves)
 *   7–9   m   : Tropical Beach & Shoreline (silica sand, black sand, driftwood)
 *   9–14  m   : Coastal Jungle Fringe (palms, shrubs, ferns)
 *  14–22  m   : Dense Tropical Rainforest (hardwood canopy, bamboo, undergrowth)
 *  22–26  m   : Upper Volcanic Slopes (basalt, tuff, pumice boulders, sparse ash trees)
 *  26–35  m   : Caldera Rim & Summit (obsidian, sulfur vents, ash, lava lake)
 */
class VoxelIsland {
public:
    int dim_x, dim_y, dim_z;
    float voxel_size;
    float sea_level;
    std::vector<uint16_t> voxels;
    SCR::Spatial::ReferenceFrame reference_frame;

    FastNoise3D noise_terrain, noise_flora, noise_detail, noise_boulder, noise_tree;

    float center_x, center_z;
    float island_radius, peak_height, caldera_radius, caldera_depth;

    // Fixed lava river bearing (NE direction)
    static constexpr float RIVER_ANGLE = 0.75f;

    VoxelIsland(int dx=320,int dy=64,int dz=320,float vs=1.f)
        : dim_x(dx),dim_y(dy),dim_z(dz),voxel_size(vs), sea_level(9.f),
          voxels(dx*dy*dz,Material::MAT_AIR),
          reference_frame("island_lattice_frame","world_reference_frame"),
          noise_terrain(1337),noise_flora(1438),noise_detail(1539),
          noise_boulder(1640),noise_tree(1741),
          center_x(dx*.5f),center_z(dz*.5f),
          island_radius(128.f),peak_height(64.f),caldera_radius(22.f),caldera_depth(18.f) {}

    inline int index(int x,int y,int z) const { return (y*dim_z+z)*dim_x+x; }
    bool inBounds(int x,int y,int z) const {
        return x>=0&&x<dim_x&&y>=0&&y<dim_y&&z>=0&&z<dim_z;
    }
    bool inBounds(const Spatial::LatticeCoord3D& c) const { return inBounds(c.x,c.y,c.z); }

    uint16_t getVoxel(int x,int y,int z) const {
        if(!inBounds(x,y,z)) return y<=(int)sea_level?Material::MAT_WATER:Material::MAT_AIR;
        return voxels[index(x,y,z)];
    }
    uint16_t getVoxel(const Spatial::LatticeCoord3D& c) const { return getVoxel(c.x,c.y,c.z); }
    void setVoxel(int x,int y,int z,uint16_t m) { if(inBounds(x,y,z)) voxels[index(x,y,z)]=m; }
    void setVoxel(const Spatial::LatticeCoord3D& c,uint16_t m) { setVoxel(c.x,c.y,c.z,m); }
    bool isSolid(int x,int y,int z) const { return Material::MaterialRegistry::instance().get(getVoxel(x,y,z)).is_solid; }
    bool isFluid(int x,int y,int z) const { return Material::MaterialRegistry::instance().get(getVoxel(x,y,z)).is_fluid; }

    // ── Geomorphology ──────────────────────────────────────────────────────────

    /** Deterministic height H(x,z) — the authoritative island surface elevation. */
    float getIslandHeight(float x,float z) const {
        float dx=x-center_x, dz=z-center_z;
        float r=std::sqrt(dx*dx+dz*dz);
        float theta=std::atan2(dz,dx);

        if(r>island_radius*1.45f) return sea_level-8.f; // deep ocean

        // Stratovolcano exponential cone with radial flutes and scenic spurs
        float flutes = 1.f
            + 0.11f*std::cos(5.f*theta)
            + 0.08f*std::sin(3.f*theta)
            + 0.04f*std::cos(8.f*theta);
        float cone = (peak_height-sea_level)*std::exp(-std::pow(r/(island_radius*.42f),1.85f))*flutes;
        float h = sea_level + cone;

        // Broad sloping tropical beaches & continental shelf
        if(r>island_radius*.70f){
            float t=(r-island_radius*.70f)/(island_radius*.60f);
            t=std::min(1.0f, std::max(0.0f, t));
            h=(1.f-t)*h+t*(sea_level-7.5f);
        }

        // Coastal barrier sandbars and scenic reef spits
        float coastal_spit = noise_boulder.fbm(x*.016f, 0.f, z*.016f, 3, 2.f, .5f) * 3.6f;
        if(r > island_radius * 0.65f && r < island_radius * 1.15f) {
            h += coastal_spit;
        }

        // Summit caldera bowl
        if(r<caldera_radius){
            float ct=1.f-(r/caldera_radius);
            h-=caldera_depth*(ct*ct);
        }

        // Sinuous lava river gorge along NE flank
        {
            float ad=std::abs(theta-RIVER_ANGLE);
            if(ad>3.14159f) ad=6.28318f-ad;
            float rd=r*ad;
            if(r>caldera_radius*.70f && r<island_radius*.95f && rd<7.5f){
                h-=(1.f-rd/7.5f)*4.8f;
            }
        }

        // Fractal micro-roughness
        h += noise_terrain.fbm(x*.028f,.0f,z*.028f,4,2.f,.5f)*3.5f;
        return h;
    }

    /** Authoritative 3D continuous density — positive=solid, negative=void. */
    float sampleContinuousDensity(float x,float y,float z) const {
        if(x<.5f||x>=dim_x-.5f||z<.5f||z>=dim_z-.5f||y<.5f||y>=dim_y-.5f) return -1.f;
        float h=getIslandHeight(x,z);
        float density=h-y;
        // Add 3D rocky overhangs on mid-slopes
        if(y>sea_level+2.f && y<peak_height-6.f){
            float rn=noise_detail.fbm(x*.04f,y*.06f,z*.04f,2,2.f,.5f);
            density+=rn*1.4f;
        }
        return density;
    }

    // ── Spawn ──────────────────────────────────────────────────────────────────

    SCR::Spatial::Point3D findBeachSpawnPosition() const {
        // Panoramic South-Southwest beach dune: wide vista of the volcano, coastline and lava river
        float sx = center_x - 36.0f;
        float sz = center_z - island_radius * 0.92f;
        float h = getIslandHeight(sx, sz);
        if(h < sea_level + 0.4f) h = sea_level + 0.8f;
        return SCR::Spatial::Point3D(sx, h + 1.2f, sz);
    }

    // ── Internal flora helpers ─────────────────────────────────────────────────

    /** Build a palm tree: trunk(height) + fronds at top */
    void placePalmTree(int bx,int by,int bz,int height){
        for(int y=0;y<height;y++) setVoxel(bx,by+y,bz,Material::MAT_PALM);
        int ty=by+height;
        // Crown fronds: cross pattern
        for(int dx=-2;dx<=2;dx++) for(int dz=-2;dz<=2;dz++){
            int ad=std::abs(dx)+std::abs(dz);
            if(ad<=2 && inBounds(bx+dx,ty,bz+dz)) setVoxel(bx+dx,ty,bz+dz,Material::MAT_FOLIAGE);
        }
        // Second frond tier offset
        for(int dx=-1;dx<=1;dx++) for(int dz=-1;dz<=1;dz++)
            if(inBounds(bx+dx,ty+1,bz+dz)) setVoxel(bx+dx,ty+1,bz+dz,Material::MAT_FOLIAGE);
    }

    /** Build a jungle hardwood tree: bark trunk + layered canopy */
    void placeJungleTree(int bx,int by,int bz,int height){
        for(int y=0;y<height;y++) setVoxel(bx,by+y,bz,Material::MAT_WOOD);
        int ty=by+height;
        // 3-layer spheroid canopy — wider in middle
        for(int layer=-1;layer<=2;layer++){
            int rad=(layer==0||layer==1)?3:2;
            for(int dx=-rad;dx<=rad;dx++) for(int dz=-rad;dz<=rad;dz++){
                if(dx*dx+dz*dz<=rad*rad+1 && inBounds(bx+dx,ty+layer,bz+dz))
                    setVoxel(bx+dx,ty+layer,bz+dz,Material::MAT_FOLIAGE);
            }
        }
    }

    /** Place a volcanic boulder cluster centred at bx,by,bz */
    void placeBoulder(int bx,int by,int bz,uint16_t mat,int size){
        for(int dy=0;dy<size;dy++) for(int dx=-size+1;dx<size;dx++) for(int dz=-size+1;dz<size;dz++){
            if(dx*dx+dy*dy/4+dz*dz<(size*size) && inBounds(bx+dx,by+dy,bz+dz))
                setVoxel(bx+dx,by+dy,bz+dz,mat);
        }
    }

    // ── Main Generation ────────────────────────────────────────────────────────

    /**
     * Full procedural island pass:
     *   Pass 1 — Terrain substrate (solid rock, sand, ocean water)
     *   Pass 2 — Surface biome materials (caldera, cliff, jungle soil, beach)
     *   Pass 3 — Flora placement (jungle trees, palms, shrubs, ferns, boulders)
     *   Pass 4 — Volcanic features (obsidian shards, sulfur deposits, ash)
     */
    void generateProceduralIsland(unsigned seed=1337) {
        noise_terrain = FastNoise3D(seed);
        noise_flora   = FastNoise3D(seed+101);
        noise_detail  = FastNoise3D(seed+202);
        noise_boulder = FastNoise3D(seed+303);
        noise_tree    = FastNoise3D(seed+404);

        std::fill(voxels.begin(),voxels.end(),Material::MAT_AIR);

        // ── Pass 1 & 2: Terrain substrate + surface materials ─────────────────
        for(int x=0;x<dim_x;x++) for(int z=0;z<dim_z;z++){
            float h=getIslandHeight(float(x),float(z));
            int sy=(int)std::floor(h);

            float dx=float(x)-center_x, dz=float(z)-center_z;
            float r=std::sqrt(dx*dx+dz*dz);
            float theta=std::atan2(dz,dx);

            // River membership
            float ad=std::abs(theta-RIVER_ANGLE);
            if(ad>3.14159f) ad=6.28318f-ad;
            float river_dist=r*ad;
            bool in_lava_river  = (r>caldera_radius*.65f && r<island_radius*.95f && river_dist<2.2f);
            bool near_lava_river= (r>caldera_radius*.55f && r<island_radius        && river_dist<4.f);

            for(int y=0;y<dim_y;y++){
                if(y==0){ setVoxel(x,y,z,Material::MAT_BEDROCK); continue; }

                if(y<=sy){
                    // Deep core basalt
                    if(y<(int)(sea_level-4.f)){
                        setVoxel(x,y,z,Material::MAT_BASALT); continue;
                    }
                    // Caldera magma lake
                    if(r<caldera_radius*.7f){
                        if(y>=sy-1)      setVoxel(x,y,z,Material::MAT_LAVA);
                        else if(y>=sy-4) setVoxel(x,y,z,Material::MAT_OBSIDIAN);
                        else             setVoxel(x,y,z,Material::MAT_BASALT);
                        continue;
                    }
                    // Lava river channel
                    if(in_lava_river){
                        setVoxel(x,y,z, y>=sy-1?Material::MAT_LAVA:Material::MAT_OBSIDIAN);
                        continue;
                    }
                    // Surface layer
                    if(y==sy || y==sy-1){
                        if(near_lava_river)            setVoxel(x,y,z,Material::MAT_OBSIDIAN);
                        else if(r<caldera_radius*1.3f){
                            float sn=noise_flora.noise(x*.22f,.0f,z*.22f);
                            setVoxel(x,y,z, sn>.3f ? Material::MAT_SULFUR
                                          : sn<-.25f? Material::MAT_ASH
                                          :            Material::MAT_BASALT);
                        }
                        else if(h>=22.f) setVoxel(x,y,z,Material::MAT_BASALT);
                        else if(h>=14.f) setVoxel(x,y,z,Material::MAT_DIRT);
                        else if(h>= 8.f) setVoxel(x,y,z,Material::MAT_SAND);
                        else             setVoxel(x,y,z,Material::MAT_SAND);
                    } else {
                        // Sub-surface
                        if(y>=(int)(sea_level) && y<sy-1) setVoxel(x,y,z,Material::MAT_DIRT);
                        else                               setVoxel(x,y,z,Material::MAT_BASALT);
                    }
                } else if(y<=(int)sea_level){
                    setVoxel(x,y,z,Material::MAT_WATER);
                }
            }
        }

        // ── Pass 3: Flora ─────────────────────────────────────────────────────
        for(int x=2;x<dim_x-2;x++) for(int z=2;z<dim_z-2;z++){
            float fx=float(x),fz=float(z);
            float h=getIslandHeight(fx,fz);
            int sy=(int)std::floor(h);
            if(sy<1||sy>=dim_y-8) continue;

            float dx=fx-center_x, dz2=fz-center_z;
            float r=std::sqrt(dx*dx+dz2*dz2);
            float theta=std::atan2(dz2,dx);
            float ad=std::abs(theta-RIVER_ANGLE); if(ad>3.14159f) ad=6.28318f-ad;
            bool near_river=(r<island_radius && r*ad<5.f);

            uint16_t surf_mat=getVoxel(x,sy,z);
            float tn=noise_tree.noise(fx*.28f,.0f,fz*.28f);   // tree placement noise
            float fn=noise_flora.noise(fx*.55f,.0f,fz*.55f);  // fine flora noise
            float bn=noise_boulder.noise(fx*.18f,.0f,fz*.18f);// boulder noise

            // ── Beach zone (7–9m): Palms + beach debris ───────────────────────
            if(h>=7.5f && h<10.5f && surf_mat==Material::MAT_SAND && !near_river){
                if(tn>0.62f) placePalmTree(x,sy+1,z,4+int((tn-.6f)*10.f));
                else if(fn>0.55f) setVoxel(x,sy+1,z,Material::MAT_SHRUB);
                // Occasional beach rock
                if(bn>0.72f && getVoxel(x,sy+1,z)==Material::MAT_AIR)
                    placeBoulder(x,sy+1,z,Material::MAT_BASALT,1);
            }

            // ── Coastal jungle fringe (9–14m) ─────────────────────────────────
            if(h>=9.5f && h<14.f && surf_mat==Material::MAT_DIRT && !near_river){
                if(tn>0.50f)       placePalmTree(x,sy+1,z,3+int((tn-.5f)*8.f));
                else if(tn>0.30f)  placeJungleTree(x,sy+1,z,3+int((tn-.3f)*8.f));
                else if(fn>0.35f)  setVoxel(x,sy+1,z,Material::MAT_SHRUB);
                else if(fn<-.35f)  setVoxel(x,sy+1,z,Material::MAT_FERN);
                else if(fn>0.1f && fn<0.2f){
                    setVoxel(x,sy+1,z,Material::MAT_BAMBOO);
                    if(sy+2<dim_y) setVoxel(x,sy+2,z,Material::MAT_BAMBOO);
                }
                // Fern understory under trees
                if(getVoxel(x,sy+1,z)==Material::MAT_AIR && fn>0.0f)
                    setVoxel(x,sy+1,z,Material::MAT_FERN);
            }

            // ── Dense rainforest (14–22m) ──────────────────────────────────────
            if(h>=14.f && h<22.f && surf_mat==Material::MAT_DIRT && !near_river){
                float density_mult=1.f-(h-14.f)/8.f; // denser at lower elevation
                if(tn>0.28f*density_mult+0.2f){
                    int tree_h=4+int((tn-.28f)*12.f);
                    placeJungleTree(x,sy+1,z,tree_h);
                } else if(tn>0.0f){
                    // Bamboo grove
                    int bh=3+int(tn*6.f);
                    for(int ty=0;ty<bh&&sy+1+ty<dim_y;ty++)
                        setVoxel(x,sy+1+ty,z,Material::MAT_BAMBOO);
                } else if(fn>0.2f){
                    setVoxel(x,sy+1,z,Material::MAT_SHRUB);
                } else {
                    setVoxel(x,sy+1,z,Material::MAT_FERN);
                }
                // Scattered boulders among trees
                if(bn>0.70f && getVoxel(x,sy+1,z)==Material::MAT_WOOD){
                    // Boulder beside tree
                    if(inBounds(x+1,sy+1,z)) placeBoulder(x+1,sy+1,z,Material::MAT_BASALT,1);
                }
            }

            // ── Upper slopes (22–26m) ──────────────────────────────────────────
            if(h>=22.f && h<26.f && !near_river){
                // Sparse bleached ash trees
                if(tn>0.68f){
                    for(int ty=0;ty<3&&sy+1+ty<dim_y;ty++)
                        setVoxel(x,sy+1+ty,z,Material::MAT_WOOD);
                    if(sy+4<dim_y) setVoxel(x,sy+4,z,Material::MAT_FOLIAGE);
                }
                // Pumice boulders
                if(bn>0.62f) placeBoulder(x,sy+1,z,Material::MAT_PUMICE,1+int(bn*2.f));
                // Tuff outcroppings
                if(bn<-0.65f) placeBoulder(x,sy+1,z,Material::MAT_TUFF,1);
            }

            // ── Obsidian shards & fumaroles (near caldera, r < caldera_radius*2) ─
            float cr=std::sqrt(dx*dx+dz2*dz2);
            if(cr<caldera_radius*2.f && cr>caldera_radius*.9f){
                if(bn>0.7f && getVoxel(x,sy+1,z)==Material::MAT_AIR){
                    // Obsidian shard: 1–3 voxels tall jagged spire
                    int shard_h=1+int((bn-.7f)*10.f);
                    for(int ty=0;ty<shard_h&&sy+1+ty<dim_y;ty++)
                        setVoxel(x,sy+1+ty,z,Material::MAT_OBSIDIAN);
                }
                if(fn>0.75f && getVoxel(x,sy+1,z)==Material::MAT_AIR){
                    // Sulfur deposit mound
                    setVoxel(x,sy+1,z,Material::MAT_SULFUR);
                    if(fn>0.82f && sy+2<dim_y) setVoxel(x,sy+2,z,Material::MAT_SULFUR);
                }
            }
        }

        // ── Pass 4: Scattered shoreline rocks & reef ──────────────────────────
        for(int x=3;x<dim_x-3;x++) for(int z=3;z<dim_z-3;z++){
            float h=getIslandHeight(float(x),float(z));
            int sy=(int)std::floor(h);
            float bn=noise_boulder.noise(float(x)*.25f,.5f,float(z)*.25f);

            // Submerged reef basalt outcroppings at seafloor
            if(h<sea_level-1.f && h>sea_level-5.f && bn>0.72f && getVoxel(x,sy+1,z)==Material::MAT_AIR)
                setVoxel(x,sy+1,z,Material::MAT_BASALT);
        }

        std::cout << "[VoxelIsland] Procedural Volcanic Island generated — seed " << seed
                  << " (" << dim_x << "x" << dim_y << "x" << dim_z << " lattice, "
                  << "sea level " << sea_level << "m).\n";
    }

    // ── STC Thermodynamic Reactions ────────────────────────────────────────────
    int stepSTCReactions() {
        int n=0;
        std::vector<uint16_t> nv=voxels;
        const auto& reg=Material::MaterialRegistry::instance();
        for(int y=1;y<dim_y-1;y++) for(int z=1;z<dim_z-1;z++) for(int x=1;x<dim_x-1;x++){
            uint16_t cur=getVoxel(x,y,z);
            if(cur==Material::MAT_AIR) continue;
            for(int d=0;d<6;d++){
                auto off=Spatial::getDirectionOffset((Spatial::Direction6)d);
                uint16_t nb=getVoxel(x+off.x,y+off.y,z+off.z);
                uint16_t out=reg.evaluateFaceAdjacencySTC(cur,nb);
                if(out!=cur){nv[index(x,y,z)]=out;n++;break;}
            }
        }
        if(n>0) voxels=std::move(nv);
        return n;
    }
};

} // namespace SCR::Island
#endif // CAVE_PROCEDURAL_ISLAND_HPP
