using Godot;

public partial class RiverTextureLoader : Node
{
    [Export] public MeshInstance3D terrainMesh;

    [Export] public string riverMaskPath = "res://assets/map/rivers/river_mask.png";
    [Export] public string riverBottomDiffusePath = "res://assets/map/rivers/river_bottom_diffuse.png";
    [Export] public string riverBottomNormalPath = "res://assets/map/rivers/river_bottom_normal.png";
    [Export] public string riverBottomGlossPath = "res://assets/map/rivers/river_bottom_gloss.png";

    [Export] public string waterColorPath = "res://assets/map/water/watercolor_rgb_waterspec_a.png";
    [Export] public string ambientNormalPath = "res://assets/map/water/ambient_normal.png";
    [Export] public string flowMapPath = "res://assets/map/water/flowmap.png";
    [Export] public string flowNormalPath = "res://assets/map/water/flow_normal.png";
    [Export] public string foamPath = "res://assets/map/water/foam.png";
    [Export] public string foamRampPath = "res://assets/map/water/foam_ramp.png";
    [Export] public string foamMapPath = "res://assets/map/water/foam_map.png";
    [Export] public string foamNoisePath = "res://assets/map/water/foam_noise.png";

    public override void _Ready()
    {
        if (terrainMesh == null)
        {
            GD.PrintErr("Terrain mesh não atribuído ao RiverTextureLoader!");
            return;
        }

        ShaderMaterial material = terrainMesh.GetActiveMaterial(0) as ShaderMaterial;
        if (material == null)
        {
            GD.PrintErr("O material do terreno não é um ShaderMaterial!");
            return;
        }

        // Carrega as texturas dos rios
        SetShaderTexture(material, "river_mask", riverMaskPath);
        SetShaderTexture(material, "river_bottom_diffuse", riverBottomDiffusePath);
        SetShaderTexture(material, "river_bottom_normal", riverBottomNormalPath);
        SetShaderTexture(material, "river_bottom_gloss", riverBottomGlossPath);

        // Carrega as texturas da água
        SetShaderTexture(material, "water_color", waterColorPath);
        SetShaderTexture(material, "ambient_normal", ambientNormalPath);
        SetShaderTexture(material, "flow_map", flowMapPath);
        SetShaderTexture(material, "flow_normal", flowNormalPath);
        SetShaderTexture(material, "foam", foamPath);
        SetShaderTexture(material, "foam_ramp", foamRampPath);
        SetShaderTexture(material, "foam_map", foamMapPath);
        SetShaderTexture(material, "foam_noise", foamNoisePath);

        GD.Print("Texturas de rio carregadas com sucesso.");
    }

    private void SetShaderTexture(ShaderMaterial material, string paramName, string texturePath)
    {
        if (!ResourceLoader.Exists(texturePath))
        {
            GD.PrintErr($"Textura não encontrada: {texturePath}");
            return;
        }

        Texture2D texture = ResourceLoader.Load<Texture2D>(texturePath);
        if (texture != null)
        {
            material.SetShaderParameter(paramName, texture);
        }
        else
        {
            GD.PrintErr($"Falha ao carregar a textura: {texturePath}");
        }
    }
}