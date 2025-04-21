// Definições para terreno base (sem máscara)
// Texturas para o terreno base 0 (geralmente para áreas mais baixas/planas)
uniform sampler2D terrain_base_diffuse0 : hint_default_white, filter_linear, repeat_enable;
uniform sampler2D terrain_base_normal0 : hint_normal, filter_linear, repeat_enable;
uniform sampler2D terrain_base_material0 : hint_default_white, filter_linear, repeat_enable;

// Texturas para o terreno base 1 (geralmente para áreas mais altas/inclinadas)
uniform sampler2D terrain_base_diffuse1 : hint_default_white, filter_linear, repeat_enable;
uniform sampler2D terrain_base_normal1 : hint_normal, filter_linear, repeat_enable;
uniform sampler2D terrain_base_material1 : hint_default_white, filter_linear, repeat_enable;

// Propriedades básicas
uniform float terrain_base_tiling = 10.0; // Escala de tiling para as texturas base
uniform float terrain_base_slope_factor = 0.7; // Influência da inclinação no blend
uniform float terrain_base_height_factor = 0.3; // Influência da altura no blend

// Função para processar as texturas base do terreno
void process_terrain_base(vec2 uv, vec3 normal_world, float height, inout vec3 albedo, inout vec3 normal, inout float roughness, inout float metallic, inout float ao) {
    // Calcular UVs com tiling
    vec2 tiled_uv = uv * terrain_base_tiling;
    
    // Calcular inclinação (slope) baseada no normal do mundo
    float slope = 1.0 - normal_world.y; // 0 = plano, 1 = vertical
    
    // Normalizar a altura para 0-1
    float normalized_height = clamp((height + 100.0) / 200.0, 0.0, 1.0);
    
    // Calcular o fator de blend entre as texturas 0 e 1
    float blend = clamp(
        slope * terrain_base_slope_factor + 
        normalized_height * terrain_base_height_factor,
        0.0, 1.0
    );
    
    // Amostra das texturas
    // Textura 0 (base)
    vec3 diffuse0 = texture(terrain_base_diffuse0, tiled_uv).rgb;
    vec3 normal_map0 = texture(terrain_base_normal0, tiled_uv).rgb;
    vec4 material0 = texture(terrain_base_material0, tiled_uv);
    
    // Textura 1 (detalhes adicionais/superfície alternativa)
    vec3 diffuse1 = texture(terrain_base_diffuse1, tiled_uv).rgb;
    vec3 normal_map1 = texture(terrain_base_normal1, tiled_uv).rgb;
    vec4 material1 = texture(terrain_base_material1, tiled_uv);
    
    // Extrair propriedades do material
    float metallic0 = material0.r;
    float roughness0 = material0.g;
    float ao0 = material0.b;
    
    float metallic1 = material1.r;
    float roughness1 = material1.g;
    float ao1 = material1.b;
    
    // Converter normal maps para espaço tangente (-1 a 1)
    vec3 tangent_normal0 = normalize(normal_map0 * 2.0 - 1.0);
    vec3 tangent_normal1 = normalize(normal_map1 * 2.0 - 1.0);
    
    // Combinar as texturas com base no fator de blend
    albedo = mix(diffuse0, diffuse1, blend);
    normal = mix(tangent_normal0, tangent_normal1, blend);
    roughness = mix(roughness0, roughness1, blend);
    metallic = mix(metallic0, metallic1, blend);
    ao = mix(ao0, ao1, blend);
} 