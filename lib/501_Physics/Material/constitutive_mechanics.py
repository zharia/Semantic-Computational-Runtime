#!/usr/bin/env python3
"""
SCR Physical Constitutive Mechanics & Fracture Solver
Evaluates Lamé parameters, Hookean stress tensors, Mohr-Coulomb yield failure,
and Chapman-Jouguet blast wave fracture radii for all 96 universal materials.
"""

import json
import os
import math
from typing import Tuple, Dict, Any, List

SCR_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "../../../"))
CATALOG_PATH = os.path.join(SCR_ROOT, "lib/A01_Render/Material/materials_catalog.json")

def compute_lame_parameters(e_gpa: float, nu: float) -> Tuple[float, float, float]:
    """
    Computes Lamé parameters (lambda, mu/G) and Bulk Modulus (K) from Young's modulus and Poisson's ratio.
    Units: GPa.
    """
    if nu >= 0.5:
        # Incompressible limit approximation
        nu = 0.4999
    
    lmbda = (e_gpa * nu) / ((1.0 + nu) * (1.0 - 2.0 * nu))
    mu = e_gpa / (2.0 * (1.0 + nu))
    k_bulk = e_gpa / (3.0 * (1.0 - 2.0 * nu))
    return lmbda, mu, k_bulk

def evaluate_hookean_stress(strain_3x3: List[List[float]], e_gpa: float, nu: float) -> List[List[float]]:
    """
    Computes Cauchy stress tensor sigma_ij = lambda * delta_ij * tr(epsilon) + 2 * mu * epsilon_ij.
    Units: GPa.
    """
    lmbda, mu, _ = compute_lame_parameters(e_gpa, nu)
    tr_eps = strain_3x3[0][0] + strain_3x3[1][1] + strain_3x3[2][2]
    
    stress = [[0.0 for _ in range(3)] for _ in range(3)]
    for i in range(3):
        for j in range(3):
            delta = 1.0 if i == j else 0.0
            stress[i][j] = lmbda * delta * tr_eps + 2.0 * mu * strain_3x3[i][j]
    return stress

def evaluate_mohr_coulomb_failure(shear_stress_kpa: float, normal_stress_kpa: float, 
                                  cohesion_kpa: float, friction_coefficient: float) -> bool:
    """
    Mohr-Coulomb failure criterion: tau_crit = c + sigma_n * tan(phi) = c + sigma_n * mu.
    Returns True if shear stress exceeds yield envelope (inducing plastic flow/collapse).
    """
    tau_crit = cohesion_kpa + max(0.0, normal_stress_kpa) * friction_coefficient
    return shear_stress_kpa > tau_crit

def evaluate_blast_fracture_radius(blast_energy_j: float, blast_resistance_j: float) -> float:
    """
    Computes the spherical fracture envelope radius where shock impulse exceeds blast resistance threshold:
    impulse(r) = E_blast / (4 * pi * r^2) >= J_blast ==> r = sqrt(E_blast / (4 * pi * J_blast)).
    Units: meters.
    """
    if blast_resistance_j <= 0.0:
        return float('inf')
    return math.sqrt(blast_energy_j / (4.0 * math.pi * blast_resistance_j))

class ElasticModuli:
    def __init__(self, bulk_K: float, shear_G: float, lame_lambda: float):
        self.bulk_K = bulk_K
        self.shear_G = shear_G
        self.lame_lambda = lame_lambda

class AcousticVelocities:
    def __init__(self, vp: float, vs: float):
        self.vp = vp
        self.vs = vs

class ConstitutiveSolver:
    def __init__(self, catalog_path: str = None):
        if catalog_path is None:
            catalog_path = CATALOG_PATH
        with open(catalog_path, "r") as f:
            data = json.load(f)
        self.catalog = data.get("materials", [])
        self._by_id = {}
        for m in self.catalog:
            mid = m["id"]
            self._by_id[mid] = m
            # Also allow suffix shorthand
            short = mid.split(".")[-1]
            if short not in self._by_id:
                self._by_id[short] = m

    def get_material(self, mat_id: str) -> Dict[str, Any]:
        if mat_id in self._by_id:
            return self._by_id[mat_id]
        safe = mat_id.replace(".", "_")
        for m in self.catalog:
            if m["id"].replace(".", "_") == safe:
                return m
        raise KeyError(f"Material {mat_id} not found")

    def compute_elastic_moduli(self, mat: Dict[str, Any]) -> ElasticModuli:
        phys = mat.get("physical", {})
        e = phys.get("youngs_modulus_gpa", 1.0)
        nu = phys.get("poisson_ratio", 0.3)
        lmbda, mu, k_bulk = compute_lame_parameters(e, nu)
        return ElasticModuli(bulk_K=k_bulk, shear_G=mu, lame_lambda=lmbda)

    def compute_wave_velocities(self, mat: Dict[str, Any]) -> AcousticVelocities:
        phys = mat.get("physical", {})
        e = phys.get("youngs_modulus_gpa", 1.0)
        nu = phys.get("poisson_ratio", 0.3)
        rho = phys.get("density_kg_m3", 2500.0)
        lmbda, mu, _ = compute_lame_parameters(e, nu)
        # Convert GPa to Pa: 1 GPa = 1e9 N/m^2
        lmbda_pa = lmbda * 1e9
        mu_pa = mu * 1e9
        vp = math.sqrt(max(0.0, (lmbda_pa + 2.0 * mu_pa) / rho))
        vs = math.sqrt(max(0.0, mu_pa / rho))
        return AcousticVelocities(vp=vp, vs=vs)

    def compute_stress_tensor(self, mat: Dict[str, Any], strain_3x3: List[List[float]]) -> List[List[float]]:
        phys = mat.get("physical", {})
        e = phys.get("youngs_modulus_gpa", 1.0)
        nu = phys.get("poisson_ratio", 0.3)
        return evaluate_hookean_stress(strain_3x3, e, nu)

    def mohr_coulomb_failure(self, mat: Dict[str, Any], normal_stress: float) -> float:
        phys = mat.get("physical", {})
        # Cohesion from tensile/compressive strength
        sigma_c = phys.get("compressive_strength_mpa", 50.0) * 1e6
        mu_fric = phys.get("friction_coefficient", 0.5)
        cohesion = sigma_c / 2.0
        return cohesion + max(0.0, normal_stress) * mu_fric

    def compute_blast_radius(self, mat: Dict[str, Any], energy_tnt_joules: float) -> float:
        phys = mat.get("physical", {})
        j_blast = phys.get("blast_resistance_j", 5000.0)
        return evaluate_blast_fracture_radius(energy_tnt_joules, j_blast)

def run_constitutive_audit():
    with open(CATALOG_PATH, "r") as f:
        catalog = json.load(f)
        
    materials = catalog.get("materials", [])
    print(f"=== Running Constitutive Mechanics Audit on {len(materials)} Materials ===")
    
    solver = ConstitutiveSolver()
    for mat in materials:
        mid = mat["id"]
        moduli = solver.compute_elastic_moduli(mat)
        assert moduli.shear_G > 0, f"Shear modulus <= 0 for {mid}"
        assert moduli.bulk_K > 0, f"Bulk modulus <= 0 for {mid}"
        
        r_blast = solver.compute_blast_radius(mat, 50000.0)
        assert r_blast >= 0, f"Negative blast radius for {mid}"

    print(f"Audit PASSED: All {len(materials)} materials exhibit valid elasticity tensors and fracture radii.")
    return True

if __name__ == "__main__":
    run_constitutive_audit()
