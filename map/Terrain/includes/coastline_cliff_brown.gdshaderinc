// Definições para linha costeira marrom
// Usando apenas a máscara disponível
uniform sampler2D coastline_cliff_brown_mask : hint_default_black, filter_linear;

// Propriedades básicas
uniform float coastline_cliff_brown_tiling = 15.0;
uniform float coastline_cliff_brown_density = 1.0;
uniform vec3 coastline_cliff_brown_color = vec3(0.45, 0.32, 0.2); // Cor marrom padrão

// Função para processar a linha costeira marrom
bool process_coastline_cliff_brown(vec2 uv, inout vec3 albedo, inout vec3 normal, inout float roughness, inout float metallic, inout float ao) {
    // Amostra da máscara
    float mask = texture(coastline_cliff_brown_mask, uv).r;
    
    // Se o valor da máscara for muito baixo, não estamos em uma área de linha costeira marrom
    if (mask < 0.1) return false;
    
    // Fator de mistura baseado na máscara e na densidade configurada
    float blend_factor = mask * coastline_cliff_brown_density;
    
    // Misturar com as propriedades do terreno base usando valores padrão
    albedo = mix(albedo, coastline_cliff_brown_color, blend_factor);
    // Manter normal map e outras propriedades inalteradas
    roughness = mix(roughness, 0.9, blend_factor); // Falésias são ásperas
    metallic = mix(metallic, 0.0, blend_factor);   // Falésias não são metálicas
    ao = mix(ao, 0.7, blend_factor);               // Alguma oclusão
    
    return true;
} 