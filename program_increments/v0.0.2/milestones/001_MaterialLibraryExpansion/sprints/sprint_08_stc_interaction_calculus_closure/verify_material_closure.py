#!/usr/bin/env python3
"""
Automated Verification & Invariant Testing Harness for Milestone 001:
Universal Material Library & Semantic Transition Calculus Closure
"""

import json
import os
import sys

SCR_ROOT = "/home/kobus/Projects/Semantic-Computational-Runtime"
CATALOG_JSON = os.path.join(SCR_ROOT, "lib/A01_Render/Material/materials_catalog.json")
REACTIONS_JSON = os.path.join(SCR_ROOT, "lib/A01_Render/Material/material_reactions.json")
CATALOG_MD = os.path.join(SCR_ROOT, "lib/A01_Render/Material/105_unified_materials_catalog.md")
REACTIONS_MD = os.path.join(SCR_ROOT, "lib/A01_Render/Material/106_material_transformations_and_reactions.md")

REPORT_DIR = os.path.join(SCR_ROOT, "program_increments/v0.0.2/milestones/001_MaterialLibraryExpansion/sprints/sprint_08_stc_interaction_calculus_closure/reports")
EVIDENCE_JSON = os.path.join(REPORT_DIR, "verification_evidence.json")

def verify_materials():
    results = {
        "status": "PASSED",
        "total_materials_tested": 0,
        "total_reactions_tested": 0,
        "physical_invariant_failures": [],
        "optical_invariant_failures": [],
        "reaction_invariant_failures": [],
        "cross_reference_failures": []
    }

    with open(CATALOG_JSON) as f:
        cat_data = json.load(f)

    with open(REACTIONS_JSON) as f:
        rx_data = json.load(f)

    with open(CATALOG_MD) as f:
        cat_md_text = f.read()

    with open(REACTIONS_MD) as f:
        rx_md_text = f.read()

    materials = cat_data.get("materials", [])
    reactions = rx_data.get("reactions", [])

    results["total_materials_tested"] = len(materials)
    results["total_reactions_tested"] = len(reactions)

    material_id_set = set()

    for m in materials:
        mid = m.get("id")
        material_id_set.add(mid)
        phys = m.get("physical", {})
        opt = m.get("optical", {})

        # INVAR-MAT-001: Physical Realism
        rho = phys.get("density_kg_m3", 0)
        if rho <= 0:
            results["physical_invariant_failures"].append(f"{mid}: Density <= 0 ({rho})")

        nu = phys.get("poisson_ratio", 0)
        if not (-1.0 < nu <= 0.5):
            results["physical_invariant_failures"].append(f"{mid}: Poisson ratio out of bounds ({nu})")

        mohs = phys.get("mohs_hardness", -1)
        if not (0.0 <= mohs <= 10.0):
            results["physical_invariant_failures"].append(f"{mid}: Mohs hardness out of bounds ({mohs})")

        k = phys.get("thermal_conductivity_w_mk", 0)
        if k <= 0:
            results["physical_invariant_failures"].append(f"{mid}: Thermal conductivity <= 0 ({k})")

        cp = phys.get("specific_heat_j_kgk", 0)
        if cp <= 0:
            results["physical_invariant_failures"].append(f"{mid}: Specific heat <= 0 ({cp})")

        # INVAR-MAT-002: Optical Conservation
        albedo = opt.get("base_color_srgb", [])
        if len(albedo) != 3 or any(not (0.0 <= c <= 1.0) for c in albedo):
            results["optical_invariant_failures"].append(f"{mid}: Invalid albedo sRGB ({albedo})")

        roughness = opt.get("roughness", -1)
        if not (0.0 <= roughness <= 1.0):
            results["optical_invariant_failures"].append(f"{mid}: Roughness out of bounds ({roughness})")

        metallic = opt.get("metallic", -1)
        if not (0.0 <= metallic <= 1.0):
            results["optical_invariant_failures"].append(f"{mid}: Metallic out of bounds ({metallic})")

        ior = opt.get("ior", 0)
        is_conductor = (opt.get("bsdf_model") == "conductor_fresnel_ggx" or opt.get("metallic", 0) == 1.0)
        if is_conductor:
            if ior <= 0.0:
                results["optical_invariant_failures"].append(f"{mid}: Conductor refractive index IOR <= 0 ({ior})")
        else:
            if ior < 1.0:
                results["optical_invariant_failures"].append(f"{mid}: Dielectric refractive index IOR < 1.0 ({ior})")

        trans = opt.get("transmission", -1)
        if not (0.0 <= trans <= 1.0):
            results["optical_invariant_failures"].append(f"{mid}: Transmission out of bounds ({trans})")

        emiss = opt.get("emission_cd_m2", -1)
        if emiss < 0.0:
            results["optical_invariant_failures"].append(f"{mid}: Emission < 0 ({emiss})")

        # Markdown cross check
        if f"`{mid}`" not in cat_md_text:
            results["cross_reference_failures"].append(f"Material {mid} missing from 105_unified_materials_catalog.md")

    # INVAR-MAT-003: Reaction Conservation & Adjacency
    for r in reactions:
        rid = r.get("id")
        prec = r.get("preconditions", {})
        trans_list = r.get("transformations", [])
        conservations = r.get("conservations", [])

        if not conservations:
            results["reaction_invariant_failures"].append(f"{rid}: No conservation invariants declared")

        if not trans_list:
            results["reaction_invariant_failures"].append(f"{rid}: No transformation outcomes declared")

        # Markdown cross check
        if f"`{rid}`" not in rx_md_text:
            results["cross_reference_failures"].append(f"Reaction {rid} missing from 106_material_transformations_and_reactions.md")

    # Check overall status
    failures = (
        len(results["physical_invariant_failures"]) +
        len(results["optical_invariant_failures"]) +
        len(results["reaction_invariant_failures"]) +
        len(results["cross_reference_failures"])
    )

    if failures > 0:
        results["status"] = "FAILED"

    os.makedirs(REPORT_DIR, exist_ok=True)
    with open(EVIDENCE_JSON, "w") as f:
        json.dump(results, f, indent=2)

    print("================================================================================")
    print(f"VERIFICATION STATUS: {results['status']}")
    print(f"Total Materials Tested: {results['total_materials_tested']}")
    print(f"Total Reactions Tested: {results['total_reactions_tested']}")
    print(f"Physical Invariant Failures: {len(results['physical_invariant_failures'])}")
    print(f"Optical Invariant Failures: {len(results['optical_invariant_failures'])}")
    print(f"Reaction Invariant Failures: {len(results['reaction_invariant_failures'])}")
    print(f"Cross-Reference Failures: {len(results['cross_reference_failures'])}")
    print("================================================================================")

    return failures == 0

if __name__ == "__main__":
    success = verify_materials()
    sys.exit(0 if success else 1)
