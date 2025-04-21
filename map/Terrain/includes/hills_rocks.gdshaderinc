// Definições para terreno de colinas com rochas
uniform sampler2D hills_rocks_diffuse : hint_default_white, filter_linear;
uniform sampler2D hills_rocks_normal : hint_normal, filter_linear;
uniform sampler2D hills_rocks_properties : hint_default_white, filter_linear;
uniform sampler2D hills_rocks_mask : hint_default_black, filter_linear;

// Propriedades básicas
uniform float hills_rocks_tiling = 30.0;
uniform float hills_rocks_density = 1.0;

// Função para processar terreno de colinas com rochas
bool process_hills_rocks(vec2 uv, inout vec3 albedo, inout vec3 normal, inout float roughness, inout float metallic, inout float ao) {
    // Amostra da máscara
    float mask = texture(hills_rocks_mask, uv).r;
    
    // Se o valor da máscara for muito baixo, não estamos em uma área de colinas com rochas
    if (mask < 0.1) return false;
    
    // Coordenadas UV com tiling para as texturas
    vec2 tiled_uv = uv * hills_rocks_tiling;
    
    // Amostra das texturas
    vec3 rocks_albedo = texture(hills_rocks_diffuse, tiled_uv).rgb;
    vec3 rocks_normal_map = texture(hills_rocks_normal, tiled_uv).rgb;
    vec4 rocks_props = texture(hills_rocks_properties, tiled_uv);
    
    // Extrair propriedades do material
    float rocks_roughness = rocks_props.g;
    float rocks_metallic = rocks_props.r;
    float rocks_ao_value = rocks_props.b;
    
    // Fator de mistura baseado na máscara e na densidade configurada
    float blend_factor = mask * hills_rocks_density;
    
    // Converter o normal map para espaço tangente (-1 a 1)
    vec3 rocks_normal_tangent = normalize(rocks_normal_map * 2.0 - 1.0);
    
    // Misturar com as propriedades do terreno base
    albedo = mix(albedo, rocks_albedo, blend_factor);
    normal = mix(normal, rocks_normal_tangent, blend_factor);
    roughness = mix(roughness, rocks_roughness, blend_factor);
    metallic = mix(metallic, rocks_metallic, blend_factor);
    ao = mix(ao, rocks_ao_value, blend_factor);
    
    return true;
} 