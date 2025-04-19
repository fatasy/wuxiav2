using Godot;
using System.Collections.Generic;

public partial class MaterialLoader : Node
{
    [Export]
    public ShaderMaterial TerrainMaterial;

    [Export]
    public string BordersPath = "res://assets/gfx/map/borders";

    // Dicionário para mapear nomes de textura para caminhos reais
    private readonly Dictionary<string, string> _borderTextureMap = [];

    // Lista de todas as texturas de borda que precisamos carregar
    private readonly string[] _borderTextureNames =
    [
        // Bordas de água
        "border_water",
        
        // Bordas administrativas
        "border_province",
        "border_county",
        "border_domain",
        
        // Bordas de reino
        "border_other_realm",
        "border_my_realm",
        "border_sub_realm",
        "border_hovered_realm",
        "border_hovered_realm_flat_map",
        "border_selected_realm",
        "border_selected_realm_flat_map",
        "border_realm_explorer_independent",
        "border_realm_explorer_vassal",
        "my_top_realm",
        
        // Bordas de destaque/seleção
        "border_highlighted_province",
        "selection_highlight",
        "selection_highlight_flat_map",
        
        // Bordas de guerra
        "border_war",
        "border_war_ally",
        "border_war_target",
        "border_civil_war",
        
        // Bordas especiais
        "border_impassable",
        "epidemic",
        "struggle",
        "struggle_involved",
        "struggle_interloper",
        "struggle_uninvolved",
        "debug"
    ];

    // Called when the node enters the scene tree for the first time.
    public override void _Ready()
    {
        // Verificar se o material foi definido
        if (TerrainMaterial == null)
        {
            GD.PrintErr("Nenhum material de terreno atribuído ao MaterialLoader!");
            return;
        }

        // Carregar o mapeamento de texturas dos arquivos de configuração
        LoadBorderSettings();

        // Carregar e atribuir texturas ao material
        LoadBorderTextures();

        // Carregar máscara de borda inicial (este seria um recurso gerado em tempo de execução)
        // Por enquanto, usando uma textura temporária
        LoadTempBorderMask();

        GD.Print("MaterialLoader: Todas as texturas de borda foram carregadas");
    }

    private void LoadBorderSettings()
    {
        // Carregar o arquivo settings.txt para mapear texturas
        string settingsPath = BordersPath + "/settings.txt";

        if (!FileAccess.FileExists(settingsPath))
        {
            GD.PrintErr($"Arquivo de configurações de borda não encontrado: {settingsPath}");
            return;
        }

        using FileAccess file = FileAccess.Open(settingsPath, FileAccess.ModeFlags.Read);

        while (!file.EofReached())
        {
            string line = file.GetLine().Trim();

            // Pular linhas de comentário e vazias
            if (string.IsNullOrEmpty(line) || line.StartsWith("#"))
                continue;

            // Se a linha contém um = simples, processamos como um mapeamento direto
            if (line.Contains('=') && !line.Contains('{'))
            {
                string[] parts = line.Split('=', 2);
                if (parts.Length == 2)
                {
                    string key = parts[0].Trim();
                    string value = parts[1].Trim().Replace("\"", "").Replace(".dds", ".png");

                    // Mapeamos o nome da textura para seu caminho real
                    _borderTextureMap[key] = value;
                }
            }
            // Para entradas complexas, apenas extraímos a textura básica
            else if (line.Contains('{'))
            {
                string[] parts = line.Split('=', 2);
                if (parts.Length == 2 && parts[1].Contains("texture"))
                {
                    string key = parts[0].Trim();

                    // Encontre a definição de textura
                    int textureStart = parts[1].IndexOf("texture") + "texture".Length;
                    int textureEnd = parts[1].IndexOf(".dds", textureStart) + 4;

                    if (textureEnd > textureStart)
                    {
                        string texturePath = parts[1][textureStart..textureEnd]
                            .Trim().Trim('=', ' ', '\"')
                            .Replace(".dds", ".png");

                        _borderTextureMap[key] = texturePath;
                    }
                }
            }
        }
    }

