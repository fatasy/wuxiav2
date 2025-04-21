// Definições para terreno de neve de inverno combinada
uniform sampler2D snow_diffuse_for_combined_winter : hint_default_white, filter_linear;
uniform bool winter_mode = false;  // Uniform para ativar/desativar o modo inverno

// Propriedades básicas
uniform float snow_winter_tiling = 20.0;
uniform float snow_winter_strength = 0.8;  // Força do efeito de inverno

// Função para processar terreno com neve de inverno combinada
// Esta função é chamada após todos os outros tipos de terreno
// e sobrepõe uma camada de neve caso o modo inverno esteja ativado
bool process_snow_winter(vec2 uv, inout vec3 albedo, inout vec3 normal, inout float roughness, inout float metallic, inout float ao, float height) {
    // Se o modo inverno não estiver ativado, não fazemos nada
    if (!winter_mode) return false;
    
    // Coordenadas UV com tiling para as texturas
    vec2 tiled_uv = uv * snow_winter_tiling;
    
    // Amostra da textura de neve para inverno combinado
    vec3 winter_snow_albedo = texture(snow_diffuse_for_combined_winter, tiled_uv).rgb;
    
    // Calculamos quanto de neve aplicar baseado na altura do terreno
    // Terrenos mais altos recebem mais neve
    float height_factor = clamp((height + 30.0) / 100.0, 0.0, 1.0);
    
    // Fator de mistura baseado na altura e na força configurada
    float blend_factor = height_factor * snow_winter_strength;
    
    // Misturar com as propriedades do terreno base
    albedo = mix(albedo, winter_snow_albedo, blend_factor);
    
    // A neve aumenta a rugosidade e reduz o metallic
    roughness = mix(roughness, min(roughness + 0.2, 1.0), blend_factor);
    metallic = mix(metallic, max(metallic - 0.2, 0.0), blend_factor);
    
    // A neve também clareia o terreno onde se acumula mais
    vec3 brightening = vec3(blend_factor * 0.3);
    albedo = min(albedo + brightening, vec3(1.0));
    
    return true;
} 