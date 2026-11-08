shader_type canvas_item;

uniform sampler2D voronoi_sampler : repeat_enable;
uniform sampler2D edge_curve;
uniform float offset = 0.0;
uniform vec2 texture_offset = vec2(0.0);
uniform sampler2D color_gradient : source_color;
// Pixelation: the cloud is drawn in square blocks this many screen pixels
// wide. fwidth(UV) is how much UV changes per screen pixel, so the blocks stay
// the same size on screen while the cloud grows.
uniform float pixel_size = 4.0;

void fragment() {
	vec2 block = fwidth(UV) * pixel_size;
	vec2 uv = (floor(UV / block) + 0.5) * block;
	float voronoi = 1.0 - texture(voronoi_sampler, uv * 0.25 + texture_offset).x;
	float d = distance(uv, vec2(0.5)) * 2.0;
	float n_smooth_d = (voronoi * offset) * texture(edge_curve, vec2(d, 0.0)).x;
	COLOR.a *= step(0.5, n_smooth_d);
	COLOR.rgb = texture(color_gradient, vec2(n_smooth_d, 0.0)).rgb;
}
