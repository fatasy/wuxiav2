// Definições para linha costeira cinza
uniform sampler2D coastline_cliff_grey_diffuse : hint_default_white, filter_linear;
uniform sampler2D coastline_cliff_grey_normal : hint_normal, filter_linear;
uniform sampler2D coastline_cliff_grey_properties : hint_default_white, filter_linear;
uniform sampler2D coastline_cliff_grey_mask : hint_default_black, filter_linear;

// Propriedades básicas
uniform float coastline_cliff_grey_tiling = 15.0;
uniform float coastline_cliff_grey_density = 1.0;

// Função para processar a linha costeira cinza
bool process_coastline_cliff_grey(vec2 uv, inout vec3 albedo, inout vec3 normal, inout float roughness, inout float metallic, inout float ao) {
    // Amostra da máscara
    float mask = texture(coastline_cliff_grey_mask, uv).r;
    
    // Se o valor da máscara for muito baixo, não estamos em uma área de linha costeira
    if (mask < 0.1) return false;
    
    // Coordenadas UV com tiling para as texturas
    vec2 tiled_uv = uv * coastline_cliff_grey_tiling;
    
    // Amostra das texturas
    vec3 cliff_albedo = texture(coastline_cliff_grey_diffuse, tiled_uv).rgb;
    vec3 cliff_normal_map = texture(coastline_cliff_grey_normal, tiled_uv).rgb;
    vec4 cliff_properties = texture(coastline_cliff_grey_properties, tiled_uv);
    
    // Extrair propriedades do material
    float cliff_roughness = cliff_properties.g;
    float cliff_metallic = cliff_properties.r;
    float cliff_ao = cliff_properties.b;
    
    // Fator de mistura baseado na máscara e na densidade configurada
    float blend_factor = mask * coastline_cliff_grey_density;
    
    // Converter o normal map para espaço tangente (-1 a 1)
    vec3 cliff_normal_tangent = normalize(cliff_normal_map * 2.0 - 1.0);
    
    // Misturar com as propriedades do terreno base
    albedo = mix(albedo, cliff_albedo, blend_factor);
    normal = mix(normal, cliff_normal_tangent, blend_factor);
    roughness = mix(roughness, cliff_roughness, blend_factor);
    metallic = mix(metallic, cliff_metallic, blend_factor);
    ao = mix(ao, cliff_ao, blend_factor);
    
    return true;
} 