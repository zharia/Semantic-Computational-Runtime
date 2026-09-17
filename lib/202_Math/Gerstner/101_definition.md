# SCR-LIB-MATH-GERSTNER: Normative Trochoidal Gerstner Wave Semantics

**Document ID:** `SCR-LIB-MATH-GERSTNER-101`  
**Semantic Domain:** `lib/202_Math/Gerstner`  
**Version:** 1.0.0  
**Authority:** Authoritative Specification  

---

## 1. Domain Purpose & Scope

Defines the mathematical semantics and operational contracts for directional Trochoidal Gerstner Waves, wave superposition, analytical surface derivatives (normal, tangent, binormal), Jacobian wave crest steepness metrics, and physical water displacement fields.

---

## 2. Mathematical Definition

### 2.1 Single Gerstner Wave Harmonic

Given an undeformed horizontal surface point $\mathbf{p}_0 = (x_0, z_0)$ at rest height $y_{\text{sea}}$, a Gerstner wave octave $i$ is parameterized by:
- Direction unit vector $\mathbf{d}_i = (d_{x,i}, d_{z,i})$, where $\|\mathbf{d}_i\| = 1$
- Wavelength $\lambda_i > 0$ and wavenumber $k_i = \frac{2\pi}{\lambda_i}$
- Amplitude $A_i > 0$
- Phase speed $c_i = \sqrt{\frac{g}{k_i}}$ (deep water dispersion relation)
- Angular frequency $\omega_i = k_i c_i = \sqrt{g k_i}$
- Steepness parameter $Q_i \in [0, 1]$, where $Q_i = \frac{S_i}{k_i A_i \sum_{j} A_j}$

The displaced position $\mathbf{P}(x_0, z_0, t)$ is given by:
$$x = x_0 - \sum_{i=1}^{N} Q_i A_i d_{x,i} \sin(k_i (\mathbf{d}_i \cdot \mathbf{p}_0) - \omega_i t + \phi_i)$$
$$z = z_0 - \sum_{i=1}^{N} Q_i A_i d_{z,i} \sin(k_i (\mathbf{d}_i \cdot \mathbf{p}_0) - \omega_i t + \phi_i)$$
$$y = y_{\text{sea}} + \sum_{i=1}^{N} A_i \cos(k_i (\mathbf{d}_i \cdot \mathbf{p}_0) - \omega_i t + \phi_i)$$

### 2.2 Analytical Surface Normal & Tangent Frame

Let $\theta_i = k_i (\mathbf{d}_i \cdot \mathbf{p}_0) - \omega_i t + \phi_i$. The tangent $\mathbf{T}$ and binormal $\mathbf{B}$ vectors are:
$$\mathbf{T} = \frac{\partial \mathbf{P}}{\partial x_0} = \begin{pmatrix} 1 - \sum Q_i d_{x,i}^2 k_i A_i \cos\theta_i \\ \sum d_{x,i} k_i A_i \sin\theta_i \\ -\sum Q_i d_{x,i} d_{z,i} k_i A_i \cos\theta_i \end{pmatrix}$$
$$\mathbf{B} = \frac{\partial \mathbf{P}}{\partial z_0} = \begin{pmatrix} -\sum Q_i d_{x,i} d_{z,i} k_i A_i \cos\theta_i \\ \sum d_{z,i} k_i A_i \sin\theta_i \\ 1 - \sum Q_i d_{z,i}^2 k_i A_i \cos\theta_i \end{pmatrix}$$

The unnormalized surface normal $\mathbf{N}$ is:
$$\mathbf{N} = \mathbf{B} \times \mathbf{T} = \begin{pmatrix} -\sum d_{x,i} k_i A_i \sin\theta_i \\ 1 - \sum Q_i k_i A_i \cos\theta_i \\ -\sum d_{z,i} k_i A_i \sin\theta_i \end{pmatrix}$$

### 2.3 Jacobian & Crest Whitecap Foam Factor

The Jacobian determinant $J$ of the horizontal deformation measures surface compression/stretching:
$$J = \frac{\partial(x, z)}{\partial(x_0, z_0)} = \left(1 - \sum Q_i d_{x,i}^2 k_i A_i \cos\theta_i\right)\left(1 - \sum Q_i d_{z,i}^2 k_i A_i \cos\theta_i\right) - \left(\sum Q_i d_{x,i} d_{z,i} k_i A_i \cos\theta_i\right)^2$$

When $J < 0.65$ or normalized wave height exceeds $0.7$, surface self-intersection / wave peaking occurs, generating physical **crest whitecap foam**.

---

## 3. Invariants & Compliance Rules

1. **Energy Conservation**: Total wave energy $E = \frac{1}{2} \rho g \sum A_i^2$.
2. **Steepness Bound**: $\sum Q_i k_i A_i \le 1.0$ to prevent severe topological self-intersection.
3. **Continuity**: $\mathbf{P}(x_0, z_0, t)$ is $C^\infty$ smooth everywhere in time and space.
