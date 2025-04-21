// Wetlands Mud Shader para terrenos de lama em áreas alagadas
// Inclui texturas para áreas úmidas com lama e detritos

uniform sampler2D wetlands_mud_mask : hint_default_black, filter_linear;
uniform sampler2D wetlands_mud_diffuse : hint_default_white, filter_linear;
uniform sampler2D wetlands_mud_normal : hint_normal, filter_linear;
uniform sampler2D wetlands_mud_properties : hint_default_white, filter_linear;

bool process_wetlands_mud(vec2 uv, inout vec3 albedo, inout vec3 normal, inout float roughness, inout float metallic, inout float ao) {
    // Obtém o valor da máscara na posição UV
    float mask_value = texture(wetlands_mud_mask, uv).r;
    
    // Se o valor da máscara for maior que um limiar, aplicar o terreno de wetlands com lama
    if (mask_value > 0.1) {
        // Interpola entre o terreno base e o wetlands com lama baseado na força da máscara
        float blend = smoothstep(0.1, 0.5, mask_value);
        
        // Obtém as texturas do wetlands com lama
        vec3 wetlands_mud_albedo = texture(wetlands_mud_diffuse, uv).rgb;
        vec3 wetlands_mud_normal_map = texture(wetlands_mud_normal, uv).rgb;
        vec4 wetlands_mud_properties_c = texture(wetlands_mud_properties, uv);
        
        // Aplica as propriedades do wetlands com lama
        float wetlands_mud_roughness = wetlands_mud_properties_c.g;
        float wetlands_mud_metallic = wetlands_mud_properties_c.r;
        float wetlands_mud_ao = wetlands_mud_properties_c.b;
        
        // Interpola as propriedades
        albedo = mix(albedo, wetlands_mud_albedo, blend);
        normal = mix(normal, wetlands_mud_normal_map, blend);
        roughness = mix(roughness, wetlands_mud_roughness, blend);
        metallic = mix(metallic, wetlands_mud_metallic, blend);
        ao = mix(ao, wetlands_mud_ao, blend);
        
        return true;
    }
    
    return false;
} 