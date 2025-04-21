// Definições para terreno de estepe com arbustos tipo 01
uniform sampler2D steppe_bushes_01_diffuse : hint_default_white, filter_linear;
uniform sampler2D steppe_bushes_01_normal : hint_normal, filter_linear;
uniform sampler2D steppe_bushes_01_properties : hint_default_white, filter_linear;
// Usamos a máscara padrão de arbustos já que não há uma específica para tipo 01
uniform sampler2D steppe_bushes_01_mask : hint_default_black, filter_linear;

// Propriedades básicas
uniform float steppe_bushes_01_tiling = 29.0;
uniform float steppe_bushes_01_density = 1.0;

// Função para processar terreno de estepe com arbustos tipo 01
bool process_steppe_bushes_01(vec2 uv, inout vec3 albedo, inout vec3 normal, inout float roughness, inout float metallic, inout float ao) {
    // Amostra da máscara
    float mask = texture(steppe_bushes_01_mask, uv).r;
    
    // Se o valor da máscara for muito baixo, não estamos em uma área de estepe com arbustos
    if (mask < 0.1) return false;
    
    // Coordenadas UV com tiling para as texturas
    vec2 tiled_uv = uv * steppe_bushes_01_tiling;
    
    // Amostra das texturas
    vec3 bushes_albedo = texture(steppe_bushes_01_diffuse, tiled_uv).rgb;
    vec3 bushes_normal_map = texture(steppe_bushes_01_normal, tiled_uv).rgb;
    vec4 bushes_props = texture(steppe_bushes_01_properties, tiled_uv);
    
    // Extrair propriedades do material
    float bushes_roughness = bushes_props.g;
    float bushes_metallic = bushes_props.r;
    float bushes_ao_value = bushes_props.b;
    
    // Fator de mistura baseado na máscara e na densidade configurada
    float blend_factor = mask * steppe_bushes_01_density;
    
    // Converter o normal map para espaço tangente (-1 a 1)
    vec3 bushes_normal_tangent = normalize(bushes_normal_map * 2.0 - 1.0);
    
    // Misturar com as propriedades do terreno base
    albedo = mix(albedo, bushes_albedo, blend_factor);
    normal = mix(normal, bushes_normal_tangent, blend_factor);
    roughness = mix(roughness, bushes_roughness, blend_factor);
    metallic = mix(metallic, bushes_metallic, blend_factor);
    ao = mix(ao, bushes_ao_value, blend_factor);
    
    return true;
} 