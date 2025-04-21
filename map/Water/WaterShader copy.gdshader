shader_type spatial;
render_mode blend_mix, cull_back, depth_prepass_alpha, unshaded;

// ----------------------------
// 🎨 Configuração de Cores
// ----------------------------
uniform vec4 color_shallow : source_color = vec4(0.0, 0.5, 1.0, 0.8);
uniform vec4 color_deep : source_color = vec4(0.0, 0.3, 0.6, 0.8);
uniform vec4 color_map_tint : source_color = vec4(0.0, 0.4, 0.8, 1.0);
uniform float color_map_tint_start_height = 10.0;
uniform float color_map_tint_end_height = 100.0;
uniform float color_map_tint_alpha = 0.5;

// ----------------------------
// 🌊 Configuração da Espuma
// ----------------------------
uniform sampler2D foam_noise_texture : hint_default_white;
uniform float foam_noise_scale = 0.1;
uniform float foam_noise_speed = 0.15;
uniform float foam_shore_mask_depth = 0.5;
uniform float foam_shore_mask_sharpness = 5.0;
uniform float foam_strength = 1.0;

// ----------------------------
// 🌫️ Transparência (See-Through)
// ----------------------------
uniform float see_through_density = 1.0;
uniform float see_through_shore_mask_depth = 1.0;
uniform float see_through_shore_mask_sharpness = 1.0;
uniform float see_through_density_angle_offset = 0.5;

// ----------------------------
// 🌊 Configuração de Ondas / Normais
// ----------------------------
uniform sampler2D ambient_normal_texture : hint_normal;
uniform float global_normal_strength = 1.0;

uniform float wave1_scale = 1.0;
uniform float wave1_speed = 0.4;
uniform float wave1_rotation = 0.0;

uniform float wave2_scale = 1.0;
uniform float wave2_speed = 0.5;
uniform float wave2_rotation = 1.0;

uniform float wave3_scale = 1.0;
uniform float wave3_speed = 0.3;
uniform float wave3_rotation = -1.0;

// ---------------------------
// 🏄 Animação da Superfície
// ---------------------------
uniform float wave_height = 0.15;
uniform float wave_speed = 1.0;
uniform float wave_time_scale = 1.0;

// Novas configurações para distorção
uniform float uv_distortion_strength = 0.02;
uniform float specular_strength = 0.4;

uniform sampler2D DEPTH_TEXTURE : hint_depth_texture, filter_linear_mipmap;

// Matriz de projeção (deve ser atualizada pelo código C#)
uniform mat4 u_projection_matrix;
uniform mat4 u_inv_projection_matrix;
uniform float water_height = 0.0;

// ----------------------------
// 🛠️ Funções Utilitárias
// ----------------------------

/// Máscara de proximidade à costa (usada para espuma e transparência)
float shoreline_mask(float depth, float mask_depth, float sharpness) {
    return 1.0 - clamp((depth - mask_depth) * sharpness, 0.0, 1.0);
}

/// Conversão de normal codificada RGB para espaço normal
vec3 decode_normal(vec3 color) {
    return normalize(color * 2.0 - 1.0);
}

/// Rotaciona UVs para simular movimento ondulatório
vec2 rotate_uv(vec2 uv, float angle) {
    float cos_a = cos(angle);
    float sin_a = sin(angle);
    return vec2(
        uv.x * cos_a - uv.y * sin_a,
        uv.x * sin_a + uv.y * cos_a
    );
}

/// Calcula a diferença de profundidade entre o mundo e a textura de profundidade da câmera
float compute_depth_diff(vec3 world_pos, vec2 screen_uv) {
    // Método simplificado para estimar a profundidade
    float depth_sample = texture(DEPTH_TEXTURE, screen_uv).r;
    
    // Ajuste para cenas do Godot 4.4 (estimativa de profundidade)
    // Quanto mais próximo de 1.0, mais longe está o objeto
    float linear_depth = depth_sample;
    
    // Aproximação da distância até a superfície
    // water_height deve ser definido no script C# como a altura real da água
    float scene_depth = mix(0.1, 20.0, 1.0 - linear_depth);
    
    return clamp(scene_depth, 0.0, 10.0);
}

/// Combina três normais animadas para simular ondas dinâmicas
vec3 get_combined_normal(vec2 world_xz, float time) {
    vec2 uv1 = rotate_uv(world_xz * wave1_scale, wave1_rotation) + time * wave1_speed;
    vec2 uv2 = rotate_uv(world_xz * wave2_scale, wave2_rotation) + time * wave2_speed;
    vec2 uv3 = rotate_uv(world_xz * wave3_scale, wave3_rotation) + time * wave3_speed;

    vec3 n1 = decode_normal(texture(ambient_normal_texture, uv1).rgb);
    vec3 n2 = decode_normal(texture(ambient_normal_texture, uv2).rgb);
    vec3 n3 = decode_normal(texture(ambient_normal_texture, uv3).rgb);

    return normalize((n1 + n2 + n3) * global_normal_strength);
}

