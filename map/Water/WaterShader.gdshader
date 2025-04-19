shader_type spatial;
render_mode blend_mix,depth_draw_opaque,cull_back,diffuse_lambert,specular_schlick_ggx;
uniform vec4 color_shallow : source_color = vec4(0.1, 0.3, 0.5, 0.8);
uniform vec4 color_deep : source_color = vec4(0.05, 0.15, 0.25, 0.9);
uniform float glossiness : hint_range(0.0, 1.0) = 0.9;
uniform float specular_intensity : hint_range(0.0, 1.0) = 0.5;
uniform float fresnel_bias : hint_range(0.0, 1.0) = 0.01;
uniform float fresnel_power : hint_range(0.0, 10.0) = 4.3;
uniform float refraction_scale : hint_range(0.0, 1.0) = 0.1;

// Textura de normal para ondas
uniform sampler2D wave_normal_texture1 : source_color;
uniform sampler2D wave_normal_texture2 : source_color;
uniform sampler2D foam_texture : source_color;
uniform sampler2D noise_texture : source_color;
uniform sampler2D DEPTH_TEXTURE : hint_depth_texture;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture;

// Parâmetros inspirados no CK3
uniform vec2 wave1_scale = vec2(10.0, 10.0);
uniform float wave1_speed = 0.01;
uniform float wave1_direction = -0.35;
uniform float wave1_flatten = 1.5;

uniform vec2 wave2_scale = vec2(2.0, 1.0);
uniform float wave2_speed = 0.016;
uniform float wave2_direction = -1.6;
uniform float wave2_flatten = 1.5;

uniform float foam_scale = 0.3;
uniform float foam_strength = 0.6;
uniform float foam_shore_mask_depth = 0.5;
uniform float foam_shore_mask_sharpness = 5.0;

uniform float time_scale = 1.0;

varying vec3 vertex_pos;
varying vec3 normal_vec;
varying vec3 world_pos;

void vertex() {
    vertex_pos = VERTEX;
    world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    normal_vec = NORMAL;
}

vec2 rotate_uv(vec2 uv, float rotation) {
    float s = sin(rotation);
    float c = cos(rotation);
    return vec2(
        uv.x * c - uv.y * s,
        uv.x * s + uv.y * c
    );
}

void fragment() {



    // Tempo para animação
    float time = TIME * time_scale;

    // Ondas combinadas
    vec2 uv1 = rotate_uv(world_pos.xz * wave1_scale, wave1_direction);
    vec2 uv2 = rotate_uv(world_pos.xz * wave2_scale, wave2_direction);

    // Amostras de mapas normais com animação
    vec2 offset1 = vec2(time * wave1_speed, time * wave1_speed * 0.8);
    vec2 offset2 = vec2(time * wave2_speed * 1.2, time * wave2_speed);

    vec3 normal1 = texture(wave_normal_texture1, uv1 + offset1).rgb;
    vec3 normal2 = texture(wave_normal_texture2, uv2 + offset2).rgb;

    // Calcular normal combinada
    vec3 normal_blend = mix(normal1, normal2, 0.5);
    normal_blend = normalize(mix(vec3(0.0, 0.0, 1.0), normal_blend * 2.0 - 1.0, 1.0 / wave1_flatten));

    // Efeito de profundidade
    float depth = texture(DEPTH_TEXTURE, SCREEN_UV).r;
    vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth);
    vec4 world = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
    world.xyz /= world.w;
    float depth_diff = world_pos.y - world.y;
    float water_depth = clamp(depth_diff / 5.0, 0.0, 1.0);

    // Cor da água baseada na profundidade
    vec4 water_color = mix(color_shallow, color_deep, water_depth);

    // Espuma nas bordas
    float foam_noise = texture(noise_texture, world_pos.xz * foam_scale + vec2(time * 0.02)).r;
    float shore_mask = 1.0 - clamp((depth_diff - foam_shore_mask_depth) * foam_shore_mask_sharpness, 0.0, 1.0);
    float foam = texture(foam_texture, world_pos.xz * foam_scale + vec2(time * 0.03)).r;
    foam = clamp(foam * shore_mask * foam_strength + foam_noise * 0.2, 0.0, 1.0) * shore_mask;

    // Cálculo de Fresnel
    vec3 view_dir = normalize(CAMERA_POSITION_WORLD - world_pos);
    float fresnel = fresnel_bias + (1.0 - fresnel_bias) * pow(1.0 - dot(view_dir, normal_vec), fresnel_power);

    // Refração
    vec2 refraction_offset = normal_blend.xy * refraction_scale * (1.0 - water_depth);
    vec2 refraction_uv = SCREEN_UV + refraction_offset;
    vec4 refraction_color = texture(SCREEN_TEXTURE, refraction_uv);

    // Cor final
    ALBEDO = mix(refraction_color.rgb * water_color.rgb, water_color.rgb, water_color.a);
    ALBEDO = mix(ALBEDO, vec3(1.0), foam);

    // Propriedades de material
    SPECULAR = specular_intensity;
    ROUGHNESS = 1.0 - glossiness;
    NORMAL_MAP = normal_blend;

    // Transparência
    ALPHA = mix(water_color.a, 1.0, foam);
}