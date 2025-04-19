// Texturas para bordas de água
uniform sampler2D border_water : hint_default_white;

// Configurações de visualização
uniform bool show_water_borders = true;

// Função para processar bordas de água
vec3 process_water_borders(vec2 uv, vec3 base_color) {
    if (!show_water_borders) {
        return base_color;
    }
    
    // Obter máscara de água do canal R
    vec4 masks = texture(border_masks, uv);
    float water_mask = masks.r;
    
    if (water_mask < 0.1) {
        return base_color;
    }
    
    // Aplicar textura de borda de água
    vec4 result = apply_border_texture(border_water, water_mask, uv, base_color, false, false);
    
    return result.rgb;
} 