/// Determina a cor da água com base na profundidade e distância da câmera
vec4 get_water_color(float depth_diff, float camera_distance, float time) {
    // Adicionar uma sutil variação de profundidade baseada no tempo
    float time_factor = sin(time * 0.2) * 0.05;
    float water_depth = clamp(depth_diff * see_through_density + time_factor, 0.0, 1.0);
    
    float shore_mask = shoreline_mask(depth_diff, see_through_shore_mask_depth, see_through_shore_mask_sharpness);
    water_depth = mix(water_depth, 1.0, shore_mask * see_through_density_angle_offset);
    vec4 base_color = mix(color_shallow, color_deep, water_depth);

    float tint_factor = smoothstep(color_map_tint_start_height, color_map_tint_end_height, camera_distance) * color_map_tint_alpha;
    return mix(base_color, color_map_tint, tint_factor);
}

/// Gera a espuma na superfície da água com base no ruído e proximidade da costa
float compute_foam(vec2 world_xz, float depth_diff, float time) {
    // Duas camadas de espuma com velocidades diferentes para mais movimento
    vec2 foam_uv1 = world_xz * foam_noise_scale + time * foam_noise_speed;
    vec2 foam_uv2 = world_xz * (foam_noise_scale * 1.3) - time * (foam_noise_speed * 0.8);
    
    float noise1 = texture(foam_noise_texture, foam_uv1).r;
    float noise2 = texture(foam_noise_texture, foam_uv2).r;
    float noise = mix(noise1, noise2, 0.5);
    
    float foam_mask = shoreline_mask(depth_diff, foam_shore_mask_depth, foam_shore_mask_sharpness);
    return clamp(noise * foam_mask * foam_strength, 0.0, 1.0);
}

/// Calcula a altura da onda para o deslocamento vertical
float wave_height_at(vec2 position, float time) {
    // Ondas senoidais com diferentes frequências
    float wave1 = sin(position.x * 0.1 + time * 0.5) * 0.5;
    float wave2 = sin(position.y * 0.15 + time * 0.7) * 0.25;
    float wave3 = sin(position.x * 0.06 + position.y * 0.1 + time * 0.3) * 0.25;
    
    return (wave1 + wave2 + wave3) * wave_height;
}

// ----------------------------
// 💧 Shader Principal
// ----------------------------
void vertex() {
    // Aplicar deslocamento vertical nas ondas
    float time = TIME * wave_time_scale * wave_speed;
    float height = wave_height_at(VERTEX.xz, time);
    VERTEX.y += height;
    
    // Atualizar normais baseado na inclinação da onda
    float height_dx = wave_height_at(VERTEX.xz + vec2(0.1, 0.0), time) - height;
    float height_dz = wave_height_at(VERTEX.xz + vec2(0.0, 0.1), time) - height;
    NORMAL = normalize(vec3(-height_dx * 5.0, 1.0, -height_dz * 5.0));
}

void fragment() {
    vec3 world_pos = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
    float camera_distance = length(world_pos);
    float time = TIME * wave_time_scale * wave_speed;

    // Normais dinâmicas das ondas
    vec3 wave_normal = get_combined_normal(world_pos.xz, time);
    NORMAL = normalize(mix(NORMAL, wave_normal, 0.8)); // Misturar com a normal de vertex
    
    // Adicionar distorção sutil à UV baseada no tempo
    vec2 screen_uv = SCREEN_UV;
    screen_uv += wave_normal.xz * uv_distortion_strength; 
    
    // Cálculo da profundidade real
    float depth_diff = compute_depth_diff(world_pos, screen_uv);

    // Cor base da água
    vec4 water_color = get_water_color(depth_diff, camera_distance, time);

    // Espuma
    float foam = compute_foam(world_pos.xz, depth_diff, time);
    
    // Adicionar reflexos animados baseados no tempo e posição
    float specular = pow(max(0.0, dot(normalize(vec3(0.3, 0.6, 0.3)), wave_normal)), 20.0);
    specular *= specular_strength * (0.8 + 0.2 * sin(time * 1.5));

    // Cor final
    ALBEDO = water_color.rgb + foam + specular;
    ALPHA = water_color.a;
    
    // Adicionar valores de materiais para renderização física
    ROUGHNESS = 0.1 - foam * 0.05;
    METALLIC = 0.5;
    SPECULAR = 0.5 + 0.2 * foam;
}