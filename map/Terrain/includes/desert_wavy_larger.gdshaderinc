// Definições para terreno de deserto ondulado com padrões maiores
uniform sampler2D desert_wavy_01_larger_diffuse : hint_default_white, filter_linear;
uniform sampler2D desert_wavy_01_larger_normal : hint_normal, filter_linear;
uniform sampler2D desert_wavy_01_larger_properties : hint_default_white, filter_linear;
uniform sampler2D desert_wavy_01_larger_mask : hint_default_black, filter_linear;

// Propriedades básicas
uniform float desert_wavy_larger_tiling = 20.0; // Tiling menor para padrões maiores
uniform float desert_wavy_larger_density = 1.0;

// Função para processar terreno de deserto ondulado com padrões maiores
bool process_desert_wavy_larger(vec2 uv, inout vec3 albedo, inout vec3 normal, inout float roughness, inout float metallic, inout float ao) {
    // Amostra da máscara
    float mask = texture(desert_wavy_01_larger_mask, uv).r;
    
    // Se o valor da máscara for muito baixo, não estamos em uma área de deserto ondulado com padrões maiores
    if (mask < 0.1) return false;
    
    // Coordenadas UV com tiling para as texturas
    vec2 tiled_uv = uv * desert_wavy_larger_tiling;
    
    // Amostra das texturas
    vec3 wavy_larger_albedo = texture(desert_wavy_01_larger_diffuse, tiled_uv).rgb;
    vec3 wavy_larger_normal_map = texture(desert_wavy_01_larger_normal, tiled_uv).rgb;
    vec4 wavy_larger_props = texture(desert_wavy_01_larger_properties, tiled_uv);
    
    // Extrair propriedades do material
    float wavy_larger_roughness = wavy_larger_props.g;
    float wavy_larger_metallic = wavy_larger_props.r;
    float wavy_larger_ao_value = wavy_larger_props.b;
    
    // Fator de mistura baseado na máscara e na densidade configurada
    float blend_factor = mask * desert_wavy_larger_density;
    
    // Converter o normal map para espaço tangente (-1 a 1)
    vec3 wavy_larger_normal_tangent = normalize(wavy_larger_normal_map * 2.0 - 1.0);
    
    // Misturar com as propriedades do terreno base
    albedo = mix(albedo, wavy_larger_albedo, blend_factor);
    normal = mix(normal, wavy_larger_normal_tangent, blend_factor);
    roughness = mix(roughness, wavy_larger_roughness, blend_factor);
    metallic = mix(metallic, wavy_larger_metallic, blend_factor);
    ao = mix(ao, wavy_larger_ao_value, blend_factor);
    
    return true;
} 