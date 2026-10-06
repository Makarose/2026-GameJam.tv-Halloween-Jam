// AnyRenderer VFX - Sprite Hit FX (2D, canvas_item)
// One material for the most common 2D "game feel" needs:
//   * hit flash (tint the sprite towards a colour)
//   * outline (needs ~outline_px of transparent padding around the sprite)
//   * dissolve with a glowing edge (death / teleport)
// ArfxSpriteHit makes the material unique per sprite at runtime, so one
// sprite flashing never makes every other sprite flash too.
shader_type canvas_item;

#include "res://addons/anyrenderer_vfx/shaders/fx_common.gdshaderinc"

group_uniforms Flash;
uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

group_uniforms Outline;
uniform float outline_px : hint_range(0.0, 8.0) = 0.0;
uniform vec4 outline_color : source_color = vec4(1.0, 0.85, 0.2, 1.0);

group_uniforms Dissolve;
uniform float dissolve : hint_range(0.0, 1.0) = 0.0;
uniform float dissolve_scale : hint_range(1.0, 64.0) = 14.0;
uniform float dissolve_edge : hint_range(0.0, 0.3) = 0.07;
uniform vec4 dissolve_edge_color : source_color = vec4(0.4, 0.9, 1.0, 1.0);
group_uniforms;

void fragment() {
	// In Godot 4, COLOR already holds texture * modulate here.
	vec4 base = COLOR;

	// Outline: only where this pixel is (mostly) transparent but a neighbour is not.
	if (outline_px > 0.0) {
		// Largest alpha found in 8 directions at outline_px pixels (cheap probe).
		// Kept inline: passing TEXTURE into a helper function fails to compile
		// on the Compatibility renderer in Godot 4.2.
		float na = 0.0;
		for (int i = 0; i < 8; i++) {
			float ang = float(i) * (TAU / 8.0);
			vec2 dir = vec2(cos(ang), sin(ang));
			na = max(na, texture(TEXTURE, UV + dir * TEXTURE_PIXEL_SIZE * outline_px).a);
		}
		float outline = clamp(na - base.a, 0.0, 1.0);
		base.rgb = mix(base.rgb, outline_color.rgb, outline);
		base.a = max(base.a, outline * outline_color.a);
	}

	// Flash tint keeps the sprite's own alpha.
	base.rgb = mix(base.rgb, flash_color.rgb, flash_amount * flash_color.a);

	// Dissolve with an emissive edge.
	if (dissolve > 0.0) {
		float n = arfx_fbm2(UV / TEXTURE_PIXEL_SIZE / 64.0 * dissolve_scale);
		float threshold = dissolve * (1.0 + 2.0 * dissolve_edge) - dissolve_edge;
		float keep = step(threshold, n);
		float edge = (1.0 - smoothstep(threshold, threshold + dissolve_edge, n)) * keep;
		base.rgb = mix(base.rgb, dissolve_edge_color.rgb, edge);
		base.a *= keep;
	}

	COLOR = base;
}
