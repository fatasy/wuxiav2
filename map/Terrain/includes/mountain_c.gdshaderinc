// Definições para terreno de montanha tipo C
uniform sampler2D mountain_c_diffuse : hint_default_white, filter_linear;
uniform sampler2D mountain_c_normal : hint_normal, filter_linear;
uniform sampler2D mountain_c_properties : hint_default_white, filter_linear;
uniform sampler2D mountain_c_mask : hint_default_black, filter_linear;

// Propriedades básicas
uniform float mountain_c_tiling = 35.0;
uniform float mountain_c_density = 1.0;

// Função para processar terreno de montanha tipo C
bool process_mountain_c(vec2 uv, inout vec3 albedo, inout vec3 normal, inout float roughness, inout float metallic, inout float ao) {
    // Amostra da máscara
    float mask = texture(mountain_c_mask, uv).r;
    
    // Se o valor da máscara for muito baixo, não estamos em uma área de montanha tipo C
    if (mask < 0.1) return false;
    
    // Coordenadas UV com tiling para as texturas
    vec2 tiled_uv = uv * mountain_c_tiling;
    
    // Amostra das texturas
    vec3 mountain_albedo = texture(mountain_c_diffuse, tiled_uv).rgb;
    vec3 mountain_normal_map = texture(mountain_c_normal, tiled_uv).rgb;
    vec4 mountain_props = texture(mountain_c_properties, tiled_uv);
    
    // Extrair propriedades do material
    float mountain_roughness = mountain_props.g;
    float mountain_metallic = mountain_props.r;
    float mountain_ao_value = mountain_props.b;
    
    // Fator de mistura baseado na máscara e na densidade configurada
    float blend_factor = mask * mountain_c_density;
    
    // Converter o normal map para espaço tangente (-1 a 1)
    vec3 mountain_normal_tangent = normalize(mountain_normal_map * 2.0 - 1.0);
    
    // Misturar com as propriedades do terreno base
    albedo = mix(albedo, mountain_albedo, blend_factor);
    normal = mix(normal, mountain_normal_tangent, blend_factor);
    roughness = mix(roughness, mountain_roughness, blend_factor);
    metallic = mix(metallic, mountain_metallic, blend_factor);
    ao = mix(ao, mountain_ao_value, blend_factor);
    
    return true;
} 