# Phenome golden generator (NOT a test — a maintenance tool).
#
# Regenerates tests/fixtures/phenome/goldens.txt: the AP-24 discrete
# conformance axis (render_derivation output) for every grammar across a
# fixed stage × trait-milli grid, frozen as reviewable text. The JSON
# grammar file stays the SINGLE SOURCE of vocabulary (AP-23); this file is
# a DERIVED fixture (checked in) — regenerate only when the grammar file,
# the expander, or the render format changes intentionally, then review the
# diff and re-run test_phenome_grammar.
#
# Run (from repo root):
#   mojo run -I applications/godot/src/mojo \
#     applications/godot/tests/mojo/gen_phenome_goldens.mojo
#
# Line format (parser lives in test_phenome_grammar.mojo — keep in sync):
#   <grammar_id>|<vseed>|<stage>|<ash_milli>|<drought_milli>|<depth>|<count>|<render>
# Lines starting with '#' are comments; render is the last field (may
# contain spaces, never '|').

from phenome.expand import (
    parse_grammars,
    expand_derivation,
    render_derivation,
    grammar_depth,
    derivation_module_count,
)
from util.files import find_repo_root, join_path, read_file_text, write_file_bytes

comptime GRAMMAR_REL = "applications/godot/godot/data/phenome_grammars.json"
comptime GOLDEN_REL = "applications/godot/tests/fixtures/phenome/goldens.txt"

# Frozen probe points — changing these re-generates every line (review it).
comptime VSEED: UInt32 = 12345


def _probes(mut stages: List[Int], mut ash: List[Int], mut dry: List[Int]) raises:
    stages.append(0)
    stages.append(3)
    stages.append(7)
    stages.append(15)
    ash.append(0)
    ash.append(317)
    ash.append(1000)  # milli (trait_quant = 1000)
    dry.append(0)
    dry.append(622)
    dry.append(1000)


def _push(mut buf: List[UInt8], s: String) raises:
    for b in s.bytes():
        buf.append(b)


def main() raises:
    var root = find_repo_root()
    var gs = parse_grammars(read_file_text(join_path(root, GRAMMAR_REL)))
    var stage_probes = List[Int]()
    var ash_probes = List[Int]()
    var dry_probes = List[Int]()
    _probes(stage_probes, ash_probes, dry_probes)
    var buf = List[UInt8]()
    _push(buf, "# scr.phenome_goldens/1 — DERIVED fixture, do not hand-edit\n")
    _push(
        buf,
        "# grammar_id|vseed|stage|ash_milli|drought_milli|depth|count|render\n",
    )
    var lines = 0
    for gi in range(len(gs)):
        var g = gs[gi].copy()
        for si in range(len(stage_probes)):
            var stage = stage_probes[si]
            for ti in range(len(ash_probes)):
                var millis = List[Int]()
                millis.append(ash_probes[ti])
                millis.append(dry_probes[ti])
                var mods = expand_derivation(g, VSEED, stage, millis)
                var line = (
                    g.grammar_id
                    + "|"
                    + String(Int(VSEED))
                    + "|"
                    + String(stage)
                    + "|"
                    + String(ash_probes[ti])
                    + "|"
                    + String(dry_probes[ti])
                    + "|"
                    + String(grammar_depth(g, stage))
                    + "|"
                    + String(derivation_module_count(mods))
                    + "|"
                    + render_derivation(mods)
                    + "\n"
                )
                _push(buf, line)
                lines += 1
    var path = join_path(root, GOLDEN_REL)
    write_file_bytes(path, buf)
    print("wrote", path, String(lines), "golden lines")
