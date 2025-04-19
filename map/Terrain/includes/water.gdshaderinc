// Texturas para água
uniform sampler2D water_color : hint_default_white;
uniform sampler2D ambient_normal : hint_default_white;
uniform sampler2D flow_map : hint_default_black;
uniform sampler2D flow_normal : hint_default_white;
uniform sampler2D foam : hint_default_white;
uniform sampler2D foam_ramp : hint_default_white;
uniform sampler2D foam_map : hint_default_white;
uniform sampler2D foam_noise : hint_default_white;

// Configurações da água do rio
uniform vec3 water_color_shallow : source_color = vec3(0.134, 0.16, 0.22);
uniform vec3 water_color_deep : source_color = vec3(0.02, 0.03, 0.06);
uniform float water_cubemap_intensity = 0.5;
uniform float water_gloss_base = 1.15;
uniform float water_gloss_scale = 0.1;
uniform float water_specular = 1.0;
uniform float water_foam_scale = 0.3;
uniform float water_foam_distort_factor = 0.1;
uniform float water_foam_strength = 0.6;
uniform float water_fresnel_bias = 0.01;
uniform float water_fresnel_pow = 4.3;
uniform float water_refraction_scale = 500.0;
uniform float water_normal_strength = 0.5;

// Configurações das ondas
uniform vec2 water_wave1_scale = vec2(10.0, 10.0);
uniform float water_wave1_rotation = -0.35;
uniform float water_wave1_speed = 0.01;
uniform float water_wave1_flatten = 1.5;

uniform vec2 water_wave2_scale = vec2(2.0, 1.0);
uniform float water_wave2_rotation = -1.6;
uniform float water_wave2_speed = 0.016;
uniform float water_wave2_flatten = 1.5;

uniform vec2 water_wave3_scale = vec2(0.2, 0.1);
uniform float water_wave3_rotation = 1.73;
uniform float water_wave3_speed = 0.005;
uniform float water_wave3_flatten = 1.5;

uniform float water_flow_speed = 0.005;
uniform float water_flow_normal_scale = 0.025;

// Configurações de fluxo de água compartilhadas (para rios e praias)
uniform float flow_normal_uv_scale = 0.4;
uniform float flow_normal_speed = 0.075;
uniform float foam_factor_near = 0.5;
uniform float foam_factor_far = 1.0;
uniform float noise_scale = 0.25;
uniform float noise_speed = 2.0;

// Função para rotacionar UV
vec2 rotate_uv(vec2 uv, float rotation) {
    float s = sin(rotation);
    float c = cos(rotation);
    return vec2(
        uv.x * c - uv.y * s,
        uv.x * s + uv.y * c
    );
}

// Função para calcular as normais das ondas
vec3 calculate_wave_normal(vec2 uv, float time, vec2 scale, float rotation, float speed, float flatten) {
    vec2 rotated_uv = rotate_uv(uv * scale, rotation);
    vec2 flow_uv = rotated_uv + vec2(time * speed, 0.0);
    vec3 normal = texture(ambient_normal, flow_uv).rgb * 2.0 - 1.0;
    normal.z /= flatten;
    return normalize(normal);
}

// Função para calcular o fluxo de água (útil para rios e praias)
vec2 calculate_water_flow(vec2 uv, float time) {
    // Direção do fluxo da água
    vec2 flow_direction = texture(flow_map, uv).rg * 2.0 - 1.0;
    
    // Animar fluxo
    return uv + flow_direction * time * water_flow_speed;
}

// Função para calcular as normais combinadas das ondas de água
vec3 calculate_combined_water_normal(vec2 uv, float time) {
    // Combinar ondas normais
    vec3 wave1 = calculate_wave_normal(uv, time, water_wave1_scale, water_wave1_rotation, water_wave1_speed, water_wave1_flatten);
    vec3 wave2 = calculate_wave_normal(uv, time, water_wave2_scale, water_wave2_rotation, water_wave2_speed, water_wave2_flatten);
    vec3 wave3 = calculate_wave_normal(uv, time, water_wave3_scale, water_wave3_rotation, water_wave3_speed, water_wave3_flatten);
    
    // Calcular normal da água
    return normalize(wave1 + wave2 + wave3);
}

// Função para calcular espuma da água
float calculate_water_foam(vec2 uv, vec3 normal, float water_edge_factor, float time) {
    // Direção do fluxo da água
    vec2 flow_direction = texture(flow_map, uv).rg * 2.0 - 1.0;
    
    // Distorcer UVs para efeito de movimento
    vec2 distorted_uv = uv + normal.xy * 0.02;
    
    // Adicionar espuma nas bordas
    float foam_mask = water_edge_factor;
    foam_mask = smoothstep(0.0, 0.3, foam_mask);
    
    vec2 foam_uv = distorted_uv * water_foam_scale + flow_direction * time * 0.05;
    float foam_pattern = texture(foam, foam_uv).r;
    
    return foam_mask * foam_pattern * water_foam_strength;
}