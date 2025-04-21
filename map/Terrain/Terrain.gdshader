shader_type spatial;
// Ativar processamento de profundidade para efeitos de água
render_mode depth_prepass_alpha;


#include "includes/helpers.gdshaderinc"
#include "includes/water.gdshaderinc"

#include "includes/uniforms.gdshaderinc"
#include "includes/vertex.gdshaderinc"
#include "includes/borders_manager.gdshaderinc"
#include "includes/pattern_utils.gdshaderinc"

#include "includes/terrain_base.gdshaderinc"

// Terrain Types (Ordered based on materials.settings)
#include "includes/plains.gdshaderinc"
#include "includes/plains_dry.gdshaderinc"
#include "includes/plains_dry_mud.gdshaderinc"
#include "includes/plains_rough.gdshaderinc"
#include "includes/plains_noisy.gdshaderinc"
#include "includes/farmland.gdshaderinc"
#include "includes/mud_wet.gdshaderinc"
// #include "includes/beach.gdshaderinc"
// #include "includes/beach_pebbles.gdshaderinc"
// #include "includes/beach_mediterranean.gdshaderinc"
#include "includes/hills_base.gdshaderinc"
#include "includes/hills_rocks.gdshaderinc"
#include "includes/hills_rocks_medi.gdshaderinc"
#include "includes/hills_rocks_small.gdshaderinc"
#include "includes/floodplains.gdshaderinc"
#include "includes/wetlands_base.gdshaderinc"
#include "includes/wetlands_mud.gdshaderinc"
#include "includes/coastline_cliff_grey.gdshaderinc"
#include "includes/coastline_cliff_desert.gdshaderinc"
#include "includes/mountain_base.gdshaderinc"
#include "includes/mountain_b.gdshaderinc"
#include "includes/mountain_d.gdshaderinc"
#include "includes/mountain_d_valleys.gdshaderinc"
#include "includes/mountain_d_snow.gdshaderinc"
#include "includes/mountain_snow.gdshaderinc"
#include "includes/mountain_c.gdshaderinc"
#include "includes/mountain_c_snow.gdshaderinc"
#include "includes/forest_leaf.gdshaderinc"
#include "includes/forest_jungle.gdshaderinc"
#include "includes/forest_pine.gdshaderinc"
#include "includes/forest_floor.gdshaderinc"
#include "includes/desert_base.gdshaderinc"
#include "includes/desert_02.gdshaderinc"
#include "includes/desert_cracked.gdshaderinc"
#include "includes/desert_wavy.gdshaderinc"
#include "includes/desert_wavy_larger.gdshaderinc"
#include "includes/desert_flat.gdshaderinc"
#include "includes/desert_rocky.gdshaderinc"
#include "includes/mountain_desert.gdshaderinc"
#include "includes/mountain_desert_c.gdshaderinc"
#include "includes/drylands_base.gdshaderinc"
#include "includes/drylands_grassy.gdshaderinc"
#include "includes/drylands_cracked.gdshaderinc"
#include "includes/oasis.gdshaderinc"
#include "includes/medi_dry_mud.gdshaderinc"
#include "includes/medi_grass.gdshaderinc"
#include "includes/medi_lumpy_grass.gdshaderinc"
#include "includes/medi_noisy_grass.gdshaderinc"
#include "includes/medi_farmlands.gdshaderinc"
#include "includes/northern_plains.gdshaderinc"
#include "includes/steppe_base.gdshaderinc"
#include "includes/steppe_rocks.gdshaderinc"
#include "includes/steppe_bushes.gdshaderinc"
#include "includes/snow.gdshaderinc"
#include "includes/india_farmlands.gdshaderinc"

// Utility / Special / Unmatched Includes
#include "includes/plains_desat.gdshaderinc"
// #include "includes/river.gdshaderinc"
#include "includes/coastline_cliff_brown.gdshaderinc"
#include "includes/drylands_grass_clean.gdshaderinc"
#include "includes/northern_hills.gdshaderinc"
#include "includes/steppe_bushes_01.gdshaderinc"
#include "includes/steppe_cracked.gdshaderinc"
#include "includes/snow_winter.gdshaderinc"


