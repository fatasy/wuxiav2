// Texturas para as bordas
uniform sampler2D border_water : hint_default_white;
uniform sampler2D border_province : hint_default_white;
uniform sampler2D border_county : hint_default_white;
uniform sampler2D border_domain : hint_default_white;
uniform sampler2D border_other_realm : hint_default_white;
uniform sampler2D border_my_realm : hint_default_white;
uniform sampler2D border_sub_realm : hint_default_white;
uniform sampler2D border_hovered_realm : hint_default_white;
uniform sampler2D border_hovered_realm_flat_map : hint_default_white;
uniform sampler2D border_highlighted_province : hint_default_white;
uniform sampler2D selection_highlight : hint_default_white;
uniform sampler2D selection_highlight_flat_map : hint_default_white;
uniform sampler2D border_selected_realm : hint_default_white;
uniform sampler2D border_selected_realm_flat_map : hint_default_white;
uniform sampler2D border_impassable : hint_default_white;
uniform sampler2D border_war : hint_default_white;
uniform sampler2D border_war_ally : hint_default_white;
uniform sampler2D border_war_target : hint_default_white;
uniform sampler2D border_civil_war : hint_default_white;
uniform sampler2D border_realm_explorer_independent : hint_default_white;
uniform sampler2D border_realm_explorer_vassal : hint_default_white;
uniform sampler2D epidemic : hint_default_white;
uniform sampler2D my_top_realm : hint_default_white;
uniform sampler2D struggle : hint_default_white;
uniform sampler2D struggle_involved : hint_default_white;
uniform sampler2D struggle_interloper : hint_default_white;
uniform sampler2D struggle_uninvolved : hint_default_white;
uniform sampler2D debug : hint_default_white;

// Máscaras de borda para determinar quais bordas mostrar
uniform sampler2D border_masks : hint_default_black; // R: água, G: província, B: condado, A: domínio

// Configurações de visualização de bordas
uniform bool show_water_borders = true;
uniform bool show_province_borders = true;
uniform bool show_county_borders = true;
uniform bool show_domain_borders = false;
uniform bool show_realm_borders = true;
uniform bool show_war_borders = true;

// Configurações de aparência das bordas
uniform float border_width = 1.0;
uniform float border_sharpness = 2.0;
uniform float border_blend = 0.8;
uniform vec3 border_glow_color = vec3(1.0, 1.0, 1.0);
uniform float border_glow_intensity = 0.0;
uniform float border_animation_speed = 0.5;

// Variáveis para modos de jogo
uniform bool flat_map_mode = false;
uniform bool is_selected_province = false;
uniform bool is_hovered_province = false;
uniform bool is_at_war = false;
uniform bool is_war_target = false;
uniform bool is_civil_war = false;
uniform bool is_my_realm = false;
uniform bool is_in_struggle = false;

// Função para aplicar a textura da borda com efeitos
vec4 apply_border_texture(sampler2D border_texture, float mask_value, vec2 uv, vec3 base_color) {
    if (mask_value < 0.1) {
        return vec4(base_color, 1.0); // Sem borda
    }
    
    // Obter cor da textura de borda
    vec4 border_color = texture(border_texture, uv);
    
    // Calcular intensidade da borda baseada no valor da máscara
    float border_intensity = smoothstep(0.5 - border_sharpness * 0.01, 0.5 + border_sharpness * 0.01, mask_value);
    
    // Adicionar animação sutil para bordas específicas (guerra, selecionadas)
    float animation_offset = 0.0;
    if (border_texture == border_war || border_texture == border_war_target || 
        border_texture == selection_highlight) {
        animation_offset = sin(TIME * border_animation_speed) * 0.1;
        border_intensity += animation_offset;
        border_intensity = clamp(border_intensity, 0.0, 1.0);
    }
    
    // Adicionar glow para bordas especiais
    vec3 glow = vec3(0.0);
    if (border_texture == border_war_target || border_texture == selection_highlight) {
        glow = border_glow_color * border_glow_intensity * (1.0 + 0.2 * sin(TIME * 2.0));
    }
    
    // Misturar cor base com a cor da borda
    vec3 final_color = mix(base_color, border_color.rgb + glow, border_intensity * border_color.a * border_blend);
    
    return vec4(final_color, 1.0);
}

// Função principal para processar todas as bordas
vec3 process_borders(vec2 uv, vec3 base_color) {
    // Ler máscaras de borda
    vec4 masks = texture(border_masks, uv);
    
    // Cor inicial é a cor base
    vec4 color = vec4(base_color, 1.0);
    
    // Processar bordas em ordem de prioridade (de menos para mais importante)
    
    // Bordas de água
    if (show_water_borders && masks.r > 0.1) {
        color = apply_border_texture(border_water, masks.r, uv, color.rgb);
    }
    
    // Bordas de província
    if (show_province_borders && masks.g > 0.1) {
        color = apply_border_texture(border_province, masks.g, uv, color.rgb);
    }
    
    // Bordas de condado
    if (show_county_borders && masks.b > 0.1) {
        color = apply_border_texture(border_county, masks.b, uv, color.rgb);
    }
    
    // Bordas de domínio
    if (show_domain_borders && masks.a > 0.1) {
        color = apply_border_texture(border_domain, masks.a, uv, color.rgb);
    }
    
    // Bordas de guerra (se aplicável)
    if (show_war_borders) {
        if (is_at_war) {
            color = apply_border_texture(border_war, masks.g, uv, color.rgb);
        }
        
        if (is_war_target) {
            color = apply_border_texture(border_war_target, masks.g, uv, color.rgb);
        }
        
        if (is_civil_war) {
            color = apply_border_texture(border_civil_war, masks.g, uv, color.rgb);
        }
    }
    
    // Bordas de seleção/destaque (maior prioridade)
    if (is_selected_province) {
        color = apply_border_texture(flat_map_mode ? selection_highlight_flat_map : selection_highlight, 
                                   masks.g, uv, color.rgb);
    } else if (is_hovered_province) {
        color = apply_border_texture(border_highlighted_province, masks.g, uv, color.rgb);
    }
    
    // Bordas de reino
    if (show_realm_borders) {
        if (is_my_realm) {
            color = apply_border_texture(border_my_realm, masks.g, uv, color.rgb);
        }
    }
    
    // Bordas de luta (struggle)
    if (is_in_struggle) {
        color = apply_border_texture(struggle, masks.g, uv, color.rgb);
    }
    
    // Retornar a cor final
    return color.rgb;
}

// Função de conveniência para verificar se estamos em uma borda
bool is_on_border(vec2 uv) {
    vec4 masks = texture(border_masks, uv);
    return (masks.r > 0.1 || masks.g > 0.1 || masks.b > 0.1 || masks.a > 0.1);
}

// Função para ajustar propriedades do material nas bordas
void adjust_material_for_borders(vec2 uv, inout float roughness, inout float metallic, inout float specular) {
    if (is_on_border(uv)) {
        // Bordas são mais lisas e tem um pouco mais de brilho
        roughness = mix(roughness, 0.7, 0.3);
        specular += 0.1;
    }
} 