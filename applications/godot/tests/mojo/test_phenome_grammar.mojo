# Milestone 0010 Sprint 01 — Flora Phenome core contract tests (R6).
#
# Exercises the CONTRACT, not the implementation:
#   (1) stage_for_age == the JSON stage table (monotone, bounded, pure);
#   (2) variant_seed pure + distinct over the 64×64 build grid;
#   (3) trait quantization + modulation exact vs phenome_grammars.json
#       (AP-24: integers only, no float in the conformance axis);
#   (4) grammar file parses/validates (AP-23: JSON is the vocabulary);
#   (5) reference expansion deterministic, bounded, depth-table driven,
#       trait-sensitive (never in the tick path — R5);
#   (6) goldens.txt matches a fresh expansion (AP-24 conformance axis);
#   (7) wire record stride: FLORA_RECORD_BYTES == 32 (Sprint 02, 0010
#       §3.2 — schema 7 record grew 24 → 32 B).
#
# raise-based checks: `assert` is a NO-OP in this toolchain (see
# test_flora_growth.mojo header).
#
# Run (from repo root):
#   mojo run -I applications/godot/src/mojo \
#     applications/godot/tests/mojo/test_phenome_grammar.mojo

from std.collections import List
from std.testing import TestSuite

from sim.parameters import (
    STAGE_MAX,
    PHENOME_STAGE_COUNT,
    PHENOME_TRAIT_QUANT,
    PHENOME_EXPAND_MAX_MODULES,
)
from sim.phenome import (
    stage_for_age,
    variant_seed,
    trait_quantize,
    phenome_modulate,
    phenome_maturity_ticks,
    phenome_param_crown,
    phenome_param_leaf,
    phenome_mod_delta,
    PHENOME_TRAIT_INDEX_ASH,
    PHENOME_TRAIT_INDEX_DROUGHT,
)
from phenome.expand import (
    parse_grammars,
    find_grammar,
    expand_derivation,
    expand_derivation_f64,
    render_derivation,
    grammar_depth,
    derivation_module_count,
    Grammar,
)
from snapshot.types import FLORA_RECORD_BYTES
from util.files import find_repo_root, join_path, read_file_text

comptime GRAMMAR_REL = "applications/godot/godot/data/phenome_grammars.json"
comptime GOLDEN_REL = "applications/godot/tests/fixtures/phenome/goldens.txt"
comptime SPECIES_COUNT: Int = 7

# Frozen probe points (mirror gen_phenome_goldens.mojo — keep in sync).
comptime GOLDEN_VSEED: UInt32 = 12345


def _check(cond: Bool, msg: String) raises:
    if not cond:
        raise Error(msg)


def _grams() raises -> List[Grammar]:
    var root = find_repo_root()
    return parse_grammars(read_file_text(join_path(root, GRAMMAR_REL)))


def _millis(ash_milli: Int, dry_milli: Int) -> List[Int]:
    var m = List[Int]()
    m.append(ash_milli)
    m.append(dry_milli)
    return m^


def _param_index(g: Grammar, name: String) -> Int:
    for i in range(len(g.param_names)):
        if g.param_names[i] == name:
            return i
    return -1


def _split_lines(text: String) -> List[String]:
    """Manual byte splitter — no reliance on String.split semantics."""
    var out = List[String]()
    var cur = String()
    for b in text.bytes():
        if Int(b) == 10:  # '\n'
            out.append(cur^)
            cur = String()
        else:
            cur = cur + chr(Int(b))
    if cur.byte_length() > 0:
        out.append(cur^)
    return out^


def _split_golden(line: String) -> List[String]:
    """Split a golden line into exactly 8 fields; the render (field 8) may
    contain spaces but never '|'."""
    var out = List[String]()
    var cur = String()
    for b in line.bytes():
        if Int(b) == 124 and len(out) < 7:  # '|'
            out.append(cur^)
            cur = String()
        else:
            cur = cur + chr(Int(b))
    out.append(cur^)
    return out^


# --- (1) grammar file parses, validates, and looks up ------------------------

