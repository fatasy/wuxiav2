// Texturas para os rios
uniform sampler2D river_mask : hint_default_black;
uniform sampler2D river_bottom_diffuse : hint_default_white;
uniform sampler2D river_bottom_normal : hint_default_white;
uniform sampler2D river_bottom_gloss : hint_default_white;

// Incluir arquivo de configurações de água
#include "res://map/Terrain/includes/water.gdshaderinc"

// Configurações específicas dos rios
uniform float flatten_mult = 1.0;
uniform float depth_fake_factor = 2.0;
uniform float ocean_fade_rate = 0.8;
uniform float river_depth = 0.15;

// Função principal para processar rios
bool process_river(vec2 uv, inout vec3 albedo, inout vec3 normal, inout float roughness, inout float metallic) {
    // Verifica se estamos em um rio usando a máscara
    // Obtemos os valores RGB completos
    vec3 mask_color = texture(river_mask, uv).rgb;
    
    // Verificamos se o azul é a cor dominante (maior que vermelho e verde)
    // E se tem um valor mínimo para evitar detecção em áreas escuras
    if (!(mask_color.b > mask_color.r && mask_color.b > mask_color.g && mask_color.b > 0.2)) {
        return false; // Não é um rio - o azul não é dominante
    }
    
    // Usamos o valor do azul para determinar a profundidade
    float river_value = mask_color.b;
    
    // Calcular tempo para animações
    float time = TIME;
    
    // Obter normal combinada das ondas de água usando a função da biblioteca water
    vec3 water_normal = calculate_combined_water_normal(uv, time);
    
    // Preservar alguma informação da normal do terreno para que a água siga o contorno
    // Isso ajuda a fazer com que a água não pareça estar "abaixo" do terreno
    normal = mix(normal, water_normal, water_normal_strength);
    
    // Obter fluxo de água usando a função da biblioteca water
    vec2 flow_uv = calculate_water_flow(uv, time);
    
    // Distorcer UVs para efeito de movimento
    vec2 distorted_uv = uv + normal.xy * 0.02;
    
    // Calcular profundidade simulada (mais profundo no centro do rio)
    float depth = river_value * river_depth;
    
    // Misturar cores de água baseado em profundidade
    vec3 water_color_final = mix(water_color_shallow, water_color_deep, depth);
    
    // Aplicar textura de fundo do rio
    vec3 bottom_color = texture(river_bottom_diffuse, distorted_uv).rgb;
    
    // Misturar cor do fundo com a cor da água
    // Ajustar para menos transparência no centro do rio (mais profundo)
    float water_opacity = mix(0.5, 0.9, depth);
    vec3 final_color = mix(bottom_color, water_color_final, water_opacity);
    
    // Calcular espuma usando a função da biblioteca water
    float water_edge_factor = 1.0 - river_value;
    float foam_amount = calculate_water_foam(uv, normal, water_edge_factor, time);
    final_color = mix(final_color, vec3(1.0), foam_amount);
    
    // Ajustar brilho e reflexão para dar aparência de água
    roughness = 0.05 + (1.0 - river_value) * 0.3; // Mais rugoso nas bordas
    metallic = water_gloss_base * depth;
    
    // Configurar cor final
    albedo = final_color;
    
    return true;
} 