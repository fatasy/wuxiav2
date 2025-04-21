// Definições para terreno de drylands com grama
uniform sampler2D drylands_grassy_diffuse : hint_default_white, filter_linear;
uniform sampler2D drylands_grassy_normal : hint_normal, filter_linear;
uniform sampler2D drylands_grassy_properties : hint_default_white, filter_linear;
uniform sampler2D drylands_grassy_mask : hint_default_black, filter_linear;

// Propriedades básicas
uniform float drylands_grassy_tiling = 20.0;
uniform float drylands_grassy_density = 1.0;

// Função para processar terreno de drylands com grama
bool process_drylands_grassy(vec2 uv, inout vec3 albedo, inout vec3 normal, inout float roughness, inout float metallic, inout float ao) {
    // Amostra da máscara
    float mask = texture(drylands_grassy_mask, uv).r;
    
    // Se o valor da máscara for muito baixo, não estamos em uma área de drylands com grama
    if (mask < 0.1) return false;
    
    // Coordenadas UV com tiling para as texturas
    vec2 tiled_uv = uv * drylands_grassy_tiling;
    
    // Amostra das texturas
    vec3 grassy_albedo = texture(drylands_grassy_diffuse, tiled_uv).rgb;
    vec3 grassy_normal_map = texture(drylands_grassy_normal, tiled_uv).rgb;
    vec4 grassy_props = texture(drylands_grassy_properties, tiled_uv);
    
    // Extrair propriedades do material
    float grassy_roughness = grassy_props.g;
    float grassy_metallic = grassy_props.r;
    float grassy_ao_value = grassy_props.b;
    
    // Fator de mistura baseado na máscara e na densidade configurada
    float blend_factor = mask * drylands_grassy_density;
    
    // Converter o normal map para espaço tangente (-1 a 1)
    vec3 grassy_normal_tangent = normalize(grassy_normal_map * 2.0 - 1.0);
    
    // Misturar com as propriedades do terreno base
    albedo = mix(albedo, grassy_albedo, blend_factor);
    normal = mix(normal, grassy_normal_tangent, blend_factor);
    roughness = mix(roughness, grassy_roughness, blend_factor);
    metallic = mix(metallic, grassy_metallic, blend_factor);
    ao = mix(ao, grassy_ao_value, blend_factor);
    
    return true;
} 