    private void LoadBorderTextures()
    {
        foreach (string textureName in _borderTextureNames)
        {
            string fileName = textureName + ".png";

            // Verificar se temos um mapeamento personalizado para essa textura
            if (_borderTextureMap.TryGetValue(textureName, out string value))
            {
                fileName = value;
            }

            string texturePath = BordersPath + "/" + fileName;

            // Carregar a textura
            if (ResourceLoader.Exists(texturePath))
            {
                Texture2D texture = GD.Load<Texture2D>(texturePath);
                if (texture != null)
                {
                    // Definir a textura no material
                    TerrainMaterial.SetShaderParameter(textureName, texture);
                    GD.Print($"Carregada textura de borda: {textureName} ({texturePath})");
                }
                else
                {
                    GD.PrintErr($"Não foi possível carregar textura de borda: {texturePath}");
                }
            }
            else
            {
                GD.PrintErr($"Textura de borda não encontrada: {texturePath}");
            }
        }
    }

    private void LoadTempBorderMask()
    {
        // Em um jogo real, a máscara de borda seria gerada em tempo de execução
        // com base na geometria do mapa e na lógica do jogo
        // Por enquanto, vamos apenas carregar uma textura temporária se estiver disponível

        string maskPath = BordersPath + "/border_mask_temp.png";

        if (ResourceLoader.Exists(maskPath))
        {
            Texture2D maskTexture = GD.Load<Texture2D>(maskPath);
            if (maskTexture != null)
            {
                TerrainMaterial.SetShaderParameter("border_masks", maskTexture);
                GD.Print("Carregada máscara de borda temporária");
            }
        }
        else
        {
            GD.Print("Aviso: Máscara de borda temporária não encontrada. As bordas não serão renderizadas até que uma máscara seja gerada.");
        }
    }

    // Método para atualizar o estado das bordas (chamado pela lógica do jogo)
    public void UpdateBorderStates(bool isSelected, bool isHovered, bool atWar, bool isWarTarget, bool isCivilWar, bool isMyRealm, bool inStruggle)
    {
        if (TerrainMaterial != null)
        {
            TerrainMaterial.SetShaderParameter("is_selected_province", isSelected);
            TerrainMaterial.SetShaderParameter("is_hovered_province", isHovered);
            TerrainMaterial.SetShaderParameter("is_at_war", atWar);
            TerrainMaterial.SetShaderParameter("is_war_target", isWarTarget);
            TerrainMaterial.SetShaderParameter("is_civil_war", isCivilWar);
            TerrainMaterial.SetShaderParameter("is_my_realm", isMyRealm);
            TerrainMaterial.SetShaderParameter("is_in_struggle", inStruggle);
        }
    }

    // Método para alternar a visibilidade de diferentes tipos de borda
    public void SetBorderVisibility(bool showWater, bool showProvince, bool showCounty, bool showDomain, bool showRealm, bool showWar)
    {
        if (TerrainMaterial != null)
        {
            TerrainMaterial.SetShaderParameter("show_water_borders", showWater);
            TerrainMaterial.SetShaderParameter("show_province_borders", showProvince);
            TerrainMaterial.SetShaderParameter("show_county_borders", showCounty);
            TerrainMaterial.SetShaderParameter("show_domain_borders", showDomain);
            TerrainMaterial.SetShaderParameter("show_realm_borders", showRealm);
            TerrainMaterial.SetShaderParameter("show_war_borders", showWar);
        }
    }

    // Método para definir o modo de mapa plano
    public void SetFlatMapMode(bool isFlat)
    {
        TerrainMaterial?.SetShaderParameter("flat_map_mode", isFlat);
    }

    // Método para ajustar a aparência das bordas
    public void AdjustBorderAppearance(float width, float sharpness, float blend, Color glowColor, float glowIntensity, float animSpeed)
    {
        if (TerrainMaterial != null)
        {
            TerrainMaterial.SetShaderParameter("border_width", width);
            TerrainMaterial.SetShaderParameter("border_sharpness", sharpness);
            TerrainMaterial.SetShaderParameter("border_blend", blend);
            TerrainMaterial.SetShaderParameter("border_glow_color", new Vector3(glowColor.R, glowColor.G, glowColor.B));
            TerrainMaterial.SetShaderParameter("border_glow_intensity", glowIntensity);
            TerrainMaterial.SetShaderParameter("border_animation_speed", animSpeed);
        }
    }
}