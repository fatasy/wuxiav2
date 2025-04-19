// Texturas para bordas de guerra
uniform sampler2D border_war : hint_default_white;
uniform sampler2D border_war_ally : hint_default_white;
uniform sampler2D border_war_target : hint_default_white;
uniform sampler2D border_civil_war : hint_default_white;

// Configurações de visualização
uniform bool show_war_borders = true;
uniform bool is_at_war = false;
uniform bool is_war_target = false;
uniform bool is_civil_war = false;

// Função para processar bordas de guerra
vec3 process_war_borders(vec2 uv, vec3 base_color) {
    if (!show_war_borders) {
        return base_color;
    }
    
    // Se não tiver nenhum estado de guerra ativo
    if (!is_at_war && !is_war_target && !is_civil_war) {
        return base_color;
    }
    
    // Usar o canal G (província) para as bordas de guerra também
    vec4 masks = texture(border_masks, uv);
    float war_mask = masks.g;
    
    if (war_mask < 0.1) {
        return base_color;
    }
    
    vec3 color = base_color;
    
    // Aplicar bordas de guerra em ordem de prioridade
    if (is_civil_war) {
        vec4 result = apply_border_texture(border_civil_war, war_mask, uv, color, true, false);
        color = result.rgb;
    }
    else if (is_war_target) {
        // Alvo de guerra tem animação e glow
        vec4 result = apply_border_texture(border_war_target, war_mask, uv, color, true, true);
        color = result.rgb;
    }
    else if (is_at_war) {
        // Guerra normal tem animação
        vec4 result = apply_border_texture(border_war, war_mask, uv, color, true, false);
        color = result.rgb;
    }
    
    return color;
} 