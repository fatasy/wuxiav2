using Godot;

namespace Wuxia
{
    [Tool]
    public partial class WaterManager : MeshInstance3D
    {
        [Export] private ShaderMaterial waterMaterial;

        // Propriedades baseadas no arquivo CK3
        [Export(PropertyHint.ColorNoAlpha)] private Color waterColorShallow = new(0.134f, 0.18f, 0.3f);
        [Export(PropertyHint.ColorNoAlpha)] private Color waterColorDeep = new(0.022f, 0.11f, 0.2f);
        [Export] private float waterGlossBase = 1.15f;
        [Export] private float waterSpecular = 1.0f;
        [Export] private float waterFoamScale = 0.3f;
        [Export] private float waterFoamStrength = 0.6f;
        [Export] private float waterFresnelBias = 0.01f;
        [Export] private float waterFresnelPow = 4.3f;
        [Export] private float waterRefractionScale = 0.1f;

        [Export] private Vector2 waterWave1Scale = new(10.0f, 10.0f);
        [Export] private float waterWave1Rotation = -0.35f;
        [Export] private float waterWave1Speed = 0.01f;
        [Export] private float waterWave1NormalFlatten = 1.5f;

        [Export] private Vector2 waterWave2Scale = new(2.0f, 1.0f);
        [Export] private float waterWave2Rotation = -1.6f;
        [Export] private float waterWave2Speed = 0.016f;
        [Export] private float waterWave2NormalFlatten = 1.5f;

        public override void _Ready()
        {
            if (waterMaterial == null)
            {
                GD.PrintErr("WaterManager: Material não configurado!");
                return;
            }



            // Configura o material
            Mesh = new PlaneMesh();

            MaterialOverride = waterMaterial;

            ApplyWaterSettings();
        }

        private void ApplyWaterSettings()
        {
            // Aplicar todas as configurações do arquivo CK3 ao shader
            waterMaterial.SetShaderParameter("color_shallow", new Vector4(waterColorShallow.R, waterColorShallow.G, waterColorShallow.B, 0.8f));
            waterMaterial.SetShaderParameter("color_deep", new Vector4(waterColorDeep.R, waterColorDeep.G, waterColorDeep.B, 0.9f));
            waterMaterial.SetShaderParameter("glossiness", Mathf.Clamp(waterGlossBase / 1.5f, 0, 1));
            waterMaterial.SetShaderParameter("specular_intensity", waterSpecular);
            waterMaterial.SetShaderParameter("fresnel_bias", waterFresnelBias);
            waterMaterial.SetShaderParameter("fresnel_power", waterFresnelPow);
            waterMaterial.SetShaderParameter("refraction_scale", waterRefractionScale);

            // Configurações de ondas
            waterMaterial.SetShaderParameter("wave1_scale", waterWave1Scale);
            waterMaterial.SetShaderParameter("wave1_speed", waterWave1Speed);
            waterMaterial.SetShaderParameter("wave1_direction", waterWave1Rotation);
            waterMaterial.SetShaderParameter("wave1_flatten", waterWave1NormalFlatten);

            waterMaterial.SetShaderParameter("wave2_scale", waterWave2Scale);
            waterMaterial.SetShaderParameter("wave2_speed", waterWave2Speed);
            waterMaterial.SetShaderParameter("wave2_direction", waterWave2Rotation);
            waterMaterial.SetShaderParameter("wave2_flatten", waterWave2NormalFlatten);

            // Configurações de espuma
            waterMaterial.SetShaderParameter("foam_scale", waterFoamScale);
            waterMaterial.SetShaderParameter("foam_strength", waterFoamStrength);
        }

        // Método para ajustar configurações em tempo real (útil para debug)
        public void UpdateWaterSettings(
            Color? shallowColor = null,
            Color? deepColor = null,
            float? foamScale = null,
            float? refractionScale = null)
        {
            if (shallowColor.HasValue)
            {
                waterColorShallow = shallowColor.Value;
            }

            if (deepColor.HasValue)
            {
                waterColorDeep = deepColor.Value;
            }

            if (foamScale.HasValue)
            {
                waterFoamScale = foamScale.Value;
            }

            if (refractionScale.HasValue)
            {
                waterRefractionScale = refractionScale.Value;
            }

            ApplyWaterSettings();
        }
    }
}