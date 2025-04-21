// Usamos o river_mask declarado em river.gdshaderinc
uniform float river_elevation_adjust = 0.05; // Ajuste de elevação para rios

varying vec2 base_uv;

// void vertex() {
//     base_uv = UV;
    
//     // Ajustar elevação nos rios para garantir que não pareçam afundados
//     float river_value = texture(river_mask, UV).b;
//     if (river_value > 0.1) {
//         // Elevar levemente os vértices onde há rios
//         VERTEX.y += river_elevation_adjust * river_value;
//     }
// }


