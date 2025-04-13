shader_type spatial;
render_mode cull_back, depth_draw_opaque;

uniform sampler2D province_map : source_color;
uniform sampler2D normal_texture : hint_normal;
uniform vec3 selected_province_color = vec3(-1.0);
uniform vec4 highlight_color : source_color = vec4(1.0, 1.0, 0.0, 1.0); // Amarelo
uniform sampler2D albedo_texture;

bool compare_colors(vec3 color1, vec3 color2) {
    float threshold = 0.001; // Aumenta a precisão 10x
    return abs(color1.r - color2.r) < threshold &&
           abs(color1.g - color2.g) < threshold &&
           abs(color1.b - color2.b) < threshold;
}

void fragment() {
    vec3 province_color = texture(province_map, UV).rgb;
    vec3 normal = texture(normal_texture, UV).rgb * 2.0 - 1.0;
    NORMAL = normalize(normal);

    if (compare_colors(province_color, selected_province_color)) {
        ALBEDO = highlight_color.rgb;
    } 
    
    // else {
    //     vec4 province_pixel = texture(province_map, UV);
    //     float r = floor(province_pixel.r * 255.0);
    //     float g = floor(province_pixel.g * 255.0);
    //     float b = floor(province_pixel.b * 255.0);
        
    //     float province_id = r + g * 256.0 + b * 256.0 * 256.0;
    //     ALBEDO = vec3(province_id / 16777215.0); // tons de cinza
    // }
    
    ROUGHNESS = 0.7;
    METALLIC = 0.0;
}
