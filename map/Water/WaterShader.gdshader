shader_type spatial;
// Ativar processamento de profundidade para efeitos de água
render_mode depth_prepass_alpha;

// Cores da água
uniform vec4 color_shallow : source_color = vec4(0.0, 0.5, 1.0, 0.8); // Convertido de HSV { 0.600 0.3 0.134375 }
uniform vec4 color_deep : source_color = vec4(0.0, 0.3, 0.6, 0.8); // Convertido de HSV { 0.55 0.2 0.022031 }
uniform vec4 color_map_tint : source_color = vec4(0.0, 0.4, 0.8, 1.0); // HSV { 0.0 0.0 0.0 }
uniform float color_map_tint_alpha = 1.0;
uniform float color_map_tint_start_height = 10.0;
uniform float color_map_tint_end_height = 100.0;
uniform float diffuse_multiplier = 0.0;

// Propriedades de material
uniform float glossiness_base = 1.15;
uniform float glossiness_scale = 0.1;
uniform float zoomed_out_gloss_scale_offset = 0.1;
uniform float specular_intensity = 1.0;
uniform float specular_factor = 0.01;

// Texturas
uniform sampler2D water_color_texture : source_color;
uniform sampler2D ambient_normal_texture : source_color;
uniform sampler2D flow_map_texture : source_color;
uniform sampler2D flow_normal_texture : source_color;
uniform samplerCube cube_map_texture : source_color;
uniform sampler2D foam_texture : source_color;
uniform sampler2D foam_ramp_texture : source_color;
uniform sampler2D foam_map_texture : source_color;
uniform sampler2D foam_noise_texture : source_color;

// Texturas do sistema
uniform sampler2D DEPTH_TEXTURE : hint_depth_texture;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture;

// Cubemap
uniform float cubemap_intensity = 0.5;

// Configurações de espuma
uniform float foam_scale = 0.3;
uniform float foam_distort_factor = 0.1;
uniform float foam_shore_mask_depth = 0.0;
uniform float foam_shore_mask_sharpness = 1.0;
uniform float foam_noise_scale = 0.005;
uniform float foam_noise_speed = 0.025;
uniform float foam_strength = 0.6;

// Alturas de zoom
uniform float zoomed_in_height = 100.0;
uniform float zoomed_out_height = 750.0;

// Fresnel
uniform float fresnel_bias = 0.01;
uniform float zoomed_out_fresnel_bias_offset = 0.15;
uniform float fresnel_power = 4.3;
uniform float zoomed_out_fresnel_power_offset = -2.0;
uniform float reflection_flatten = 3.0;

// Refração
uniform float refraction_shore_mask_depth = 3.0;
uniform float refraction_shore_mask_sharpness = 1.0;
uniform float refraction_fade_start = 100.0;
uniform float refraction_fade_end = 500.0;
uniform float refraction_scale = 500.0;

// Configurações de ondas
uniform float wave_flatness = 1.5;

// Wave 1
uniform vec2 wave1_scale = vec2(10.0, 10.0);
uniform float wave1_rotation = -0.35;
uniform float wave1_speed = 0.01;
uniform float wave1_normal_flatten = 1.5;

// Wave 2
uniform vec2 wave2_scale = vec2(2.0, 1.0);
uniform float wave2_rotation = -1.6;
uniform float wave2_speed = 0.016;
uniform float wave2_normal_flatten = 1.5;

// Wave 3 (nova)
uniform vec2 wave3_scale = vec2(0.2, 0.1);
uniform float wave3_rotation = 1.725075;
uniform float wave3_speed = 0.005;
uniform float wave3_normal_flatten = 1.5;

// Fluxo de água
uniform float flow_speed = 0.005;
uniform float zoomed_out_flow_speed_offset = 0.03;
uniform float flow_normal_scale = 0.025;
uniform float flow_normal_flatten = 1.5;

// Visibilidade da costa
uniform float fade_shore_mask_depth = 0.5;
uniform float fade_shore_mask_sharpness = 5.0;
uniform float see_through_density = 0.8;
uniform float see_through_density_angle_offset = 0.0;
uniform float see_through_shore_mask_depth = 20.0;
uniform float see_through_shore_mask_sharpness = 1.0;

// Escala de tempo para animações
uniform float time_scale = 1.0;

