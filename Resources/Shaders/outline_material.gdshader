shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float outline_width : hint_range(0, 10) = 1.0; 

void fragment() {
	vec2 pixel_size = TEXTURE_PIXEL_SIZE;
	float max_alpha = 0.0;
	int search_radius = 4;
	
	for (int x = -search_radius; x <= search_radius; x++) {
		for (int y = -search_radius; y <= search_radius; y++) {
			max_alpha = max(max_alpha, texture(TEXTURE, UV + vec2(float(x), float(y)) * pixel_size * outline_width).a);
		}
	}
	
	vec4 original_color = texture(TEXTURE, UV);
	
	float outline_factor = step(original_color.a, 0.1) * max_alpha;
	
	COLOR = mix(original_color, outline_color, outline_factor);
}