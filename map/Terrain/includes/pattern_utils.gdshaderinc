// Definições para o padrão de variação do terreno
uniform sampler2D pattern_texture : hint_default_white, filter_linear;

// Propriedades do padrão
uniform float pattern_strength = 0.4; // Força de aplicação do padrão
uniform float pattern_scale = 0.5;    // Escala geral do padrão

// Função para obter um offset de UV baseado no padrão
// Isso ajuda a quebrar a repetição de texturas nos terrenos
vec2 get_pattern_offset(vec2 uv) {
    // Amostra o padrão em uma escala diferente para criar variação
    vec3 pattern = texture(pattern_texture, uv * pattern_scale).rgb;
    
    // Usar dois canais do padrão para criar um deslocamento 2D
    vec2 offset = vec2(pattern.r, pattern.g) * 2.0 - 1.0; // Converter de 0-1 para -1 a 1
    
    // Aplicar a força de pattern configurada
    return offset * pattern_strength;
}

// Função para aplicar o padrão a um conjunto de coordenadas UV
vec2 apply_pattern(vec2 uv, float variation_scale) {
    // Obter um offset baseado no padrão
    vec2 pattern_offset = get_pattern_offset(uv);
    
    // Ajustar a escala de variação específica para este terreno
    pattern_offset *= variation_scale;
    
    // Retornar as coordenadas UV com o padrão aplicado
    return uv + pattern_offset;
}

// Função para obter um fator de mistura baseado no padrão
// Útil para misturar variações em um mesmo tipo de terreno
float get_pattern_blend_factor(vec2 uv, float base_factor, float pattern_influence) {
    // Obter um valor de pattern para modulação
    float pattern_value = texture(pattern_texture, uv * pattern_scale).r;
    
    // Ajustar o fator base com o pattern
    // pattern_influence controla quanto o padrão afeta o fator de mistura
    return mix(base_factor, base_factor * pattern_value, pattern_influence);
}

// Função para variar a intensidade de uma propriedade de material baseada no padrão
float vary_by_pattern(float base_value, vec2 uv, float variation_amount) {
    // Obter um valor de padrão
    float pattern_value = texture(pattern_texture, uv * pattern_scale).b; // Usando canal azul para variedade
    
    // Normalizar para criar variação em torno do valor base
    float variation = (pattern_value * 2.0 - 1.0) * variation_amount;
    
    // Retornar o valor base modificado pelo padrão, mantendo dentro de limites razoáveis
    return clamp(base_value + variation, 0.0, 1.0);
} 