def test_grammar_file_parses_and_validates() raises:
    var gs = _grams()
    _check(len(gs) == SPECIES_COUNT, "seven species grammars")
    var ids = List[String]()
    ids.append("flora.palm_cluster")
    ids.append("flora.palm_solo")
    ids.append("flora.bamboo_grove")
    ids.append("flora.canopy_tree")
    ids.append("flora.canopy_cluster")
    ids.append("flora.shrub")
    ids.append("flora.fern_carpet")
    for i in range(len(ids)):
        var gi = find_grammar(gs, ids[i])
        _check(gi == i, "grammar order " + ids[i])
        var g = gs[gi].copy()
        _check(
            g.species_id == i + 1,
            "species_id sequential from 1 for " + ids[i],
        )
        _check(
            len(g.trait_names) == 2
            and g.trait_names[0] == "ash_tolerance"
            and g.trait_names[1] == "drought_tolerance",
            "trait vocabulary order for " + ids[i],
        )
        _check(
            len(g.stage_depths) == PHENOME_STAGE_COUNT,
            "16-row stage_depths for " + ids[i],
        )
        _check(
            len(g.maturity) == PHENOME_STAGE_COUNT,
            "16-row maturity for " + ids[i],
        )
        _check(g.maturity[0] == 0, "maturity[0] == 0 for " + ids[i])
        var prev_d = -1
        var prev_m = -1
        for s in range(PHENOME_STAGE_COUNT):
            _check(
                g.stage_depths[s] >= prev_d,
                "stage_depths non-decreasing for " + ids[i],
            )
            _check(
                g.maturity[s] > prev_m,
                "maturity strictly increasing for " + ids[i],
            )
            prev_d = g.stage_depths[s]
            prev_m = g.maturity[s]
            _check(
                grammar_depth(g, s) == g.stage_depths[s],
                "grammar_depth == table row " + String(s) + " for " + ids[i],
            )
        _check(
            phenome_maturity_ticks(UInt32(g.species_id)) == g.maturity[STAGE_MAX],
            "sim maturity mirror == JSON maturity[STAGE_MAX] for " + ids[i],
        )
    var raised = False
    try:
        _ = find_grammar(gs, "flora.nonexistent")
    except e:
        raised = True
    _check(raised, "unknown grammar_id raises")


# --- (2) stage_for_age: pure, monotone, bounded, JSON-exact ------------------

def test_stage_for_age_monotone_bounded_and_json_exact() raises:
    var gs = _grams()
    for i in range(len(gs)):
        var g = gs[i].copy()
        var sp = UInt32(g.species_id)
        var mat = g.maturity[STAGE_MAX]
        var prev = -1
        for age in range(-5, mat + 101):
            var s = stage_for_age(sp, age)
            _check(s >= 0 and s <= STAGE_MAX, "stage within [0, STAGE_MAX]")
            _check(
                s >= prev,
                "stage monotone at age " + String(age) + " (" + g.grammar_id + ")",
            )
            _check(
                s == 0 if age <= 0 else True,
                "stage 0 at age <= 0 (" + g.grammar_id + ")",
            )
            # JSON-table oracle: max s with maturity[s] <= age (>= 0).
            var oracle = 0
            for si in range(PHENOME_STAGE_COUNT):
                if g.maturity[si] <= age:
                    oracle = si
            _check(
                s == oracle,
                "stage == JSON table at age "
                + String(age)
                + " ("
                + g.grammar_id
                + "): "
                + String(s)
                + " vs "
                + String(oracle),
            )
            prev = s
        _check(
            stage_for_age(sp, mat) == STAGE_MAX,
            "stage == STAGE_MAX at maturity (" + g.grammar_id + ")",
        )


# --- (3) variant_seed: pure, distinct on the build grid ----------------------

def test_variant_seed_pure_and_distinct_on_grid() raises:
    var a = variant_seed(1, 10, 20)
    _check(a == variant_seed(1, 10, 20), "variant_seed deterministic")
    _check(
        a != variant_seed(2, 10, 20),
        "variant_seed varies with world seed",
    )
    _check(a != variant_seed(1, 11, 20), "variant_seed varies with x")
    _check(a != variant_seed(1, 10, 21), "variant_seed varies with z")
    # 64×64 build grid, seed 1: every cell a distinct u32 (measured — the
    # splitmix64 finalizer has no collisions on this grid for seed 1).
    var vals = List[UInt32]()
    for x in range(64):
        for z in range(64):
            vals.append(variant_seed(1, x, z))
    _check(len(vals) == 4096, "grid size 4096")
    for i in range(len(vals)):
        for j in range(i + 1, len(vals)):
            _check(
                vals[i] != vals[j],
                "grid collision at (" + String(i) + ", " + String(j) + ")",
            )


# --- (4) quantization + constants mirror the JSON file -----------------------

