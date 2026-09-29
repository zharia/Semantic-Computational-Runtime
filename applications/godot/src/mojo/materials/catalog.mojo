# Material vocabulary + catalog loader (SCR-LIB-RENDER-MATERIAL).
#
# Single material source (milestone invariant 5 / AP-3): every shading
# parameter in the RenderSnapshot derives from
# `lib/A01_Render/Material/materials_catalog.json`, loaded repo-relative via
# util.files.find_repo_root() (AP-4: no absolute paths in source).
#
# Stable u32 ids (104_contract.md §4.3): `catalog_index` — the record's
# position in the catalog `materials[]` array, assigned at load, stable for a
# given catalog file. Snapshot MATERIALS records carry this id; TERRAIN
# vertex material_ids carry it too.
#
# DEVIATION (recorded): the catalog has no `bedrock` entry; MAT_BEDROCK maps
# to `rock.basalt` (nearest normative geological equivalent).

from std.collections import List
from materials.json import parse_json, JSON_ARRAY, JSON_STRING, JSON_NUMBER
from util.files import find_repo_root, join_path, read_file_text
from sim.parameters import MATERIAL_EMISSION_SATURATION

# --- Voxel material codes (pipeline vocabulary, §2 of Voxel/Synthesis) -----
comptime MAT_BEDROCK: UInt32 = 0
comptime MAT_BASALT: UInt32 = 1
comptime MAT_SAND: UInt32 = 2
comptime MAT_ASH: UInt32 = 3
comptime MAT_SULFUR: UInt32 = 4
comptime MAT_OBSIDIAN: UInt32 = 5
comptime MAT_LAVA: UInt32 = 6
comptime MAT_WATER: UInt32 = 7
comptime MAT_DIRT: UInt32 = 8
comptime MAT_PUMICE: UInt32 = 9
# milestone_0005: non-source lava quench outcome (material_reactions.json
# reaction.lava_water_quench → rock.cobblestone); unused by any biome row.
comptime MAT_COBBLESTONE: UInt32 = 10
comptime MAT_VOCAB_COUNT: Int = 11


def vocab_catalog_id_string(code: UInt32) raises -> String:
    """Table: voxel code → catalog `id` string (index = code)."""
    if Int(code) >= MAT_VOCAB_COUNT:
        raise Error("unknown voxel material code " + String(Int(code)))
    var table = List[String]()
    table.append("rock.basalt")  # 0 MAT_BEDROCK  (deviation: no bedrock entry)
    table.append("rock.basalt")  # 1 MAT_BASALT
    table.append("soil.sand")  # 2 MAT_SAND
    table.append("mineral.ash")  # 3 MAT_ASH
    table.append("mineral.sulfur")  # 4 MAT_SULFUR
    table.append("rock.obsidian")  # 5 MAT_OBSIDIAN
    table.append("fluid.lava")  # 6 MAT_LAVA
    table.append("fluid.water")  # 7 MAT_WATER
    table.append("soil.dirt")  # 8 MAT_DIRT
    table.append("rock.pumice")  # 9 MAT_PUMICE
    table.append("rock.cobblestone")  # 10 MAT_COBBLESTONE (quench, 0005)
    return table[Int(code)].copy()


struct MaterialDef(Copyable, Movable, Deinitable):
    var voxel_code: UInt32
    var catalog_id: String
    var catalog_index: UInt32  # stable u32 id carried in snapshots
    var albedo_r: Float32
    var albedo_g: Float32
    var albedo_b: Float32
    var roughness: Float32
    var metallic: Float32
    var emissive_r: Float32
    var emissive_g: Float32
    var emissive_b: Float32
    var opacity: Float32

    def __init__(
        out self,
        voxel_code: UInt32,
        catalog_id: String,
        catalog_index: UInt32,
        albedo_r: Float32,
        albedo_g: Float32,
        albedo_b: Float32,
        roughness: Float32,
        metallic: Float32,
        emissive_r: Float32,
        emissive_g: Float32,
        emissive_b: Float32,
        opacity: Float32,
    ):
        self.voxel_code = voxel_code
        self.catalog_id = catalog_id
        self.catalog_index = catalog_index
        self.albedo_r = albedo_r
        self.albedo_g = albedo_g
        self.albedo_b = albedo_b
        self.roughness = roughness
        self.metallic = metallic
        self.emissive_r = emissive_r
        self.emissive_g = emissive_g
        self.emissive_b = emissive_b
        self.opacity = opacity

    def __deinit__(deinit self):
        pass


struct MaterialCatalog(Copyable, Movable, Deinitable):
    var defs: List[MaterialDef]  # index = voxel code
    var root: String  # repo root used for the load (diagnostics)

    def __init__(out self, var defs: List[MaterialDef], root: String):
        self.defs = defs^
        self.root = root

    def __deinit__(deinit self):
        pass

    def def_for(self, code: UInt32) raises -> MaterialDef:
        if Int(code) >= MAT_VOCAB_COUNT:
            raise Error("unknown voxel material code " + String(Int(code)))
        return self.defs[Int(code)].copy()

    def catalog_id_of(self, code: UInt32) raises -> UInt32:
        return self.def_for(code).catalog_index

    def count(self) -> Int:
        return len(self.defs)


def load_catalog() raises -> MaterialCatalog:
    """Load + derive the core-slice vocabulary from the normative catalog."""
    var root = find_repo_root()
    var path = join_path(root, "lib/A01_Render/Material/materials_catalog.json")
    var doc = parse_json(read_file_text(path))
    if not doc.has("materials"):
        raise Error("materials_catalog.json: missing 'materials'")
    var materials = doc.get("materials")

    # Index catalog entries by id string (stable ids = array position).
    var index_by_id = List[String]()
    for i in range(materials.len()):
        var entry = materials.at(i)
        index_by_id.append(entry.get("id").as_string())

    var defs = List[MaterialDef]()
    for code in range(MAT_VOCAB_COUNT):
        var want = vocab_catalog_id_string(UInt32(code))
        var found = -1
        for i in range(len(index_by_id)):
            if index_by_id[i] == want:
                found = i
                break
        if found < 0:
            raise Error("catalog id not found: " + want)
        var entry = materials.at(found)
        var optical = entry.get("optical")
        var albedo = optical.get("base_color_srgb")
        var r = Float32(albedo.at(0).as_float())
        var g = Float32(albedo.at(1).as_float())
        var b = Float32(albedo.at(2).as_float())
        var roughness = Float32(optical.get("roughness").as_float())
        var metallic = Float32(optical.get("metallic").as_float())
        var transmission = Float32(optical.get("transmission").as_float())
        var emission = Float64(optical.get("emission_cd_m2").as_float())
        var scale = emission / MATERIAL_EMISSION_SATURATION
        if scale > 1.0:
            scale = 1.0
        if scale < 0.0:
            scale = 0.0
        var f = Float32(scale)
        defs.append(
            MaterialDef(
                voxel_code=UInt32(code),
                catalog_id=want^,
                catalog_index=UInt32(found),
                albedo_r=r,
                albedo_g=g,
                albedo_b=b,
                roughness=roughness,
                metallic=metallic,
                emissive_r=r * f,
                emissive_g=g * f,
                emissive_b=b * f,
                opacity=1.0 - transmission,
            )
        )
    return MaterialCatalog(defs^, root^)
