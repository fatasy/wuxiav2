// Definições para terreno de chão de floresta
uniform sampler2D forestfloor_diffuse : hint_default_white, filter_linear;
uniform sampler2D forestfloor_normal : hint_normal, filter_linear;
uniform sampler2D forestfloor_properties : hint_default_white, filter_linear;
uniform sampler2D forestfloor_mask : hint_default_black, filter_linear;

// Propriedades básicas
uniform float forestfloor_tiling = 25.0;
uniform float forestfloor_density = 1.0;

// Função para processar terreno de chão de floresta
bool process_forest_floor(vec2 uv, inout vec3 albedo, inout vec3 normal, inout float roughness, inout float metallic, inout float ao) {
    // Amostra da máscara
    float mask = texture(forestfloor_mask, uv).r;
    
    // Se o valor da máscara for muito baixo, não estamos em uma área de chão de floresta
    if (mask < 0.1) return false;
    
    // Coordenadas UV com tiling para as texturas
    vec2 tiled_uv = uv * forestfloor_tiling;
    
    // Amostra das texturas
    vec3 floor_albedo = texture(forestfloor_diffuse, tiled_uv).rgb;
    vec3 floor_normal_map = texture(forestfloor_normal, tiled_uv).rgb;
    vec4 floor_props = texture(forestfloor_properties, tiled_uv);
    
    // Extrair propriedades do material
    float floor_roughness = floor_props.g;
    float floor_metallic = floor_props.r;
    float floor_ao_value = floor_props.b;
    
    // Fator de mistura baseado na máscara e na densidade configurada
    float blend_factor = mask * forestfloor_density;
    
    // Converter o normal map para espaço tangente (-1 a 1)
    vec3 floor_normal_tangent = normalize(floor_normal_map * 2.0 - 1.0);
    
    // Misturar com as propriedades do terreno base
    albedo = mix(albedo, floor_albedo, blend_factor);
    normal = mix(normal, floor_normal_tangent, blend_factor);
    roughness = mix(roughness, floor_roughness, blend_factor);
    metallic = mix(metallic, floor_metallic, blend_factor);
    ao = mix(ao, floor_ao_value, blend_factor);
    
    return true;
} 