// Texturas para as praias de seixos
uniform sampler2D beach_pebbles_mask : hint_default_black;
uniform sampler2D beach_pebbles_diffuse : hint_default_white;
uniform sampler2D beach_pebbles_normal : hint_default_white;
uniform sampler2D beach_pebbles_properties : hint_default_white;

// Incluir arquivo de configurações de água
#include "res://map/Terrain/includes/water.gdshaderinc"

// Configurações da praia de seixos
uniform float beach_pebbles_roughness = 0.6;
uniform float beach_pebbles_metallic = 0.05;
uniform float beach_pebbles_transition_width = 0.15;
uniform float beach_pebbles_normal_strength = 1.0;
uniform float beach_pebbles_water_depth = 0.25;
uniform float beach_pebbles_wave_strength = 0.9;

// Função para processar praias de seixos
bool process_beach_pebbles(vec2 uv, inout vec3 albedo, inout vec3 normal, inout float roughness, inout float metallic) {
    // Verifica se estamos em uma praia de seixos usando a máscara
    float beach_value = texture(beach_pebbles_mask, uv).r;
    if (beach_value < 0.1) {
        return false; // Não estamos em uma praia de seixos
    }
    
    // Ler texturas da praia
    vec3 beach_albedo = texture(beach_pebbles_diffuse, uv).rgb;
    vec3 beach_normal_map = texture(beach_pebbles_normal, uv).rgb;
    vec4 beach_props = texture(beach_pebbles_properties, uv);
    
    // Converter normal map para espaço tangente
    vec3 beach_normal_value = normalize(beach_normal_map * 2.0 - 1.0);
    
    // Áreas com valores mais altos são mais profundas (água)
    // Áreas com valores mais baixos são mais rasas (seixos)
    float water_factor = smoothstep(0.6 - beach_pebbles_transition_width * 0.5, 
                                  0.6 + beach_pebbles_transition_width * 0.5, 
                                  beach_value);
    
    // Calcular tempo para animações
    float time = TIME;
    
    // Obter normal combinada das ondas de água usando a função da biblioteca water
    vec3 water_normal = calculate_combined_water_normal(uv, time);
    
    // Preservar alguma informação da normal do terreno para que a água siga o contorno
    vec3 mixed_normal;
    if (water_factor > 0.05) {
        // Misturar normal dos seixos com normal da água, mais forte na água profunda
        // Seixos têm mais influência na água do que areia comum
        mixed_normal = mix(beach_normal_value, water_normal, water_factor * beach_pebbles_wave_strength);
    } else {
        mixed_normal = beach_normal_value;
    }
    
    // Suavizar transição entre praia e terreno
    float blend_factor = smoothstep(0.0, beach_pebbles_transition_width, beach_value);
    
    // Misturar com o terreno existente considerando a água
    if (water_factor > 0.05) {
        normal = mix(normal, mixed_normal, blend_factor * (water_factor > 0.05 ? water_normal_strength : beach_pebbles_normal_strength));
    } else {
        normal = mix(normal, beach_normal_value, blend_factor * beach_pebbles_normal_strength);
    }
    
    // Calcular profundidade simulada da água
    float depth = water_factor * beach_pebbles_water_depth;
    
    // Misturar cores de água baseado em profundidade
    vec3 water_color_final = mix(water_color_shallow, water_color_deep, depth * 0.6);
    
    // Misturar cor da praia com a cor da água baseado no fator de água
    vec3 final_color;
    if (water_factor > 0.05) {
        // Águas em praias de seixos têm mais transparência
        final_color = mix(beach_albedo, water_color_final, water_factor * 0.7);
    } else {
        final_color = beach_albedo;
    }
    
    // Calcular espuma nas bordas da água usando a função da biblioteca water
    if (water_factor > 0.03 && water_factor < 0.5) {
        // Mais espuma na transição entre seixos e água
        // Praias de seixos tendem a ter mais espuma devido à turbulência
        float foam_factor = 1.0 - abs(water_factor - 0.25) * 2.0;
        float foam_amount = calculate_water_foam(uv, normal, foam_factor, time);
        final_color = mix(final_color, vec3(1.0), foam_amount * 0.8);
    }
    
    // Propriedades da praia
    float beach_roughness_value = beach_props.g * beach_pebbles_roughness;
    float beach_metallic_value = beach_props.b * beach_pebbles_metallic;
    
    // Ajustar brilho e reflexão
    if (water_factor > 0.2) {
        // Mais água
        roughness = mix(beach_roughness_value, 0.1, (water_factor - 0.2) * 1.5); // Mais liso na água
        metallic = mix(beach_metallic_value, water_gloss_base * depth * 0.8, (water_factor - 0.2) * 1.5);
    } else {
        // Mais seixos
        roughness = beach_roughness_value;
        metallic = beach_metallic_value;
    }
    
    // Configurar cor final
    albedo = mix(albedo, final_color, blend_factor);
    
    return true;
} 