// Função para calcular as propriedades do terreno
void process_terrain(in vec2 uv, out vec3 albedo, out vec3 normal_map) {
    albedo = texture(terrain_diffuse, uv).rgb;
    normal_map = texture(terrain_normalmap, uv).rgb * 2.0 - 1.0;
    // Adicione outros cálculos de terreno conforme necessário
} 