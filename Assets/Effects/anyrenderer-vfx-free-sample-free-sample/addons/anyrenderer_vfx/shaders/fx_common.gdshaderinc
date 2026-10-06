// AnyRenderer VFX - shared shader helpers.
// Written for this pack by Mothlight Studio (no third-party code copied). Plain math intended to run
// the same way on Forward+, Mobile and Compatibility (OpenGL ES 3 / WebGL 2 feature set):
//   * no screen/depth texture reads
//   * no compute, no SSBOs, no derivative tricks
//   * loops have a constant trip count (required by some WebGL 2 drivers)

// Integer hash written for this pack: xor-shift / multiply rounds with
// arbitrary odd constants we picked ourselves. Structure inspired by
// MurmurHash3 fmix32 (public domain); see THIRD_PARTY_NOTICES.txt.
// 32-bit uint maths is exact by specification (GLSL ES 3.0 highp, Vulkan), so
// the pattern is the same on all three renderers and does not drift with
// large coordinates.
uint arfx_scramble(uint h) {
	h ^= h >> 16u;
	h *= 0xac8d1a7fu;
	h ^= h >> 13u;
	h *= 0x495db021u;
	h ^= h >> 16u;
	return h;
}

// 24 high bits -> float in [0, 1).
float arfx_unit(uint h) {
	return float(h >> 8u) * (1.0 / 16777216.0);
}

// Maps a 2D integer cell coordinate to a pseudo-random value in [0, 1).
float arfx_hash21(vec2 cell) {
	uint x = uint(int(cell.x));
	uint y = uint(int(cell.y));
	return arfx_unit(arfx_scramble((x * 0x7eab475du) ^ (y * 0x14d1734du)));
}

// Same for 3D cells (used by object-space effects such as dissolve).
float arfx_hash31(vec3 cell) {
	uint x = uint(int(cell.x));
	uint y = uint(int(cell.y));
	uint z = uint(int(cell.z));
	return arfx_unit(arfx_scramble((x * 0x7eab475du) ^ (y * 0x14d1734du) ^ (z * 0xeacb8711u)));
}

// Smooth value noise in 2D, output in [0, 1].
float arfx_noise2(vec2 p) {
	vec2 cell = floor(p);
	vec2 f = fract(p);
	vec2 w = f * f * (3.0 - 2.0 * f); // smoothstep weights
	float n00 = arfx_hash21(cell);
	float n10 = arfx_hash21(cell + vec2(1.0, 0.0));
	float n01 = arfx_hash21(cell + vec2(0.0, 1.0));
	float n11 = arfx_hash21(cell + vec2(1.0, 1.0));
	return mix(mix(n00, n10, w.x), mix(n01, n11, w.x), w.y);
}

// Smooth value noise in 3D, output in [0, 1].
float arfx_noise3(vec3 p) {
	vec3 cell = floor(p);
	vec3 f = fract(p);
	vec3 w = f * f * (3.0 - 2.0 * f);
	float a = mix(arfx_hash31(cell),                    arfx_hash31(cell + vec3(1.0, 0.0, 0.0)), w.x);
	float b = mix(arfx_hash31(cell + vec3(0.0, 1.0, 0.0)), arfx_hash31(cell + vec3(1.0, 1.0, 0.0)), w.x);
	float c = mix(arfx_hash31(cell + vec3(0.0, 0.0, 1.0)), arfx_hash31(cell + vec3(1.0, 0.0, 1.0)), w.x);
	float d = mix(arfx_hash31(cell + vec3(0.0, 1.0, 1.0)), arfx_hash31(cell + vec3(1.0, 1.0, 1.0)), w.x);
	return mix(mix(a, b, w.y), mix(c, d, w.y), w.z);
}

// Three octaves of 2D noise ("fractal" detail). Fixed loop count on purpose.
float arfx_fbm2(vec2 p) {
	float sum = 0.0;
	float amp = 0.55;
	for (int i = 0; i < 3; i++) {
		sum += amp * arfx_noise2(p);
		p = p * 2.07 + vec2(11.3, 7.9);
		amp *= 0.5;
	}
	return sum / 0.9625; // normalise back to roughly [0, 1]
}

// Three octaves of 3D noise.
float arfx_fbm3(vec3 p) {
	float sum = 0.0;
	float amp = 0.55;
	for (int i = 0; i < 3; i++) {
		sum += amp * arfx_noise3(p);
		p = p * 2.03 + vec3(5.1, 13.7, 3.3);
		amp *= 0.5;
	}
	return sum / 0.9625;
}

// Value noise that repeats every `period` units along x (period = whole
// number). Use it for anything driven by an angle, e.g. ang01 * period, so
// there is no seam where atan() wraps from +PI to -PI.
float arfx_noise2_wrap_x(vec2 p, float period) {
	vec2 cell = floor(p);
	vec2 f = fract(p);
	vec2 w = f * f * (3.0 - 2.0 * f);
	float x0 = mod(cell.x, period);
	float x1 = mod(cell.x + 1.0, period);
	float n00 = arfx_hash21(vec2(x0, cell.y));
	float n10 = arfx_hash21(vec2(x1, cell.y));
	float n01 = arfx_hash21(vec2(x0, cell.y + 1.0));
	float n11 = arfx_hash21(vec2(x1, cell.y + 1.0));
	return mix(mix(n00, n10, w.x), mix(n01, n11, w.x), w.y);
}

// Three octaves of arfx_noise2_wrap_x; each octave doubles both the frequency
// and the period, so the sum still repeats every `period` units along x.
float arfx_fbm2_wrap_x(vec2 p, float period) {
	float sum = 0.0;
	float amp = 0.55;
	for (int i = 0; i < 3; i++) {
		sum += amp * arfx_noise2_wrap_x(p, period);
		p = p * 2.0 + vec2(0.0, 7.9);
		period *= 2.0;
		amp *= 0.5;
	}
	return sum / 0.9625;
}

// Cheap "fake bloom": a soft exponential halo around a shape whose distance
// to the shape edge is `dist`. Lets effects read as glowing even when the
// WorldEnvironment glow is disabled or unavailable (e.g. low-end targets).
float arfx_halo(float dist, float width) {
	return exp(-max(dist, 0.0) / max(width, 0.0001));
}
