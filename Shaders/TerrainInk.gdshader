shader_type spatial;

// Base
uniform sampler2D base_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D base_normal_map : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D base_properties : source_color, filter_linear_mipmap, repeat_enable; // Textura de propriedades para a base

// Defina o número máximo de camadas
const int MAX_LAYERS = 60;

// Arrays para as camadas
uniform sampler2D layer_textures[MAX_LAYERS];     // Albedo (_diffuse.dds)
uniform sampler2D layer_normal_maps[MAX_LAYERS];  // Normal (_normal.dds)
uniform sampler2D layer_masks[MAX_LAYERS];        // Máscaras (ex: .png)
uniform sampler2D layer_properties[MAX_LAYERS];   // Propriedades (_properties.dds)

uniform float blend_sharpness : hint_range(1.0, 32.0) = 8.0;

// --- Uniforms do ProvinceHighlight ---
uniform sampler2D province_map : source_color, filter_nearest, repeat_disable; // Usar filter_nearest para cores exatas
uniform vec3 selected_province_color = vec3(-1.0); // Cor que indica "nenhuma seleção"
uniform vec4 highlight_color : source_color = vec4(1.0, 1.0, 0.0, 1.0); // Amarelo


uniform sampler2D rivers_map : source_color, filter_linear, repeat_disable;
uniform vec3 river_color : source_color = vec3(0.2, 0.4, 0.8);
uniform float river_opacity : hint_range(0.0, 1.0) = 0.8;

// Defina aqui qual canal corresponde a qual propriedade (AJUSTE SE NECESSÁRIO!)
// Exemplo comum: R=AO, G=Roughness, B=Metallic
const int AO_CHANNEL = 0;        // R = 0
const int ROUGHNESS_CHANNEL = 1; // G = 1
const int METALLIC_CHANNEL = 2;  // B = 2

// --- Função de Comparação de Cores (do ProvinceHighlight) ---
bool compare_colors(vec3 color1, vec3 color2) {
    // Usar uma comparação direta ou com pequena tolerância para cores exatas do mapa de províncias
    // Se as cores no mapa de províncias forem *exatamente* as mesmas, use ==
    // return color1 == color2;
    // Se houver pequenas variações devido à compressão ou filtragem, use um threshold:
    float threshold = 0.001; // Ajuste conforme necessário
    return all(lessThan(abs(color1 - color2), vec3(threshold))); // Maneira mais eficiente de comparar todos os componentes
}

void fragment() {
    // --- Leitura Base ---
    vec3 current_albedo = texture(base_texture, UV).rgb;
    vec3 current_normal = texture(base_normal_map, UV).rgb;
    vec4 base_props = texture(base_properties, UV);
    float current_ao = base_props[AO_CHANNEL];
    float current_roughness = base_props[ROUGHNESS_CHANNEL];
    float current_metallic = base_props[METALLIC_CHANNEL];

    // --- Loop Pelas Camadas ---
    for (int i = 0; i < MAX_LAYERS; i++) {
        float mask_intensity = texture(layer_masks[i], UV).r;
        float blend_factor = pow(mask_intensity, blend_sharpness);

        // Leitura das texturas da camada
        vec3 layer_albedo = texture(layer_textures[i], UV).rgb;
        vec3 layer_normal = texture(layer_normal_maps[i], UV).rgb;
        vec4 layer_props = texture(layer_properties[i], UV);
        float layer_ao = layer_props[AO_CHANNEL];
        float layer_roughness = layer_props[ROUGHNESS_CHANNEL];
        float layer_metallic = layer_props[METALLIC_CHANNEL];

        // Mistura (Mix)
        current_albedo = mix(current_albedo, layer_albedo, blend_factor);
        current_normal = mix(current_normal, layer_normal, blend_factor);
        current_ao = mix(current_ao, layer_ao, blend_factor);
        current_roughness = mix(current_roughness, layer_roughness, blend_factor);
        current_metallic = mix(current_metallic, layer_metallic, blend_factor);
    }

    // --- Lógica do ProvinceHighlight (Sobrescrever Albedo se selecionado) ---
    if (selected_province_color.r >= 0.0) { // Verifica se uma província válida foi selecionada
        vec3 province_color = texture(province_map, UV).rgb;
        if (compare_colors(province_color, selected_province_color)) {
            // Se for a província selecionada, usa a cor de destaque
            current_albedo = highlight_color.rgb;
            // Opcional: Você pode querer alterar outras propriedades no highlight,
            // como deixar menos áspero ou remover o metálico
            // current_roughness = 0.2;
            // current_metallic = 0.0;
        }
    }

      // Pega o valor da máscara
    float river_mask = texture(rivers_map, UV).r;

    // Aplica a cor do rio, misturando com o albedo
    current_albedo = mix(current_albedo, river_color, river_mask * river_opacity);



    // --- Saída Final ---
    ALBEDO = current_albedo;
    NORMAL_MAP = normalize(current_normal * 2.0 - 1.0);
    NORMAL_MAP_DEPTH = 1.0;
    AO = current_ao;
    ROUGHNESS = current_roughness;
    METALLIC = current_metallic;
    AO_LIGHT_AFFECT = 1.0; // Controla o quanto a AO afeta a luz direta/indireta
}