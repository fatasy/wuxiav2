// Definições para terreno de estepe base
uniform sampler2D steppe_01_diffuse : hint_default_white, filter_linear;
uniform sampler2D steppe_01_normal : hint_normal, filter_linear;
uniform sampler2D steppe_01_properties : hint_default_white, filter_linear;
uniform sampler2D steppe_01_mask : hint_default_black, filter_linear;

// Propriedades básicas
uniform float steppe_base_tiling = 25.0;
uniform float steppe_base_density = 1.0;

// Função para processar terreno de estepe base
bool process_steppe_base(vec2 uv, inout vec3 albedo, inout vec3 normal, inout float roughness, inout float metallic, inout float ao) {
    // Amostra da máscara
    float mask = texture(steppe_01_mask, uv).r;
    
    // Se o valor da máscara for muito baixo, não estamos em uma área de estepe
    if (mask < 0.1) return false;
    
    // Coordenadas UV com tiling para as texturas
    vec2 tiled_uv = uv * steppe_base_tiling;
    
    // Amostra das texturas
    vec3 steppe_albedo = texture(steppe_01_diffuse, tiled_uv).rgb;
    vec3 steppe_normal_map = texture(steppe_01_normal, tiled_uv).rgb;
    vec4 steppe_props = texture(steppe_01_properties, tiled_uv);
    
    // Extrair propriedades do material
    float steppe_roughness = steppe_props.g;
    float steppe_metallic = steppe_props.r;
    float steppe_ao_value = steppe_props.b;
    
    // Fator de mistura baseado na máscara e na densidade configurada
    float blend_factor = mask * steppe_base_density;
    
    // Converter o normal map para espaço tangente (-1 a 1)
    vec3 steppe_normal_tangent = normalize(steppe_normal_map * 2.0 - 1.0);
    
    // Misturar com as propriedades do terreno base
    albedo = mix(albedo, steppe_albedo, blend_factor);
    normal = mix(normal, steppe_normal_tangent, blend_factor);
    roughness = mix(roughness, steppe_roughness, blend_factor);
    metallic = mix(metallic, steppe_metallic, blend_factor);
    ao = mix(ao, steppe_ao_value, blend_factor);
    
    return true;
} 