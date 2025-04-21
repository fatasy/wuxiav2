// Definições para linha costeira desértica
// Usando apenas as texturas disponíveis
uniform sampler2D coastline_cliff_desert_diffuse : hint_default_white, filter_linear;
uniform sampler2D coastline_cliff_desert_mask : hint_default_black, filter_linear;

// Propriedades básicas
uniform float coastline_cliff_desert_tiling = 15.0;
uniform float coastline_cliff_desert_density = 1.0;

// Função para processar a linha costeira desértica
bool process_coastline_cliff_desert(vec2 uv, inout vec3 albedo, inout vec3 normal, inout float roughness, inout float metallic, inout float ao) {
    // Amostra da máscara
    float mask = texture(coastline_cliff_desert_mask, uv).r;
    
    // Se o valor da máscara for muito baixo, não estamos em uma área de linha costeira desértica
    if (mask < 0.1) return false;
    
    // Coordenadas UV com tiling para as texturas
    vec2 tiled_uv = uv * coastline_cliff_desert_tiling;
    
    // Amostra apenas da textura difusa disponível
    vec3 cliff_albedo = texture(coastline_cliff_desert_diffuse, tiled_uv).rgb;
    
    // Fator de mistura baseado na máscara e na densidade configurada
    float blend_factor = mask * coastline_cliff_desert_density;
    
    // Misturar com as propriedades do terreno base usando valores padrão para propriedades não disponíveis
    albedo = mix(albedo, cliff_albedo, blend_factor);
    // Manter normal map inalterado
    roughness = mix(roughness, 0.85, blend_factor); // Falésias desérticas são ásperas
    metallic = mix(metallic, 0.0, blend_factor);    // Falésias não são metálicas
    ao = mix(ao, 0.8, blend_factor);                // Pouca oclusão em desertos
    
    return true;
} 