varying vec3 vertex_pos;
varying vec3 normal_vec;
varying vec3 world_pos;
varying float camera_distance;

void vertex() {
    vertex_pos = VERTEX;
    world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    normal_vec = NORMAL;
    
    // Calcula distância da câmera para efeitos de zoom - usando cálculo mais suave
    camera_distance = length(CAMERA_POSITION_WORLD - world_pos);
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
    
    // Fator de zoom para ajustes baseados na distância da câmera - transição mais gradual
    // Removendo linhas abruptas usando uma curva cúbica suave
    float zoom_distance = clamp((camera_distance - zoomed_in_height) / (zoomed_out_height - zoomed_in_height), 0.0, 1.0);
    float zoom_factor = zoom_distance * zoom_distance * (3.0 - 2.0 * zoom_distance); // Interpolação Hermite
    
    // Ondas combinadas - agora com 3 camadas
    vec2 uv1 = rotate_uv(world_pos.xz * wave1_scale, wave1_rotation);
    vec2 uv2 = rotate_uv(world_pos.xz * wave2_scale, wave2_rotation);
    vec2 uv3 = rotate_uv(world_pos.xz * wave3_scale, wave3_rotation);
    
    // Amostras de mapas normais com animação
    vec2 offset1 = vec2(time * wave1_speed, time * wave1_speed * 0.8);
    vec2 offset2 = vec2(time * wave2_speed * 1.2, time * wave2_speed);
    vec2 offset3 = vec2(time * wave3_speed * 0.7, time * wave3_speed * 1.3);
    
    vec3 normal1 = texture(ambient_normal_texture, uv1 + offset1).rgb;
    vec3 normal2 = texture(ambient_normal_texture, uv2 + offset2).rgb;
    vec3 normal3 = texture(ambient_normal_texture, uv3 + offset3).rgb;
    
    // Calcular normal combinada das três camadas - usando smoothstep para suavizar transições
    vec3 normal_blend = mix(normal1, normal2, 0.5);
    normal_blend = mix(normal_blend, normal3, 0.3);
    normal_blend = normalize(mix(vec3(0.0, 0.0, 1.0), normal_blend * 2.0 - 1.0, 1.0 / wave_flatness));
    
    // Fluxo de água - suavizar a transição do fluxo baseado no zoom
    float flow_speed_adjusted = flow_speed + smoothstep(0.0, 1.0, zoom_factor) * zoomed_out_flow_speed_offset;
    vec2 flow_uv = world_pos.xz * flow_normal_scale;
    vec2 flow_offset = vec2(time * flow_speed_adjusted);
    vec3 flow_normal = texture(flow_normal_texture, flow_uv + flow_offset).rgb;
    flow_normal = normalize(mix(vec3(0.0, 0.0, 1.0), flow_normal * 2.0 - 1.0, 1.0 / flow_normal_flatten));
    
    // Combinar normais ambientes com normais de fluxo - transição mais suave
    normal_blend = normalize(mix(normal_blend, flow_normal, 0.3));
    
    // Efeito de profundidade
    float depth = texture(DEPTH_TEXTURE, UV).r;
    vec3 ndc = vec3(UV * 2.0 - 1.0, depth);
    vec4 world = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
    world.xyz /= world.w;
    float depth_diff = world_pos.y - world.y;
    
    // Para evitar divisões visíveis relacionadas à distância da câmera,
    // aplicamos um filtro de anti-aliasing nas transições baseadas em distância
    float depth_transition = mix(depth_diff, smoothstep(0.0, 3.0, depth_diff), 0.7);
    
    // Atualizando as máscaras baseadas em profundidade para usar a transição suavizada
    float shore_mask = 1.0 - smoothstep(fade_shore_mask_depth, fade_shore_mask_depth + (2.0/fade_shore_mask_sharpness), depth_transition);
    float see_through_shore_mask = 1.0 - smoothstep(see_through_shore_mask_depth, see_through_shore_mask_depth + (2.0/see_through_shore_mask_sharpness), depth_transition);
    float foam_shore = 1.0 - smoothstep(foam_shore_mask_depth, foam_shore_mask_depth + (2.0/foam_shore_mask_sharpness), depth_transition);
    float refraction_shore = 1.0 - smoothstep(refraction_shore_mask_depth, refraction_shore_mask_depth + (2.0/refraction_shore_mask_sharpness), depth_transition);
    
    // Cor da água baseada na profundidade - criando uma transição mais suave
    float water_depth = smoothstep(0.0, 2.0/see_through_density, depth_transition);
    water_depth = mix(water_depth, 1.0, see_through_shore_mask * see_through_density_angle_offset);
    
    // Cor da água baseada na profundidade
    vec4 water_color = mix(color_shallow, color_deep, water_depth);
    
    // Adicionar tinta do mapa se estiver no modo de zoom
    float map_tint_factor = smoothstep(color_map_tint_start_height, color_map_tint_end_height, camera_distance) * color_map_tint_alpha;
    water_color = mix(water_color, color_map_tint, map_tint_factor);
    
    // Espuma nas bordas - suavizando a transição
    float foam_noise_value = texture(foam_noise_texture, world_pos.xz * foam_noise_scale + vec2(time * foam_noise_speed)).r;
    
    vec2 foam_uv = world_pos.xz * foam_scale;
    foam_uv += normal_blend.xy * foam_distort_factor;
    float foam_value = texture(foam_texture, foam_uv + vec2(time * 0.03)).r;
    float foam_map_value = texture(foam_map_texture, world_pos.xz * foam_scale * 0.1).r;
    
    float foam = smoothstep(0.0, 1.0, foam_value * foam_shore * foam_strength + foam_noise_value * 0.2) * foam_shore;
    foam = mix(foam, foam * foam_map_value, 0.5);
    
    // Fresnel para reflexões - transição suavizada
    vec3 view_dir = normalize(CAMERA_POSITION_WORLD - world_pos);
    float fresnel_bias_adjusted = fresnel_bias + smoothstep(0.0, 1.0, zoom_factor) * zoomed_out_fresnel_bias_offset;
    float fresnel_power_adjusted = fresnel_power + smoothstep(0.0, 1.0, zoom_factor) * zoomed_out_fresnel_power_offset;
    float fresnel = fresnel_bias_adjusted + (1.0 - fresnel_bias_adjusted) * pow(1.0 - dot(view_dir, vec3(0.0, 1.0, 0.0)), fresnel_power_adjusted);
    
    // Reduzir a influência do Fresnel na aparência final
    fresnel *= 0.7;
    
    // Refração - usando uma transição mais gradual baseada em distância
    // Evitando descontinuidades no cálculo da refração
    float refraction_blend = smoothstep(refraction_fade_end * 0.95, refraction_fade_start * 1.05, camera_distance);
    float refraction_factor = mix(0.0, 1.0, refraction_blend);
    
    vec2 refraction_offset = normal_blend.xy * refraction_scale * refraction_factor * (1.0 - refraction_shore) / 1000.0;
    vec2 refraction_uv = UV + refraction_offset;
    vec4 refraction_color = texture(SCREEN_TEXTURE, refraction_uv);
    
    // Reflexão do cubemap
    vec3 reflect_dir = reflect(-view_dir, mix(normal_vec, vec3(normal_blend.x, normal_blend.z, normal_blend.y), 1.0 / reflection_flatten));
    vec4 reflection_color = texture(cube_map_texture, reflect_dir);
    
    // Glossiness ajustada com zoom - suavizando a transição
    float adjusted_glossiness = glossiness_base + (smoothstep(0.0, 1.0, zoom_factor) * zoomed_out_gloss_scale_offset);
    
    // Cor final
    vec3 final_color = mix(refraction_color.rgb * water_color.rgb, water_color.rgb, water_color.a);
    // Reduzir a influência da reflexão
    float reflection_influence = fresnel * water_color.a * 0.6;
    final_color = mix(final_color, reflection_color.rgb * cubemap_intensity, reflection_influence);
    final_color = mix(final_color, vec3(1.0), foam);
    
    // Propriedades de material
    ALBEDO = final_color;
    SPECULAR = specular_intensity * specular_factor;
    ROUGHNESS = 1.0 - clamp(adjusted_glossiness * glossiness_scale, 0.0, 1.0);
    NORMAL_MAP = normal_blend;
    
    // Transparência - suavizando a transição final
    ALPHA = mix(mix(water_color.a, 1.0, fresnel), 1.0, foam);
}