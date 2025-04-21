// Definições para terreno de terras agrícolas mediterrâneas
uniform sampler2D medi_farmlands_diffuse : hint_default_white, filter_linear;
uniform sampler2D medi_farmlands_normal : hint_normal, filter_linear;
uniform sampler2D medi_farmlands_properties : hint_default_white, filter_linear;
uniform sampler2D medi_farmlands_mask : hint_default_black, filter_linear;

// Propriedades básicas
uniform float medi_farmlands_tiling = 25.0;
uniform float medi_farmlands_density = 1.0;

// Função para processar terreno de terras agrícolas mediterrâneas
bool process_medi_farmlands(vec2 uv, inout vec3 albedo, inout vec3 normal, inout float roughness, inout float metallic, inout float ao) {
    // Amostra da máscara
    float mask = texture(medi_farmlands_mask, uv).r;
    
    // Se o valor da máscara for muito baixo, não estamos em uma área de terras agrícolas mediterrâneas
    if (mask < 0.1) return false;
    
    // Coordenadas UV com tiling para as texturas
    vec2 tiled_uv = uv * medi_farmlands_tiling;
    
    // Amostra das texturas
    vec3 farm_albedo = texture(medi_farmlands_diffuse, tiled_uv).rgb;
    vec3 farm_normal_map = texture(medi_farmlands_normal, tiled_uv).rgb;
    vec4 farm_props = texture(medi_farmlands_properties, tiled_uv);
    
    // Extrair propriedades do material
    float farm_roughness = farm_props.g;
    float farm_metallic = farm_props.r;
    float farm_ao_value = farm_props.b;
    
    // Fator de mistura baseado na máscara e na densidade configurada
    float blend_factor = mask * medi_farmlands_density;
    
    // Converter o normal map para espaço tangente (-1 a 1)
    vec3 farm_normal_tangent = normalize(farm_normal_map * 2.0 - 1.0);
    
    // Misturar com as propriedades do terreno base
    albedo = mix(albedo, farm_albedo, blend_factor);
    normal = mix(normal, farm_normal_tangent, blend_factor);
    roughness = mix(roughness, farm_roughness, blend_factor);
    metallic = mix(metallic, farm_metallic, blend_factor);
    ao = mix(ao, farm_ao_value, blend_factor);
    
    return true;
} 