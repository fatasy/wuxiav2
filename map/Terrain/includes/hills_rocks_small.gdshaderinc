// Definições para terreno de colinas com rochas pequenas
uniform sampler2D hills_rocks_small_diffuse : hint_default_white, filter_linear;
uniform sampler2D hills_rocks_small_normal : hint_normal, filter_linear;
uniform sampler2D hills_rocks_small_properties : hint_default_white, filter_linear;
uniform sampler2D hills_rocks_small_mask : hint_default_black, filter_linear;

// Propriedades básicas
uniform float hills_rocks_small_tiling = 35.0;
uniform float hills_rocks_small_density = 1.0;

// Função para processar terreno de colinas com rochas pequenas
bool process_hills_rocks_small(vec2 uv, inout vec3 albedo, inout vec3 normal, inout float roughness, inout float metallic, inout float ao) {
    // Amostra da máscara
    float mask = texture(hills_rocks_small_mask, uv).r;
    
    // Se o valor da máscara for muito baixo, não estamos em uma área de colinas com rochas pequenas
    if (mask < 0.1) return false;
    
    // Coordenadas UV com tiling para as texturas
    vec2 tiled_uv = uv * hills_rocks_small_tiling;
    
    // Amostra das texturas
    vec3 rocks_small_albedo = texture(hills_rocks_small_diffuse, tiled_uv).rgb;
    vec3 rocks_small_normal_map = texture(hills_rocks_small_normal, tiled_uv).rgb;
    vec4 rocks_small_props = texture(hills_rocks_small_properties, tiled_uv);
    
    // Extrair propriedades do material
    float rocks_small_roughness = rocks_small_props.g;
    float rocks_small_metallic = rocks_small_props.r;
    float rocks_small_ao_value = rocks_small_props.b;
    
    // Fator de mistura baseado na máscara e na densidade configurada
    float blend_factor = mask * hills_rocks_small_density;
    
    // Converter o normal map para espaço tangente (-1 a 1)
    vec3 rocks_small_normal_tangent = normalize(rocks_small_normal_map * 2.0 - 1.0);
    
    // Misturar com as propriedades do terreno base
    albedo = mix(albedo, rocks_small_albedo, blend_factor);
    normal = mix(normal, rocks_small_normal_tangent, blend_factor);
    roughness = mix(roughness, rocks_small_roughness, blend_factor);
    metallic = mix(metallic, rocks_small_metallic, blend_factor);
    ao = mix(ao, rocks_small_ao_value, blend_factor);
    
    return true;
} 