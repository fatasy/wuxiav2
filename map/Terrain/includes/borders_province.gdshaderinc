// Texturas para bordas de província
uniform sampler2D border_province : hint_default_white;
uniform sampler2D border_highlighted_province : hint_default_white;
uniform sampler2D selection_highlight : hint_default_white;
uniform sampler2D selection_highlight_flat_map : hint_default_white;
uniform sampler2D province_map : source_color, filter_nearest, repeat_disable; // Mapa de províncias

// Configurações de visualização
uniform bool show_province_borders = true;
uniform bool is_selected_province = false;
uniform bool is_hovered_province = false;
uniform vec3 selected_province_color = vec3(-1.0); // Cor que indica "nenhuma seleção"
uniform vec4 highlight_color : source_color = vec4(1.0, 1.0, 0.0, 1.0); // Cor de destaque para província selecionada


// Função para processar bordas de província
vec3 process_province_borders(vec2 uv, vec3 base_color) {
    if (!show_province_borders) {
        return base_color;
    }
    
    // Obter a cor da província atual no mapa
    vec3 province_color = texture(province_map, uv).rgb;
    vec3 color = base_color;
    
    // Verificar se é a província selecionada
    bool is_selected = selected_province_color.r >= 0.0 && compare_colors(province_color, selected_province_color);
    
    // Aplicar cor de destaque se for a província selecionada
    if (is_selected) {
        color = mix(color, highlight_color.rgb, 0.5);
    }
    
    // Detectar bordas entre províncias verificando pixels vizinhos
    float offset = 0.001; // Distância de amostragem
    vec2 offsets[4] = {
        vec2(offset, 0.0),
        vec2(-offset, 0.0),
        vec2(0.0, offset),
        vec2(0.0, -offset)
    };
    
    // Verificar pixels vizinhos para detectar bordas
    float edge_mask = 0.0;
    for (int i = 0; i < 4; i++) {
        vec3 neighbor_color = texture(province_map, uv + offsets[i]).rgb;
        // Se o vizinho tiver cor diferente, estamos na borda
        if (!compare_colors(neighbor_color, province_color)) {
            edge_mask = 1.0;
            break;
        }
    }
    
    // Aplicar bordas padrão entre províncias
    if (edge_mask > 0.1) {
        // Aplicar borda de província padrão
        vec4 result = apply_border_texture(border_province, edge_mask, uv, color, false, false);
        color = result.rgb;
    }
    
    // Se estiver selecionada, aplica a borda de seleção
    if (is_selected || is_selected_province) {
        // Verificar novamente pixels vizinhos para bordas da província selecionada
        float selected_edge_mask = 0.0;
        for (int i = 0; i < 4; i++) {
            vec3 neighbor_color = texture(province_map, uv + offsets[i]).rgb;
            // Se o vizinho não for da província selecionada, estamos na borda
            if (!compare_colors(neighbor_color, province_color)) {
                selected_edge_mask = 1.0;
                break;
            }
        }
        
        // Se estivermos na borda da província selecionada, aplicar textura de destaque
        if (selected_edge_mask > 0.1) {
            if (flat_map_mode) {
                color = apply_border_texture(selection_highlight_flat_map, selected_edge_mask, uv, color, true, true).rgb;
            } else {
                color = apply_border_texture(selection_highlight, selected_edge_mask, uv, color, true, true).rgb;
            }
        }
    }
    else if (is_hovered_province) {
        // Aplicar borda para província sob o mouse
        if (edge_mask > 0.1) {
            color = apply_border_texture(border_highlighted_province, edge_mask, uv, color, false, false).rgb;
        }
    }
    
    return color;
} 