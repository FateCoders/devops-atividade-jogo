shader_type canvas_item;

uniform vec4 glow_color : source_color = vec4(1.0, 1.0, 0.6, 1.0);
uniform float glow_boost : hint_range(0.0, 5.0) = 2.0;

void fragment() {
    vec4 tex = texture(TEXTURE, UV);

    // Intensifica a cor para o sistema de Glow capturar
    vec4 bright_color = tex * glow_color * glow_boost;

    COLOR = bright_color;
}