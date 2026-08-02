shader_type canvas_item;

// Define the maximum size of the palette array (e.g., 12 slots)
const int MAX_COLORS = 12;

uniform vec4 before_colors[MAX_COLORS] : source_color;
uniform vec4 after_colors[MAX_COLORS] : source_color;

// Total active colors to check out of the max array size
uniform int active_color_count : hint_range(0, 12) = 10; 
// Sensitivity padding for float precision matching
uniform float tolerance : hint_range(0.0, 0.1) = 0.01;

void fragment() {
    vec4 input_color = texture(TEXTURE, UV);
    
    // Ignore fully transparent pixels completely
    if (input_color.a > 0.0) {
        for (int i = 0; i < active_color_count; i++) {
            // Check if the current pixel color matches the array target
            if (distance(input_color.rgb, before_colors[i].rgb) < tolerance) {
                // Swap the color while preserving the sprite's original alpha channel
                input_color.rgb = after_colors[i].rgb;
                break; // Exit loop immediately upon finding a match
            }
        }
    }
    
    COLOR = input_color;
}
