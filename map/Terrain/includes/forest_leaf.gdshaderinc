// Definições para terreno de floresta de folhas
uniform sampler2D forest_leaf_diffuse : hint_default_white, filter_linear;
uniform sampler2D forest_leaf_normal : hint_normal, filter_linear;
uniform sampler2D forest_leaf_properties : hint_default_white, filter_linear;
uniform sampler2D forest_leaf_mask : hint_default_black, filter_linear;

// Propriedades básicas
uniform float forest_leaf_tiling = 28.0;
uniform float forest_leaf_density = 1.0;

// Função para processar terreno de floresta de folhas
bool process_forest_leaf(vec2 uv, inout vec3 albedo, inout vec3 normal, inout float roughness, inout float metallic, inout float ao) {
    // Amostra da máscara
    float mask = texture(forest_leaf_mask, uv).r;
    
    // Se o valor da máscara for muito baixo, não estamos em uma área de floresta de folhas
    if (mask < 0.1) return false;
    
    // Coordenadas UV com tiling para as texturas
    vec2 tiled_uv = uv * forest_leaf_tiling;
    
    // Amostra das texturas
    vec3 leaf_albedo = texture(forest_leaf_diffuse, tiled_uv).rgb;
    vec3 leaf_normal_map = texture(forest_leaf_normal, tiled_uv).rgb;
    vec4 leaf_props = texture(forest_leaf_properties, tiled_uv);
    
    // Extrair propriedades do material
    float leaf_roughness = leaf_props.g;
    float leaf_metallic = leaf_props.r;
    float leaf_ao_value = leaf_props.b;
    
    // Fator de mistura baseado na máscara e na densidade configurada
    float blend_factor = mask * forest_leaf_density;
    
    // Converter o normal map para espaço tangente (-1 a 1)
    vec3 leaf_normal_tangent = normalize(leaf_normal_map * 2.0 - 1.0);
    
    // Misturar com as propriedades do terreno base
    albedo = mix(albedo, leaf_albedo, blend_factor);
    normal = mix(normal, leaf_normal_tangent, blend_factor);
    roughness = mix(roughness, leaf_roughness, blend_factor);
    metallic = mix(metallic, leaf_metallic, blend_factor);
    ao = mix(ao, leaf_ao_value, blend_factor);
    
    return true;
} 