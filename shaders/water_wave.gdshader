shader_type canvas_item;
// Calm coastal water: slow horizontal roll + soft foam highlights.
// Avoids high-frequency caustics that read as psychedelic lines.

uniform float time_scale : hint_range(0.0, 2.0) = 0.55;
uniform float wave_strength : hint_range(0.0, 0.04) = 0.008;
uniform float foam_strength : hint_range(0.0, 0.35) = 0.14;
uniform vec4 shallow_tint : source_color = vec4(0.30, 0.62, 0.66, 1.0);
uniform vec4 deep_tint : source_color = vec4(0.12, 0.40, 0.50, 1.0);
uniform float alpha_mul : hint_range(0.5, 1.3) = 0.95;

void fragment() {
	float t = TIME * time_scale;
	vec2 uv = UV;

	// Slow, large-scale roll (ocean swell) — keep frequencies low
	float swell = sin(UV.y * 3.5 + t * 1.1) * cos(UV.x * 1.8 - t * 0.7);
	uv.x += swell * wave_strength;
	uv.y += sin(UV.x * 2.2 + t * 0.9) * wave_strength * 0.65;

	vec4 tex = texture(TEXTURE, uv);

	// Depth from atlas darkness / green-blue bias
	float depth = clamp(1.0 - (tex.r * 0.35 + tex.g * 0.45 + tex.b * 0.2), 0.0, 1.0);
	vec3 tint = mix(shallow_tint.rgb, deep_tint.rgb, depth * 0.7);

	// Soft foam ridges along swell crests (broad bands, not sparkles)
	float crest = sin(UV.y * 4.0 - t * 1.4 + UV.x * 0.8);
	crest = smoothstep(0.55, 0.95, crest);
	float foam = crest * foam_strength * (0.75 + 0.25 * sin(t * 0.8 + UV.x * 2.0));

	// Very soft shimmer (single low-amp term, not multiplied caustics)
	float shimmer = sin(UV.x * 5.0 + UV.y * 3.0 + t * 1.2) * 0.025;

	vec3 rgb = tex.rgb * tint;
	rgb += vec3(foam * 0.9, foam * 0.95, foam);
	rgb += vec3(shimmer);

	float a = tex.a * alpha_mul;
	// Gentle breathing on alpha only
	a *= 0.96 + 0.04 * sin(t * 0.9 + UV.y * 2.5);

	COLOR = vec4(rgb, clamp(a, 0.0, 1.0));
}
