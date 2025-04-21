// Definições para terreno de grama irregular mediterrânea
uniform sampler2D medi_lumpy_grass_diffuse : hint_default_white, filter_linear;
uniform sampler2D medi_lumpy_grass_normal : hint_normal, filter_linear;
uniform sampler2D medi_lumpy_grass_properties : hint_default_white, filter_linear;
uniform sampler2D medi_lumpy_grass_mask : hint_default_black, filter_linear;

// Propriedades básicas
uniform float medi_lumpy_grass_tiling = 30.0;
uniform float medi_lumpy_grass_density = 1.0;

// Função para processar terreno de grama irregular mediterrânea
bool process_medi_lumpy_grass(vec2 uv, inout vec3 albedo, inout vec3 normal, inout float roughness, inout float metallic, inout float ao) {
    // Amostra da máscara
    float mask = texture(medi_lumpy_grass_mask, uv).r;
    
    // Se o valor da máscara for muito baixo, não estamos em uma área de grama irregular mediterrânea
    if (mask < 0.1) return false;
    
    // Coordenadas UV com tiling para as texturas
    vec2 tiled_uv = uv * medi_lumpy_grass_tiling;
    
    // Amostra das texturas
    vec3 lumpy_albedo = texture(medi_lumpy_grass_diffuse, tiled_uv).rgb;
    vec3 lumpy_normal_map = texture(medi_lumpy_grass_normal, tiled_uv).rgb;
    vec4 lumpy_props = texture(medi_lumpy_grass_properties, tiled_uv);
    
    // Extrair propriedades do material
    float lumpy_roughness = lumpy_props.g;
    float lumpy_metallic = lumpy_props.r;
    float lumpy_ao_value = lumpy_props.b;
    
    // Fator de mistura baseado na máscara e na densidade configurada
    float blend_factor = mask * medi_lumpy_grass_density;
    
    // Converter o normal map para espaço tangente (-1 a 1)
    vec3 lumpy_normal_tangent = normalize(lumpy_normal_map * 2.0 - 1.0);
    
    // Misturar com as propriedades do terreno base
    albedo = mix(albedo, lumpy_albedo, blend_factor);
    normal = mix(normal, lumpy_normal_tangent, blend_factor);
    roughness = mix(roughness, lumpy_roughness, blend_factor);
    metallic = mix(metallic, lumpy_metallic, blend_factor);
    ao = mix(ao, lumpy_ao_value, blend_factor);
    
    return true;
} 