def test_quantize_and_constants_match_json() raises:
    _check(trait_quantize(0.0) == 0, "quantize 0")
    _check(trait_quantize(0.317) == 317, "quantize 0.317")
    _check(trait_quantize(0.9999) == 999, "quantize 0.9999 floors")
    _check(trait_quantize(1.0) == PHENOME_TRAIT_QUANT, "quantize 1.0")
    _check(trait_quantize(-0.5) == 0, "quantize clamps low")
    _check(trait_quantize(1.5) == PHENOME_TRAIT_QUANT, "quantize clamps high")
    var gs = _grams()
    for i in range(len(gs)):
        var g = gs[i].copy()
        var sp = UInt32(g.species_id)
        var ci = _param_index(g, "crown_density")
        var li = _param_index(g, "leaf_count")
        _check(ci >= 0 and li >= 0, "crown_density + leaf_count params exist")
        _check(
            g.param_values[ci].den == 1 and g.param_values[li].den == 1,
            "base params integer (AP-24)",
        )
        _check(
            phenome_param_crown(sp) == g.param_values[ci].num,
            "crown base mirror == JSON for " + g.grammar_id,
        )
        _check(
            phenome_param_leaf(sp) == g.param_values[li].num,
            "leaf base mirror == JSON for " + g.grammar_id,
        )
        var saw_ash = False
        var saw_dry = False
        for j in range(len(g.mod_params)):
            var tidx = g.mod_trait_idx[j]
            if tidx == PHENOME_TRAIT_INDEX_ASH:
                saw_ash = True
                var pi = _param_index(g, g.mod_params[j])
                _check(
                    pi == ci,
                    "ash modulates crown_density for " + g.grammar_id,
                )
                _check(
                    phenome_mod_delta(sp, PHENOME_TRAIT_INDEX_ASH)
                    == g.mod_deltas[j],
                    "ash delta mirror == JSON for " + g.grammar_id,
                )
            elif tidx == PHENOME_TRAIT_INDEX_DROUGHT:
                saw_dry = True
                var pi = _param_index(g, g.mod_params[j])
                _check(
                    pi == li,
                    "drought modulates leaf_count for " + g.grammar_id,
                )
                _check(
                    phenome_mod_delta(sp, PHENOME_TRAIT_INDEX_DROUGHT)
                    == g.mod_deltas[j],
                    "drought delta mirror == JSON for " + g.grammar_id,
                )
        _check(saw_ash and saw_dry, "both modulation entries present")


# --- (5) modulation: exact integer conformance vs JSON -----------------------

def test_modulation_exact_vs_json() raises:
    var gs = _grams()
    var ashes = List[Float64]()
    var drys = List[Float64]()
    ashes.append(0.0)
    ashes.append(0.317)
    ashes.append(0.622)
    ashes.append(1.0)
    drys.append(0.0)
    drys.append(0.622)
    drys.append(0.317)
    drys.append(1.0)
    for i in range(len(gs)):
        var g = gs[i].copy()
        var sp = UInt32(g.species_id)
        var ci = _param_index(g, "crown_density")
        var li = _param_index(g, "leaf_count")
        var ash_delta = phenome_mod_delta(sp, PHENOME_TRAIT_INDEX_ASH)
        var dry_delta = phenome_mod_delta(sp, PHENOME_TRAIT_INDEX_DROUGHT)
        for k in range(len(ashes)):
            var ash = ashes[k]
            var dry = drys[k]
            var p = phenome_modulate(sp, ash, dry)
            var exp_crown = (
                g.param_values[ci].num * PHENOME_TRAIT_QUANT
                + ash_delta * trait_quantize(ash)
            )
            var exp_leaf = (
                g.param_values[li].num * PHENOME_TRAIT_QUANT
                + dry_delta * trait_quantize(dry)
            )
            _check(
                p.crown_density_milli == exp_crown,
                "crown milli exact for "
                + g.grammar_id
                + " traits ("
                + String(exp_crown)
                + " vs "
                + String(p.crown_density_milli)
                + ")",
            )
            _check(
                p.leaf_count_milli == exp_leaf,
                "leaf milli exact for " + g.grammar_id,
            )


# --- (6) reference expansion: deterministic, bounded, trait-sensitive --------

