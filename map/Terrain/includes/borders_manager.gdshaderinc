// Incluir todos os arquivos de borda
#include "borders_common.gdshaderinc"
#include "borders_water.gdshaderinc"
#include "borders_province.gdshaderinc"
#include "borders_county.gdshaderinc"
#include "borders_domain.gdshaderinc"
#include "borders_realm.gdshaderinc"
#include "borders_war.gdshaderinc"
#include "borders_special.gdshaderinc"

// Função principal para processar todas as bordas
vec3 process_all_borders(vec2 uv, vec3 base_color) {
    // Processamos em ordem de prioridade (da menor para a maior)
    vec3 color = base_color;
    
    // 1. Bordas de água (prioridade mais baixa)
    color = process_water_borders(uv, color);
    
    // 2. Bordas administrativas
    color = process_county_borders(uv, color);
    color = process_domain_borders(uv, color);
    color = process_province_borders(uv, color);
    
    // 3. Bordas de reino
    color = process_realm_borders(uv, color);
    
    // 4. Bordas de guerra
    color = process_war_borders(uv, color);
    
    // 5. Bordas especiais (prioridade mais alta)
    color = process_special_borders(uv, color);
    
    return color;
} 