// void fragment() {
//     // --- Ler a máscara do rio ---
//     float river_blend = texture(rivers_mask, base_uv).r; // Usar canal vermelho como fator

//     // --- Calcular aparência do Terreno ---
//     vec3 terrain_albedo, terrain_normal_map;
//     process_terrain(base_uv, terrain_albedo, terrain_normal_map);

//     // --- Calcular aparência do Rio ---
//     // Fundo do Rio
//     vec3 bottom_albedo, bottom_normal_map;
//     vec4 bottom_mat;
//     process_river_bottom(base_uv, bottom_albedo, bottom_normal_map, bottom_mat);

//     // Superfície da Água
//     vec3 water_albedo, water_normal_map;
//     float water_roughness, water_metallic;
//     // Usar um vetor normal simples apontando para cima como normal da superfície da água
//     vec3 water_surface_normal = vec3(0.0, 1.0, 0.0);
//     process_water(base_uv, water_surface_normal, water_albedo, water_normal_map, water_roughness, water_metallic);

//     // --- Misturar Terreno e Rio ---
//     ALBEDO = mix(terrain_albedo, water_albedo, river_blend);
//     NORMAL_MAP = normalize(mix(terrain_normal_map, water_normal_map, river_blend));
//     ROUGHNESS = mix(0.5, water_roughness, river_blend); // Exemplo de valor para terreno
//     METALLIC = mix(0.0, water_metallic, river_blend); // Exemplo de valor para terreno
//     // AO, etc.
// } 

