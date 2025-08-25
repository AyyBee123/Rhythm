shader_type canvas_item;

uniform vec3 color: source_color = vec3(1.0, 0.0, 0.0);

void fragment() {
	COLOR.rgb = vec3(color);
}
