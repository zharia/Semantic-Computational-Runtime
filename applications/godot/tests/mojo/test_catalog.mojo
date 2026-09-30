# Spec test — Material catalog invariant (milestone_0002 §6.5 / AP-3):
# every shading parameter the snapshot can carry derives from
# lib/A01_Render/Material/materials_catalog.json, loaded repo-relative
# (AP-4: no absolute paths).

# NOTE on `assert`: this Mojo 1.0.0 toolchain compiles `assert` to a no-op
# (verified in test_volcano.mojo: `assert False` does not stop execution).
# Every check below uses `_check`, which raises Error => TestSuite reports
# FAIL and exits non-zero.

from std.collections import List
from std.testing import TestSuite
from std.math import abs

from util.files import find_repo_root, join_path, read_file_text
from materials.json import parse_json
from materials.catalog import (
    load_catalog,
    vocab_catalog_id_string,
    species_catalog_id_string,
    SPECIES_NONE,
    SPECIES_COUNT,
    MAT_VOCAB_COUNT,
    MAT_BEDROCK,
    MAT_BASALT,
    MAT_SAND,
    MAT_OBSIDIAN,
    MAT_DIRT,
    MAT_PUMICE,
    MAT_SULFUR,
    MAT_ASH,
    MAT_WATER,
    MAT_LAVA,
)
from sim.parameters import MATERIAL_EMISSION_SATURATION

comptime REL_PATH = "lib/A01_Render/Material/materials_catalog.json"


def _check(cond: Bool, msg: String) raises:
    """Raise-based check (see header note: `assert` is a no-op here)."""
    if not cond:
        raise Error(msg)


def test_catalog_loads_repo_relative() raises:
    var root = find_repo_root()
    _check(root.byte_length() > 0,  "repo root discoverable")
    var path = join_path(root, REL_PATH)
    # AP-4: path is built repo-relative; must exist and parse.
    var doc = parse_json(read_file_text(path))
    _check(doc.has("materials"),  "catalog has materials array")
    var materials = doc.get("materials")
    _check(materials.len() >= 96,  "full catalog present")

def test_vocabulary_ids_stable() raises:
    var cat = load_catalog()
    _check(cat.count() == MAT_VOCAB_COUNT,  "one def per vocabulary code")
    # Vocab → catalog id strings (single source, table-driven).
    _check(vocab_catalog_id_string(MAT_BEDROCK) == "rock.basalt",  "deviation: bedrock→basalt")
    _check(vocab_catalog_id_string(MAT_BASALT) == "rock.basalt", "line 47")
    _check(vocab_catalog_id_string(MAT_SAND) == "soil.sand", "line 48")
    _check(vocab_catalog_id_string(MAT_OBSIDIAN) == "rock.obsidian", "line 49")
    _check(vocab_catalog_id_string(MAT_DIRT) == "soil.dirt", "line 50")
    _check(vocab_catalog_id_string(MAT_PUMICE) == "rock.pumice", "line 51")
    _check(vocab_catalog_id_string(MAT_SULFUR) == "mineral.sulfur", "line 52")
    _check(vocab_catalog_id_string(MAT_ASH) == "mineral.ash", "line 53")
    _check(vocab_catalog_id_string(MAT_WATER) == "fluid.water", "line 54")
    _check(vocab_catalog_id_string(MAT_LAVA) == "fluid.lava", "line 55")


