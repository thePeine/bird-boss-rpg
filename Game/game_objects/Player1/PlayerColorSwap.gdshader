shader_type canvas_item;

const int MAX_COLORS = 12;

uniform vec4 before_colors[MAX_COLORS] : source_color;
uniform vec4 after_colors[MAX_COLORS] : source_color;

uniform int active_color_count : hint_range(0, 12) = 10; 
uniform float tolerance : hint_range(0.0, 0.1) = 0.01;

varying vec4 modulate_color;

void vertex() {
    modulate_color = COLOR;
}

void fragment() {
    vec4 input_color = texture(TEXTURE, UV);
    
    // Ignore fully transparent pixels completely
    if (input_color.a > 0.0) {
        for (int i = 0; i < active_color_count; i++) {
            if (distance(input_color.rgb, before_colors[i].rgb) < tolerance) {
                input_color.rgb = after_colors[i].rgb;
                break; 
            }
        }
    }
    
    COLOR = input_color * modulate_color;
}
