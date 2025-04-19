// Função auxiliar para rotacionar UVs
vec2 rotateUV(vec2 uv, float rotation, vec2 center) {
    float cos_r = cos(rotation);
    float sin_r = sin(rotation);
    uv -= center;
    return vec2(uv.x * cos_r - uv.y * sin_r, uv.x * sin_r + uv.y * cos_r) + center;
} 


bool compare_colors(vec3 color1, vec3 color2) {
    // Usar uma comparação direta ou com pequena tolerância para cores exatas do mapa de províncias
    // Se as cores no mapa de províncias forem *exatamente* as mesmas, use ==
    // return color1 == color2;
    // Se houver pequenas variações devido à compressão ou filtragem, use um threshold:
    float threshold = 0.001; // Ajuste conforme necessário
    return all(lessThan(abs(color1 - color2), vec3(threshold))); // Maneira mais eficiente de comparar todos os componentes
}
