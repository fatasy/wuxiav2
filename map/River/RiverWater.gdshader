shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_lambert, specular_schlick_ggx;

// Texturas do fundo do rio
uniform sampler2D river_bottom_diffuse : source_color;
uniform sampler2D river_bottom_normal : hint_normal;
uniform sampler2D river_bottom_material;

// Texturas da água
uniform sampler2D water_color_texture : source_color;
uniform sampler2D ambient_normal_texture : hint_normal;
uniform sampler2D flow_normal_texture : hint_normal;
uniform sampler2D foam_texture : source_color;
uniform sampler2D foam_noise_texture : source_color;

// Parâmetros do rio
uniform float flow_normal_speed = 0.075;
uniform float depth = 0.15;
uniform float foam_factor = 0.5;

// Cores da água
uniform vec4 water_color_shallow : source_color = vec4(0.1, 0.3, 0.13, 1.0);
uniform vec4 water_color_deep : source_color = vec4(0.05, 0.1, 0.02, 1.0);

// Parâmetros de ondas
uniform vec2 wave1_scale = vec2(10.0, 10.0);
uniform float wave1_speed = 0.01;
uniform float wave1_rotation = -0.35;

varying vec2 uv_ripple;
varying vec3 world_pos;

void vertex() {
    world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

    // Computar UVs para as ondas
    uv_ripple = UV * wave1_scale;
    float angle = wave1_rotation;
    vec2 dir = vec2(cos(angle), sin(angle));
    uv_ripple += TIME * wave1_speed * dir;
}

// Função de rotação UV
vec2 rotateUV(vec2 uv, float rotation) {
    float c = cos(rotation);
    float s = sin(rotation);
    return vec2(uv.x * c - uv.y * s, uv.x * s + uv.y * c);
}

void fragment() {
    // Cor base do fundo do rio
    vec3 bottom_color = texture(river_bottom_diffuse, UV).rgb;
    vec3 bottom_normal = texture(river_bottom_normal, UV).rgb * 2.0 - 1.0;
    vec4 bottom_mat = texture(river_bottom_material, UV);

    // Normais da água (ondas)
    vec3 water_normal = texture(ambient_normal_texture, uv_ripple).rgb * 2.0 - 1.0;

    // Cálculo de ondas de fluxo
    vec2 flow_uv = UV + TIME * flow_normal_speed;
    vec3 flow_normal = texture(flow_normal_texture, flow_uv).rgb * 2.0 - 1.0;

    // Combinar normais
    vec3 final_normal = normalize(water_normal + flow_normal * 0.5);

    // Calcular fator de profundidade/visualização
    float view_angle = 1.0 - abs(dot(normalize(VIEW), normalize(NORMAL)));

    // Misturar cores da água baseado no ângulo de visão
    vec3 water_color = mix(water_color_shallow.rgb, water_color_deep.rgb, view_angle);

    // Adicionar espuma nas bordas
    float foam_visibility = texture(foam_noise_texture, UV * 0.3 + TIME * 0.02).r * foam_factor;
    vec3 foam = texture(foam_texture, UV * 0.3 + final_normal.xy * 0.1).rgb * foam_visibility;

    // Cor final com efeito de refração simples
    vec3 refracted_bottom = bottom_color + final_normal * 0.02;
    vec3 final_color = mix(refracted_bottom, water_color, 0.7) + foam;

    // Saída
    ALBEDO = final_color;
    NORMAL_MAP = final_normal * 0.5 + 0.5;
    ROUGHNESS = 0.1;
    SPECULAR = 0.5;
    METALLIC = 0.0;
}