// Definições para terreno de neve
uniform sampler2D snow_diffuse : hint_default_white, filter_linear;
uniform sampler2D snow_normal : hint_normal, filter_linear;
uniform sampler2D snow_properties : hint_default_white, filter_linear;
uniform sampler2D snow_mask : hint_default_black, filter_linear;

// Propriedades básicas
uniform float snow_tiling = 30.0;
uniform float snow_density = 1.0;

// Função para processar terreno de neve
bool process_snow(vec2 uv, inout vec3 albedo, inout vec3 normal, inout float roughness, inout float metallic, inout float ao) {
    // Amostra da máscara
    float mask = texture(snow_mask, uv).r;
    
    // Se o valor da máscara for muito baixo, não estamos em uma área de neve
    if (mask < 0.1) return false;
    
    // Coordenadas UV com tiling para as texturas
    vec2 tiled_uv = uv * snow_tiling;
    
    // Amostra das texturas
    vec3 snow_albedo = texture(snow_diffuse, tiled_uv).rgb;
    vec3 snow_normal_map = texture(snow_normal, tiled_uv).rgb;
    vec4 snow_props = texture(snow_properties, tiled_uv);
    
    // Extrair propriedades do material
    float snow_roughness = snow_props.g;
    float snow_metallic = snow_props.r;
    float snow_ao_value = snow_props.b;
    
    // Fator de mistura baseado na máscara e na densidade configurada
    float blend_factor = mask * snow_density;
    
    // Converter o normal map para espaço tangente (-1 a 1)
    vec3 snow_normal_tangent = normalize(snow_normal_map * 2.0 - 1.0);
    
    // Misturar com as propriedades do terreno base
    albedo = mix(albedo, snow_albedo, blend_factor);
    normal = mix(normal, snow_normal_tangent, blend_factor);
    roughness = mix(roughness, snow_roughness, blend_factor);
    metallic = mix(metallic, snow_metallic, blend_factor);
    ao = mix(ao, snow_ao_value, blend_factor);
    
    return true;
} 