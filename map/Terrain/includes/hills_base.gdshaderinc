// Definições para terreno de colinas base
uniform sampler2D hills_base_diffuse : hint_default_white, filter_linear;
uniform sampler2D hills_base_normal : hint_normal, filter_linear;
uniform sampler2D hills_base_properties : hint_default_white, filter_linear;
uniform sampler2D hills_base_mask : hint_default_black, filter_linear;

// Propriedades básicas
uniform float hills_base_tiling = 25.0;
uniform float hills_base_density = 1.0;

// Função para processar terreno de colinas base
bool process_hills_base(vec2 uv, inout vec3 albedo, inout vec3 normal, inout float roughness, inout float metallic, inout float ao) {
    // Amostra da máscara
    float mask = texture(hills_base_mask, uv).r;
    
    // Se o valor da máscara for muito baixo, não estamos em uma área de colinas
    if (mask < 0.1) return false;
    
    // Coordenadas UV com tiling para as texturas
    vec2 tiled_uv = uv * hills_base_tiling;
    
    // Amostra das texturas
    vec3 hills_albedo = texture(hills_base_diffuse, tiled_uv).rgb;
    vec3 hills_normal_map = texture(hills_base_normal, tiled_uv).rgb;
    vec4 hills_props = texture(hills_base_properties, tiled_uv);
    
    // Extrair propriedades do material
    float hills_roughness = hills_props.g;
    float hills_metallic = hills_props.r;
    float hills_ao_value = hills_props.b;
    
    // Fator de mistura baseado na máscara e na densidade configurada
    float blend_factor = mask * hills_base_density;
    
    // Converter o normal map para espaço tangente (-1 a 1)
    vec3 hills_normal_tangent = normalize(hills_normal_map * 2.0 - 1.0);
    
    // Misturar com as propriedades do terreno base
    albedo = mix(albedo, hills_albedo, blend_factor);
    normal = mix(normal, hills_normal_tangent, blend_factor);
    roughness = mix(roughness, hills_roughness, blend_factor);
    metallic = mix(metallic, hills_metallic, blend_factor);
    ao = mix(ao, hills_ao_value, blend_factor);
    
    return true;
} 