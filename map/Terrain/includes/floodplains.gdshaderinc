// Definições para terreno de planícies aluviais
uniform sampler2D floodplains_01_diffuse : hint_default_white, filter_linear;
uniform sampler2D floodplains_01_normal : hint_normal, filter_linear;
uniform sampler2D floodplains_01_properties : hint_default_white, filter_linear;
uniform sampler2D floodplains_01_mask : hint_default_black, filter_linear;

// Propriedades básicas
uniform float floodplains_tiling = 25.0;
uniform float floodplains_density = 1.0;

// Função para processar terreno de planícies aluviais
bool process_floodplains(vec2 uv, inout vec3 albedo, inout vec3 normal, inout float roughness, inout float metallic, inout float ao) {
    // Amostra da máscara
    float mask = texture(floodplains_01_mask, uv).r;
    
    // Se o valor da máscara for muito baixo, não estamos em uma área de planícies aluviais
    if (mask < 0.1) return false;
    
    // Coordenadas UV com tiling para as texturas
    vec2 tiled_uv = uv * floodplains_tiling;
    
    // Amostra das texturas
    vec3 fp_albedo = texture(floodplains_01_diffuse, tiled_uv).rgb;
    vec3 fp_normal_map = texture(floodplains_01_normal, tiled_uv).rgb;
    vec4 fp_props = texture(floodplains_01_properties, tiled_uv);
    
    // Extrair propriedades do material
    float fp_roughness = fp_props.g;
    float fp_metallic = fp_props.r;
    float fp_ao_value = fp_props.b;
    
    // Fator de mistura baseado na máscara e na densidade configurada
    float blend_factor = mask * floodplains_density;
    
    // Converter o normal map para espaço tangente (-1 a 1)
    vec3 fp_normal_tangent = normalize(fp_normal_map * 2.0 - 1.0);
    
    // Misturar com as propriedades do terreno base
    albedo = mix(albedo, fp_albedo, blend_factor);
    normal = mix(normal, fp_normal_tangent, blend_factor);
    roughness = mix(roughness, fp_roughness, blend_factor);
    metallic = mix(metallic, fp_metallic, blend_factor);
    ao = mix(ao, fp_ao_value, blend_factor);
    
    return true;
} 