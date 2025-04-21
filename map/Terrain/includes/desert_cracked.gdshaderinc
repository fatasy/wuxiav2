// Definições para terreno de deserto rachado
uniform sampler2D desert_cracked_diffuse : hint_default_white, filter_linear;
uniform sampler2D desert_cracked_normal : hint_normal, filter_linear;
uniform sampler2D desert_cracked_properties : hint_default_white, filter_linear;
uniform sampler2D desert_cracked_mask : hint_default_black, filter_linear;

// Propriedades básicas
uniform float desert_cracked_tiling = 32.0;
uniform float desert_cracked_density = 1.0;

// Função para processar terreno de deserto rachado
bool process_desert_cracked(vec2 uv, inout vec3 albedo, inout vec3 normal, inout float roughness, inout float metallic, inout float ao) {
    // Amostra da máscara
    float mask = texture(desert_cracked_mask, uv).r;
    
    // Se o valor da máscara for muito baixo, não estamos em uma área de deserto rachado
    if (mask < 0.1) return false;
    
    // Coordenadas UV com tiling para as texturas
    vec2 tiled_uv = uv * desert_cracked_tiling;
    
    // Amostra das texturas
    vec3 cracked_albedo = texture(desert_cracked_diffuse, tiled_uv).rgb;
    vec3 cracked_normal_map = texture(desert_cracked_normal, tiled_uv).rgb;
    vec4 cracked_props = texture(desert_cracked_properties, tiled_uv);
    
    // Extrair propriedades do material
    float cracked_roughness = cracked_props.g;
    float cracked_metallic = cracked_props.r;
    float cracked_ao_value = cracked_props.b;
    
    // Fator de mistura baseado na máscara e na densidade configurada
    float blend_factor = mask * desert_cracked_density;
    
    // Converter o normal map para espaço tangente (-1 a 1)
    vec3 cracked_normal_tangent = normalize(cracked_normal_map * 2.0 - 1.0);
    
    // Misturar com as propriedades do terreno base
    albedo = mix(albedo, cracked_albedo, blend_factor);
    normal = mix(normal, cracked_normal_tangent, blend_factor);
    roughness = mix(roughness, cracked_roughness, blend_factor);
    metallic = mix(metallic, cracked_metallic, blend_factor);
    ao = mix(ao, cracked_ao_value, blend_factor);
    
    return true;
} 