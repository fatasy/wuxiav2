// Texturas para as praias
uniform sampler2D beach_mask : hint_default_black;
uniform sampler2D beach_sand_diffuse : hint_default_white;
uniform sampler2D beach_sand_normal : hint_default_white;

// Incluir arquivo de configurações de água
#include "res://map/Terrain/includes/water.gdshaderinc"

// Configurações específicas das praias
uniform float beach_water_depth = 0.2;
uniform float beach_transition_width = 0.3;
uniform float beach_wave_strength = 1.2;

// Função principal para processar praias
bool process_beach(vec2 uv, inout vec3 albedo, inout vec3 normal, inout float roughness, inout float metallic) {
    // Verifica se estamos em uma praia usando a máscara
    vec4 mask_color = texture(beach_mask, uv);
    
    // Se não for uma praia, retornamos false
    if (mask_color.r < 0.2) {
        return false;
    }
    
    // Usamos o valor da máscara para determinar a transição entre areia e água
    float beach_value = mask_color.r;
    
    // Áreas com valores mais altos são mais profundas (água)
    // Áreas com valores mais baixos são mais rasas (areia)
    float water_factor = smoothstep(0.5 - beach_transition_width * 0.5, 0.5 + beach_transition_width * 0.5, beach_value);
    
    // Calcular tempo para animações
    float time = TIME;
    
    // Obter normal combinada das ondas de água usando a função da biblioteca water
    vec3 water_normal = calculate_combined_water_normal(uv, time);
    
    // Textura da areia
    vec3 sand_albedo = texture(beach_sand_diffuse, uv).rgb;
    vec3 sand_normal_map = texture(beach_sand_normal, uv).rgb * 2.0 - 1.0;
    
    // Preservar alguma informação da normal do terreno para que a água siga o contorno
    vec3 mixed_normal;
    if (water_factor > 0.1) {
        // Misturar normal da areia com normal da água, mais forte na água profunda
        mixed_normal = mix(sand_normal_map, water_normal, water_factor * beach_wave_strength);
    } else {
        mixed_normal = sand_normal_map;
    }
    
    normal = mix(normal, mixed_normal, water_factor > 0.1 ? water_normal_strength : 0.5);
    
    // Calcular profundidade simulada da água
    float depth = water_factor * beach_water_depth;
    
    // Misturar cores de água baseado em profundidade
    vec3 water_color_final = mix(water_color_shallow, water_color_deep, depth * 0.5);
    
    // Misturar cor da areia com a cor da água baseado no fator de água
    vec3 final_color = mix(sand_albedo, water_color_final, water_factor * 0.85);
    
    // Calcular espuma nas bordas da água usando a função da biblioteca water
    if (water_factor > 0.05 && water_factor < 0.6) {
        // Mais espuma na transição entre areia e água
        float foam_factor = 1.0 - abs(water_factor - 0.3) * 2.5;
        float foam_amount = calculate_water_foam(uv, normal, foam_factor, time);
        final_color = mix(final_color, vec3(1.0), foam_amount * 0.7);
    }
    
    // Ajustar brilho e reflexão
    if (water_factor > 0.3) {
        // Mais água
        roughness = mix(0.7, 0.1, (water_factor - 0.3) * 1.5); // Mais liso na água
        metallic = water_gloss_base * depth * 0.7;
    } else {
        // Mais areia
        roughness = 0.9; // Areia é rugosa
        metallic = 0.0; // Areia não é metálica
    }
    
    // Configurar cor final
    albedo = final_color;
    
    return true;
} 