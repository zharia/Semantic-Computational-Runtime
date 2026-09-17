---

document: 101_definition
document_type: normative_semantic_definition
schema_version: 1.0.0

id: SCR-LIB-SIMULATION-WEATHER
name: Weather
domain: 503_Simulation/Environment/Weather

version: 0.1.0
status: draft

created: 2026-09-17
updated: 2026-09-17

parent: SCR-LIB-SIMULATION-ENVIRONMENT

authority: SCR
---

# Weather Semantics

## 1. Abstract & Semantic Authority

Weather is the semantic computational domain representing the **spatiotemporal atmospheric state, thermodynamic balances, fluid transport, phase transitions of volatiles (water, vapor, condensate, aerosols, volcanic ash), and radiant energy fluxes** occurring in a simulated planetary boundary layer.

In accordance with SCR Rule 1 (*Semantics are authoritative*) and Rule 5 (*Relationships must be explicit*), weather is neither a purely graphical post-process nor an ad-hoc visual effect. Weather is an authoritative physical-environmental domain with well-defined mathematical contracts that drive and couple physical, biological, ecological, hydrological, and visual manifestation layers.

```text
               Thermodynamic Forcing / Diurnal Solar Energy
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                        WEATHER SEMANTIC STATE (W)                           │
│  • Barometric Pressure Field P(x,y,z,t)      • Temperature Field T(x,y,z,t) │
│  • Humidity Field q(x,y,z,t)                 • 3D Wind Vector Field v(x,y,z)│
│  • Precipitation Intensity & Phase           • Cloud Optical Depth & Cover  │
│  • Aerosol / Volcanic Particulate Density    • Lightning Discharge Electric │
└──────┬────────────────────┬───────────────────┬────────────────────┬────────┘
       │                    │                   │                    │
       ▼                    ▼                   ▼                    ▼
┌──────────────┐    ┌──────────────┐    ┌──────────────┐     ┌───────────────┐
│ Dynamic      │    │ Procedural   │    │ Ecosystem &  │     │ Volumetric    │
│ Ocean Waves  │    │ Vegetation   │    │ Fauna Flight │     │ Atmospheric   │
│ & Hydro-SDF  │    │ Wind Sway    │    │ (Boids)      │     │ Rendering     │
└──────────────┘    └──────────────┘    └──────────────┘     └───────────────┘
```

---

## 2. Mathematical & Thermodynamic Formulation

A formal Weather State $\mathcal{W}(\mathbf{x}, t)$ at spatial position $\mathbf{x} = (x, y, z)$ and time $t$ is represented as a multidimensional semantic tuple:

$$\mathcal{W}(\mathbf{x}, t) = \Big( P(\mathbf{x}, t),\, T(\mathbf{x}, t),\, \Phi(\mathbf{x}, t),\, \mathbf{v}_{\text{wind}}(\mathbf{x}, t),\, C(\mathbf{x}, t),\, \tau(\mathbf{x}, t),\, R_{\text{precip}}(\mathbf{x}, t),\, \rho_{\text{aerosol}}(\mathbf{x}, t),\, \mathcal{E}_{\text{lightning}}(t) \Big)$$

Where:

1. **Barometric Pressure $P(\mathbf{x}, t)$** (measured in $hPa$):
   Standard sea-level barometric pressure $P_0 \approx 1013.25\, hPa$. Altitude lapse rate follows the barometric formula:
   $$P(y) = P_0 \cdot \exp\left( -\frac{M g y}{R T_0} \right)$$
   Cyclonic low-pressure depressions ($P < 995\, hPa$) trigger convective storm fronts; high-pressure cells ($P > 1020\, hPa$) produce clear skies.

2. **Ambient Temperature $T(\mathbf{x}, t)$** (measured in $^\circ C$):
   Driven by solar zenith angle $\theta_z(t)$, diurnal cycle, and environmental lapse rate ($\Gamma \approx 6.5^\circ C / 1000m$):
   $$T(\mathbf{x}, t) = T_{\text{sea}}(t) - \Gamma \cdot (y - y_{\text{sea}}) + \Delta T_{\text{biome}}$$

3. **Relative Humidity $\Phi(\mathbf{x}, t) \in [0.0, 1.0]$**:
   Ratio of water vapor partial pressure to saturation vapor pressure (via Magnus-Tetens approximation).

4. **3D Wind Velocity Field $\mathbf{v}_{\text{wind}}(\mathbf{x}, t) \in \mathbb{R}^3$** (measured in $m/s$):
   Driven by horizontal barometric pressure gradients, terrain deflection, thermal updrafts, and altitude wind shear:
   $$\mathbf{v}_{\text{wind}}(y) = \mathbf{v}_{\text{surface}} \cdot \left( \frac{y}{y_0} \right)^\alpha + \mathbf{v}_{\text{shear}}(y)$$

