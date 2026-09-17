# SCR-LIB-MATH-ATMOSPHERE: Physical Atmospheric Scattering & Volumetric Cloud Optics

**Document ID:** `SCR-LIB-MATH-ATMOSPHERE-101`  
**Semantic Domain:** `lib/202_Math/Atmosphere`  
**Version:** 1.0.0  
**Authority:** Authoritative Specification  

---

## 1. Physical Atmospheric Scattering Models

Atmospheric radiance along a view ray $\mathbf{r}(s) = \mathbf{p}_0 + s \mathbf{v}$ is governed by Rayleigh molecular scattering and Mie aerosol scattering:

$$\beta_R(\lambda) = \frac{8\pi^3 (n^2 - 1)^2}{3 N \lambda^4}$$
where $n$ is air refractive index, $N$ is molecular density, and $\lambda \in \{680\,\text{nm}, 550\,\text{nm}, 440\,\text{nm}\}$.

### 1.1 Phase Functions

#### Rayleigh Phase Function (Isotropic & Dipolar Molecular Scattering)
$$P_R(\theta) = \frac{3}{16\pi} (1 + \cos^2\theta)$$

#### Henyey-Greenstein Dual-Lobe Phase Function (Cloud Mie Forward Scattering & Silver Lining)
$$P_{HG}(\theta, g) = \frac{1 - g^2}{4\pi (1 + g^2 - 2g\cos\theta)^{3/2}}$$

For hyper-realistic cloud silver linings (RDR2 standard), a dual-lobe phase function blends strong forward silver lining with backward glory:
$$P_{\text{cloud}}(\theta) = w_{\text{fwd}} P_{HG}(\theta, g_{\text{fwd}}) + (1 - w_{\text{fwd}}) P_{HG}(\theta, g_{\text{back}})$$
where $g_{\text{fwd}} \approx 0.82$, $g_{\text{back}} \approx -0.22$, and $w_{\text{fwd}} = 0.72$.

---

## 2. Volumetric Transmittance & Multi-Scattering (Beer-Lambert & Powdered Sugar)

Along an optical path through cloud density $\rho(\mathbf{x})$, the cumulative optical depth $\tau$ is:
$$\tau(s) = \int_0^s \sigma_t \rho(\mathbf{r}(u)) \, du$$

### 2.1 Powdered Sugar Effect (Multiple-Scattering Compensation)
Standard Beer-Lambert $e^{-\tau}$ under-estimates lighting in thick forward-scattering cloud billows. The Wrenninge-Neyret / RDR2 powdered sugar formulation modulates transmittance by:
$$T(d) = e^{-\sigma_t d} \cdot \left(1 - e^{-2 \sigma_t d}\right)$$
This produces soft, luminous translucent edges on cloud tops with dense, shadowed bases.

---

## 3. Stratified Multi-Layer Cloud Metrics

Let $h$ be altitude above sea level:
- **Cumulus Layer ($h_1 \le h \le h_2$)**: Low troposphere, dense convective cumulus tops.
- **Altocumulus Layer ($h_3 \le h \le h_4$)**: Mid-altitude undulating ripple sheets and volcanic plume drift.
- **Cirrus Layer ($h_5 \le h \le h_6$)**: High-altitude wispy ice crystal streaks.
