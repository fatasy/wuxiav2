// Definições para planícies dessaturadas (plains_01_desat_mask)
uniform sampler2D plains_desat_diffuse : hint_default_white, filter_linear;
uniform sampler2D plains_desat_normal : hint_normal, filter_linear;
uniform sampler2D plains_desat_properties : hint_default_white, filter_linear;
uniform sampler2D plains_desat_mask : hint_default_black, filter_linear;

// Propriedades das planícies dessaturadas
uniform float plains_desat_tiling = 20.0;
uniform float plains_desat_density = 1.0;

// Função para processar planícies dessaturadas
bool process_plains_desat(vec2 uv, inout vec3 albedo, inout vec3 normal, inout float roughness, inout float metallic, inout float ao) {
    // Amostra da máscara
    float mask = texture(plains_desat_mask, uv).r;
    
    // Se o valor da máscara for muito baixo, não estamos em uma área de planície dessaturada
    if (mask < 0.1) return false;
    
    // Coordenadas UV com tiling para as texturas
    vec2 tiled_uv = uv * plains_desat_tiling;
    
    // Amostra das texturas
    vec3 plains_albedo = texture(plains_desat_diffuse, tiled_uv).rgb;
    vec3 plains_normal_map = texture(plains_desat_normal, tiled_uv).rgb;
    vec4 plains_properties = texture(plains_desat_properties, tiled_uv);
    
    // Extrair propriedades do material
    float plains_roughness = plains_properties.g;
    float plains_metallic = plains_properties.r;
    float plains_ao = plains_properties.b;
    
    // Fator de mistura baseado na máscara e na densidade configurada
    float blend_factor = mask * plains_desat_density;
    
    // Converter o normal map para espaço tangente (-1 a 1)
    vec3 plains_normal_tangent = normalize(plains_normal_map * 2.0 - 1.0);
    
    // Misturar com as propriedades do terreno base
    albedo = mix(albedo, plains_albedo, blend_factor);
    normal = mix(normal, plains_normal_tangent, blend_factor);
    roughness = mix(roughness, plains_roughness, blend_factor);
    metallic = mix(metallic, plains_metallic, blend_factor);
    ao = mix(ao, plains_ao, blend_factor);
    
    return true;
} 