// Definições para terreno de drylands (base)
uniform sampler2D drylands_diffuse : hint_default_white, filter_linear;
uniform sampler2D drylands_normal : hint_normal, filter_linear;
uniform sampler2D drylands_properties : hint_default_white, filter_linear;
uniform sampler2D drylands_mask : hint_default_black, filter_linear;

// Propriedades básicas
uniform float drylands_tiling = 30.0;
uniform float drylands_density = 1.0;

// Função para processar terreno de drylands (base)
bool process_drylands(vec2 uv, inout vec3 albedo, inout vec3 normal, inout float roughness, inout float metallic, inout float ao) {
    // Amostra da máscara
    float mask = texture(drylands_mask, uv).r;
    
    // Se o valor da máscara for muito baixo, não estamos em uma área de drylands
    if (mask < 0.1) return false;
    
    // Coordenadas UV com tiling para as texturas
    vec2 tiled_uv = uv * drylands_tiling;
    
    // Amostra das texturas
    vec3 drylands_albedo = texture(drylands_diffuse, tiled_uv).rgb;
    vec3 drylands_normal_map = texture(drylands_normal, tiled_uv).rgb;
    vec4 drylands_props = texture(drylands_properties, tiled_uv);
    
    // Extrair propriedades do material
    float drylands_roughness = drylands_props.g;
    float drylands_metallic = drylands_props.r;
    float drylands_ao_value = drylands_props.b;
    
    // Fator de mistura baseado na máscara e na densidade configurada
    float blend_factor = mask * drylands_density;
    
    // Converter o normal map para espaço tangente (-1 a 1)
    vec3 drylands_normal_tangent = normalize(drylands_normal_map * 2.0 - 1.0);
    
    // Misturar com as propriedades do terreno base
    albedo = mix(albedo, drylands_albedo, blend_factor);
    normal = mix(normal, drylands_normal_tangent, blend_factor);
    roughness = mix(roughness, drylands_roughness, blend_factor);
    metallic = mix(metallic, drylands_metallic, blend_factor);
    ao = mix(ao, drylands_ao_value, blend_factor);
    
    return true;
} 