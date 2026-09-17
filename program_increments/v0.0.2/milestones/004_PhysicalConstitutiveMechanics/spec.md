# Milestone 004 Specification: Physical Constitutive Mechanics & Fracture Solver

## 1. Scope & Objective
Provide high-precision constitutive mechanics equations and solvers evaluating the mechanical response, deformation, wave propagation, and fracture limits of SCR materials.

## 2. Constitutive Equations
1. **Elastic Moduli Conversions**:
   $$K = \frac{E}{3(1 - 2\nu)}, \quad G = \mu = \frac{E}{2(1 + \nu)}, \quad \lambda = \frac{E\nu}{(1 + \nu)(1 - 2\nu)}$$
2. **Acoustic Velocities**:
   $$v_p = \sqrt{\frac{\lambda + 2\mu}{\rho}}, \quad v_s = \sqrt{\frac{\mu}{\rho}}$$
3. **Continuum Stress-Strain Relation**:
   $$\boldsymbol{\sigma} = 2\mu\boldsymbol{\varepsilon} + \lambda\text{tr}(\boldsymbol{\varepsilon})\mathbf{I}$$
4. **Mohr-Coulomb Brittle Failure**:
   $$\tau_{\text{crit}} = c + \sigma_n \tan \phi$$
5. **Explosive Blast Cavity Radius**:
   $$R_{\text{cavity}} = C_{\text{blast}} \left(\frac{E_{\text{TNT}}}{\sigma_c}\right)^{1/3}$$

## 3. Verification & Invariants
- Solids must satisfy $E > 0$, $0 \le \nu < 0.5$, $\rho > 0$.
- Acoustic velocities must be real and positive ($v_p > v_s > 0$).
- Stress tensor must remain symmetric: $\sigma_{ij} = \sigma_{ji}$.
