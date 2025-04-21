// Definições para terreno de deserto rochoso
uniform sampler2D desert_rocky_diffuse : hint_default_white, filter_linear;
uniform sampler2D desert_rocky_normal : hint_normal, filter_linear;
uniform sampler2D desert_rocky_properties : hint_default_white, filter_linear;
uniform sampler2D desert_rocky_mask : hint_default_black, filter_linear;

// Propriedades básicas
uniform float desert_rocky_tiling = 30.0;
uniform float desert_rocky_density = 1.0;

// Função para processar terreno de deserto rochoso
bool process_desert_rocky(vec2 uv, inout vec3 albedo, inout vec3 normal, inout float roughness, inout float metallic, inout float ao) {
    // Amostra da máscara
    float mask = texture(desert_rocky_mask, uv).r;
    
    // Se o valor da máscara for muito baixo, não estamos em uma área de deserto rochoso
    if (mask < 0.1) return false;
    
    // Coordenadas UV com tiling para as texturas
    vec2 tiled_uv = uv * desert_rocky_tiling;
    
    // Amostra das texturas
    vec3 rocky_albedo = texture(desert_rocky_diffuse, tiled_uv).rgb;
    vec3 rocky_normal_map = texture(desert_rocky_normal, tiled_uv).rgb;
    vec4 rocky_props = texture(desert_rocky_properties, tiled_uv);
    
    // Extrair propriedades do material
    float rocky_roughness = rocky_props.g;
    float rocky_metallic = rocky_props.r;
    float rocky_ao_value = rocky_props.b;
    
    // Fator de mistura baseado na máscara e na densidade configurada
    float blend_factor = mask * desert_rocky_density;
    
    // Converter o normal map para espaço tangente (-1 a 1)
    vec3 rocky_normal_tangent = normalize(rocky_normal_map * 2.0 - 1.0);
    
    // Misturar com as propriedades do terreno base
    albedo = mix(albedo, rocky_albedo, blend_factor);
    normal = mix(normal, rocky_normal_tangent, blend_factor);
    roughness = mix(roughness, rocky_roughness, blend_factor);
    metallic = mix(metallic, rocky_metallic, blend_factor);
    ao = mix(ao, rocky_ao_value, blend_factor);
    
    return true;
} 