shader_type spatial;
// ocean.gdshader — display-only Gerstner ocean surface (SCR island scene).
//
// AUTHORITY SPLIT (docs/04_simulation_engine.md):
//   * src/mojo/ocean/gerstner.mojo is authoritative for water height,
//     grounding and foam physics. This shader mirrors SCR-LIB-MATH-GERSTNER
//     §2.1 displacement FOR DISPLAY ONLY, from OCEAN-section uniforms that
//     the GDExtension adapter writes every physics frame (104_contract §4.3).
//   * The 8 sim uniforms below (sea_level, amplitude, frequency, steepness,
//     dir_x, dir_z, speed, phase) are normative names — they MUST match the
//     adapter's set_shader_parameter list exactly.
//   * `phase` already folds −ω·t + φ (encode.mojo `_encode_ocean`), so TIME is
//     deliberately NOT used: animating with TIME as well would double-count
//     the temporal term.
//   * The Ocean node transform must stay identity (position 0,0,0): local
//     space == world space, so wave phase samples world x/z directly.
//   * Everything else (colors, fresnel, foam thresholds, roughness curve) is
//     DISPLAY-ONLY and lives in scenes/island.tscn shader params — values and
//     provenance documented in docs/04_simulation_engine.md §5 (AP-7).
//
// ---------------------------------------------------------------------------
// DISPLAY-ONLY WAVE SPECTRUM (docs/04 §7) — "water looked fake + repetitive"
// ---------------------------------------------------------------------------
// The sim ships ONE harmonic travelling along a single contract direction, so
// the display was a perfectly periodic set of parallel stripes (corduroy).
// The vertex stage therefore sums WAVE_COUNT harmonics derived from the SAME
// contract uniforms — no new uniform names, no sim change:
//
//   direction_i = contract dir rotated by W_OFF[i]   |W_OFF| <= 40 deg
//   k_i         = frequency * W_KS[i]                W_KS in [0.75, 1.60]
//   A_i         = amplitude * W_RAW[i] / sum(W_RAW)  decaying shares
//   temporal_i  = sqrt(W_KS[i]) * phase + W_PH[i]
//
// Amplitude shares are NORMALISED: sum(A_i) == `amplitude`, so the display
// crest envelope is still bounded by the contract amplitude — the shoreline
// can never be MORE submerged than the authoritative single-wave height says.
// The temporal term uses sqrt(k_i/k) because §2.1 fixes deep-water dispersion
// c = sqrt(g/k) ⇒ ω = k·c = sqrt(g·k) ⇒ ω_i/ω = sqrt(k_i/k); `phase` carries
// −ω·t for the contract wave and φ = 0 for the core slice (gerstner.mojo).
//
// SIM stays authoritative: ocean/gerstner.mojo still computes the single
// harmonic y = sea + A·cosθ for grounding, in_water and foam physics.

// --- OCEAN section fields (written by adapter, every frame) ----------------
uniform float sea_level;   // water datum (world y)
uniform float amplitude;   // A
uniform float frequency;   // k in rad/u (sim ships wavenumber)
uniform float steepness;   // Q ∈ [0,1]
uniform float dir_x;       // unit wave direction
uniform float dir_z;
uniform float speed;       // c = sqrt(|g|/k) — contract field; temporal term
                           // arrives folded into `phase`, so unused here.
uniform float phase;       // −ω·t + φ folded to [0, 2π) by the sim

// --- display-only (scene-provided; see docs/04 §5 parameter table) ---------
uniform vec4 shallow_color : source_color;
uniform vec4 deep_color : source_color;
uniform vec4 sky_tint : source_color;
uniform vec4 foam_color : source_color;
uniform float fresnel_power;
uniform float foam_jacobian_threshold;  // mirror of parameters.mojo FOAM_JACOBIAN_THRESHOLD (display mirror)
uniform float foam_height_threshold;    // mirror of parameters.mojo FOAM_HEIGHT_THRESHOLD (display mirror)
uniform float specular_gain;            // Fresnel highlight strength (display)

// --- display-only spectrum constants (docs/04 §7) --------------------------
// Direction offsets (rad) about the contract dir — all within ±40° (0.698 rad).
const float W_OFF[6] = float[](0.00, 0.62, -0.50, 0.28, -0.68, 0.42);
// Wavenumber multipliers, 0.75×–1.6× the contract frequency.
const float W_KS[6] = float[](1.00, 0.78, 1.35, 0.75, 1.60, 1.12);
// Raw decaying amplitude shares; normalised by W_RAW_SUM so ΣA_i = amplitude.
const float W_RAW[6] = float[](1.00, 0.50, 0.33, 0.22, 0.15, 0.10);
const float W_RAW_SUM = 2.30;
// Per-harmonic phase offsets (rad) so crests do not line up across harmonics.
const float W_PH[6] = float[](0.00, 2.10, 4.40, 1.30, 5.20, 3.30);

