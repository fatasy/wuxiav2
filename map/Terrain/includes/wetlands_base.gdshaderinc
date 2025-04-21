// Wetlands Base Shader para terrenos pantanosos básicos
// Inclui texturas para áreas úmidas e pântanos

uniform sampler2D wetlands_mask : hint_default_black, filter_linear;
uniform sampler2D wetlands_diffuse : hint_default_white, filter_linear;
uniform sampler2D wetlands_normal : hint_normal, filter_linear;
uniform sampler2D wetlands_properties : hint_default_white, filter_linear;

bool process_wetlands_base(vec2 uv, inout vec3 albedo, inout vec3 normal, inout float roughness, inout float metallic, inout float ao) {
    // Obtém o valor da máscara na posição UV
    float mask_value = texture(wetlands_mask, uv).r;
    
    // Se o valor da máscara for maior que um limiar, aplicar o terreno de wetlands
    if (mask_value > 0.1) {
        // Interpola entre o terreno base e o wetlands baseado na força da máscara
        float blend = smoothstep(0.1, 0.5, mask_value);
        
        // Obtém as texturas do wetlands
        vec3 wetlands_albedo = texture(wetlands_diffuse, uv).rgb;
        vec3 wetlands_normal_map = texture(wetlands_normal, uv).rgb;
        vec4 wetlands_base_properties = texture(wetlands_properties, uv);
        
        // Aplica as propriedades do wetlands
        float wetlands_roughness = wetlands_base_properties.g;
        float wetlands_metallic = wetlands_base_properties.r;
        float wetlands_ao = wetlands_base_properties.b;
        
        // Interpola as propriedades
        albedo = mix(albedo, wetlands_albedo, blend);
        normal = mix(normal, wetlands_normal_map, blend);
        roughness = mix(roughness, wetlands_roughness, blend);
        metallic = mix(metallic, wetlands_metallic, blend);
        ao = mix(ao, wetlands_ao, blend);
        
        return true;
    }
    
    return false;
} 