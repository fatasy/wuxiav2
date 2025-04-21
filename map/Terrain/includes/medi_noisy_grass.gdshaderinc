// Definições para terreno de grama ruidosa mediterrânea
uniform sampler2D medi_noisy_grass_diffuse : hint_default_white, filter_linear;
uniform sampler2D medi_noisy_grass_normal : hint_normal, filter_linear;
uniform sampler2D medi_noisy_grass_properties : hint_default_white, filter_linear;
uniform sampler2D medi_noisy_grass_mask : hint_default_black, filter_linear;

// Propriedades básicas
uniform float medi_noisy_grass_tiling = 28.0;
uniform float medi_noisy_grass_density = 1.0;

// Função para processar terreno de grama ruidosa mediterrânea
bool process_medi_noisy_grass(vec2 uv, inout vec3 albedo, inout vec3 normal, inout float roughness, inout float metallic, inout float ao) {
    // Amostra da máscara
    float mask = texture(medi_noisy_grass_mask, uv).r;
    
    // Se o valor da máscara for muito baixo, não estamos em uma área de grama ruidosa mediterrânea
    if (mask < 0.1) return false;
    
    // Coordenadas UV com tiling para as texturas
    vec2 tiled_uv = uv * medi_noisy_grass_tiling;
    
    // Amostra das texturas
    vec3 noisy_albedo = texture(medi_noisy_grass_diffuse, tiled_uv).rgb;
    vec3 noisy_normal_map = texture(medi_noisy_grass_normal, tiled_uv).rgb;
    vec4 noisy_props = texture(medi_noisy_grass_properties, tiled_uv);
    
    // Extrair propriedades do material
    float noisy_roughness = noisy_props.g;
    float noisy_metallic = noisy_props.r;
    float noisy_ao_value = noisy_props.b;
    
    // Fator de mistura baseado na máscara e na densidade configurada
    float blend_factor = mask * medi_noisy_grass_density;
    
    // Converter o normal map para espaço tangente (-1 a 1)
    vec3 noisy_normal_tangent = normalize(noisy_normal_map * 2.0 - 1.0);
    
    // Misturar com as propriedades do terreno base
    albedo = mix(albedo, noisy_albedo, blend_factor);
    normal = mix(normal, noisy_normal_tangent, blend_factor);
    roughness = mix(roughness, noisy_roughness, blend_factor);
    metallic = mix(metallic, noisy_metallic, blend_factor);
    ao = mix(ao, noisy_ao_value, blend_factor);
    
    return true;
} 