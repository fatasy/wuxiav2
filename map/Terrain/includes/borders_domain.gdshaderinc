// Texturas para bordas de domínio
uniform sampler2D border_domain : hint_default_white;

// Configurações de visualização
uniform bool show_domain_borders = false;

// Função para processar bordas de domínio
vec3 process_domain_borders(vec2 uv, vec3 base_color) {
    if (!show_domain_borders) {
        return base_color;
    }
    
    // Obter máscara de domínio do canal A
    vec4 masks = texture(border_masks, uv);
    float domain_mask = masks.a;
    
    if (domain_mask < 0.1) {
        return base_color;
    }
    
    // Aplicar textura de borda de domínio
    vec4 result = apply_border_texture(border_domain, domain_mask, uv, base_color, false, false);
    
    return result.rgb;
} 