5. **Cloud Cover Fraction $C(\mathbf{x}, t) \in [0.0, 1.0]$** and **Optical Depth $\tau(\mathbf{x}, t) \ge 0$**:
   Fraction of sky dome occluded by condensed water droplets and ice crystals across 3 distinct altitude decks:
   - Low Deck ($150m - 500m$): Stratus & Cumulus ($C_{\text{low}}$)
   - Mid Deck ($500m - 1000m$): Altocumulus & Convective Plumes ($C_{\text{mid}}$)
   - High Deck ($1000m - 2000m$): Cirrus & Anvil tops ($C_{\text{high}}$)

6. **Precipitation Rate $R_{\text{precip}}(\mathbf{x}, t)$** (measured in $mm/h$) and **Precipitation Phase**:
   - `PRECIP_NONE`: $R = 0$
   - `PRECIP_MIST_DRIZZLE`: $0 < R \le 2.5\, mm/h$
   - `PRECIP_RAIN`: $2.5 < R \le 15.0\, mm/h$
   - `PRECIP_TORRENTIAL_MONSOON`: $R > 15.0\, mm/h$
   - `PRECIP_VOLCANIC_ASH`: Solid tephra and soot sedimentation rate ($\kappa_{\text{ash}}$).

7. **Aerosol / Particulate Density $\rho_{\text{aerosol}} \in [0.0, 1.0]$**:
   Mie scattering turbidity modifier representing haze, marine fog, sea salt spray, or volcanic smog (vog).

8. **Lightning Potential & Discharge Rate $\mathcal{E}_{\text{lightning}} \ge 0$**:
   Electrostatic accumulation in convective cumulonimbus decks producing sudden ground strikes, thunder audio impulses, and skydome radiant flashes.

---

## 3. Dynamic Weather Transition Semantics

Weather evolves through continuous interpolation along a state space driven by stochastic Markov transitions, diurnal solar forcing, and microclimatic geographic zones.

```text
               ┌───────────────────────┐
       ┌──────►│  CLEAR TROPICAL SUN   │◄──────┐
       │       │  P: 1018hPa, Rain: 0  │       │
       │       └──────────┬────────────┘       │
       │                  │                    │
       │                  ▼                    │
┌──────┴──────────────┐        ┌───────────────┴─────┐
│  MARINE MIST & FOG  │        │  OVERCAST STRATUS   │
│  P: 1012hPa, Hum: 0.95       │  P: 1008hPa, Low Cld│
└─────────────────────┘        └──────────┬──────────┘
       ▲                                  │
       │                                  ▼
┌──────┴──────────────┐        ┌─────────────────────┐
│ VOLCANIC ASH TEMPEST│◄───────┤  TROPICAL MONSOON   │
│ P: 988hPa, Ash: 0.85│        │  P: 994hPa, Rain: 45│
└─────────────────────┘        └─────────────────────┘
```

The transition between active weather profile $\mathcal{P}_A$ and target profile $\mathcal{P}_B$ over duration $\Delta t_{\text{trans}}$ is governed by smooth Hermite $S_3$ interpolation:

$$s(\xi) = 3\xi^2 - 2\xi^3, \quad \xi = \frac{t - t_0}{\Delta t_{\text{trans}}}$$
$$\mathcal{W}(t) = (1 - s(\xi)) \mathcal{P}_A + s(\xi) \mathcal{P}_B$$

---

## 4. Subsystem Coupling Contracts

| Subsystem | Coupled Weather Parameter | Semantic Manifestation |
|---|---|---|
| **Ocean Simulation** | $P$, $\|\mathbf{v}_{\text{wind}}\|$, $R_{\text{precip}}$ | High wind and low pressure increase Gerstner amplitude, surface chop, and foam generation. Rain drops create micro-ripples and spray. |
| **Vegetation** | $\mathbf{v}_{\text{wind}}$, Gust Factor, $R_{\text{precip}}$ | Real-time 3-tier wind sway amplitude scales with wind vector; rain increases foliage sheen and droplet saturation. |
| **Fauna (Boids)** | $R_{\text{precip}}$, $\rho_{\text{ash}}$, $P$ | Severe storms and volcanic ash trigger low-altitude roosting and sheltering behavior; clear weather promotes high thermals. |
| **Atmosphere / Sky** | $C$, $\tau$, $\rho_{\text{aerosol}}$, $\mathcal{E}_{\text{lightning}}$ | Rayleigh/Mie turbidity shifts; volumetric clouds thicken; lightning flashes illuminate overcast terrain; rain streaks fall from cloud base. |
| **HUD / Telemetry** | $P, T, \Phi, \mathbf{v}_{\text{wind}}, \text{Condition}$ | Live digital barometric readout, temperature, humidity, and condition classification on player heads-up display. |

---

## 5. Extensibility Contract

The Weather Semantic Framework permits open registration of custom weather profiles and microclimate rules via dynamic condition IDs and user-defined profiles:

```cpp
struct CustomWeatherProfile {
    std::string condition_name;
    float target_pressure_hpa;
    float target_temperature_c;
    float target_humidity;
    Spatial::Vector3D wind_velocity;
    float cloud_coverage;
    float precipitation_rate_mm_h;
    float aerosol_density;
    float lightning_frequency_hz;
    Ogre::ColourValue ambient_tint;
};
```
