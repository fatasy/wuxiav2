using Godot;
using System.Collections.Generic;
using World;

public partial class BiomeMaskGenerator : Node
{
    [Export] public string OutputPath = "res://assets/map_objects/masks";

    public override void _Ready()
    {
        GenerateBiomeMasksFromCells();
    }

    private static bool IsOutsideTheImageLimits(int x, int y, int imageWidth, int imageHeight)
    {
        bool outside = x < 0 || x >= imageWidth || y < 0 || y >= imageHeight;
        if (outside)
        {
            GD.Print($"Célula fora dos limites: ({x}, {y})");
        }
        return outside;
    }

    public void GenerateBiomeMasksFromCells()
    {
        BiomeManager biomeManager = MapData.Instance.BiomeManager;
        List<Cell> cells = MapData.Instance.cells;

        int imageWidth = 8535;
        int imageHeight = 4800;

        // Adiciona as dimensões originais do mapa Azgaar
        int azgaarWidth = 1707;
        int azgaarHeight = 960;
        float scaleX = (float)imageWidth / azgaarWidth;
        float scaleY = (float)imageHeight / azgaarHeight;

        // Calcula a altura mínima e máxima de todas as células
        if (cells == null || cells.Count == 0)
        {
            GD.PrintErr("Lista de células está vazia ou nula!");
            return; // Sai se não houver células
        }

        int minHeight = cells[0].Height;
        int maxHeight = cells[0].Height;
        foreach (Cell cell in cells)
        {
            if (cell.Height < minHeight) minHeight = cell.Height;
            if (cell.Height > maxHeight) maxHeight = cell.Height;
        }
        float heightRange = Mathf.Max(1, maxHeight - minHeight); // Evita divisão por zero

        DirAccess dir = DirAccess.Open(OutputPath);
        if (dir == null) _ = DirAccess.MakeDirRecursiveAbsolute(OutputPath);

        Dictionary<int, Biome> allBiomes = biomeManager.GetAllBiomes();

        foreach (KeyValuePair<int, Biome> biomePair in allBiomes)
        {
            int biomeId = biomePair.Key;
            Biome biome = biomePair.Value;

            float density = biome.GetDensity();
            _ = (byte)(density * 255);

            Image image = Image.CreateEmpty(imageWidth, imageHeight, false, Image.Format.L8);
            image.Fill(new Color(0, 0, 0));

            foreach (Cell cell in cells)
            {
                if (cell.Biome != biomeId)
                    continue;

                // Calcula a intensidade base da célula com base na sua altura normalizada
                float normalizedHeight = (cell.Height - minHeight) / heightRange;
                byte cellBaseIntensity = (byte)(normalizedHeight * 255);

                // Calcula o raio baseado na Área da célula
                // Aumenta o fator de multiplicação da área para maior sobreposição e efeito "borrado"
                float cellRadius = Mathf.Sqrt(cell.Area) * scaleX * 1.0f; // Aumentado de 0.5f para 1.0f
                // Garante um raio mínimo para células muito pequenas não desaparecerem
                cellRadius = Mathf.Max(cellRadius, scaleX * 0.3f); // Aumentado um pouco o mínimo também
                float cellRadiusSq = cellRadius * cellRadius;

                // Centro da célula na imagem escalada
                float centerX = (cell.Position.X + 0.5f) * scaleX;
                float centerY = (cell.Position.Y + 0.5f) * scaleY;

                // Calcula a área de desenho (bounding box) para o círculo
                int minDrawX = Mathf.Max(0, Mathf.FloorToInt(centerX - cellRadius));
                int maxDrawX = Mathf.Min(imageWidth, Mathf.CeilToInt(centerX + cellRadius));
                int minDrawY = Mathf.Max(0, Mathf.FloorToInt(centerY - cellRadius));
                int maxDrawY = Mathf.Min(imageHeight, Mathf.CeilToInt(centerY + cellRadius));

                // Desenha o círculo com falloff
                for (int px = minDrawX; px < maxDrawX; px++)
                {
                    for (int py = minDrawY; py < maxDrawY; py++)
                    {
                        float dx = px - centerX;
                        float dy = py - centerY;
                        float distSq = (dx * dx) + (dy * dy);

                        // Verifica se o pixel está dentro do raio da célula atual
                        if (distSq < cellRadiusSq)
                        {
                            // Calcula a intensidade com falloff GAUSSIANO para efeito de "borrão"
                            float sigma = cellRadius / 1.0f; // Ajustado de 1.4f para 1.0f para mais suavidade
                            // Evita divisão por zero ou sigma muito pequeno
                            float twoSigmaSq = Mathf.Max(0.0001f, 1.0f * sigma * sigma);
                            float falloff = Mathf.Exp(-distSq / twoSigmaSq);

                            // Usa a intensidade base da CÉLULA (baseada na altura) multiplicada pelo falloff
                            byte newPixelIntensityByte = (byte)(cellBaseIntensity * falloff);

                            // Obtém a intensidade atual e SOMA a nova contribuição (efeito de mancha)
                            Color currentColor = image.GetPixel(px, py);
                            byte currentIntensityByte = (byte)currentColor.R8;

                            // Soma as intensidades, limitando a 255
                            int summedIntensity = currentIntensityByte + newPixelIntensityByte;
                            byte finalIntensityByte = (byte)Mathf.Min(summedIntensity, 255);

                            // Define o pixel com a intensidade acumulada (formato L8)

                            image.SetPixel(px, py, new Color(finalIntensityByte / 255.0f, 0, 0));
                        }
                    }
                }
            }

            string safeName = biome.Name.ToLower(System.Globalization.CultureInfo.CurrentCulture).Replace(" ", "_");
            string filename = $"{OutputPath}/biome_mask_{biomeId}_{safeName}.png";
            _ = image.SavePng(filename);
            GD.Print($"✅ Máscara geográfica para o bioma '{biome.Name}' salva em: {filename}");
        }
    }
}


