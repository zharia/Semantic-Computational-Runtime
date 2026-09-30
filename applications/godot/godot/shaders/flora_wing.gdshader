// flora_wing.gdshader — display-only sway (flora fronds) + wing flap (birds).
//
// Milestone 0006 §3.4 (locked): flap/sway run on shader TIME ONLY — no phase
// is ever read from FLORA/FAUNA bytes (0006 AP-12) and nothing here feeds
// back into the snapshot (display-only, same pattern as the ocean shader's
// display-only terms, docs/04 §7).
//
// One shader serves both views (spec §3.1 names it "flora_wing"):
//   flora_view.gd  sets sway_* > 0, flap_amount = 0
//   fauna_view.gd  sets flap_* > 0, sway_amount = 0
// Albedo/roughness come from the materials_catalog values resolved by the
// adapter (0006 AP-14) — never hard-coded per-instance here.
shader_type spatial;
render_mode cull_disabled;

// Base albedo, pre-wetness (flora_view.gd multiplies set_wetness_gain in).
uniform vec4 albedo_color : source_color = vec4(0.24, 0.52, 0.18, 1.0);
uniform float roughness_value : hint_range(0.0, 1.0) = 0.85;

// Frond sway (flora): horizontal lean proportional to height above the
// instance anchor, phase keyed on world position so neighbours desync.
uniform float sway_amount : hint_range(0.0, 0.5) = 0.0; // u at full height
uniform float sway_speed = 1.1;                         // rad/s
uniform float sway_height = 3.0;                        // u of full amplitude

// Wing flap (birds): lift ∝ |x| so the wingtips oscillate while the
// root stays put (spec §3.4 display-only).
uniform float flap_amount : hint_range(0.0, 1.0) = 0.0; // u at wingtip
uniform float flap_speed = 9.0;                         // rad/s

void vertex() {
	if (sway_amount > 0.0) {
		vec3 org = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
		float phase = TIME * sway_speed + (org.x * 0.37 + org.z * 0.53);
		float h = clamp(VERTEX.y / max(sway_height, 0.001), 0.0, 1.0);
		float lean = sin(phase) * sway_amount * h * h;
		VERTEX.x += lean;
		VERTEX.z += lean * 0.5;
	}
	if (flap_amount > 0.0) {
		VERTEX.y += sin(TIME * flap_speed) * flap_amount * abs(VERTEX.x);
	}
}

void fragment() {
	ALBEDO = albedo_color.rgb;
	ROUGHNESS = roughness_value;
}
