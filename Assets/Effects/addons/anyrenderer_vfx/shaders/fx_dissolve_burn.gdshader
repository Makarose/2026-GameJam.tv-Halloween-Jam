// AnyRenderer VFX - Dissolve / Burn-away (3D, lit)
// Drop-in material for any mesh: enemies dying, props teleporting, spell
// shields breaking. Noise is computed in OBJECT space, so it needs no UVs and
// stays glued to the mesh while it moves. Uses discard (alpha-scissor style),
// which works on all renderers and keeps correct depth sorting and shadows.
shader_type spatial;
render_mode cull_back, depth_draw_opaque;

#include "res://Assets/Effects/addons/anyrenderer_vfx/shaders/fx_common.gdshaderinc"

// 0 = fully visible, 1 = fully gone.
uniform float progress : hint_range(0.0, 1.0) = 0.4;
uniform float seed = 0.0;

group_uniforms Surface;
uniform vec4 albedo_color : source_color = vec4(0.75, 0.78, 0.85, 1.0);
uniform sampler2D albedo_texture : source_color, hint_default_white, filter_linear_mipmap;
uniform float roughness : hint_range(0.0, 1.0) = 0.6;
uniform float metallic : hint_range(0.0, 1.0) = 0.0;

group_uniforms Dissolve;
uniform float noise_scale : hint_range(0.1, 20.0) = 3.5;
uniform float edge_width : hint_range(0.0, 0.3) = 0.08;
uniform vec4 edge_color : source_color = vec4(1.0, 0.45, 0.1, 1.0);
uniform float edge_energy : hint_range(0.0, 16.0) = 4.0;
uniform vec4 char_color : source_color = vec4(0.08, 0.04, 0.03, 1.0); // scorched band before the glow
// Optional directional sweep (e.g. burn from the top down). 0 = pure noise.
uniform float direction_mix : hint_range(0.0, 1.0) = 0.5;
uniform vec3 sweep_direction = vec3(0.0, -1.0, 0.0);
uniform float object_height = 2.0; // approximate size of the mesh along sweep_direction
group_uniforms;

varying vec3 v_obj_pos;

void vertex() {
	v_obj_pos = VERTEX; // object-space position, before any transform
}

void fragment() {
	float n = arfx_fbm3(v_obj_pos * noise_scale + vec3(seed * 7.0));
	// Linear gradient along the sweep direction, remapped to roughly [0, 1].
	float g = dot(v_obj_pos, normalize(sweep_direction)) / max(object_height, 0.001) + 0.5;
	float v = mix(n, clamp(g, 0.0, 1.0) * 0.8 + n * 0.2, direction_mix);

	// Threshold travels a bit past [0,1] so that 0 and 1 are fully clean states.
	float threshold = progress * (1.0 + 2.0 * edge_width) - edge_width;
	if (v < threshold) {
		discard;
	}

	float edge = 1.0 - smoothstep(threshold, threshold + edge_width, v);
	float charred = 1.0 - smoothstep(threshold, threshold + edge_width * 2.5, v);

	vec3 base = albedo_color.rgb * texture(albedo_texture, UV).rgb;
	ALBEDO = mix(base, char_color.rgb, charred * step(0.001, progress));
	ROUGHNESS = roughness;
	METALLIC = metallic;
	EMISSION = edge_color.rgb * edge * edge_energy * step(0.001, progress);
}