def test_expansion_deterministic_bounded_and_trait_sensitive() raises:
    var gs = _grams()
    var stage_probes = List[Int]()
    stage_probes.append(0)
    stage_probes.append(5)
    stage_probes.append(10)
    stage_probes.append(STAGE_MAX)
    for i in range(len(gs)):
        var g = gs[i].copy()
        var prev_depth = -1
        var prev_count = -1
        for si in range(len(stage_probes)):
            var stage = stage_probes[si]
            var m = _millis(317, 622)
            var mods1 = expand_derivation(g, GOLDEN_VSEED, stage, m)
            var mods2 = expand_derivation(g, GOLDEN_VSEED, stage, m)
            _check(
                render_derivation(mods1) == render_derivation(mods2),
                "run-twice identical for " + g.grammar_id,
            )
            var depth = grammar_depth(g, stage)
            _check(
                depth >= prev_depth,
                "depth non-decreasing in stage for " + g.grammar_id,
            )
            prev_depth = depth
            if stage == 0:
                _check(
                    derivation_module_count(mods1) == len(g.axiom),
                    "stage 0 is axiom-only for " + g.grammar_id,
                )
            var mu = _millis(317, 622)
            var count = derivation_module_count(
                expand_derivation(g, GOLDEN_VSEED, stage, mu)
            )
            _check(
                count <= PHENOME_EXPAND_MAX_MODULES,
                "module cap for " + g.grammar_id,
            )
            _check(count >= 1, "non-empty derivation for " + g.grammar_id)
            _check(
                count >= prev_count,
                "structure accretes with stage for " + g.grammar_id,
            )
            prev_count = count
    # Seed sensitivity: a different variant_seed changes the axiom jitter
    # (axiom_jitter_mod >= 1 declared per species; at least one species's
    # axiom must react — checked over all seven grammars).
    var seed_sensitive = False
    for i in range(len(gs)):
        var g = gs[i].copy()
        var m0 = _millis(0, 0)
        var r1 = render_derivation(
            expand_derivation(g, 1, STAGE_MAX, m0)
        )
        var r2 = render_derivation(
            expand_derivation(g, 2, STAGE_MAX, m0)
        )
        if r1 != r2:
            seed_sensitive = True
    _check(seed_sensitive, "variant_seed visibly enters the derivation")
    # Trait sensitivity at stage 15 on every grammar: both traits at 0 vs
    # both at 1000 must render differently (modulation changes params).
    for i in range(len(gs)):
        var g = gs[i].copy()
        var r0 = render_derivation(
            expand_derivation(g, GOLDEN_VSEED, STAGE_MAX, _millis(0, 0))
        )
        var r1 = render_derivation(
            expand_derivation(g, GOLDEN_VSEED, STAGE_MAX, _millis(1000, 1000))
        )
        _check(
            r0 != r1,
            "trait variation changes derivation for " + g.grammar_id,
        )
    # f64 bridge: expand_derivation_f64 == expand over quantized millis.
    var g4 = gs[find_grammar(gs, "flora.canopy_tree")].copy()
    var rf = expand_derivation_f64(g4, GOLDEN_VSEED, STAGE_MAX, 0.317, 0.622)
    var rm = expand_derivation(g4, GOLDEN_VSEED, STAGE_MAX, _millis(317, 622))
    _check(
        render_derivation(rf) == render_derivation(rm),
        "f64 bridge == quantized expansion",
    )


# --- (7) goldens.txt matches a fresh expansion -------------------------------

def test_goldens_match() raises:
    var root = find_repo_root()
    var text = read_file_text(join_path(root, GOLDEN_REL))
    var gs = _grams()
    var lines = _split_lines(text)
    var checked = 0
    for li in range(len(lines)):
        var line = lines[li]
        if line.byte_length() == 0 or line.startswith("#"):
            continue
        var f = _split_golden(line)
        _check(len(f) == 8, "golden line has 8 fields: " + line)
        var gi = find_grammar(gs, f[0])
        var g = gs[gi].copy()
        var vseed = UInt32(Int(f[1]))
        var stage = Int(f[2])
        var ash = Int(f[3])
        var dry = Int(f[4])
        var mods = expand_derivation(g, vseed, stage, _millis(ash, dry))
        var rebuilt = (
            g.grammar_id
            + "|"
            + String(Int(vseed))
            + "|"
            + String(stage)
            + "|"
            + String(ash)
            + "|"
            + String(dry)
            + "|"
            + String(grammar_depth(g, stage))
            + "|"
            + String(derivation_module_count(mods))
            + "|"
            + render_derivation(mods)
        )
        _check(
            rebuilt == line,
            "golden mismatch line "
            + String(li + 1)
            + " ("
            + g.grammar_id
            + ", stage "
            + String(stage)
            + ")",
        )
        checked += 1
    _check(checked == SPECIES_COUNT * 4 * 3, "84 golden lines checked")


# --- (8) wire record untouched (R8 layout neutrality) ------------------------

def test_wire_record_untouched() raises:
    _check(
        FLORA_RECORD_BYTES == 32,
        "FLORA record 32 B (Sprint 02 schema 7: +seed +stage +pad)",
    )


def main() raises:
    TestSuite.discover_tests[
        (
            test_grammar_file_parses_and_validates,
            test_stage_for_age_monotone_bounded_and_json_exact,
            test_variant_seed_pure_and_distinct_on_grid,
            test_quantize_and_constants_match_json,
            test_modulation_exact_vs_json,
            test_expansion_deterministic_bounded_and_trait_sensitive,
            test_goldens_match,
            test_wire_record_untouched,
        )
    ]().run()
