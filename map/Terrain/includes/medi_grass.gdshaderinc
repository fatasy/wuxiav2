// Definições para terreno de grama mediterrânea
uniform sampler2D medi_grass_01_diffuse : hint_default_white, filter_linear;
uniform sampler2D medi_grass_01_normal : hint_normal, filter_linear;
uniform sampler2D medi_grass_01_properties : hint_default_white, filter_linear;
uniform sampler2D medi_grass_01_mask : hint_default_black, filter_linear;

// Propriedades básicas
uniform float medi_grass_tiling = 25.0;
uniform float medi_grass_density = 1.0;

// Função para processar terreno de grama mediterrânea
bool process_medi_grass(vec2 uv, inout vec3 albedo, inout vec3 normal, inout float roughness, inout float metallic, inout float ao) {
    // Amostra da máscara
    float mask = texture(medi_grass_01_mask, uv).r;
    
    // Se o valor da máscara for muito baixo, não estamos em uma área de grama mediterrânea
    if (mask < 0.1) return false;
    
    // Coordenadas UV com tiling para as texturas
    vec2 tiled_uv = uv * medi_grass_tiling;
    
    // Amostra das texturas
    vec3 grass_albedo = texture(medi_grass_01_diffuse, tiled_uv).rgb;
    vec3 grass_normal_map = texture(medi_grass_01_normal, tiled_uv).rgb;
    vec4 grass_props = texture(medi_grass_01_properties, tiled_uv);
    
    // Extrair propriedades do material
    float grass_roughness = grass_props.g;
    float grass_metallic = grass_props.r;
    float grass_ao_value = grass_props.b;
    
    // Fator de mistura baseado na máscara e na densidade configurada
    float blend_factor = mask * medi_grass_density;
    
    // Converter o normal map para espaço tangente (-1 a 1)
    vec3 grass_normal_tangent = normalize(grass_normal_map * 2.0 - 1.0);
    
    // Misturar com as propriedades do terreno base
    albedo = mix(albedo, grass_albedo, blend_factor);
    normal = mix(normal, grass_normal_tangent, blend_factor);
    roughness = mix(roughness, grass_roughness, blend_factor);
    metallic = mix(metallic, grass_metallic, blend_factor);
    ao = mix(ao, grass_ao_value, blend_factor);
    
    return true;
} 