// Texturas para as bordas - definições comuns
uniform sampler2D border_masks : hint_default_black; // R: água, G: província, B: condado, A: domínio

// Configurações de aparência das bordas
uniform float border_width = 1.0;
uniform float border_sharpness = 2.0;
uniform float border_blend = 0.8;
uniform vec3 border_glow_color = vec3(1.0, 1.0, 1.0);
uniform float border_glow_intensity = 0.0;
uniform float border_animation_speed = 0.5;

// Variáveis para modos de jogo
uniform bool flat_map_mode = false;

// Função para aplicar a textura da borda com efeitos
vec4 apply_border_texture(sampler2D border_texture, float mask_value, vec2 uv, vec3 base_color, bool animate, bool add_glow) {
    // Obter cor da textura de borda
    vec4 border_color = texture(border_texture, uv);
    
    // Escalar coordenadas UV para ajuste de resolução/repetição
    vec2 scaled_uv = uv * 100.0; // Ajuste esse valor para mudar a escala/densidade do padrão
    
    // Adicionar animação sutil
    if (animate) {
        vec2 animated_uv = scaled_uv;
        animated_uv.x += sin(TIME * border_animation_speed) * 0.5;
        animated_uv.y += cos(TIME * border_animation_speed) * 0.5;
        // Usar as UVs animadas para obter a textura
        border_color = texture(border_texture, animated_uv * 0.01); // Reverter escala
    } else {
        // Usar UVs escaladas para texturas não animadas
        border_color = texture(border_texture, scaled_uv * 0.01); // Reverter escala
    }
    
    // Adicionar glow para bordas especiais
    vec3 glow = vec3(0.0);
    if (add_glow) {
        glow = border_glow_color * border_glow_intensity * (1.0 + 0.2 * sin(TIME * 2.0));
        border_color.rgb += glow;
    }
    
    // Usar a máscara para criar uma transição suave entre a borda e o terreno
    float blend_factor = smoothstep(0.0, 0.4, mask_value);
    
    // Misturar a cor base com a cor da borda usando a máscara suave
    vec3 final_color = mix(base_color, border_color.rgb, blend_factor * border_color.a);
    
    return vec4(final_color, 1.0);
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