// Definições para terreno de montanha desértica tipo C
uniform sampler2D mountain_desert_c_diffuse : hint_default_white, filter_linear;
uniform sampler2D mountain_desert_c_normal : hint_normal, filter_linear;
uniform sampler2D mountain_desert_c_properties : hint_default_white, filter_linear;
uniform sampler2D mountain_desert_c_mask : hint_default_black, filter_linear;

// Propriedades básicas
uniform float mountain_desert_c_tiling = 45.0;
uniform float mountain_desert_c_density = 1.0;

// Função para processar terreno de montanha desértica tipo C
bool process_mountain_desert_c(vec2 uv, inout vec3 albedo, inout vec3 normal, inout float roughness, inout float metallic, inout float ao) {
    // Amostra da máscara
    float mask = texture(mountain_desert_c_mask, uv).r;
    
    // Se o valor da máscara for muito baixo, não estamos em uma área de montanha desértica tipo C
    if (mask < 0.1) return false;
    
    // Coordenadas UV com tiling para as texturas
    vec2 tiled_uv = uv * mountain_desert_c_tiling;
    
    // Amostra das texturas
    vec3 desert_albedo = texture(mountain_desert_c_diffuse, tiled_uv).rgb;
    vec3 desert_normal_map = texture(mountain_desert_c_normal, tiled_uv).rgb;
    vec4 desert_props = texture(mountain_desert_c_properties, tiled_uv);
    
    // Extrair propriedades do material
    float desert_roughness = desert_props.g;
    float desert_metallic = desert_props.r;
    float desert_ao_value = desert_props.b;
    
    // Fator de mistura baseado na máscara e na densidade configurada
    float blend_factor = mask * mountain_desert_c_density;
    
    // Converter o normal map para espaço tangente (-1 a 1)
    vec3 desert_normal_tangent = normalize(desert_normal_map * 2.0 - 1.0);
    
    // Misturar com as propriedades do terreno base
    albedo = mix(albedo, desert_albedo, blend_factor);
    normal = mix(normal, desert_normal_tangent, blend_factor);
    roughness = mix(roughness, desert_roughness, blend_factor);
    metallic = mix(metallic, desert_metallic, blend_factor);
    ao = mix(ao, desert_ao_value, blend_factor);
    
    return true;
} 