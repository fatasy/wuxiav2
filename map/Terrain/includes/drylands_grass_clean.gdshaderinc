// Definições para terreno de drylands com grama limpa
// Apenas a máscara está disponível para este tipo
uniform sampler2D drylands_grass_clean_mask : hint_default_black, filter_linear;

// Propriedades básicas
uniform float drylands_grass_clean_density = 1.0;
uniform vec3 drylands_grass_clean_color = vec3(0.7, 0.75, 0.4); // Verde amarelado para grama limpa/seca

// Função para processar terreno de drylands com grama limpa
bool process_drylands_grass_clean(vec2 uv, inout vec3 albedo, inout vec3 normal, inout float roughness, inout float metallic, inout float ao) {
    // Amostra da máscara
    float mask = texture(drylands_grass_clean_mask, uv).r;
    
    // Se o valor da máscara for muito baixo, não estamos em uma área de drylands com grama limpa
    if (mask < 0.1) return false;
    
    // Fator de mistura baseado na máscara e na densidade configurada
    float blend_factor = mask * drylands_grass_clean_density;
    
    // Misturar com as propriedades do terreno base usando valores padrão
    albedo = mix(albedo, drylands_grass_clean_color, blend_factor);
    // Manter normal map e outras propriedades com pequenas modificações
    roughness = mix(roughness, 0.8, blend_factor);  // Grama limpa é moderadamente áspera
    metallic = mix(metallic, 0.0, blend_factor);    // Grama não é metálica
    ao = mix(ao, 0.9, blend_factor);                // Pouca oclusão em grama limpa
    
    return true;
} 