// Definições para terreno de terras agrícolas indianas
uniform sampler2D india_farmlands_diffuse : hint_default_white, filter_linear;
uniform sampler2D india_farmlands_normal : hint_normal, filter_linear;
uniform sampler2D india_farmlands_properties : hint_default_white, filter_linear;
uniform sampler2D india_farmlands_mask : hint_default_black, filter_linear;

// Propriedades básicas
uniform float india_farmlands_tiling = 25.0;
uniform float india_farmlands_density = 1.0;

// Função para processar terreno de terras agrícolas indianas
bool process_india_farmlands(vec2 uv, inout vec3 albedo, inout vec3 normal, inout float roughness, inout float metallic, inout float ao) {
    // Amostra da máscara
    float mask = texture(india_farmlands_mask, uv).r;
    
    // Se o valor da máscara for muito baixo, não estamos em uma área de terras agrícolas indianas
    if (mask < 0.1) return false;
    
    // Coordenadas UV com tiling para as texturas
    vec2 tiled_uv = uv * india_farmlands_tiling;
    
    // Amostra das texturas
    vec3 farmlands_albedo = texture(india_farmlands_diffuse, tiled_uv).rgb;
    vec3 farmlands_normal_map = texture(india_farmlands_normal, tiled_uv).rgb;
    vec4 farmlands_props = texture(india_farmlands_properties, tiled_uv);
    
    // Extrair propriedades do material
    float farmlands_roughness = farmlands_props.g;
    float farmlands_metallic = farmlands_props.r;
    float farmlands_ao_value = farmlands_props.b;
    
    // Fator de mistura baseado na máscara e na densidade configurada
    float blend_factor = mask * india_farmlands_density;
    
    // Converter o normal map para espaço tangente (-1 a 1)
    vec3 farmlands_normal_tangent = normalize(farmlands_normal_map * 2.0 - 1.0);
    
    // Misturar com as propriedades do terreno base
    albedo = mix(albedo, farmlands_albedo, blend_factor);
    normal = mix(normal, farmlands_normal_tangent, blend_factor);
    roughness = mix(roughness, farmlands_roughness, blend_factor);
    metallic = mix(metallic, farmlands_metallic, blend_factor);
    ao = mix(ao, farmlands_ao_value, blend_factor);
    
    return true;
} 