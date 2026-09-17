# Sprint 02: 3D Hookean Stress Tensor Evaluation

## 1. Objectives
Implement isotropic linear elastic constitutive relation for small strain tensors $\boldsymbol{\varepsilon}$:
$$\boldsymbol{\sigma} = 2\mu \boldsymbol{\varepsilon} + \lambda \text{tr}(\boldsymbol{\varepsilon}) \mathbf{I}$$

## 2. Invariants
- Symmetric strain input $\varepsilon_{ij} = \varepsilon_{ji}$ must yield symmetric stress $\sigma_{ij} = \sigma_{ji}$.
- Hydrostatic strain $\boldsymbol{\varepsilon} = \varepsilon_0 \mathbf{I}$ must produce isotropic hydrostatic pressure $p = 3K \varepsilon_0$.
