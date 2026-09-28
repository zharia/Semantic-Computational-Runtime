shader_type spatial;
render_mode blend_mix, unshaded, cull_disabled, depth_draw_never, fog_disabled;
// clouds.gdshader — display-only overcast/cloud deck (SCR island scene).
//
// AUTHORITY SPLIT (docs/04_simulation_engine.md, milestone 0004):
//   * src/mojo/weather/state.mojo + weather/palette.mojo are authoritative for
//     WHAT the sky state IS (cloud_cover, precipitation, wetness, sun, fog).
//   * This shader is a pure function of ONE normative uniform written by the
//     GDExtension adapter from the SKY section (104_contract §4.3):
//         cloud_cover ∈ [0,1]   (offset +44)
//     Nothing else is read from the sim. No sim feedback (AP-17).
//   * The noise field, its scale, the threshold edge width, the wind drift and
//     the distance fade are DISPLAY-ONLY constants documented here and in
//     docs/04_simulation_engine.md §5/§6.6 — they choose how a scalar cover
//     value looks, never what it means.
//   * `cloud_cover = 0` renders nothing (step gate below), so the clear-sky
//     snapshot of milestone 0004 is bit-identical to the 0002/0003 view.
//
// WHY `fog_disabled` (documented deviation, docs/04 §6.6):
//   * The engine fog is exponential in distance (fog_density is a wire field
//     here, ~3.5e-3). The deck sits at CLOUD_PLANE_ALTITUDE (scene), i.e.
//     570-1500 u from the camera for anything inside the upper view cone, so
//     exp(-3.5e-3 * 600) ≈ 0.12 => the engine would erase the whole deck.
//   * Real cumulus sit ABOVE the boundary-layer haze, so the deck opts out of
//     the engine fog and instead does its own aerial fade below (fade to the
//     sky colour by distance), which is what the fog would have been for.

// --- SKY section field (written by adapter every frame) --------------------
uniform float cloud_cover; // [0,1] — 104_contract §4.3

// --- display-only look (scene-provided; docs/04 §5 parameter table) ---------
uniform vec4 cloud_color : source_color; // flat cloud tint (pre-sun)
uniform float noise_scale;   // world u -> noise u
uniform float drift_speed;   // TIME * drift (display shimmer only)
uniform float opacity;       // peak alpha at full cover

// --- display-only constants (docs/04 §6.6) --------------------------------
const int OCTAVES = 5;
const float WARP_AMOUNT = 0.55;  // domain warp strength (billow shape)
const float EDGE_WIDTH = 0.10;   // softness of the cover threshold
const float COVER_GATE = 0.004;  // below this the deck is fully transparent
const float FADE_NEAR = 1100.0;  // distance fade window (u from camera)
const float FADE_FAR = 3600.0;
const float PLANE_EDGE = 3600.0; // radial fade before the plane's own edge

varying vec3 v_world; // world-space fragment position (plane is world-axis aligned)

float hash21(vec2 p) {
	p = fract(p * vec2(127.1, 311.7));
	p += dot(p, p + 34.5);
	return fract(p.x * p.y);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float fbm(vec2 p) {
	float sum = 0.0;
	float amp = 0.5;
	float norm = 0.0;
	for (int i = 0; i < OCTAVES; i++) {
		sum += amp * value_noise(p);
		norm += amp;
		p = p * 2.03 + vec2(17.3, 9.1);
		amp *= 0.5;
	}
	return sum / norm;
}

void vertex() {
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	// TIME only shimmers the display noise; no semantic content (AP-17).
	vec2 p = v_world.xz * noise_scale + vec2(drift_speed, drift_speed * 0.6) * TIME;
	// Domain warp breaks up the lattice look of a single value-noise octave.
	float q = fbm(p * 0.5);
	vec2 wp = p + (q - 0.5) * WARP_AMOUNT * 4.0;
	float n = fbm(wp);

	// cover -> coverage: at cover=0 threshold is above the noise floor
	// (nothing), at cover=1 it is below (solid deck).
	float thr = 1.0 - cloud_cover;
	float cov = smoothstep(thr - EDGE_WIDTH, thr + EDGE_WIDTH, n);
	cov *= step(COVER_GATE, cloud_cover);

	float dist = length(VERTEX); // view-space distance from the camera
	float fade = 1.0 - smoothstep(FADE_NEAR, FADE_FAR, dist);
	float edge = 1.0 - smoothstep(PLANE_EDGE * 0.7, PLANE_EDGE, length(v_world.xz));

	ALBEDO = cloud_color.rgb;
	ALPHA = cov * cloud_color.a * opacity * fade * edge;
}
