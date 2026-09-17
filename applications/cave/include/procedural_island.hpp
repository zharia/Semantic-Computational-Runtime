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
#include "island_biome_types.hpp"

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
 * VoxelIsland: Procedural Multi-Biome Island Generator for Sea of Thieves Archipelago.
 *
 * Supported Biomes:
 *   - VOLCANO: Active stratovolcano cone, caldera bowl, lava gorge, obsidian & basalt cliffs.
 *   - JUNGLE: High-altitude rainforest double-peak, deep river valley, bamboo & giant canopy trees.
 *   - DESERT: Sweeping wind-carved sand dunes, sandstone sea arches, oasis springs & date palms.
 *   - GLACIAL_ICE: Translucent blue ice sheets, jagged glacial horns, snow-capped rock crevasses.
 *   - CORAL_ARCHIPELAGO: 5-islet circular ring surrounding an expansive crystal turquoise coral lagoon.
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
    IslandBiomeType biome_type;

    // Fixed lava river bearing (NE direction) for volcano biome
    static constexpr float RIVER_ANGLE = 0.75f;

    VoxelIsland(int dx=320,int dy=64,int dz=320,float vs=1.f, IslandBiomeType b=IslandBiomeType::VOLCANO)
        : dim_x(dx),dim_y(dy),dim_z(dz),voxel_size(vs), sea_level(9.f),
          voxels(dx*dy*dz,Material::MAT_AIR),
          reference_frame("island_lattice_frame","world_reference_frame"),
          noise_terrain(1337),noise_flora(1438),noise_detail(1539),
          noise_boulder(1640),noise_tree(1741),
          center_x(dx*.5f),center_z(dz*.5f),
          island_radius(128.f),peak_height(64.f),caldera_radius(22.f),caldera_depth(18.f),
          biome_type(b)
    {
        applyBiomeParameters(b);
    }

    void setBiome(IslandBiomeType b) {
        biome_type = b;
        applyBiomeParameters(b);
    }

    void applyBiomeParameters(IslandBiomeType b) {
        const auto& desc = ArchipelagoRegistry::getDescriptor(b);
        island_radius = desc.island_radius;
        peak_height = desc.peak_height;
        sea_level = desc.sea_level;
        if (b == IslandBiomeType::VOLCANO) {
            caldera_radius = 22.0f;
            caldera_depth = 18.0f;
        } else {
            caldera_radius = 0.0f;
            caldera_depth = 0.0f;
        }
    }

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

    int stepSTCReactions() {
        int reaction_count = 0;
        std::vector<uint16_t> next_voxels = voxels;
        const auto& reg = Material::MaterialRegistry::instance();

        for (int y = 1; y < dim_y - 1; ++y) {
            for (int z = 1; z < dim_z - 1; ++z) {
                for (int x = 1; x < dim_x - 1; ++x) {
                    uint16_t current = getVoxel(x, y, z);
                    if (current == Material::MAT_AIR) continue;

                    for (int d = 0; d < 6; ++d) {
                        auto off = Spatial::getDirectionOffset((Spatial::Direction6)d);
                        int nx = x + off.x;
                        int ny = y + off.y;
                        int nz = z + off.z;

                        uint16_t neighbor = getVoxel(nx, ny, nz);
                        uint16_t outcome = reg.evaluateFaceAdjacencySTC(current, neighbor);
                        if (outcome != current) {
                            next_voxels[index(x, y, z)] = outcome;
                            reaction_count++;
                            break;
                        }
                    }
                }
            }
        }

        if (reaction_count > 0) {
            voxels = std::move(next_voxels);
        }
        return reaction_count;
    }

    // ── Geomorphology ──────────────────────────────────────────────────────────

    /** Deterministic height H(x,z) based on active biome. */
    float getIslandHeight(float x,float z) const {
        float dx=x-center_x, dz=z-center_z;
        float r=std::sqrt(dx*dx+dz*dz);
        float theta=std::atan2(dz,dx);

        float h = sea_level - 16.0f; // Base ocean floor

        switch (biome_type) {
            case IslandBiomeType::VOLCANO: {
                if (r <= island_radius * 1.35f) {
                    float flutes = 1.f + 0.11f*std::cos(5.f*theta) + 0.08f*std::sin(3.f*theta) + 0.04f*std::cos(8.f*theta);
                    float cone = (peak_height-sea_level)*std::exp(-std::pow(r/(island_radius*.42f),1.85f))*flutes;
                    h = sea_level + cone;
                    if(r>island_radius*.70f){
                        float t=(r-island_radius*.70f)/(island_radius*.60f);
                        t=std::min(1.0f, std::max(0.0f, t));
                        h=(1.f-t)*h+t*(sea_level-7.5f);
                    }
                    float coastal_spit = noise_boulder.fbm(x*.016f, 0.f, z*.016f, 3, 2.f, .5f) * 3.6f;
                    if(r > island_radius * 0.65f && r < island_radius * 1.15f) h += coastal_spit;
                    if(r<caldera_radius){
                        float ct=1.f-(r/caldera_radius);
                        h-=caldera_depth*(ct*ct);
                    }
                    // Lava river gorge
                    float ad=std::abs(theta-RIVER_ANGLE);
                    if(ad>3.14159f) ad=6.28318f-ad;
                    float rd=r*ad;
                    if(r>caldera_radius*.70f && r<island_radius*.95f && rd<7.5f){
                        h-=(1.f-rd/7.5f)*4.8f;
                    }
                }
                break;
            }

            case IslandBiomeType::JUNGLE: {
                // Majestic twin mountain peaks with lush saddle valley and terraced plateaus
                if (r <= island_radius * 1.35f) {
                    float peak1_dx = x - (center_x - 30.0f);
                    float peak1_dz = z - (center_z + 20.0f);
                    float r1 = std::sqrt(peak1_dx*peak1_dx + peak1_dz*peak1_dz);

                    float peak2_dx = x - (center_x + 35.0f);
                    float peak2_dz = z - (center_z - 25.0f);
                    float r2 = std::sqrt(peak2_dx*peak2_dx + peak2_dz*peak2_dz);

                    float mtn1 = (peak_height - sea_level) * std::exp(-std::pow(r1 / 48.0f, 1.7f));
                    float mtn2 = (peak_height * 0.85f - sea_level) * std::exp(-std::pow(r2 / 44.0f, 1.6f));
                    float ridge = noise_flora.fbm(x * 0.015f, 0.0f, z * 0.015f, 4, 2.0f, 0.55f) * 16.0f;

                    h = sea_level + std::max(mtn1, mtn2) + ridge;

                    // Terraced river valley cutting through center
                    float valley_dist = std::abs(dx * 0.707f - dz * 0.707f);
                    if (valley_dist < 18.0f && r < island_radius * 0.85f) {
                        h -= (1.0f - valley_dist / 18.0f) * 12.0f;
                    }

                    // Coastal jungle shelf
                    if (r > island_radius * 0.65f) {
                        float t = std::min(1.0f, (r - island_radius * 0.65f) / (island_radius * 0.60f));
                        h = (1.0f - t) * h + t * (sea_level - 5.0f);
                    }
                }
                break;
            }

            case IslandBiomeType::DESERT: {
                // Sweeping longitudinal sand dunes & oasis lagoon basin
                if (r <= island_radius * 1.30f) {
                    // Wind dune wave field along diagonal NE wind
                    float dune_coord = (dx + dz * 0.6f) * 0.08f;
                    float dune_wave = std::sin(dune_coord) * 4.5f + std::sin(dune_coord * 0.5f + 1.2f) * 3.0f;
                    float base_dome = (peak_height - sea_level) * std::exp(-std::pow(r / (island_radius * 0.55f), 1.5f));
                    h = sea_level + base_dome + dune_wave;

                    // Central turquoise oasis spring (depressed basin with fresh water)
                    if (r < 28.0f) {
                        float ot = 1.0f - (r / 28.0f);
                        h -= ot * 14.0f;
                        h = std::max(h, sea_level + 0.8f);
                    }

                    // Coastal sandbar spits
                    float spit = noise_detail.fbm(x * 0.022f, 0.0f, z * 0.022f, 3, 2.0f, 0.5f) * 4.2f;
                    if (r > island_radius * 0.7f && r < island_radius * 1.2f) h += spit;

                    if (r > island_radius * 0.60f) {
                        float t = std::min(1.0f, (r - island_radius * 0.60f) / (island_radius * 0.60f));
                        h = (1.0f - t) * h + t * (sea_level - 6.0f);
                    }
                }
                break;
            }

            case IslandBiomeType::GLACIAL_ICE: {
                // Steep icy horn pinnacles, stepped glacier benches, sheer frozen sea cliffs
                if (r <= island_radius * 1.35f) {
                    float horn_fbm = noise_terrain.fbm(x * 0.016f, 0.0f, z * 0.016f, 4, 2.2f, 0.52f);
                    float pinnacle = (peak_height - sea_level) * std::exp(-std::pow(r / (island_radius * 0.38f), 1.4f)) * (0.8f + horn_fbm * 0.6f);
                    h = sea_level + pinnacle;

                    // Stepped ice terrace shelves
                    h = std::floor(h / 3.5f) * 3.5f + (h - std::floor(h / 3.5f) * 3.5f) * 0.3f;

                    // Sheer glacial ice cliffs drop directly into ocean
                    if (r > island_radius * 0.72f) {
                        float t = std::min(1.0f, (r - island_radius * 0.72f) / (island_radius * 0.50f));
                        h = (1.0f - t) * h + t * (sea_level - 9.0f);
                    }
                }
                break;
            }

            case IslandBiomeType::CORAL_ARCHIPELAGO: {
                // 5-islet atoll ring enclosing a central crystal lagoon
                float atoll_radius = island_radius * 0.62f;
                float islet_rad = island_radius * 0.28f;
                float max_islet_h = sea_level - 16.0f;

                for (int i = 0; i < 5; ++i) {
                    float a = i * (6.2831853f / 5.0f);
                    float ix = center_x + std::cos(a) * atoll_radius;
                    float iz = center_z + std::sin(a) * atoll_radius;
                    float idist = std::sqrt((x - ix)*(x - ix) + (z - iz)*(z - iz));
                    if (idist < islet_rad * 1.5f) {
                        float ih = sea_level + (peak_height - sea_level) * std::exp(-std::pow(idist / (islet_rad * 0.55f), 1.6f));
                        max_islet_h = std::max(max_islet_h, ih);
                    }
                }

                // Shallow central turquoise coral lagoon
                float lagoon_dist = r;
                if (lagoon_dist < atoll_radius * 0.90f) {
                    float lagoon_floor = sea_level - 2.2f + noise_detail.fbm(x*0.03f, 0.f, z*0.03f, 2, 2.f, .5f) * 1.5f;
                    max_islet_h = std::max(max_islet_h, lagoon_floor);
                }

                // Outer reef barrier
                if (r > atoll_radius * 0.85f && r < island_radius * 1.15f) {
                    float reef_bar = sea_level - 0.6f + noise_flora.fbm(x * 0.02f, 0.f, z * 0.02f, 3, 2.f, .5f) * 2.0f;
                    max_islet_h = std::max(max_islet_h, reef_bar);
                }

                h = max_islet_h;
                break;
            }

            default:
                break;
        }

        // Fractal micro-roughness
        h += noise_terrain.fbm(x*.028f,.0f,z*.028f,4,2.f,.5f)*3.2f;
        return h;
    }

    /** Authoritative 3D continuous density — positive=solid, negative=void. */
    float sampleContinuousDensity(float x,float y,float z) const {
        if (y < 0.5f) return 1.0f; // Solid bedrock foundation
        if (y > 90.0f) return -1.0f; // Atmospheric sky

        float dx = x - center_x, dz = z - center_z;
        float r = std::sqrt(dx * dx + dz * dz);

        float h = getIslandHeight(x, z);
        float density = h - y;

        // Biome-specific underground & architectural carving
        if (biome_type == IslandBiomeType::DESERT) {
            // Massive monumental hollow sandstone sea arches on outer coastline
            if (r > island_radius * 0.60f && r < island_radius * 1.05f && y > sea_level - 1.0f && y < sea_level + 18.0f) {
                float arch_noise = noise_detail.fbm(x * 0.045f, y * 0.045f, z * 0.045f, 3, 2.0f, 0.5f);
                float arch_span = std::sin((dx + dz) * 0.06f);
                if (arch_span > 0.40f && arch_noise > 0.32f && y < sea_level + 12.0f) {
                    density -= 6.0f; // Carve monumental hollow sea arch!
                }
            }
        } else if (biome_type == IslandBiomeType::GLACIAL_ICE) {
            // Deep glacial crevasses and blue ice tunnels
            if (y < sea_level + 15.0f && y > 2.0f && r < island_radius * 0.85f) {
                float crevasse = noise_detail.fbm(x * 0.035f, y * 0.06f, z * 0.035f, 3, 2.0f, 0.5f);
                if (crevasse > 0.42f) density -= 5.5f;
            }
        } else {
            // Subterranean lava tubes / karst caverns
            if (y < sea_level - 1.0f && y > 3.0f && r < 240.0f) {
                float cave_noise = noise_terrain.fbm(x * 0.032f, y * 0.048f, z * 0.032f, 3, 2.0f, 0.5f);
                float tube_rib = std::sin(x * 0.07f) * std::cos(z * 0.07f) * std::sin(y * 0.12f);
                if (cave_noise > 0.38f + 0.10f * tube_rib) {
                    density -= (cave_noise - 0.38f) * 5.0f;
                }
            }
        }

        return density;
    }

    // ── Beach / Harbor Spawn ───────────────────────────────────────────────────

    SCR::Spatial::Point3D findBeachSpawnPosition() const {
        float sx = center_x - 36.0f;
        float sz = center_z - 118.0f;

        if (biome_type == IslandBiomeType::DESERT) {
            sx = center_x + 30.0f;
            sz = center_z - 110.0f;
        } else if (biome_type == IslandBiomeType::CORAL_ARCHIPELAGO) {
            sx = center_x;
            sz = center_z - 95.0f;
        } else if (biome_type == IslandBiomeType::GLACIAL_ICE) {
            sx = center_x - 30.0f;
            sz = center_z - 110.0f;
        } else if (biome_type == IslandBiomeType::JUNGLE) {
            sx = center_x - 30.0f;
            sz = center_z - 105.0f;
        }

        float h = getIslandHeight(sx, sz);
        if (h < sea_level + 3.0f) h = sea_level + 3.0f;
        return SCR::Spatial::Point3D(sx, h + 1.2f, sz);
    }

    // ── Internal flora helpers ─────────────────────────────────────────────────

    void placePalmTree(int bx,int by,int bz,int height){
        for(int y=0;y<height;y++) setVoxel(bx,by+y,bz,Material::MAT_PALM);
        int ty=by+height;
        for(int dx=-2;dx<=2;dx++) for(int dz=-2;dz<=2;dz++){
            int ad=std::abs(dx)+std::abs(dz);
            if(ad<=2 && inBounds(bx+dx,ty,bz+dz)) setVoxel(bx+dx,ty,bz+dz,Material::MAT_FOLIAGE);
        }
        for(int dx=-1;dx<=1;dx++) for(int dz=-1;dz<=1;dz++)
            if(inBounds(bx+dx,ty+1,bz+dz)) setVoxel(bx+dx,ty+1,bz+dz,Material::MAT_FOLIAGE);
    }

    void placeJungleTree(int bx,int by,int bz,int height){
        for(int y=0;y<height;y++) setVoxel(bx,by+y,bz,Material::MAT_WOOD);
        int ty=by+height;
        for(int layer=-1;layer<=2;layer++){
            int rad=(layer==0||layer==1)?3:2;
            for(int dx=-rad;dx<=rad;dx++) for(int dz=-rad;dz<=rad;dz++){
                if(dx*dx+dz*dz<=rad*rad+1 && inBounds(bx+dx,ty+layer,bz+dz))
                    setVoxel(bx+dx,ty+layer,bz+dz,Material::MAT_FOLIAGE);
            }
        }
    }

    void placePineTree(int bx,int by,int bz,int height){
        for(int y=0;y<height;y++) setVoxel(bx,by+y,bz,Material::MAT_WOOD);
        int ty=by+height;
        for(int layer=0;layer<height-1;layer++){
            int rad = std::max(1, (height - layer) / 2);
            for(int dx=-rad;dx<=rad;dx++) for(int dz=-rad;dz<=rad;dz++){
                if(dx*dx+dz*dz<=rad*rad && inBounds(bx+dx,by+layer+2,bz+dz))
                    setVoxel(bx+dx,by+layer+2,bz+dz,Material::MAT_FOLIAGE);
            }
        }
        if(inBounds(bx,ty+1,bz)) setVoxel(bx,ty+1,bz,Material::MAT_FOLIAGE);
    }

    void placeCactus(int bx,int by,int bz,int height){
        for(int y=0;y<height;y++) setVoxel(bx,by+y,bz,Material::MAT_BAMBOO);
        if(height>=4 && inBounds(bx+1,by+2,bz)) setVoxel(bx+1,by+2,bz,Material::MAT_BAMBOO);
        if(height>=4 && inBounds(bx-1,by+3,bz)) setVoxel(bx-1,by+3,bz,Material::MAT_BAMBOO);
    }

    void placeBoulder(int bx,int by,int bz,uint16_t mat,int size){
        for(int dy=0;dy<size;dy++) for(int dx=-size+1;dx<size;dx++) for(int dz=-size+1;dz<size;dz++){
            if(dx*dx+dy*dy/4+dz*dz<(size*size) && inBounds(bx+dx,by+dy,bz+dz))
                setVoxel(bx+dx,by+dy,bz+dz,mat);
        }
    }

    // ── Main Generation ────────────────────────────────────────────────────────

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

            // River membership for volcano
            float ad=std::abs(theta-RIVER_ANGLE);
            if(ad>3.14159f) ad=6.28318f-ad;
            float river_dist=r*ad;
            bool in_lava_river  = (biome_type==IslandBiomeType::VOLCANO && r>caldera_radius*.65f && r<island_radius*.95f && river_dist<2.2f);
            bool near_lava_river= (biome_type==IslandBiomeType::VOLCANO && r>caldera_radius*.55f && r<island_radius        && river_dist<4.f);

            for(int y=0;y<dim_y;y++){
                if(y==0){ setVoxel(x,y,z,Material::MAT_BEDROCK); continue; }

                if(y<=sy){
                    // Core bedrock / deep substrate
                    if(y<(int)(sea_level-4.f)){
                        if(biome_type==IslandBiomeType::DESERT) setVoxel(x,y,z,Material::MAT_SANDSTONE);
                        else if(biome_type==IslandBiomeType::GLACIAL_ICE) setVoxel(x,y,z,Material::MAT_ICE);
                        else setVoxel(x,y,z,Material::MAT_BASALT);
                        continue;
                    }

                    // Volcano Caldera magma lake
                    if(biome_type==IslandBiomeType::VOLCANO && r<caldera_radius*.7f){
                        if(y>=sy-1)      setVoxel(x,y,z,Material::MAT_LAVA);
                        else if(y>=sy-4) setVoxel(x,y,z,Material::MAT_OBSIDIAN);
                        else             setVoxel(x,y,z,Material::MAT_BASALT);
                        continue;
                    }
                    if(in_lava_river){
                        setVoxel(x,y,z, y>=sy-1?Material::MAT_LAVA:Material::MAT_OBSIDIAN);
                        continue;
                    }

                    // Biome-specific Surface and Sub-surface
                    if(y==sy || y==sy-1){
                        switch(biome_type){
                            case IslandBiomeType::DESERT:
                                if(h>=32.f) setVoxel(x,y,z,Material::MAT_SANDSTONE);
                                else        setVoxel(x,y,z,Material::MAT_SAND);
                                break;
                            case IslandBiomeType::GLACIAL_ICE:
                                if(h>=28.f) setVoxel(x,y,z,Material::MAT_ICE);
                                else if(h>=16.f) setVoxel(x,y,z,Material::MAT_ICE);
                                else        setVoxel(x,y,z,Material::MAT_GRANITE);
                                break;
                            case IslandBiomeType::JUNGLE:
                                if(h>=30.f) setVoxel(x,y,z,Material::MAT_MOSS);
                                else if(h>=12.f) setVoxel(x,y,z,Material::MAT_DIRT);
                                else if(h>=8.f)  setVoxel(x,y,z,Material::MAT_SAND);
                                else             setVoxel(x,y,z,Material::MAT_SAND);
                                break;
                            case IslandBiomeType::CORAL_ARCHIPELAGO:
                                if(h>=18.f) setVoxel(x,y,z,Material::MAT_MOSS);
                                else if(h>=9.5f) setVoxel(x,y,z,Material::MAT_DIRT);
                                else        setVoxel(x,y,z,Material::MAT_SAND);
                                break;
                            case IslandBiomeType::VOLCANO:
                            default:
                                if(near_lava_river) setVoxel(x,y,z,Material::MAT_OBSIDIAN);
                                else if(r<caldera_radius*1.3f){
                                    float sn=noise_flora.noise(x*.22f,.0f,z*.22f);
                                    setVoxel(x,y,z, sn>.3f ? Material::MAT_SULFUR : sn<-.25f? Material::MAT_ASH : Material::MAT_BASALT);
                                }
                                else if(h>=22.f) setVoxel(x,y,z,Material::MAT_BASALT);
                                else if(h>=14.f) setVoxel(x,y,z,Material::MAT_DIRT);
                                else             setVoxel(x,y,z,Material::MAT_SAND);
                                break;
                        }
                    } else {
                        // Subsurface
                        if(biome_type==IslandBiomeType::DESERT) setVoxel(x,y,z,Material::MAT_SANDSTONE);
                        else if(biome_type==IslandBiomeType::GLACIAL_ICE) setVoxel(x,y,z,Material::MAT_ICE);
                        else if(biome_type==IslandBiomeType::JUNGLE) setVoxel(x,y,z,Material::MAT_DIRT);
                        else setVoxel(x,y,z,Material::MAT_BASALT);
                    }
                } else if(y<=(int)sea_level){
                    setVoxel(x,y,z,Material::MAT_WATER);
                }
            }
        }

        // ── Pass 3: Flora Placement based on Biome ────────────────────────────
        for(int x=2;x<dim_x-2;x++) for(int z=2;z<dim_z-2;z++){
            float fx=float(x),fz=float(z);
            float h=getIslandHeight(fx,fz);
            int sy=(int)std::floor(h);
            if(sy<1||sy>=dim_y-8) continue;

            float tn=noise_tree.fbm(fx*0.04f,0.f,fz*0.04f,3,2.f,0.5f);

            if(biome_type==IslandBiomeType::DESERT){
                if(h>=sea_level+1.f && h<=sea_level+12.f && tn>0.48f && (x%14==0)&&(z%14==0)){
                    placePalmTree(x,sy+1,z,5);
                } else if(h>sea_level+4.f && tn>0.35f && (x%11==0)&&(z%11==0)){
                    placeCactus(x,sy+1,z,3);
                }
            } else if(biome_type==IslandBiomeType::GLACIAL_ICE){
                if(h>=sea_level+2.f && h<=sea_level+26.f && tn>0.42f && (x%16==0)&&(z%16==0)){
                    placePineTree(x,sy+1,z,6);
                }
            } else if(biome_type==IslandBiomeType::JUNGLE){
                if(h>=sea_level+1.f && h<sea_level+7.f && tn>0.32f && (x%8==0)&&(z%8==0)){
                    placePalmTree(x,sy+1,z,6);
                } else if(h>=sea_level+6.f && h<=sea_level+32.f && tn>0.28f && (x%6==0)&&(z%6==0)){
                    placeJungleTree(x,sy+1,z,7);
                }
            } else if(biome_type==IslandBiomeType::CORAL_ARCHIPELAGO){
                if(h>=sea_level+0.8f && h<=sea_level+14.f && tn>0.30f && (x%9==0)&&(z%9==0)){
                    placePalmTree(x,sy+1,z,5);
                }
            } else {
                // VOLCANO
                if(h>=sea_level+1.f && h<sea_level+7.f && tn>0.38f && (x%10==0)&&(z%10==0)){
                    placePalmTree(x,sy+1,z,6);
                } else if(h>=sea_level+7.f && h<=sea_level+18.f && tn>0.30f && (x%8==0)&&(z%8==0)){
                    placeJungleTree(x,sy+1,z,6);
                }
            }
        }
    }
};

} // namespace SCR::Island

#endif // CAVE_PROCEDURAL_ISLAND_HPP
