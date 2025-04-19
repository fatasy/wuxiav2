uniform sampler2D province_map : source_color, filter_nearest, repeat_disable; // Usar filter_nearest para cores exatas
uniform vec3 selected_province_color = vec3(-1.0); // Cor que indica "nenhuma seleção"
uniform vec4 highlight_color : source_color = vec4(1.0, 1.0, 0.0, 1.0); // Amarelo

vec3 process_province(vec2 uv, vec3 albedo) {
    if (selected_province_color.r >= 0.0) { // Verifica se uma província válida foi selecionada
        vec3 province_color = texture(province_map, uv).rgb;
        if (compare_colors(province_color, selected_province_color)) {
            // Se for a província selecionada, retorna a cor de destaque
            return highlight_color.rgb;
            // Opcional: Você pode querer alterar outras propriedades no highlight,
            // como deixar menos áspero ou remover o metálico
            // current_roughness = 0.2;
            // current_metallic = 0.0;
        }
    }

    return albedo;
}

