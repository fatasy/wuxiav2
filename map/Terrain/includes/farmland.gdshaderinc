// Definições para terreno de fazenda
uniform sampler2D farmland_diffuse : hint_default_white, filter_linear;
uniform sampler2D farmland_normal : hint_normal, filter_linear;
uniform sampler2D farmland_properties : hint_default_white, filter_linear;
uniform sampler2D farmland_mask : hint_default_black, filter_linear;

// Propriedades básicas
uniform float farmland_tiling = 20.0;
uniform float farmland_density = 1.0;

// Função para processar terreno de fazenda
bool process_farmland(vec2 uv, inout vec3 albedo, inout vec3 normal, inout float roughness, inout float metallic, inout float ao) {
    // Amostra da máscara
    float mask = texture(farmland_mask, uv).r;
    
    // Se o valor da máscara for muito baixo, não estamos em uma área de fazenda
    if (mask < 0.1) return false;
    
    // Coordenadas UV com tiling para as texturas
    vec2 tiled_uv = uv * farmland_tiling;
    
    // Amostra das texturas
    vec3 farm_albedo = texture(farmland_diffuse, tiled_uv).rgb;
    vec3 farm_normal_map = texture(farmland_normal, tiled_uv).rgb;
    vec4 farm_properties = texture(farmland_properties, tiled_uv);
    
    // Extrair propriedades do material
    float farm_roughness = farm_properties.g;
    float farm_metallic = farm_properties.r;
    float farm_ao = farm_properties.b;
    
    // Fator de mistura baseado na máscara e na densidade configurada
    float blend_factor = mask * farmland_density;
    
    // Converter o normal map para espaço tangente (-1 a 1)
    vec3 farm_normal_tangent = normalize(farm_normal_map * 2.0 - 1.0);
    
    // Misturar com as propriedades do terreno base
    albedo = mix(albedo, farm_albedo, blend_factor);
    normal = mix(normal, farm_normal_tangent, blend_factor);
    roughness = mix(roughness, farm_roughness, blend_factor);
    metallic = mix(metallic, farm_metallic, blend_factor);
    ao = mix(ao, farm_ao, blend_factor);
    
    return true;
} 