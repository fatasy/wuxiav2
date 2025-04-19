// Texturas para bordas especiais
uniform sampler2D border_impassable : hint_default_white;
uniform sampler2D epidemic : hint_default_white;
uniform sampler2D struggle : hint_default_white;
uniform sampler2D struggle_involved : hint_default_white;
uniform sampler2D struggle_interloper : hint_default_white;
uniform sampler2D struggle_uninvolved : hint_default_white;
uniform sampler2D debug : hint_default_white;

// Configurações de visualização
uniform bool is_in_struggle = false;

// Função para processar bordas especiais
vec3 process_special_borders(vec2 uv, vec3 base_color) {
    // Usar o canal G (província) para as bordas especiais também
    vec4 masks = texture(border_masks, uv);
    float special_mask = masks.g;
    
    if (special_mask < 0.1) {
        return base_color;
    }
    
    vec3 color = base_color;
    
    // Processamento de regiões de luta (struggle)
    if (is_in_struggle) {
        vec4 result = apply_border_texture(struggle, special_mask, uv, color, false, true);
        color = result.rgb;
    }
    
    // Bordas impassáveis (se presentes na máscara - geralmente seria um canal separado)
    // Este é apenas um exemplo; num sistema real, você teria uma máscara própria para áreas impassáveis
    if (masks.r > 0.9 && masks.g > 0.9) { // Exemplo de detecção de área impassável
        vec4 result = apply_border_texture(border_impassable, 1.0, uv, color, false, false);
        color = result.rgb;
    }
    
    // Visualização de debug (ativada por código)
    #ifdef DEBUG_BORDERS
    vec4 result = apply_border_texture(debug, special_mask, uv, color, false, false);
    color = result.rgb;
    #endif
    
    return color;
} 