void fragment() {
    // Configurar valores iniciais antes de processar o terreno base
    vec3 normal_world = normalize(NORMAL);
    float ao = 1.0;
    float height = VERTEX.y;

    // Cálculo de UV com variação baseada no padrão para reduzir a repetição visual
    vec2 varied_uv = apply_pattern(UV, 0.0); // Aplicando uma leve variação usando o pattern
    
    // Processar terreno base (textura não mascarada que cobre todo o mapa)
    // Utilizando texturas dos uniforms definidos em uniforms.gdshaderinc
    vec2 tiled_uv = varied_uv * terrain_base_tiling;
    vec3 albedo = vec3(0.0, 0.0, 0.0); // Albedo inicial transparente (cor preta)
    vec3 normal_map = texture(terrain_normalmap, tiled_uv).rgb;
    float roughness = 0.7; // Terrenos naturais tendem a ser mais ásperos
    float metallic = 0.0; // Terrenos naturais não são metálicos
    float alpha = 0.0; // Totalmente transparente inicialmente
   
    
    // Aplicamos fatores de terrain_base sem usar a função completa:
    float normalized_height = clamp((height + 100.0) / 200.0, 0.0, 1.0);
    float slope = 1.0 - normal_world.y; // 0 = plano, 1 = vertical
    
    // Aplicando fatores dos uniforms
    float terrain_blend = clamp(
        slope * terrain_base_slope_factor + 
        normalized_height * terrain_base_height_factor,
        0.0, 1.0
    );
    
    // Ajustamos roughness baseado na inclinação do terreno
    roughness = mix(0.6, 0.8, terrain_blend);
    
    // Nota: process_terrain_base foi desativado:
    // process_terrain_base(varied_uv, normal_world, height, albedo, normal_map, roughness, metallic, ao);
    
    // Converter normal map para espaço normal
    vec3 normal = normalize(normal_map * 2.0 - 1.0);
    
    // Calcular normal em espaço de tangente (simplificado)
    float specular = 0.5;

    // Terrain Processing (Ordered based on materials.settings)


    // 4. Processar Praias
    // bool is_beach = process_beach(varied_uv, albedo, normal, roughness, metallic);
    // bool is_pebbles_beach = process_beach_pebbles(varied_uv, albedo, normal, roughness, metallic);
    // bool is_mediterranean_beach = process_beach_mediterranean(varied_uv, albedo, normal, roughness, metallic);

    
    // 1. Processar Planícies
    bool is_plains = process_plains(varied_uv, albedo, normal, roughness, metallic, ao);
    bool is_plains_dry = process_plains_dry(varied_uv, albedo, normal, roughness, metallic, ao);
    bool is_plains_dry_mud = process_plains_dry_mud(varied_uv, albedo, normal, roughness, metallic, ao);
    
    bool is_plains_rough = process_plains_rough(varied_uv, albedo, normal, roughness, metallic, ao);
    
    
    bool is_plains_noisy = process_plains_noisy(varied_uv, albedo, normal, roughness, metallic, ao);
    
    // 2. Processar Terrenos de Fazenda
    bool is_farmland = process_farmland(varied_uv, albedo, normal, roughness, metallic, ao);
    
    // 3. Processar Mud
    bool is_mud_wet = process_mud_wet(varied_uv, albedo, normal, roughness, metallic, ao);

   
    // 5. Processar Colinas
    bool is_hills_base = process_hills_base(varied_uv, albedo, normal, roughness, metallic, ao);
    bool is_hills_rocks = process_hills_rocks(varied_uv, albedo, normal, roughness, metallic, ao);
    bool is_hills_rocks_medi = process_hills_rocks_medi(varied_uv, albedo, normal, roughness, metallic, ao); // Variação Mediterrânea
    bool is_hills_rocks_small = process_hills_rocks_small(varied_uv, albedo, normal, roughness, metallic, ao);
    
    // 6. Processar Floodplains
    bool is_floodplains = process_floodplains(varied_uv, albedo, normal, roughness, metallic, ao);

    // 7. Processar Wetlands
    bool is_wetlands_base = process_wetlands_base(varied_uv, albedo, normal, roughness, metallic, ao);
    bool is_wetlands_mud = process_wetlands_mud(varied_uv, albedo, normal, roughness, metallic, ao);

    // 8. Processar Linhas Costeiras (Cliffs)
    bool is_coastline_cliff_grey = process_coastline_cliff_grey(varied_uv, albedo, normal, roughness, metallic, ao);
    bool is_coastline_cliff_desert = process_coastline_cliff_desert(varied_uv, albedo, normal, roughness, metallic, ao);

    // 9. Processar Montanhas
    bool is_mountain = process_mountain(varied_uv, albedo, normal, roughness, metallic, ao);
    bool is_mountain_b = process_mountain_b(varied_uv, albedo, normal, roughness, metallic, ao);
    bool is_mountain_d = process_mountain_d(varied_uv, albedo, normal, roughness, metallic, ao);
    bool is_mountain_d_valleys = process_mountain_d_valleys(varied_uv, albedo, normal, roughness, metallic, ao);
    bool is_mountain_d_snow = process_mountain_d_snow(varied_uv, albedo, normal, roughness, metallic, ao);
    bool is_mountain_snow = process_mountain_snow(varied_uv, albedo, normal, roughness, metallic, ao);
    bool is_mountain_c = process_mountain_c(varied_uv, albedo, normal, roughness, metallic, ao);
    bool is_mountain_c_snow = process_mountain_c_snow(varied_uv, albedo, normal, roughness, metallic, ao);

    // 10. Processar Florestas
    bool is_forest_leaf = process_forest_leaf(varied_uv, albedo, normal, roughness, metallic, ao);
    bool is_forest_jungle = process_forest_jungle(varied_uv, albedo, normal, roughness, metallic, ao);
    bool is_forest_pine = process_forest_pine(varied_uv, albedo, normal, roughness, metallic, ao);
    bool is_forest_floor = process_forest_floor(varied_uv, albedo, normal, roughness, metallic, ao);

    // 11. Processar Desertos
    bool is_desert_base = process_desert_base(varied_uv, albedo, normal, roughness, metallic, ao);
    bool is_desert_02 = process_desert_02(varied_uv, albedo, normal, roughness, metallic, ao);
    bool is_desert_cracked = process_desert_cracked(varied_uv, albedo, normal, roughness, metallic, ao);
    bool is_desert_wavy = process_desert_wavy(varied_uv, albedo, normal, roughness, metallic, ao);
    bool is_desert_wavy_larger = process_desert_wavy_larger(varied_uv, albedo, normal, roughness, metallic, ao);
    bool is_desert_flat = process_desert_flat(varied_uv, albedo, normal, roughness, metallic, ao);
    bool is_desert_rocky = process_desert_rocky(varied_uv, albedo, normal, roughness, metallic, ao);
    bool is_mountain_desert = process_mountain_desert(varied_uv, albedo, normal, roughness, metallic, ao);
    bool is_mountain_desert_c = process_mountain_desert_c(varied_uv, albedo, normal, roughness, metallic, ao);

    // 12. Processar Drylands
    bool is_drylands = process_drylands(varied_uv, albedo, normal, roughness, metallic, ao);
    bool is_drylands_grassy = process_drylands_grassy(varied_uv, albedo, normal, roughness, metallic, ao);
    bool is_drylands_cracked = process_drylands_cracked(varied_uv, albedo, normal, roughness, metallic, ao);

    // 13. Processar Oasis
    bool is_oasis = process_oasis(varied_uv, albedo, normal, roughness, metallic, ao); // Oásis como característica especial

    // 14. Processar Terrenos Mediterrâneos Específicos
    bool is_medi_dry_mud = process_medi_dry_mud(varied_uv, albedo, normal, roughness, metallic, ao);
    bool is_medi_grass = process_medi_grass(varied_uv, albedo, normal, roughness, metallic, ao);
    bool is_medi_lumpy_grass = process_medi_lumpy_grass(varied_uv, albedo, normal, roughness, metallic, ao);
    bool is_medi_noisy_grass = process_medi_noisy_grass(varied_uv, albedo, normal, roughness, metallic, ao);
    bool is_medi_farmlands = process_medi_farmlands(varied_uv, albedo, normal, roughness, metallic, ao);

    // 15. Processar Planícies do Norte
    bool is_northern_plains = process_northern_plains(varied_uv, albedo, normal, roughness, metallic, ao); // Variação Norte

    // 16. Processar Estepe
    bool is_steppe_base = process_steppe_base(varied_uv, albedo, normal, roughness, metallic, ao);
    bool is_steppe_rocks = process_steppe_rocks(varied_uv, albedo, normal, roughness, metallic, ao);
    bool is_steppe_bushes = process_steppe_bushes(varied_uv, albedo, normal, roughness, metallic, ao);

    // 17. Processar Neve Geral (não sazonal)
    bool is_snow = process_snow(varied_uv, albedo, normal, roughness, metallic, ao);

    // 18. Processar Fazendas da Índia
    bool is_india_farmlands = process_india_farmlands(varied_uv, albedo, normal, roughness, metallic, ao); // Variação Indiana

    // Processamento de Terrenos Utilitários / Especiais / Não Mapeados
    bool is_plains_desat = process_plains_desat(varied_uv, albedo, normal, roughness, metallic, ao);
    // bool is_river = process_river(varied_uv, albedo, normal, roughness, metallic);
    bool is_coastline_cliff_brown = process_coastline_cliff_brown(varied_uv, albedo, normal, roughness, metallic, ao);
    bool is_drylands_grass_clean = process_drylands_grass_clean(varied_uv, albedo, normal, roughness, metallic, ao);
    bool is_northern_hills = process_northern_hills(varied_uv, albedo, normal, roughness, metallic, ao);
    bool is_steppe_bushes_01 = process_steppe_bushes_01(varied_uv, albedo, normal, roughness, metallic, ao);
    bool is_steppe_cracked = process_steppe_cracked(varied_uv, albedo, normal, roughness, metallic, ao);

    // Processar Neve de Inverno (Sazonal)
    process_snow_winter(varied_uv, albedo, normal, roughness, metallic, ao, height);

    // Definir saídas do shader
    ALBEDO = albedo;
    NORMAL_MAP = normal * 0.5 + 0.5; // Converte de -1,1 para 0,1
    
    METALLIC = metallic;
    SPECULAR = specular;
    AO = ao;

    // Aplicar Efeitos Especiais (Ordem correspondente ao processamento)

    // Efeitos para Planícies
    if (is_plains) {
        ALBEDO *= vec3(0.98, 1.02, 0.98); // Realçar levemente o verde
        NORMAL_MAP_DEPTH = 0.9; // Geralmente mais suaves
    }
    if (is_plains_dry) {
        EMISSION = albedo * 0.005; // Brilho sutil de calor
        ROUGHNESS = clamp(ROUGHNESS + 0.15, 0.6, 0.9);
    }
    if (is_plains_dry_mud) {
        NORMAL_MAP_DEPTH = 1.2; // Destacar rachaduras
        ROUGHNESS = clamp(ROUGHNESS + 0.1, 0.6, 0.9);
        SPECULAR *= 0.8;
    }
    //  if (is_plains_rough) {
    //     NORMAL_MAP_DEPTH = 1.3; // Terreno áspero bem definido
    //     ROUGHNESS = clamp(ROUGHNESS + 0.2, 0.7, 1.0);
    //     SPECULAR *= 0.7;
    // }
    if (is_plains_noisy) {
        AO *= 0.9; // Oclusão da grama alta/ruído
    }

    // Efeitos para Fazendas
    if (is_farmland || is_medi_farmlands || is_india_farmlands) { // Agrupando farmlands
        NORMAL_MAP_DEPTH = 1.1; // Sulcos e padrões de cultivo
        ROUGHNESS = clamp(roughness + 0.05, 0.5, 0.8);
        AO *= 0.9; // Oclusão sutil das plantações/sulcos
    }

    // Efeitos para Mud (Wet)
    if (is_mud_wet) { // Efeito específico para mud_wet_01
        ROUGHNESS = clamp(roughness - 0.2, 0.2, 0.6); 
        SPECULAR = clamp(SPECULAR + 0.15, 0.2, 0.7); // Lama molhada reflete mais
        NORMAL_MAP_DEPTH = 1.1;
        AO *= 0.85;
        SSS_STRENGTH = 0.25;
        SSS_TRANSMITTANCE_COLOR = vec4(albedo * 0.5, 1.0);
    }

    // Efeitos para Praias
    // if (is_beach) {
    //     // Simular areia molhada perto da água (implícito pela proximidade com água/rio)
    //     SPECULAR = clamp(SPECULAR + 0.15, 0.0, 0.8); // Areia molhada reflete mais
    //     ROUGHNESS = clamp(roughness - 0.1, 0.2, 0.6); // Areia molhada é mais lisa
    //     SSS_STRENGTH = 0.1; // Leve SSS para translucidez da areia
    //     SSS_TRANSMITTANCE_COLOR = vec4(albedo * 0.8, 1.0);
    //     NORMAL_MAP_DEPTH = 1.1; // Detalhes sutis na areia
    // }
    // if (is_pebbles_beach) {
    //     // Seixos são mais ásperos e detalhados
    //     NORMAL_MAP_DEPTH = 1.3; // Mais profundidade para os seixos
    //     ROUGHNESS = clamp(roughness + 0.2, 0.5, 0.9); // Mais áspera
    //     SPECULAR *= 0.7; // Menos especular
    //     AO *= 0.9; // Leve oclusão entre os seixos
    // }
    // if (is_mediterranean_beach) {
    //     // Areia mais clara e seca
    //     ROUGHNESS = clamp(roughness + 0.05, 0.4, 0.8); // Mais áspera que a praia comum
    //     SPECULAR *= 0.8; // Menos reflexiva
    // }

    // Efeitos para Colinas
    if (is_hills_base || is_hills_rocks || is_hills_rocks_medi || is_hills_rocks_small || is_northern_hills) { // Agrupando colinas
        NORMAL_MAP_DEPTH = 1.2; // Menos intenso que montanhas
        ROUGHNESS = clamp(roughness + 0.05, 0.5, 0.9);
        AO *= 0.95; // Oclusão suave da vegetação/rochas
    }
    if (is_hills_rocks || is_hills_rocks_medi || is_hills_rocks_small) { // Efeitos específicos para rochas em colinas
        SPECULAR *= 0.7; // Rochas refletem menos
    }

    // Efeitos para Floodplains (Geralmente combinados com Wetlands/Mud)
    if (is_floodplains) {
         ROUGHNESS = clamp(roughness - 0.15, 0.25, 0.65);
         SPECULAR = clamp(SPECULAR + 0.1, 0.2, 0.6); 
         AO *= 0.9;
         SSS_STRENGTH = 0.15;
         SSS_TRANSMITTANCE_COLOR = vec4(albedo * 0.6, 1.0);
    }

    // Efeitos para Wetlands
    if (is_wetlands_base || is_wetlands_mud) { // Agrupando wetlands
        ROUGHNESS = clamp(roughness - 0.2, 0.2, 0.6); // Superfície molhada/lamacenta é mais lisa
        SPECULAR = clamp(SPECULAR + 0.1, 0.2, 0.6); // Reflexo da água/lama
        NORMAL_MAP_DEPTH = 1.1; // Detalhes da lama
        AO *= 0.85; // Água/lama pode escurecer fendas
        // if (!is_river) { // Evitar SSS duplo se também for rio
        //     SSS_STRENGTH = 0.2; // Leve SSS para lama/água rasa
        //     SSS_TRANSMITTANCE_COLOR = vec4(albedo * 0.5, 1.0);
        // }
    }

    // Efeitos para Linhas Costeiras (Cliffs)
    if (is_coastline_cliff_grey || is_coastline_cliff_desert || is_coastline_cliff_brown) { // Agrupando cliffs
        NORMAL_MAP_DEPTH = 1.6; // Penhascos muito detalhados
        ROUGHNESS = clamp(roughness + 0.3, 0.8, 1.0); // Rocha exposta muito áspera
        SPECULAR = 0.1; // Quase sem reflexo especular
        AO *= 0.8; // Oclusão forte nas fendas
    }

    // Efeitos para Montanhas
    if (is_mountain || is_mountain_b || is_mountain_c || is_mountain_d) { // Montanhas base
        NORMAL_MAP_DEPTH = 1.4; // Rochas precisam de detalhes
        ROUGHNESS = clamp(roughness + 0.15, 0.6, 1.0); // Rocha é áspera
        SPECULAR *= 0.5; // Rocha reflete pouco
        AO *= 0.9; // Oclusão em fendas
    }
     if (is_mountain_d_valleys) {
        NORMAL_MAP_DEPTH = 1.5; // Destacar relevo dos vales
        AO = clamp(AO * (0.85 + 0.15 * sin(varied_uv.x * 10.0 + varied_uv.y * 15.0)), 0.0, 1.0); // Variação AO
        ROUGHNESS = clamp(ROUGHNESS - 0.05, 0.5, 0.9); // Leve erosão
    }
     if (is_mountain_snow || is_mountain_c_snow || is_mountain_d_snow) { // Montanhas com neve
        ROUGHNESS = clamp(roughness + 0.2, 0.7, 1.0); // Neve muito áspera
        SPECULAR = 0.1; // Neve reflete muito pouco de forma especular
        ALBEDO = mix(albedo, vec3(0.95), 0.8); // Neve é muito clara (sobrepõe parcialmente cor base)
    }

    // Efeitos para Florestas
    if (is_forest_leaf || is_forest_pine || is_forest_floor) { // Florestas comuns e chão
        AO *= 0.75; // Oclusão forte do dossel/vegetação densa
        ROUGHNESS = clamp(roughness + 0.1, 0.6, 0.9); // Chão de floresta é irregular
        SPECULAR *= 0.6;
    }
     if (is_forest_jungle) { // Floresta tropical
        ALBEDO *= vec3(0.9, 1.05, 0.9); // Verde mais vibrante
        ROUGHNESS = clamp(roughness - 0.05, 0.5, 0.8); // Mais úmido
        AO *= 0.7; // Ainda mais oclusão
    }

    // Efeitos para Desertos
    if (is_desert_base || is_desert_02 || is_desert_flat) { // Desertos base/planos
        ROUGHNESS = clamp(roughness + 0.25, 0.8, 1.0); // Muito áspero
        SPECULAR = 0.1; // Quase nenhum reflexo especular
        EMISSION = albedo * 0.015; // Brilho de calor mais intenso
    }
    if (is_desert_cracked) {
        NORMAL_MAP_DEPTH = 1.4; // Rachaduras bem visíveis
        ROUGHNESS = clamp(roughness + 0.3, 0.85, 1.0);
        SPECULAR = 0.05;
    }
    if (is_desert_wavy || is_desert_wavy_larger) {
        NORMAL_MAP_DEPTH = 1.1; // Ondulações suaves
        // Poderia adicionar animação de vento aqui no futuro
    }
    if (is_desert_rocky) {
        NORMAL_MAP_DEPTH = 1.4;
        ROUGHNESS = clamp(roughness + 0.3, 0.8, 1.0);
        SPECULAR *= 0.3;
    }
    if (is_mountain_desert || is_mountain_desert_c) { // Montanhas Desérticas
        ROUGHNESS = clamp(roughness + 0.2, 0.7, 1.0); // Rocha desértica muito áspera
        SPECULAR *= 0.4;
        EMISSION = albedo * 0.01; // Leve brilho de calor
    }

    // Efeitos para Drylands
    if (is_drylands || is_drylands_grassy || is_drylands_cracked || is_drylands_grass_clean) { // Agrupando Drylands
        ROUGHNESS = clamp(roughness + 0.15, 0.6, 0.9);
        SPECULAR *= 0.6;
    }
    if (is_drylands_cracked) { // Efeito específico para rachado
        NORMAL_MAP_DEPTH = 1.3; // Rachaduras profundas
        ROUGHNESS = clamp(roughness + 0.2, 0.7, 1.0);
        SPECULAR *= 0.5;
    }
     if (is_drylands_grassy || is_drylands_grass_clean) { // Efeito específico para gramado
        AO *= 0.9; // Oclusão da vegetação esparsa
    }

    // Efeitos para Oasis
    if (is_oasis) {
        ROUGHNESS = clamp(roughness - 0.1, 0.3, 0.7); // Umidade reduz a aspereza
        SPECULAR = clamp(SPECULAR + 0.1, 0.1, 0.5); // Leve reflexo da umidade
        ALBEDO *= vec3(0.9, 1.1, 0.9); // Mais verde
        EMISSION = vec3(0.0); // Sem brilho de calor
        AO *= 0.85; // Vegetação densa
    }

    // Efeitos para Terrenos Mediterrâneos (não praia/colina/fazenda)
    if (is_medi_dry_mud) {
        NORMAL_MAP_DEPTH = 1.2;
        ROUGHNESS = clamp(roughness + 0.15, 0.6, 0.9);
        SPECULAR *= 0.7;
    }
    if (is_medi_grass || is_medi_lumpy_grass || is_medi_noisy_grass) {
        ROUGHNESS = clamp(roughness + 0.05, 0.5, 0.8);
        SPECULAR *= 0.9;
    }

    // Efeitos para Planícies do Norte (Já coberto parcialmente pelos efeitos de planície? Adicionar especificidade se necessário)
    if (is_northern_plains) {
         // Efeitos específicos para northern_plains, se houver. 
         // Ex: ALBEDO *= vec3(0.95, 0.98, 1.0); // Tom mais frio
    }

    // Efeitos para Estepe
    if (is_steppe_base || is_steppe_rocks || is_steppe_bushes || is_steppe_bushes_01 || is_steppe_cracked) { // Agrupando estepes
        ROUGHNESS = clamp(roughness + 0.15, 0.6, 0.9);
        SPECULAR *= 0.6;
    }
    if (is_steppe_rocks) {
        NORMAL_MAP_DEPTH = 1.2;
        ROUGHNESS = clamp(roughness + 0.2, 0.7, 1.0);
        SPECULAR *= 0.6;
    }
    if (is_steppe_bushes || is_steppe_bushes_01) {
        AO *= 0.9; // Oclusão da vegetação esparsa
    }
    if (is_steppe_cracked) {
        NORMAL_MAP_DEPTH = 1.3; // Rachaduras profundas
        ROUGHNESS = clamp(roughness + 0.2, 0.7, 1.0);
        SPECULAR *= 0.5;
    }

    // Efeitos para Neve Geral
    if (is_snow) {
        ROUGHNESS = clamp(roughness + 0.2, 0.7, 1.0); // Neve muito áspera
        SPECULAR = 0.1; // Neve reflete muito pouco de forma especular
        // Mistura com albedo existente para não sobrescrever totalmente neve de montanha, etc.
        // A intensidade da mistura pode depender se já há neve de montanha, etc.
        // Exemplo simples: ALBEDO = mix(albedo, vec3(0.95), 0.7);
        AO *= 0.95;
    }

    // Efeitos para Fazendas da Índia (Já coberto pelo if de farmlands geral)

    // Efeitos Utilitários / Especiais / Não Mapeados
    if (is_plains_desat) {
        NORMAL_MAP_DEPTH = 1.0; // Terreno seco um pouco mais definido
        ROUGHNESS = clamp(ROUGHNESS + 0.1, 0.5, 0.8);
    }
    // Efeito para River (é especial, aplicado antes)
    // if (is_river) {
    //     // Efeito de água corrente e profunda
    //     SPECULAR = water_specular;
    //     EMISSION = albedo * 0.05; // Leve brilho para simular reflexo
    //     SSS_STRENGTH = 0.5; // Aumentar SSS para profundidade
    //     SSS_TRANSMITTANCE_COLOR = vec4(water_color_deep, 1.0);
    //     METALLIC = clamp(metallic + 0.1, 0.0, 1.0); // Um pouco mais metálico para reflexos
    //     ROUGHNESS = clamp(roughness - 0.2, 0.1, 0.5); // Mais liso para reflexos nítidos
    //     AO *= 0.8; // Escurecer um pouco para dar profundidade
    // }
    // Efeito para coastline_cliff_brown (coberto pelo if geral de cliffs)
    // Efeito para drylands_grass_clean (coberto pelo if geral de drylands)
    // Efeito para northern_hills (coberto pelo if geral de hills)

    // Efeito final para Neve de Inverno (sobrepõe outros)
    // if (is_winter_snow_applied()) { // Usar uma função helper para verificar se a neve de inverno foi aplicada
    //    ROUGHNESS = clamp(winter_snow_roughness, 0.7, 1.0);
    //    SPECULAR = winter_snow_specular;
    //    ALBEDO = mix(ALBEDO, winter_snow_color, winter_snow_intensity);
    //    AO = mix(AO, 1.0, winter_snow_intensity * 0.5); // Neve preenche pequenas oclusões
    //    NORMAL_MAP_DEPTH = mix(NORMAL_MAP_DEPTH, 1.0, winter_snow_intensity); // Neve suaviza detalhes finos
    // }

    // Efeito de borda (pode ser combinado com outros efeitos)
    // if (is_on_border(varied_uv)) {
    //     EMISSION += albedo * 0.04; // Leve glow nas bordas para destaque
    // }

    // << Efeito Adicional: Shoreline entre Plains Rough e Beach >>
    // if (is_beach || (is_plains_rough && is_beach)) {
    //     // Fatores para detectar a proximidade da shoreline
    //     float is_near_beach = float(is_beach);
    //     float is_near_plains_rough = float(is_plains_rough);
    //     float overlap_factor = is_near_beach * is_near_plains_rough * 0.8; // Reduzido para efeito mais sutil
        
    //     // Usar pattern_utils para adicionar variação natural
    //     vec2 shore_uv = apply_pattern(varied_uv, 0.2); // Reduzido para menos distorção
    //     float pattern_blend = get_pattern_blend_factor(shore_uv, 0.5, 0.3); // Ajustado para menos intensidade
        
    //     // Calcular fluxo de água baseado no tempo
    //     vec2 flow_uv = calculate_water_flow(shore_uv, TIME * 0.5); // Mais lento
        
    //     // Obter normais da água para o movimento das ondas
    //     vec3 water_normal = calculate_combined_water_normal(flow_uv, TIME * 0.4);
        
    //     // Efeito de espuma específico para shoreline
    //     float shoreline_factor = 0.0;
        
    //     if (is_beach) {
    //         // Calcular a proximidade com a água - corrigido para valor positivo
    //         float water_edge_proximity = 1.0 - smoothstep(0.2, 0.5, ROUGHNESS);
    //         float slope_influence = smoothstep(0.15, 0.4, 1.0 - normal_world.y);
            
    //         // Calcular espuma com as funções existentes - reduzida
    //         float foam_value = texture(foam_noise, shore_uv * (noise_scale * 0.7) + TIME * 0.05).r;
    //         float foam_intensity = calculate_water_foam(flow_uv, water_normal, water_edge_proximity * 0.4, TIME) * 0.6;
            
    //         // Combinar fatores com menor intensidade
    //         shoreline_factor = mix(foam_intensity * foam_value, 
    //                               foam_intensity * pattern_blend, 
    //                               slope_influence) * water_edge_proximity * 0.5;
            
    //         // Reduzir intensidade da espuma na transição
    //         if (is_plains_rough) {
    //             shoreline_factor *= 0.7;
    //         }
            
    //         // Aplicar espuma apenas onde realmente necessário
    //         if (shoreline_factor > 0.15) {
    //             // Cor da espuma mais sutil e menos branca
    //             vec3 foam_color = vec3(0.75, 0.78, 0.8) * pattern_blend;
                
    //             // Aplicar efeitos com menor intensidade
    //             ALBEDO = mix(ALBEDO, foam_color, shoreline_factor * 0.4);
    //             ROUGHNESS = mix(ROUGHNESS, 0.7, shoreline_factor * 0.3);
    //             SPECULAR = mix(SPECULAR, 0.15, shoreline_factor * 0.2);
                
    //             // Remover emissão para evitar brilho excessivo
    //             // EMISSION = mix(EMISSION, foam_color * 0.08, shoreline_factor * 0.4);
    //         }
    //     }
        
    //     // Efeito específico para plains_rough próximo à água - mais sutil
    //     if (is_plains_rough) {
    //         // Mais intenso quando está próximo da praia
    //         float wet_factor = overlap_factor * pattern_blend * 0.6;
            
    //         if (wet_factor > 0.1) {
    //             // Tornar mais escuro e úmido perto da água, mas menos intenso
    //             ALBEDO = mix(ALBEDO, ALBEDO * 0.8, wet_factor);
    //             ROUGHNESS = mix(ROUGHNESS, 0.4, wet_factor * 0.6);
    //             SPECULAR = mix(SPECULAR, 0.45, wet_factor * 0.4);
    //             NORMAL_MAP_DEPTH = mix(NORMAL_MAP_DEPTH, 1.0, wet_factor * 0.3);
                
    //             // Adicionar uma ligeira variação na altura para simular terreno molhado não-uniforme
    //             float wetness_variation = vary_by_pattern(0.5, shore_uv, 0.15);
    //             ALBEDO *= (1.0 - (wetness_variation * wet_factor * 0.15));
    //         }
    //     }
    // }
    
    // // Adicionar um efeito para as ilhas pequenas no oceano
    // if (is_beach && !is_plains_rough) {
    //     // Verificar se estamos em uma "ilha" pequena baseado na textura de padrão
    //     float island_pattern = texture(pattern_texture, varied_uv * 0.15).b;
    //     if (island_pattern > 0.6) {
    //         // Aumentar contraste nas bordas de ilhas pequenas
    //         float edge_factor = smoothstep(0.6, 0.8, island_pattern);
    //         NORMAL_MAP_DEPTH = mix(NORMAL_MAP_DEPTH, 1.3, edge_factor * 0.5);
    //         ROUGHNESS = mix(ROUGHNESS, 0.6, edge_factor * 0.4);
    //         SPECULAR = mix(SPECULAR, 0.3, edge_factor * 0.3);
            
    //         // Leve ajuste de cor para ilhas
    //         ALBEDO = mix(ALBEDO, ALBEDO * vec3(1.05, 1.03, 0.97), edge_factor * 0.3);
    //     }
    // }

}