// Definições para terreno de estepe rachada
uniform sampler2D steppe_cracked_diffuse : hint_default_white, filter_linear;
uniform sampler2D steppe_cracked_normal : hint_normal, filter_linear;
uniform sampler2D steppe_cracked_properties : hint_default_white, filter_linear;
// Nota: Não encontrei arquivo de máscara específico para steppe_cracked
// Usaremos a máscara base de steppe como alternativa
uniform sampler2D steppe_cracked_mask : hint_default_black, filter_linear;

// Propriedades básicas
uniform float steppe_cracked_tiling = 32.0;
uniform float steppe_cracked_density = 1.0;
// Área de influência para terreno rachado (ajustar conforme necessidade)
uniform float steppe_cracked_threshold = 0.7; 

// Função para processar terreno de estepe rachada
bool process_steppe_cracked(vec2 uv, inout vec3 albedo, inout vec3 normal, inout float roughness, inout float metallic, inout float ao) {
    // Amostra da máscara - usando a máscara base de steppe
    float base_mask = texture(steppe_cracked_mask, uv).r;
    
    // Aplicamos apenas em áreas de steppe com valor alto (áreas mais secas)
    if (base_mask < steppe_cracked_threshold) return false;
    
    // Coordenadas UV com tiling para as texturas
    vec2 tiled_uv = uv * steppe_cracked_tiling;
    
    // Amostra das texturas
    vec3 cracked_albedo = texture(steppe_cracked_diffuse, tiled_uv).rgb;
    vec3 cracked_normal_map = texture(steppe_cracked_normal, tiled_uv).rgb;
    vec4 cracked_props = texture(steppe_cracked_properties, tiled_uv);
    
    // Extrair propriedades do material
    float cracked_roughness = cracked_props.g;
    float cracked_metallic = cracked_props.r;
    float cracked_ao_value = cracked_props.b;
    
    // Fator de mistura baseado na máscara, limiar e densidade
    float blend_factor = clamp((base_mask - steppe_cracked_threshold) / (1.0 - steppe_cracked_threshold), 0.0, 1.0) * steppe_cracked_density;
    
    // Converter o normal map para espaço tangente (-1 a 1)
    vec3 cracked_normal_tangent = normalize(cracked_normal_map * 2.0 - 1.0);
    
    // Misturar com as propriedades do terreno base
    albedo = mix(albedo, cracked_albedo, blend_factor);
    normal = mix(normal, cracked_normal_tangent, blend_factor);
    roughness = mix(roughness, cracked_roughness, blend_factor);
    metallic = mix(metallic, cracked_metallic, blend_factor);
    ao = mix(ao, cracked_ao_value, blend_factor);
    
    return true;
} 