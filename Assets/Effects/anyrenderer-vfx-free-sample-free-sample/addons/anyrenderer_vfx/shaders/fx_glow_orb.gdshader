// AnyRenderer VFX - Glow Orb (3D billboard)
// Energy core for projectiles, pickups, charge-ups and muzzle glows.
// The quad always faces the camera and keeps the node's scale. The glow is
// built into the shader (core + halo + swirling plasma), so it still looks
// bright where post-process glow is off or unsupported.
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;

#include "res://addons/anyrenderer_vfx/shaders/fx_common.gdshaderinc"

// Lifecycle like every effect in the pack: 0 = start, 1 = finished/invisible.
// 0 -> fade_in: grows in; fade_in -> (1 - fade_out): full brightness (ArfxPlayer
// holds here in persistent mode); last fade_out part: fades out.
uniform float progress : hint_range(0.0, 1.0) = 0.5;
uniform float seed = 0.0;
uniform float fade_in : hint_range(0.01, 0.5) = 0.2;
uniform float fade_out : hint_range(0.01, 0.5) = 0.3;

uniform vec4 core_color : source_color = vec4(1.0, 1.0, 0.95, 1.0);
uniform vec4 glow_color : source_color = vec4(0.55, 0.3, 1.0, 1.0);
uniform float core_size : hint_range(0.01, 0.6) = 0.18;
uniform float halo_falloff : hint_range(0.5, 8.0) = 2.6;
uniform float swirl_speed : hint_range(-6.0, 6.0) = 1.5;
uniform float swirl_amount : hint_range(0.0, 1.0) = 0.55;
uniform float flicker : hint_range(0.0, 1.0) = 0.15;
uniform float intensity : hint_range(0.0, 8.0) = 1.5;

void vertex() {
	// Camera-facing billboard that preserves the node's (non-uniform) scale.
	vec3 scale = vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz), length(MODEL_MATRIX[2].xyz));
	mat4 billboard = mat4(
		vec4(normalize(INV_VIEW_MATRIX[0].xyz) * scale.x, 0.0),
		vec4(normalize(INV_VIEW_MATRIX[1].xyz) * scale.y, 0.0),
		vec4(normalize(INV_VIEW_MATRIX[2].xyz) * scale.z, 0.0),
		MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = VIEW_MATRIX * billboard;
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	float ang = atan(p.y, p.x) / TAU;

	float core = 1.0 - smoothstep(core_size * 0.4, core_size, r);
	float halo = pow(clamp(1.0 - r, 0.0, 1.0), halo_falloff);

	// Plasma: noise sampled in a rotating polar frame. Periodic in the angle
	// (6 cells per turn), so there is no seam where atan() wraps.
	float swirl = arfx_fbm2_wrap_x(vec2(ang * 6.0 + TIME * swirl_speed * 0.25 + r * 2.0, r * 4.0 - TIME * 0.8) + seed * 13.0, 6.0);
	float plasma = smoothstep(0.35, 0.85, swirl) * (1.0 - smoothstep(0.2, 0.95, r)) * swirl_amount;

	float pulse = 1.0 - flicker * (0.5 + 0.5 * sin(TIME * 23.0 + seed * 6.0)) * arfx_noise2(vec2(TIME * 9.0, seed));
	float life = smoothstep(0.0, fade_in, progress) * (1.0 - smoothstep(1.0 - fade_out, 1.0, progress));
	float a = (core + halo * 0.8 + plasma) * pulse * life;
	a *= 1.0 - smoothstep(0.92, 1.0, r);

	vec3 col = mix(glow_color.rgb, core_color.rgb, clamp(core + plasma * 0.3, 0.0, 1.0));
	ALBEDO = col * intensity;
	ALPHA = clamp(a, 0.0, 1.0);
}
