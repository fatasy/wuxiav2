// Definições para terreno de oásis
uniform sampler2D oasis_diffuse : hint_default_white, filter_linear;
uniform sampler2D oasis_normal : hint_normal, filter_linear;
uniform sampler2D oasis_properties : hint_default_white, filter_linear;
uniform sampler2D oasis_mask : hint_default_black, filter_linear;

// Propriedades básicas
uniform float oasis_tiling = 20.0;
uniform float oasis_density = 1.0;

// Função para processar terreno de oásis
bool process_oasis(vec2 uv, inout vec3 albedo, inout vec3 normal, inout float roughness, inout float metallic, inout float ao) {
    // Amostra da máscara
    float mask = texture(oasis_mask, uv).r;
    
    // Se o valor da máscara for muito baixo, não estamos em uma área de oásis
    if (mask < 0.1) return false;
    
    // Coordenadas UV com tiling para as texturas
    vec2 tiled_uv = uv * oasis_tiling;
    
    // Amostra das texturas
    vec3 oasis_albedo = texture(oasis_diffuse, tiled_uv).rgb;
    vec3 oasis_normal_map = texture(oasis_normal, tiled_uv).rgb;
    vec4 oasis_props = texture(oasis_properties, tiled_uv);
    
    // Extrair propriedades do material
    float oasis_roughness = oasis_props.g;
    float oasis_metallic = oasis_props.r;
    float oasis_ao_value = oasis_props.b;
    
    // Fator de mistura baseado na máscara e na densidade configurada
    float blend_factor = mask * oasis_density;
    
    // Converter o normal map para espaço tangente (-1 a 1)
    vec3 oasis_normal_tangent = normalize(oasis_normal_map * 2.0 - 1.0);
    
    // Misturar com as propriedades do terreno base
    albedo = mix(albedo, oasis_albedo, blend_factor);
    normal = mix(normal, oasis_normal_tangent, blend_factor);
    roughness = mix(roughness, oasis_roughness, blend_factor);
    metallic = mix(metallic, oasis_metallic, blend_factor);
    ao = mix(ao, oasis_ao_value, blend_factor);
    
    return true;
} 