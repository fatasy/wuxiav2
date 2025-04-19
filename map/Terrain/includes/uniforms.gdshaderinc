// --- Uniforms para Texturas ---
uniform sampler2D terrain_diffuse; // Textura difusa do terreno base
uniform sampler2D terrain_normalmap; // Normal map do terreno base

// Adicione outras texturas de terreno se necessário (properties, etc.)

// uniform sampler2D rivers_mask : hint_default_black; // Máscara indicando onde estão os rios (branco = rio)

// // Texturas do fundo do rio (de rivers.settings)
// uniform sampler2D river_bottom_diffuse : source_color;
// uniform sampler2D river_bottom_normal : hint_normal;
// uniform sampler2D river_bottom_material; // gloss/properties

// // Texturas da água (de riverwater.settings)
// uniform sampler2D water_color_texture : source_color; // watercolor_rgb_waterspec_a.dds
// uniform sampler2D ambient_normal_texture : hint_normal;
// uniform sampler2D flow_map_texture;
// uniform sampler2D flow_normal_texture : hint_normal;
// uniform sampler2D foam_texture : source_color;
// uniform sampler2D foam_ramp_texture : source_color;
// uniform sampler2D foam_noise_texture : source_color;
// uniform samplerCube sky_cubemap : source_color; // Para reflexos

// // --- Uniforms para Parâmetros (copiar valores dos .settings) ---

// // Parâmetros de rivers.settings
// uniform float flow_normal_uv_scale = 0.4;
// uniform float flow_normal_speed = 0.075;
// // Adicione outros...

// // Parâmetros de riverwater.settings
// uniform vec4 water_color_shallow = vec4(0.1, 0.3, 0.13, 1.0); // Convertido de HSV
// uniform vec4 water_color_deep = vec4(0.05, 0.1, 0.02, 1.0);  // Convertido de HSV
// uniform float water_cubemap_intensity = 0.5;
// uniform float water_gloss_base = 1.15;
// uniform float water_gloss_scale = 0.1;
// uniform float water_specular = 1.0;
// // Ondas
// uniform vec2 wave1_scale = vec2(10.0, 10.0);
// uniform float wave1_rotation = -0.35;
// uniform float wave1_speed = 0.01;
// uniform float wave1_normal_flatten = 1.5;
// // Adicione wave2, wave3, foam, etc...

// varying vec2 base_uv;
// varying vec3 world_pos;
// varying vec3 view_dir;
// varying mat3 normal_basis; // TBN matrix 