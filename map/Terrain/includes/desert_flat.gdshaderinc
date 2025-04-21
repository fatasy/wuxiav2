// Definições para terreno de deserto plano
uniform sampler2D desert_flat_01_diffuse : hint_default_white, filter_linear;
uniform sampler2D desert_flat_01_normal : hint_normal, filter_linear;
uniform sampler2D desert_flat_01_properties : hint_default_white, filter_linear;
uniform sampler2D desert_flat_01_mask : hint_default_black, filter_linear;

// Propriedades básicas
uniform float desert_flat_tiling = 25.0;
uniform float desert_flat_density = 1.0;

// Função para processar terreno de deserto plano
bool process_desert_flat(vec2 uv, inout vec3 albedo, inout vec3 normal, inout float roughness, inout float metallic, inout float ao) {
    // Amostra da máscara
    float mask = texture(desert_flat_01_mask, uv).r;
    
    // Se o valor da máscara for muito baixo, não estamos em uma área de deserto plano
    if (mask < 0.1) return false;
    
    // Coordenadas UV com tiling para as texturas
    vec2 tiled_uv = uv * desert_flat_tiling;
    
    // Amostra das texturas
    vec3 flat_albedo = texture(desert_flat_01_diffuse, tiled_uv).rgb;
    vec3 flat_normal_map = texture(desert_flat_01_normal, tiled_uv).rgb;
    vec4 flat_props = texture(desert_flat_01_properties, tiled_uv);
    
    // Extrair propriedades do material
    float flat_roughness = flat_props.g;
    float flat_metallic = flat_props.r;
    float flat_ao_value = flat_props.b;
    
    // Fator de mistura baseado na máscara e na densidade configurada
    float blend_factor = mask * desert_flat_density;
    
    // Converter o normal map para espaço tangente (-1 a 1)
    vec3 flat_normal_tangent = normalize(flat_normal_map * 2.0 - 1.0);
    
    // Misturar com as propriedades do terreno base
    albedo = mix(albedo, flat_albedo, blend_factor);
    normal = mix(normal, flat_normal_tangent, blend_factor);
    roughness = mix(roughness, flat_roughness, blend_factor);
    metallic = mix(metallic, flat_metallic, blend_factor);
    ao = mix(ao, flat_ao_value, blend_factor);
    
    return true;
} 