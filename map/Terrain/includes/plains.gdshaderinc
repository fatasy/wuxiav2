// Definições para planícies padrão (plains_01_mask)
uniform sampler2D plains_diffuse : hint_default_white, filter_linear;
uniform sampler2D plains_normal : hint_normal, filter_linear;
uniform sampler2D plains_properties_base : hint_default_white, filter_linear;
uniform sampler2D plains_mask : hint_default_black, filter_linear;

// Propriedades das planícies padrão
uniform float plains_tiling = 20.0;
uniform float plains_density = 1.0;
uniform float plains_pattern_influence = 0.4; // Quanto o padrão afeta este terreno

// Função para processar planícies padrão
bool process_plains(vec2 uv, inout vec3 albedo, inout vec3 normal, inout float roughness, inout float metallic, inout float ao) {
    // Amostra da máscara
    float mask = texture(plains_mask, uv).r;
    
    // Se o valor da máscara for muito baixo, não estamos em uma área de planície padrão
    if (mask < 0.1) return false;
    
    // Coordenadas UV com tiling para as texturas, aplicando variação do pattern
    // para reduzir a repetição visual
    vec2 tiled_uv = apply_pattern(uv * plains_tiling, plains_pattern_influence);
    
    // Amostra das texturas
    vec3 plains_albedo = texture(plains_diffuse, tiled_uv).rgb;
    vec3 plains_normal_map = texture(plains_normal, tiled_uv).rgb;
    vec4 plains_properties = texture(plains_properties_base, tiled_uv);
    
    // Extrair propriedades do material
    float plains_roughness = plains_properties.g;
    float plains_metallic = plains_properties.r;
    float plains_ao = plains_properties.b;
    
    // Fator de mistura baseado na máscara e na densidade configurada
    float blend_factor = mask * plains_density;
    
    // Usar o pattern para variar ligeiramente o fator de mistura (0.2 = 20% de variação)
    blend_factor = get_pattern_blend_factor(uv, blend_factor, 0.2);
    
    // Converter o normal map para espaço tangente (-1 a 1)
    vec3 plains_normal_tangent = normalize(plains_normal_map * 2.0 - 1.0);
    
    // Misturar com as propriedades do terreno base
    albedo = mix(albedo, plains_albedo, blend_factor);
    normal = mix(normal, plains_normal_tangent, blend_factor);
    roughness = mix(roughness, plains_roughness, blend_factor);
    metallic = mix(metallic, plains_metallic, blend_factor);
    ao = mix(ao, plains_ao, blend_factor);
    
    // Variar ligeiramente as propriedades usando o pattern
    roughness = vary_by_pattern(roughness, uv, 0.1); // Variação de rugosidade de ±10%
    
    return true;
} 