// Definições para terreno de montanha tipo D com vales
uniform sampler2D mountain_d_valleys_diffuse : hint_default_white, filter_linear;
uniform sampler2D mountain_d_valleys_normal : hint_normal, filter_linear;
uniform sampler2D mountain_d_valleys_properties : hint_default_white, filter_linear;
uniform sampler2D mountain_d_valleys_mask : hint_default_black, filter_linear;

// Propriedades básicas
uniform float mountain_d_valleys_tiling = 35.0;
uniform float mountain_d_valleys_density = 1.0;

// Função para processar terreno de montanha tipo D com vales
bool process_mountain_d_valleys(vec2 uv, inout vec3 albedo, inout vec3 normal, inout float roughness, inout float metallic, inout float ao) {
    // Amostra da máscara
    float mask = texture(mountain_d_valleys_mask, uv).r;
    
    // Se o valor da máscara for muito baixo, não estamos em uma área de montanha tipo D com vales
    if (mask < 0.1) return false;
    
    // Coordenadas UV com tiling para as texturas
    vec2 tiled_uv = uv * mountain_d_valleys_tiling;
    
    // Amostra das texturas
    vec3 valleys_albedo = texture(mountain_d_valleys_diffuse, tiled_uv).rgb;
    vec3 valleys_normal_map = texture(mountain_d_valleys_normal, tiled_uv).rgb;
    vec4 valleys_props = texture(mountain_d_valleys_properties, tiled_uv);
    
    // Extrair propriedades do material
    float valleys_roughness = valleys_props.g;
    float valleys_metallic = valleys_props.r;
    float valleys_ao_value = valleys_props.b;
    
    // Fator de mistura baseado na máscara e na densidade configurada
    float blend_factor = mask * mountain_d_valleys_density;
    
    // Converter o normal map para espaço tangente (-1 a 1)
    vec3 valleys_normal_tangent = normalize(valleys_normal_map * 2.0 - 1.0);
    
    // Misturar com as propriedades do terreno base
    albedo = mix(albedo, valleys_albedo, blend_factor);
    normal = mix(normal, valleys_normal_tangent, blend_factor);
    roughness = mix(roughness, valleys_roughness, blend_factor);
    metallic = mix(metallic, valleys_metallic, blend_factor);
    ao = mix(ao, valleys_ao_value, blend_factor);
    
    return true;
} 