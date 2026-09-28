shader_type spatial;
// lava.gdshader — display-only crater lava lake (SCR island scene).
//
// AUTHORITY SPLIT (docs/04_simulation_engine.md):
//   * src/mojo/sim/volcano.mojo is authoritative for the lava state: radius,
//     lake level, emissive intensity, crust fraction, effusion state.
//   * The adapter (scr_godot_adapter.cpp apply_volcano) writes the three
//     contract uniforms below from the VOLCANO section every physics frame
//     (104_contract §7). This shader only RENDERS that state (AP-11: display
//     never derives "is it erupting / how hot / is it night").
//   * Names emissive_intensity / crust_fraction / radius are normative —
//     they MUST match the adapter's set_shader_parameter list exactly.
//
// GEOMETRY: the node is a unit CylinderMesh disc (radius 1, height 0.2) that
// the adapter scales to (radius, 1, radius) and places at
// (center_x, lake_level, center_z). UV of the top cap maps the disc as
// uv ∈ [0,1]², centre (0.5, 0.5) — the pattern is radial in UV space, so it
// stays proportional to the contracted radius under the non-uniform scale.
//
// Everything not listed as a contract uniform is DISPLAY-ONLY and lives in
// scenes/island.tscn shader params — values and provenance documented in
// docs/04_simulation_engine.md §5 (AP-7).

// --- VOLCANO section fields (written by adapter, every frame) --------------
uniform float emissive_intensity; // §7: crust-factor radiance scalar (> 0)
uniform float crust_fraction;     // §7: C ∈ [0,1], 1 = fully crusted
uniform float radius;             // §7: lava lake radius (u) — carried for
                                  // completeness; UV geometry already scales.

// --- display-only (scene-provided; see docs/04 §5 parameter table) ---------
uniform vec4 core_color : source_color;   // molten interior tint
uniform vec4 crust_color : source_color;  // cooled crust tint
uniform float pattern_scale;              // FBM frequency over the disc
uniform float pattern_strength;           // 0 = flat blend, 1 = full texture
uniform float emission_gain;              // radiance scale of EMISSION
uniform float albedo_scale;               // sun-lit base multiplier (keeps
                                          // the disc from overexposing into
                                          // pale yellow under ACES)
uniform float shimmer_amount;             // TIME-driven crust drift (display)

// --- display-only FBM (deterministic value noise; no external textures) -----
float lava_hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float lava_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	float a = lava_hash(i);
	float b = lava_hash(i + vec2(1.0, 0.0));
	float c = lava_hash(i + vec2(0.0, 1.0));
	float d = lava_hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float lava_fbm(vec2 p) {
	float v = 0.0;
	float amp = 0.5;
	for (int i = 0; i < 4; i++) {
		v += amp * lava_noise(p);
		p = p * 2.03 + vec2(17.3, 9.1);
		amp *= 0.5;
	}
	return v; // ~[0, 1]
}

void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	float disc_r = length(p); // 0 at centre, 1 at the contracted radius

	// Spatial crust pattern: display-only (sim ships a scalar crust fraction,
	// not a texture). TIME only drifts the pattern slowly (shimmer_amount is
	// a scene display constant) — no state is derived from TIME here.
	float pattern = lava_fbm(UV * pattern_scale + vec2(shimmer_amount) * TIME);
	// Radial heat: the rim cools a little faster than the centre, but the
	// blend stays bounded by crust_fraction (contract-owned coverage).
	float c = clamp(crust_fraction + (pattern - 0.5) * pattern_strength
	                + smoothstep(0.55, 1.0, disc_r) * 0.15, 0.0, 1.0);

	vec3 base = mix(core_color.rgb, crust_color.rgb, c);
	// Crusted surface keeps a dim ember glow; molten areas go bright.
	vec3 glow = core_color.rgb * (1.0 - c * 0.85);

	ALBEDO = base * albedo_scale;
	ROUGHNESS = mix(0.25, 0.9, c);
	SPECULAR = 0.2;
	EMISSION = glow * emissive_intensity * emission_gain;
}
