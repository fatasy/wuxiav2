// Texturas para bordas de reino
uniform sampler2D border_other_realm : hint_default_white;
uniform sampler2D border_my_realm : hint_default_white;
uniform sampler2D border_sub_realm : hint_default_white;
uniform sampler2D border_hovered_realm : hint_default_white;
uniform sampler2D border_hovered_realm_flat_map : hint_default_white;
uniform sampler2D border_selected_realm : hint_default_white;
uniform sampler2D border_selected_realm_flat_map : hint_default_white;
uniform sampler2D border_realm_explorer_independent : hint_default_white;
uniform sampler2D border_realm_explorer_vassal : hint_default_white;
uniform sampler2D my_top_realm : hint_default_white;

// Configurações de visualização
uniform bool show_realm_borders = true;
uniform bool is_my_realm = false;

// Função para processar bordas de reino
vec3 process_realm_borders(vec2 uv, vec3 base_color) {
    if (!show_realm_borders) {
        return base_color;
    }
    
    // Usar o canal G (província) para as bordas de reino também
    vec4 masks = texture(border_masks, uv);
    float realm_mask = masks.g;
    
    if (realm_mask < 0.1) {
        return base_color;
    }
    
    vec3 color = base_color;
    
    // Aplicar borda do meu reino se for o caso
    if (is_my_realm) {
        vec4 result = apply_border_texture(border_my_realm, realm_mask, uv, color, false, false);
        color = result.rgb;
        
        // Podemos adicionar borda do reino superior aqui também
        result = apply_border_texture(my_top_realm, realm_mask * 0.8, uv, color, false, false);
        color = result.rgb;
    } 
    else {
        // Reinos de outros jogadores
        vec4 result = apply_border_texture(border_other_realm, realm_mask, uv, color, false, false);
        color = result.rgb;
    }
    
    return color;
} 