// Definições para terreno de colinas do norte
uniform sampler2D northern_hills_01_mask : hint_default_black, filter_linear;

// Propriedades básicas
uniform float northern_hills_tiling = 30.0;
uniform float northern_hills_density = 1.0;

// Função para processar terreno de colinas do norte
bool process_northern_hills(vec2 uv, inout vec3 albedo, inout vec3 normal, inout float roughness, inout float metallic, inout float ao) {
    // Amostra da máscara
    float mask = texture(northern_hills_01_mask, uv).r;
    
    // Se o valor da máscara for muito baixo, não estamos em uma área de colinas do norte
    if (mask < 0.1) return false;
    
    // Note: Para as colinas do norte, usamos apenas a máscara para aplicar um efeito de mistura
    // com o terreno base, sem texturas específicas (pois não encontramos todas as texturas disponíveis)
    
    // Fator de mistura baseado na máscara e na densidade configurada
    float blend_factor = mask * northern_hills_density;
    
    // Ajustamos sutilmente as propriedades do material para dar mais dimensão às colinas
    // Aumentamos um pouco a rugosidade (roughness) para um aspecto mais severo de terreno nórdico
    roughness = mix(roughness, min(roughness + 0.2, 1.0), blend_factor);
    
    // Sutilmente ajustamos o albedo para dar um tom mais frio/azulado às colinas do norte
    albedo = mix(albedo, albedo * vec3(0.9, 0.95, 1.05), blend_factor);
    
    // Aumentamos sutilmente a oclusão ambiental para dar mais profundidade
    ao = mix(ao, max(ao - 0.1, 0.0), blend_factor);
    
    return true;
} 