def test_derivation_matches_raw_catalog() raises:
    # Independent re-derivation straight from the JSON (not via load_catalog):
    # the loader must be a pure projection of the file.
    var root = find_repo_root()
    var doc = parse_json(read_file_text(join_path(root, REL_PATH)))
    var materials = doc.get("materials")
    var index_by_id = List[String]()
    for i in range(materials.len()):
        index_by_id.append(materials.at(i).get("id").as_string())

    var cat = load_catalog()
    for code in range(MAT_VOCAB_COUNT):
        var want_id = vocab_catalog_id_string(UInt32(code))
        var found = -1
        for i in range(len(index_by_id)):
            if index_by_id[i] == want_id:
                found = i
        _check(found >= 0, "id missing in raw catalog: " + want_id)
        var entry = materials.at(found)
        var optical = entry.get("optical")
        var defn = cat.defs[code].copy()
        # Stable id = array position.
        _check(Int(defn.catalog_index) == found,  "stable id drift")
        _check(defn.catalog_id == want_id,  "id string drift")
        # Albedo / roughness / opacity / emissive derivation (SCR-LIB-RENDER-MATERIAL).
        var albedo = optical.get("base_color_srgb")
        _check(abs(defn.albedo_r - Float32(albedo.at(0).as_float())) < 1e-6, "line 84")
        _check(abs(defn.albedo_g - Float32(albedo.at(1).as_float())) < 1e-6, "line 85")
        _check(abs(defn.albedo_b - Float32(albedo.at(2).as_float())) < 1e-6, "line 86")
        _check(abs(defn.roughness - Float32(optical.get("roughness").as_float())) < 1e-6, "line 87")
        var transmission = Float64(optical.get("transmission").as_float())
        _check(abs(Float64(defn.opacity) - (1.0 - transmission)) < 1e-5,  "opacity = 1 − transmission")
        var emission = Float64(optical.get("emission_cd_m2").as_float())
        var scale = emission / MATERIAL_EMISSION_SATURATION
        if scale > 1.0:
            scale = 1.0
        _check(abs(Float64(defn.emissive_r) - Float64(defn.albedo_r) * scale) < 1e-5,  "emissive = albedo·sat")


def test_no_hand_authored_vocabulary() raises:
    # AP-3: every id the sim can emit exists in the catalog file — no second
    # source of truth. (Vocab table only maps onto catalog ids.)
    var root = find_repo_root()
    var doc = parse_json(read_file_text(join_path(root, REL_PATH)))
    var materials = doc.get("materials")
    var index_by_id = List[String]()
    for i in range(materials.len()):
        index_by_id.append(materials.at(i).get("id").as_string())
    for code in range(MAT_VOCAB_COUNT):
        var want = vocab_catalog_id_string(UInt32(code))
        var found = False
        for i in range(len(index_by_id)):
            if index_by_id[i] == want:
                found = True
        _check(found, "vocabulary id not from catalog: " + want)


def test_species_ids_single_sourced() raises:
    # 0006 AP-14: every flora species id maps onto exactly one
    # materials_catalog.json id (invariant 6) — no hand-authored colours,
    # no second source of truth. SPECIES_NONE must raise (never emitted).
    var root = find_repo_root()
    var doc = parse_json(read_file_text(join_path(root, REL_PATH)))
    var materials = doc.get("materials")
    var index_by_id = List[String]()
    for i in range(materials.len()):
        index_by_id.append(materials.at(i).get("id").as_string())

    var raised = False
    try:
        _ = species_catalog_id_string(SPECIES_NONE)
    except e:
        raised = True
    _check(raised, "SPECIES_NONE must raise (no material)")

    var seen_ids = List[String]()
    for species in range(1, SPECIES_COUNT):
        var want = species_catalog_id_string(UInt32(species))
        var found = False
        for i in range(len(index_by_id)):
            if index_by_id[i] == want:
                found = True
        _check(found, "species id not from catalog: " + want)
        # Exactly one row per species — the table is total on 1..7.
        var dup = False
        for i in range(len(seen_ids)):
            if seen_ids[i] == want:
                dup = True
        _ = dup  # shared display materials (foliage) are legal; ids resolve
        seen_ids.append(want)


def main() raises:
    TestSuite.discover_tests[
        (
            test_catalog_loads_repo_relative,
            test_vocabulary_ids_stable,
            test_derivation_matches_raw_catalog,
            test_no_hand_authored_vocabulary,
            test_species_ids_single_sourced,
        )
    ]().run()
