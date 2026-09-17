# SCR-LIB-RENDER-SKY: Multi-Stratified Volumetric Cloud & Atmospheric Sky System

**Document ID:** `SCR-LIB-RENDER-SKY-101`  
**Semantic Domain:** `lib/A01_Render/Sky`  
**Version:** 1.0.0  
**Authority:** Authoritative Specification  

---

## 1. Multi-Layer Cloud Hierarchy (Red Dead Redemption 2 Paradigm)

| Layer Name | Altitude Range | Morphological Type | Optical Character |
|---|---|---|---|
| **Tier 1: Low Cumulus** | $150\,\text{m} - 550\,\text{m}$ | Dense billowing cumulus / stratocumulus | Heavy optical extinction, high forward Mie silver-lining glow, dark bases |
| **Tier 2: Mid Altocumulus & Volcanic Plume** | $550\,\text{m} - 1050\,\text{m}$ | Undulating ripple sheets & rising volcanic caldera steam/ash column | Warm golden-ash scattering, convective thermal rise from caldera summit |
| **Tier 3: High Cirrus** | $1050\,\text{m} - 2000\,\text{m}$ | Wind-sheared fibrous ice streaks | Highly translucent, solar halo ring, fast differential wind shear |

---

## 2. Diurnal Solar Arc & Rayleigh Zenith-to-Horizon Gradient

The celestial skydome interpolates dynamically through:
- **Dawn/Golden Hour ($\theta_{\text{sun}} \in [0^\circ, 15^\circ]$)**: Fiery orange-pink horizon ($1.0, 0.48, 0.15$), deep indigo-blue zenith ($0.08, 0.18, 0.42$), warm golden cloud rims.
- **Tropical High Noon ($\theta_{\text{sun}} \in [45^\circ, 90^\circ]$)**: Azure blue zenith ($0.18, 0.48, 0.92$), crisp white cloud tops, luminous translucent cyan sky base.
- **Tropical Sunset ($\theta_{\text{sun}} \in [-5^\circ, 10^\circ]$)**: Deep crimson/violet horizon, vibrant fiery amber clouds, volcanic caldera glow projection.
- **Starry Tropical Night ($\theta_{\text{sun}} < -10^\circ]$)**: Deep cosmic navy ($0.008, 0.012, 0.035$), Milky Way stellar belt, soft moonlit cloud illumination.
