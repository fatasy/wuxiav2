// Definições para terreno de deserto ondulado
uniform sampler2D desert_wavy_01_diffuse : hint_default_white, filter_linear;
uniform sampler2D desert_wavy_01_normal : hint_normal, filter_linear;
uniform sampler2D desert_wavy_01_properties : hint_default_white, filter_linear;
uniform sampler2D desert_wavy_01_mask : hint_default_black, filter_linear;

// Propriedades básicas
uniform float desert_wavy_tiling = 28.0;
uniform float desert_wavy_density = 1.0;

// Função para processar terreno de deserto ondulado
bool process_desert_wavy(vec2 uv, inout vec3 albedo, inout vec3 normal, inout float roughness, inout float metallic, inout float ao) {
    // Amostra da máscara
    float mask = texture(desert_wavy_01_mask, uv).r;
    
    // Se o valor da máscara for muito baixo, não estamos em uma área de deserto ondulado
    if (mask < 0.1) return false;
    
    // Coordenadas UV com tiling para as texturas
    vec2 tiled_uv = uv * desert_wavy_tiling;
    
    // Amostra das texturas
    vec3 wavy_albedo = texture(desert_wavy_01_diffuse, tiled_uv).rgb;
    vec3 wavy_normal_map = texture(desert_wavy_01_normal, tiled_uv).rgb;
    vec4 wavy_props = texture(desert_wavy_01_properties, tiled_uv);
    
    // Extrair propriedades do material
    float wavy_roughness = wavy_props.g;
    float wavy_metallic = wavy_props.r;
    float wavy_ao_value = wavy_props.b;
    
    // Fator de mistura baseado na máscara e na densidade configurada
    float blend_factor = mask * desert_wavy_density;
    
    // Converter o normal map para espaço tangente (-1 a 1)
    vec3 wavy_normal_tangent = normalize(wavy_normal_map * 2.0 - 1.0);
    
    // Misturar com as propriedades do terreno base
    albedo = mix(albedo, wavy_albedo, blend_factor);
    normal = mix(normal, wavy_normal_tangent, blend_factor);
    roughness = mix(roughness, wavy_roughness, blend_factor);
    metallic = mix(metallic, wavy_metallic, blend_factor);
    ao = mix(ao, wavy_ao_value, blend_factor);
    
    return true;
} 