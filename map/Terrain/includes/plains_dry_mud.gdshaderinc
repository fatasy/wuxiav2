// Definições para planícies secas e lamacentas (plains_01_dry_mud)
uniform sampler2D plains_dry_mud_diffuse : hint_default_white, filter_linear;
uniform sampler2D plains_dry_mud_normal : hint_normal, filter_linear;
uniform sampler2D plains_dry_mud_properties : hint_default_white, filter_linear;
uniform sampler2D plains_dry_mud_mask : hint_default_black, filter_linear;

// Propriedades das planícies secas e lamacentas
uniform float plains_dry_mud_tiling = 8.0;
uniform float plains_dry_mud_density = 1.0;
uniform float plains_dry_mud_crack_intensity = 0.5;

// Função para processar planícies secas e lamacentas
bool process_plains_dry_mud(vec2 uv, inout vec3 albedo, inout vec3 normal, inout float roughness, inout float metallic, inout float ao) {
    // Amostra da máscara
    float mask = texture(plains_dry_mud_mask, uv).r;
    
    // Se o valor da máscara for muito baixo, não estamos em uma área de planície seca lamacenta
    if (mask < 0.1) return false;
    
    // Coordenadas UV com tiling para as texturas
    vec2 tiled_uv = uv * plains_dry_mud_tiling;
    
    // Não há efeito de vento - a lama seca não se move
    
    // Criar padrão de rachaduras para lama seca
    // Usando a mesma função de ruído que no terrain_base, mas com diferentes parâmetros
    float noise = fract(sin(dot(tiled_uv * 2.0, vec2(12.9898, 78.233))) * 43758.5453);
    float cracks = smoothstep(0.4, 0.6, noise) * plains_dry_mud_crack_intensity;
    
    // Amostra das texturas
    vec3 plains_albedo = texture(plains_dry_mud_diffuse, tiled_uv).rgb;
    vec3 plains_normal_map = texture(plains_dry_mud_normal, tiled_uv).rgb;
    vec4 plains_properties = texture(plains_dry_mud_properties, tiled_uv);
    
    // Extrair propriedades do material
    float plains_roughness = plains_properties.g;
    float plains_metallic = plains_properties.r;
    float plains_ao = plains_properties.b;
    
    // Terreno de lama seca tem rachaduras - afetar propriedades com base no padrão
    plains_roughness = min(plains_roughness + cracks * 0.2, 1.0); // Rachaduras aumentam a rugosidade
    plains_ao = max(plains_ao - cracks * 0.3, 0.0); // Rachaduras aumentam sombras (diminuem AO)
    
    // Fator de mistura baseado na máscara e na densidade configurada
    float blend_factor = mask * plains_dry_mud_density;
    
    // Converter o normal map para espaço tangente (-1 a 1)
    vec3 plains_normal_tangent = normalize(plains_normal_map * 2.0 - 1.0);
    
    // Acentuar o normal map nas áreas de rachaduras
    plains_normal_tangent.xy *= (1.0 + cracks * 0.3);
    plains_normal_tangent = normalize(plains_normal_tangent);
    
    // Misturar com as propriedades do terreno base
    albedo = mix(albedo, plains_albedo, blend_factor);
    normal = normalize(mix(normal, plains_normal_tangent, blend_factor * 0.8));
    roughness = mix(roughness, plains_roughness, blend_factor);
    metallic = mix(metallic, plains_metallic, blend_factor);
    ao = mix(ao, plains_ao, blend_factor);
    
    return true;
} 