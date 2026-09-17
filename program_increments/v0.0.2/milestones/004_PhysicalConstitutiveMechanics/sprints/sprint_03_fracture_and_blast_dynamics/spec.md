# Sprint 03: Mohr-Coulomb & Blast Dynamics Solvers

## 1. Objectives
Implement Mohr-Coulomb brittle shear/compressive yield criteria and TNT explosive blast crater / fracture scaling:
$$\tau_{\text{crit}} = c + \sigma_n \tan \phi, \quad R_{\text{cavity}} = C_{\text{blast}} \left(\frac{E_{\text{TNT}}}{\sigma_c}\right)^{1/3}$$

## 2. Invariants
- Critical shear stress must increase monotonically with confining normal stress $\sigma_n$.
- Blast cavity radius must scale inversely with rock compressive strength $\sigma_c^{1/3}$.
