shader_type spatial;
// Ativar processamento de profundidade para efeitos de água
render_mode depth_prepass_alpha;
#include "includes/helpers.gdshaderinc"
#include "includes/uniforms.gdshaderinc"
// #include "includes/province.gdshaderinc"
#include "includes/water.gdshaderinc"
#include "includes/river.gdshaderinc"
#include "includes/vertex.gdshaderinc"
#include "includes/beach.gdshaderinc"
#include "includes/beach_mediterranean.gdshaderinc"
#include "includes/beach_pebbles.gdshaderinc"
#include "includes/borders_manager.gdshaderinc"



void fragment() {
    vec3 albedo = texture(terrain_diffuse, base_uv).rgb;
    vec3 normal_map = texture(terrain_normalmap, base_uv).rgb;
    vec3 normal = normalize(normal_map * 2.0 - 1.0);
    float roughness = 0.7;
    float metallic = 0.0;
    float specular = 0.5;
    
    // Processar província (cores e seleção)
    // albedo = process_province(UV, albedo);
    
    // Processar os diferentes tipos de praia
    bool is_beach = process_beach(UV, albedo, normal, roughness, metallic);
    bool is_mediterranean_beach = process_beach_mediterranean(UV, albedo, normal, roughness, metallic);
    bool is_pebbles_beach = process_beach_pebbles(UV, albedo, normal, roughness, metallic);
    
    // Processar rios (retorna true se estiver na água)
    bool is_river = process_river(UV, albedo, normal, roughness, metallic);
    
    // Processar todas as bordas usando o gerenciador de bordas
    albedo = process_all_borders(UV, albedo);
    
    // Ajustar propriedades do material para bordas
    adjust_material_for_borders(UV, roughness, metallic, specular);
    
    // Definir saídas do shader
    ALBEDO = albedo;
    NORMAL_MAP = normal * 0.5 + 0.5; // Converte de -1,1 para 0,1
    ROUGHNESS = roughness;
    METALLIC = metallic;
    SPECULAR = specular;
    
    // Adicionar efeitos especiais para água
    if (is_river) {
        SPECULAR = water_specular;
        // Não usamos ALPHA para manter o terreno e a água no mesmo nível
        // Em vez disso, ajustamos outras propriedades para dar a aparência de água
        EMISSION = albedo * 0.05;
        
        // Adicionar efeito de SSS (subsurface scattering) para simular profundidade
        SSS_STRENGTH = 0.3;
        SSS_TRANSMITTANCE_COLOR = vec4(water_color_deep, 1.0);
        
        // Deixar a água um pouco reflexiva
        METALLIC = clamp(metallic + 0.2, 0.0, 1.0);
        ROUGHNESS = clamp(roughness - 0.4, 0.05, 1.0);
    }
    
    // Podemos adicionar efeitos especiais para cada tipo de praia também, se necessário
    // Exemplo: reflexo de areia molhada na praia comum
    if (is_beach) {
        SPECULAR += 0.1;
    }
    
    // Praias mediterrâneas podem ter um brilho sutil
    if (is_mediterranean_beach) {
        ROUGHNESS = clamp(roughness - 0.05, 0.1, 1.0);
    }
    
    // Praias de seixos podem ter mais variação na normal
    if (is_pebbles_beach) {
        NORMAL_MAP_DEPTH = 1.2;
    }
    
    // Destacar bordas com um leve glow
    if (is_on_border(UV)) {
        EMISSION += albedo * 0.04; // Leve glow nas bordas
    }
}