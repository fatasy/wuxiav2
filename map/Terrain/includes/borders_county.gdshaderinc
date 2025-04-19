// Texturas para bordas de condado
uniform sampler2D border_county : hint_default_white;

// Configurações de visualização
uniform bool show_county_borders = true;

// Função para processar bordas de condado
vec3 process_county_borders(vec2 uv, vec3 base_color) {
    if (!show_county_borders) {
        return base_color;
    }
    
    // Obter máscara de condado do canal B
    vec4 masks = texture(border_masks, uv);
    float county_mask = masks.b;
    
    if (county_mask < 0.1) {
        return base_color;
    }
    
    // Aplicar textura de borda de condado
    vec4 result = apply_border_texture(border_county, county_mask, uv, base_color, false, false);
    
    return result.rgb;
} 