// Definições para terreno de planícies do norte
uniform sampler2D northern_plains_01_diffuse : hint_default_white, filter_linear;
uniform sampler2D northern_plains_01_normal : hint_normal, filter_linear;
uniform sampler2D northern_plains_01_properties : hint_default_white, filter_linear;
uniform sampler2D northern_plains_01_mask : hint_default_black, filter_linear;

// Propriedades básicas
uniform float northern_plains_tiling = 25.0;
uniform float northern_plains_density = 1.0;

// Função para processar terreno de planícies do norte
bool process_northern_plains(vec2 uv, inout vec3 albedo, inout vec3 normal, inout float roughness, inout float metallic, inout float ao) {
    // Amostra da máscara
    float mask = texture(northern_plains_01_mask, uv).r;
    
    // Se o valor da máscara for muito baixo, não estamos em uma área de planícies do norte
    if (mask < 0.1) return false;
    
    // Coordenadas UV com tiling para as texturas
    vec2 tiled_uv = uv * northern_plains_tiling;
    
    // Amostra das texturas
    vec3 northern_albedo = texture(northern_plains_01_diffuse, tiled_uv).rgb;
    vec3 northern_normal_map = texture(northern_plains_01_normal, tiled_uv).rgb;
    vec4 northern_props = texture(northern_plains_01_properties, tiled_uv);
    
    // Extrair propriedades do material
    float northern_roughness = northern_props.g;
    float northern_metallic = northern_props.r;
    float northern_ao_value = northern_props.b;
    
    // Fator de mistura baseado na máscara e na densidade configurada
    float blend_factor = mask * northern_plains_density;
    
    // Converter o normal map para espaço tangente (-1 a 1)
    vec3 northern_normal_tangent = normalize(northern_normal_map * 2.0 - 1.0);
    
    // Misturar com as propriedades do terreno base
    albedo = mix(albedo, northern_albedo, blend_factor);
    normal = mix(normal, northern_normal_tangent, blend_factor);
    roughness = mix(roughness, northern_roughness, blend_factor);
    metallic = mix(metallic, northern_metallic, blend_factor);
    ao = mix(ao, northern_ao_value, blend_factor);
    
    return true;
} 