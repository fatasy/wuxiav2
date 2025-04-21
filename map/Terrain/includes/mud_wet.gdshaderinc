// Definições para terreno de lama molhada
uniform sampler2D mud_wet_01_diffuse : hint_default_white, filter_linear;
uniform sampler2D mud_wet_01_normal : hint_normal, filter_linear;
uniform sampler2D mud_wet_01_properties : hint_default_white, filter_linear;
uniform sampler2D mud_wet_01_mask : hint_default_black, filter_linear;

// Propriedades básicas
uniform float mud_wet_tiling = 28.0;
uniform float mud_wet_density = 1.0;

// Função para processar terreno de lama molhada
bool process_mud_wet(vec2 uv, inout vec3 albedo, inout vec3 normal, inout float roughness, inout float metallic, inout float ao) {
    // Amostra da máscara
    float mask = texture(mud_wet_01_mask, uv).r;
    
    // Se o valor da máscara for muito baixo, não estamos em uma área de lama molhada
    if (mask < 0.1) return false;
    
    // Coordenadas UV com tiling para as texturas
    vec2 tiled_uv = uv * mud_wet_tiling;
    
    // Amostra das texturas
    vec3 mud_albedo = texture(mud_wet_01_diffuse, tiled_uv).rgb;
    vec3 mud_normal_map = texture(mud_wet_01_normal, tiled_uv).rgb;
    vec4 mud_props = texture(mud_wet_01_properties, tiled_uv);
    
    // Extrair propriedades do material
    float mud_roughness = mud_props.g;
    float mud_metallic = mud_props.r;
    float mud_ao_value = mud_props.b;
    
    // Fator de mistura baseado na máscara e na densidade configurada
    float blend_factor = mask * mud_wet_density;
    
    // Converter o normal map para espaço tangente (-1 a 1)
    vec3 mud_normal_tangent = normalize(mud_normal_map * 2.0 - 1.0);
    
    // Misturar com as propriedades do terreno base
    albedo = mix(albedo, mud_albedo, blend_factor);
    normal = mix(normal, mud_normal_tangent, blend_factor);
    roughness = mix(roughness, mud_roughness, blend_factor);
    metallic = mix(metallic, mud_metallic, blend_factor);
    ao = mix(ao, mud_ao_value, blend_factor);
    
    return true;
} 