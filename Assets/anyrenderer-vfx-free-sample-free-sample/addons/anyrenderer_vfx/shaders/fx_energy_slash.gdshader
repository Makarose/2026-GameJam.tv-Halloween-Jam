// AnyRenderer VFX - Energy Slash (3D)
// A sweeping crescent for melee attacks. Put it on a PlaneMesh (the plane is
// the slash plane; rotate the node to tilt the swing). Fully procedural: no
// textures, no screen reads, so it behaves the same on every renderer.
//
// Drive it with `progress` (0 -> 1). ArfxPlayer does that for you and gives
// every effect instance its own lightweight copy of the material, so many
// copies can play at different times without syncing up. (We do not use
// `instance uniform` because Godot 4.2's Compatibility renderer rejects it.)
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;

#include "res://addons/anyrenderer_vfx/shaders/fx_common.gdshaderinc"

// Animated per effect instance by ArfxPlayer.
uniform float progress : hint_range(0.0, 1.0) = 0.45;
uniform float seed = 0.0;

group_uniforms Shape;
uniform float arc_degrees : hint_range(30.0, 360.0) = 210.0; // how far the blade travels
uniform float start_angle_degrees : hint_range(-180.0, 180.0) = -20.0;
uniform float radius : hint_range(0.1, 0.95) = 0.72;         // in UV space, 1.0 = plane edge
uniform float thickness : hint_range(0.01, 0.4) = 0.16;
uniform float trail_length : hint_range(0.05, 1.0) = 0.8;    // fraction of the arc
uniform float sweep_portion : hint_range(0.2, 1.0) = 0.55;   // part of the lifetime spent sweeping

group_uniforms Look;
uniform vec4 core_color : source_color = vec4(1.0, 0.98, 0.92, 1.0);
uniform vec4 edge_color : source_color = vec4(0.25, 0.75, 1.0, 1.0);
uniform float intensity : hint_range(0.0, 8.0) = 1.6;         // >1 feeds HDR glow on Forward+/Mobile
uniform float halo_strength : hint_range(0.0, 1.0) = 0.35;    // built-in fake bloom
uniform float noise_scale : hint_range(1.0, 20.0) = 7.0;
uniform float breakup : hint_range(0.0, 1.0) = 0.6;           // how much the tail erodes
group_uniforms;

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);

	// Angle measured from start_angle, wrapped into [0, 1) of a full turn.
	float ang = atan(p.y, p.x) / TAU;
	float a01 = fract(ang - start_angle_degrees / 360.0);
	float s = a01 / (arc_degrees / 360.0); // 0..1 along the arc, >1 = outside

	// Head of the blade: eased sweep from the start to the end of the arc.
	float sweep_t = clamp(progress / sweep_portion, 0.0, 1.0);
	float head = 1.0 - pow(1.0 - sweep_t, 3.0); // ease-out cubic
	// The trail grows while the blade accelerates...
	float trail = max(trail_length * (0.35 + 0.65 * sweep_t), 0.001);
	float t = (head - s) / trail;            // 0 at head, 1 at tail end
	// ...and collapses towards the head after the sweep.
	float collapse = smoothstep(sweep_portion, 1.0, progress);
	float visible_len = 1.0 - collapse;

	// Soft masks (no hard wedge edges): head, collapsing tail and arc end.
	float inside = smoothstep(-0.02, 0.03, t)
			* (1.0 - smoothstep(visible_len - 0.2, visible_len, t))
			* smoothstep(0.0, 0.1, s)
			* (1.0 - smoothstep(0.82, 1.0, s));
	// Keep the halo away from the plane edges so no quad border ever shows.
	inside *= 1.0 - smoothstep(0.82, 0.99, r);

	// Band thickness tapers from head to tail.
	float w = thickness * pow(clamp(1.0 - t, 0.0, 1.0), 0.6);
	float dist = abs(r - radius);
	float band = 1.0 - smoothstep(w * 0.35, w, dist);
	float core = 1.0 - smoothstep(0.0, w * 0.35, dist);
	float tail = clamp(1.0 - t, 0.0, 1.0);
	float halo = arfx_halo(dist - w, w * 0.6 + 0.01) * halo_strength * tail * tail;

	// Streaky noise running along the arc erodes the tail.
	float n = arfx_fbm2(vec2(s * noise_scale * 2.0 - progress * 6.0, r * noise_scale) + seed * 17.0);
	float erode = smoothstep(t * breakup, t * breakup + 0.35, n);

	float fade = 1.0 - smoothstep(0.75, 1.0, progress);
	float a = (band * erode + halo) * inside * fade;

	vec3 col = mix(edge_color.rgb, core_color.rgb, core * erode);
	ALBEDO = col * intensity;
	ALPHA = clamp(a, 0.0, 1.0);
}