varying float v_norm;  // (y − sea_level)/amplitude ∈ [−1, 1]
varying float v_jacq;  // Q · Σ k_i·A_i·cosθ_i  (display Jacobian proxy)

void vertex() {
	float y = sea_level;
	float jac = 0.0;
	vec2 horiz = vec2(0.0, 0.0);
	// N ∝ (−∂y/∂x, 1, −∂y/∂z); for y = ΣA_i cosθ_i that is Σ A_i·k_i·d_i·sinθ_i.
	vec2 slope = vec2(0.0, 0.0);

	for (int i = 0; i < 6; i++) {
		float ks = W_KS[i];
		float k = frequency * ks;
		float a = amplitude * (W_RAW[i] / W_RAW_SUM);
		float c_off = cos(W_OFF[i]);
		float s_off = sin(W_OFF[i]);
		vec2 d = vec2(dir_x * c_off - dir_z * s_off,
		              dir_x * s_off + dir_z * c_off);
		// §2.1 θ = k·(d·p) − ω·t + φ ; the −ω·t + φ part is the snapshot
		// `phase` (φ = 0), scaled per harmonic by sqrt(k_i/k) (dispersion).
		float theta = k * (d.x * VERTEX.x + d.y * VERTEX.z)
		              + sqrt(ks) * phase + W_PH[i];
		float s = sin(theta);
		float c = cos(theta);
		y += a * c;
		jac += k * a * c;
		horiz += steepness * a * d * s;
		slope += a * k * d * s;
	}

	v_norm = (y - sea_level) / max(amplitude, 0.0001);
	v_jacq = steepness * jac;

	// Vertical sum matches the sim's sea + A·cosθ envelope (bound preserved by
	// ΣA_i = amplitude). Horizontal shoaling is display-only (gerstner.mojo
	// header): textbook Q·A_i·d·sinθ per harmonic, in quadrature with the
	// cosθ vertical terms.
	VERTEX = vec3(VERTEX.x + horiz.x, y, VERTEX.z + horiz.y);

	NORMAL = normalize(vec3(slope.x, 1.0, slope.y));
}

void fragment() {
	// §2.3 normalized crest height ∈ [0,1] (sim normalized_wave_height),
	// computed from the summed display surface: 0.5·(y_local/amplitude + 1).
	float crest = 0.5 * (v_norm + 1.0);
	// §2.3 Jacobian generalised to the display spectrum: J ≈ 1 − Q·Σk_i·A_i·
	// cosθ_i (reduces to the sim's 1 − Q·k·A·cosθ for a single harmonic).
	// Recomputed here because the snapshot carries no foam field (docs/04).
	float jacobian = 1.0 - v_jacq;

	// AA half-widths are CLAMPED: fwidth(crest) explodes at grazing angles
	// (one pixel spans a large theta range), which made the smoothstep saturate
	// and foamed the entire far ocean into a solid white wedge/band. The cap
	// keeps per-pixel antialiasing near the camera while bounding the foam band
	// to (threshold ± cap) everywhere (docs/04 §6.4).
	float wj = clamp(fwidth(jacobian), 1e-4, 0.04);
	float foam_j = 1.0 - smoothstep(foam_jacobian_threshold - wj,
	                                foam_jacobian_threshold + wj, jacobian);
	float wh = clamp(fwidth(crest), 1e-4, 0.006);
	float foam_h = smoothstep(foam_height_threshold - wh,
	                          foam_height_threshold + wh, crest);
	// Foam only on high crests: the height term is gated by the scene's
	// foam_height_threshold; the Jacobian term is a second, independent gate.
	float foam = clamp(max(foam_j, foam_h), 0.0, 1.0);

	// Fresnel toward the sky tint (sun-node specular highlight is NOT wired
	// into this shader — display simplification, documented in docs/04).
	float ndv = clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0);
	// Display tuning: grazing-angle fresnel is capped so the horizon does not
	// wash to a solid sky-colored band (docs/04 §5/§6.4).
	float fresnel = min(pow(1.0 - ndv, fresnel_power), 0.5);

	// Depth-ish blend toward the horizon: grazing view angles (small ndv) lean
	// deep, wave crests lean shallow. Real shoreline depth needs
	// y_terrain(x,z), which the display side does not have — deviation from
	// SCR-LIB-RENDER-WATER recorded in docs/04_simulation_engine.md.
	vec3 water = mix(deep_color.rgb, shallow_color.rgb, crest * ndv);
	vec3 col = mix(water, sky_tint.rgb, fresnel);
	col = mix(col, foam_color.rgb, foam);

	ALBEDO = col;
	// Display-only roughness/specular curve: kept high enough that the sun's
	// directional specular lobe cannot blow out into white wedges.
	ROUGHNESS = mix(0.5, 0.2, fresnel);
	SPECULAR = 0.35;
	EMISSION = foam * foam_color.rgb * specular_gain * 0.01; // faint foam glow
}
