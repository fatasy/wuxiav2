// Definições para terreno de floresta de selva
uniform sampler2D forest_jungle_diffuse : hint_default_white, filter_linear;
uniform sampler2D forest_jungle_normal : hint_normal, filter_linear;
uniform sampler2D forest_jungle_properties : hint_default_white, filter_linear;
uniform sampler2D forest_jungle_mask : hint_default_black, filter_linear;

// Propriedades básicas
uniform float forest_jungle_tiling = 25.0;
uniform float forest_jungle_density = 1.0;

// Função para processar terreno de floresta de selva
bool process_forest_jungle(vec2 uv, inout vec3 albedo, inout vec3 normal, inout float roughness, inout float metallic, inout float ao) {
    // Amostra da máscara
    float mask = texture(forest_jungle_mask, uv).r;
    
    // Se o valor da máscara for muito baixo, não estamos em uma área de floresta de selva
    if (mask < 0.1) return false;
    
    // Coordenadas UV com tiling para as texturas
    vec2 tiled_uv = uv * forest_jungle_tiling;
    
    // Amostra das texturas
    vec3 jungle_albedo = texture(forest_jungle_diffuse, tiled_uv).rgb;
    vec3 jungle_normal_map = texture(forest_jungle_normal, tiled_uv).rgb;
    vec4 jungle_props = texture(forest_jungle_properties, tiled_uv);
    
    // Extrair propriedades do material
    float jungle_roughness = jungle_props.g;
    float jungle_metallic = jungle_props.r;
    float jungle_ao_value = jungle_props.b;
    
    // Fator de mistura baseado na máscara e na densidade configurada
    float blend_factor = mask * forest_jungle_density;
    
    // Converter o normal map para espaço tangente (-1 a 1)
    vec3 jungle_normal_tangent = normalize(jungle_normal_map * 2.0 - 1.0);
    
    // Misturar com as propriedades do terreno base
    albedo = mix(albedo, jungle_albedo, blend_factor);
    normal = mix(normal, jungle_normal_tangent, blend_factor);
    roughness = mix(roughness, jungle_roughness, blend_factor);
    metallic = mix(metallic, jungle_metallic, blend_factor);
    ao = mix(ao, jungle_ao_value, blend_factor);
    
    return true;
} 