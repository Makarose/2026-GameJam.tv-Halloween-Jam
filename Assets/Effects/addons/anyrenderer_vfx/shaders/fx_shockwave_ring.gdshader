// AnyRenderer VFX - Shockwave Ring (3D)
// Expanding ground ring for landings, slams and explosions. Use on a
// PlaneMesh lying on the ground (or rotate it for a vertical "sonic boom").
// No refraction/screen texture on purpose: screen reads differ between
// renderers and break on Compatibility, so the ring is purely emissive.
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;

#include "res://addons/anyrenderer_vfx/shaders/fx_common.gdshaderinc"

uniform float progress : hint_range(0.0, 1.0) = 0.35;
uniform float seed = 0.0;

group_uniforms Shape;
uniform float start_radius : hint_range(0.0, 0.5) = 0.08;
uniform float end_radius : hint_range(0.3, 1.0) = 0.95;
uniform float ring_width : hint_range(0.01, 0.3) = 0.09;
uniform float spoke_count : hint_range(0.0, 48.0, 1.0) = 18.0; // radial cracks/dust rays
uniform float spoke_strength : hint_range(0.0, 1.0) = 0.45;

group_uniforms Look;
uniform vec4 inner_color : source_color = vec4(1.0, 0.85, 0.55, 1.0);
uniform vec4 outer_color : source_color = vec4(1.0, 0.35, 0.1, 1.0);
uniform float intensity : hint_range(0.0, 8.0) = 1.4;
uniform float halo_strength : hint_range(0.0, 1.0) = 0.4;
uniform float flash_strength : hint_range(0.0, 2.0) = 0.8;     // bright disc at the very start
group_uniforms;

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	float ang = atan(p.y, p.x) / TAU + 0.5;

	float ease = 1.0 - pow(1.0 - progress, 2.5);
	float ring_r = mix(start_radius, end_radius, ease);
	float w = ring_width * (1.0 - 0.6 * progress); // ring gets thinner as it travels

	// Wobble the ring radius slightly with angular noise so it is not a perfect circle.
	float wobble = (arfx_noise2_wrap_x(vec2(ang * 24.0, seed * 3.0), 24.0) - 0.5) * 0.04; // periodic: no seam at atan wrap
	float dist = abs(r - (ring_r + wobble));

	float ring = 1.0 - smoothstep(w * 0.25, w, dist);
	float halo = arfx_halo(dist - w, w * 1.2) * halo_strength;

	// Radial rays inside the ring.
	float rays = 0.0;
	if (spoke_count > 0.0) {
		float spokes = max(floor(spoke_count + 0.5), 1.0);
		float ray_noise = arfx_noise2_wrap_x(vec2(ang * spokes, seed * 5.0 + 1.0), spokes);
		float ray_mask = smoothstep(0.55, 0.95, ray_noise);
		float radial = smoothstep(ring_r * 0.2, ring_r, r) * (1.0 - smoothstep(ring_r, ring_r + w, r));
		rays = ray_mask * radial * spoke_strength;
	}

	// Short flash disc in the first 15% of the lifetime.
	float flash = (1.0 - smoothstep(0.0, 0.15, progress)) * (1.0 - smoothstep(0.0, 0.35, r)) * flash_strength;

	float fade = 1.0 - smoothstep(0.45, 1.0, progress);
	float a = (ring + halo + rays) * fade + flash;
	a *= 1.0 - smoothstep(0.97, 1.0, r); // never show the square edge of the quad

	vec3 col = mix(inner_color.rgb, outer_color.rgb, clamp(progress * 1.3 + (1.0 - ring) * 0.3, 0.0, 1.0));
	ALBEDO = col * intensity;
	ALPHA = clamp(a, 0.0, 1.0);
}
