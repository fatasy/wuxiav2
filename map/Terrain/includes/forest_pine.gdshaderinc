// Definições para terreno de floresta de pinheiros
uniform sampler2D forest_pine_diffuse : hint_default_white, filter_linear;
uniform sampler2D forest_pine_normal : hint_normal, filter_linear;
uniform sampler2D forest_pine_properties : hint_default_white, filter_linear;
uniform sampler2D forest_pine_mask : hint_default_black, filter_linear;

// Propriedades básicas
uniform float forest_pine_tiling = 30.0;
uniform float forest_pine_density = 1.0;

// Função para processar terreno de floresta de pinheiros
bool process_forest_pine(vec2 uv, inout vec3 albedo, inout vec3 normal, inout float roughness, inout float metallic, inout float ao) {
    // Amostra da máscara
    float mask = texture(forest_pine_mask, uv).r;
    
    // Se o valor da máscara for muito baixo, não estamos em uma área de floresta de pinheiros
    if (mask < 0.1) return false;
    
    // Coordenadas UV com tiling para as texturas
    vec2 tiled_uv = uv * forest_pine_tiling;
    
    // Amostra das texturas
    vec3 pine_albedo = texture(forest_pine_diffuse, tiled_uv).rgb;
    vec3 pine_normal_map = texture(forest_pine_normal, tiled_uv).rgb;
    vec4 pine_props = texture(forest_pine_properties, tiled_uv);
    
    // Extrair propriedades do material
    float pine_roughness = pine_props.g;
    float pine_metallic = pine_props.r;
    float pine_ao_value = pine_props.b;
    
    // Fator de mistura baseado na máscara e na densidade configurada
    float blend_factor = mask * forest_pine_density;
    
    // Converter o normal map para espaço tangente (-1 a 1)
    vec3 pine_normal_tangent = normalize(pine_normal_map * 2.0 - 1.0);
    
    // Misturar com as propriedades do terreno base
    albedo = mix(albedo, pine_albedo, blend_factor);
    normal = mix(normal, pine_normal_tangent, blend_factor);
    roughness = mix(roughness, pine_roughness, blend_factor);
    metallic = mix(metallic, pine_metallic, blend_factor);
    ao = mix(ao, pine_ao_value, blend_factor);
    
    return true;
} 