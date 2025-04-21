// Texturas para bordas de província
uniform sampler2D border_province : hint_default_white;
uniform sampler2D border_highlighted_province : hint_default_white;
uniform sampler2D selection_highlight : hint_default_white;
uniform sampler2D selection_highlight_flat_map : hint_default_white;
uniform sampler2D province_map : source_color; // Mapa de províncias

// Configurações de visualização
uniform bool show_province_borders = true;
uniform bool is_hovered_province = false;
uniform vec3 selected_province_color = vec3(-1.0); // Cor que indica "nenhuma seleção"
uniform vec4 highlight_color : source_color = vec4(1.0, 1.0, 0.0, 1.0); // Cor de destaque para província selecionada


// Função para processar bordas de província
vec3 process_province_borders(vec2 uv, vec3 albedo) {
    if (!show_province_borders) return albedo;
    
    
    // Obter a cor da província atual no mapa
    vec3 province_color = texture(province_map, uv).rgb;
  
    
    // Verificar se é a província selecionada
    bool is_selected_province = selected_province_color.r >= 0.0;
    bool is_selected = is_selected_province && compare_colors(province_color, selected_province_color);
    
    // Detectar bordas entre províncias verificando pixels vizinhos
    float offset = 0.001; // Distância de amostragem
    // Aumentar número de amostras para detecção de borda mais suave
    vec2 offsets[8] = {
        vec2(offset, 0.0),
        vec2(-offset, 0.0),
        vec2(0.0, offset),
        vec2(0.0, -offset),
        vec2(offset, offset),
        vec2(-offset, -offset),
        vec2(offset, -offset),
        vec2(-offset, offset)
    };
    
    // Verificar pixels vizinhos para detectar bordas
    float edge_mask = 0.0;
    float dist_min = 1.0; // Para calcular distância até a borda
    
    for (int i = 0; i < 8; i++) {
        vec3 neighbor_color = texture(province_map, uv + offsets[i]).rgb;
        // Se o vizinho tiver cor diferente, estamos na borda
        if (!compare_colors(neighbor_color, province_color)) {
            // Calculamos aqui um valor que representa o quão "próximo" estamos da borda
            float dist = length(offsets[i]);
            dist_min = min(dist_min, dist);
            edge_mask = 1.0;
        }
    }
    
    // Suavização adicional da borda usando a distância
    if (edge_mask > 0.0) {
        // Converte a distância para um valor suave entre 0 e 1
        edge_mask = 1.0 - smoothstep(0.0, offset * 1.414, dist_min);
    }
    
    // Primeiro verifique se é a província selecionada
    if (is_selected) {
        // Se estivermos em uma borda da província selecionada
        if (edge_mask > 0.1) {
            if (flat_map_mode) {
                // Aplicar borda de seleção para modo de mapa plano
                vec4 result = apply_border_texture(selection_highlight_flat_map, edge_mask, uv, albedo, true, true);
                albedo = result.rgb;
            } else {
                // Aplicar borda de seleção para modo normal
                vec4 result = apply_border_texture(selection_highlight, edge_mask, uv, albedo, true, true);
                albedo = result.rgb;
            }
        }
    } 
    // Depois verifique se é uma província sob o cursor
    else if (is_hovered_province) {
        // Aplicar borda para província sob o mouse
        if (edge_mask > 0.1) {
            vec4 result = apply_border_texture(border_highlighted_province, edge_mask, uv, albedo, false, false);
            albedo = result.rgb;
        }
    }
    // Por último, bordas padrão para as demais províncias
    else if (edge_mask > 0.1) {
        // Aplicar borda de província padrão
        vec4 result = apply_border_texture(border_province, edge_mask, uv, albedo, true, true);
        albedo = result.rgb;
    }
    
    return albedo;
} 