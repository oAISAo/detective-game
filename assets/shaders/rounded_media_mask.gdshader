shader_type canvas_item;

uniform vec2 rect_size = vec2(348.0, 232.0);
uniform float corner_radius = 8.0;
varying vec2 local_pos;

void vertex() {
	local_pos = VERTEX;
}

float rounded_box_sdf(vec2 center_pos, vec2 half_size, float radius) {
	vec2 q = abs(center_pos) - (half_size - vec2(radius));
	return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - radius;
}

void fragment() {
	vec2 center = rect_size * 0.5;
	float safe_radius = min(corner_radius, min(center.x, center.y));
	float dist = rounded_box_sdf(local_pos - center, center, safe_radius);
	float mask = 1.0 - smoothstep(0.0, 1.0, dist);
	vec4 sampled = texture(TEXTURE, UV);
	if (mask <= 0.0) {
		discard;
	}

	COLOR = vec4(sampled.rgb, sampled.a * mask);
}