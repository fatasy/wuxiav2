// Definições para terreno de deserto base
uniform sampler2D desert_01_diffuse : hint_default_white, filter_linear;
uniform sampler2D desert_01_normal : hint_normal, filter_linear;
uniform sampler2D desert_01_properties : hint_default_white, filter_linear;
uniform sampler2D desert_01_mask : hint_default_black, filter_linear;

// Propriedades básicas
uniform float desert_base_tiling = 25.0;
uniform float desert_base_density = 1.0;

// Função para processar terreno de deserto base
bool process_desert_base(vec2 uv, inout vec3 albedo, inout vec3 normal, inout float roughness, inout float metallic, inout float ao) {
    // Amostra da máscara
    float mask = texture(desert_01_mask, uv).r;
    
    // Se o valor da máscara for muito baixo, não estamos em uma área de deserto
    if (mask < 0.1) return false;
    
    // Coordenadas UV com tiling para as texturas
    vec2 tiled_uv = uv * desert_base_tiling;
    
    // Amostra das texturas
    vec3 desert_albedo = texture(desert_01_diffuse, tiled_uv).rgb;
    vec3 desert_normal_map = texture(desert_01_normal, tiled_uv).rgb;
    vec4 desert_props = texture(desert_01_properties, tiled_uv);
    
    // Extrair propriedades do material
    float desert_roughness = desert_props.g;
    float desert_metallic = desert_props.r;
    float desert_ao_value = desert_props.b;
    
    // Fator de mistura baseado na máscara e na densidade configurada
    float blend_factor = mask * desert_base_density;
    
    // Converter o normal map para espaço tangente (-1 a 1)
    vec3 desert_normal_tangent = normalize(desert_normal_map * 2.0 - 1.0);
    
    // Misturar com as propriedades do terreno base
    albedo = mix(albedo, desert_albedo, blend_factor);
    normal = mix(normal, desert_normal_tangent, blend_factor);
    roughness = mix(roughness, desert_roughness, blend_factor);
    metallic = mix(metallic, desert_metallic, blend_factor);
    ao = mix(ao, desert_ao_value, blend_factor);
    
    return true;
} 