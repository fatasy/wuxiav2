using Godot;
using System.Collections.Generic;

public partial class BiomeMaskGenerator : Node
{


    [Export] public string OutputPath = "res://assets/map_objects/masks";

    public override void _Ready()
    {
        GenerateBiomeMasksFromCells();
    }

    private static bool IsOutsideTheImageLimits(int x, int y, int imageWidth, int imageHeight)
    {
        return x < 0 || x >= imageWidth || y < 0 || y >= imageHeight;
    }

    public void GenerateBiomeMasksFromCells()
    {
        BiomeManager biomeManager = MapData.Instance.BiomeManager;
        List<Cell> cells = MapData.Instance.cells;

        int imageWidth = 8535;
        int imageHeight = 4800;

        // Encontra limites reais dos cells (bounding box)
        float minX = float.MaxValue, maxX = float.MinValue;
        float minY = float.MaxValue, maxY = float.MinValue;

        foreach (Cell cell in cells)
        {
            if (cell.Position.X < minX) minX = cell.Position.X;
            if (cell.Position.X > maxX) maxX = cell.Position.X;
            if (cell.Position.Y < minY) minY = cell.Position.Y;
            if (cell.Position.Y > maxY) maxY = cell.Position.Y;
        }

        float rangeX = maxX - minX;
        float rangeY = maxY - minY;

        DirAccess dir = DirAccess.Open(OutputPath);
        if (dir == null) _ = DirAccess.MakeDirRecursiveAbsolute(OutputPath);

        Dictionary<int, Biome> allBiomes = biomeManager.GetAllBiomes();

        foreach (KeyValuePair<int, Biome> biomePair in allBiomes)
        {
            int biomeId = biomePair.Key;
            Biome biome = biomePair.Value;

            float density = biome.GetDensity();
            byte intensity = (byte)(density * 255);

            Image image = Image.CreateEmpty(imageWidth, imageHeight, false, Image.Format.L8);
            image.Fill(new Color(0, 0, 0));

            foreach (Cell cell in cells)
            {
                if (cell.Biome != biomeId) continue;

                int x = Mathf.FloorToInt((cell.Position.X - minX) / rangeX * (imageWidth - 1));
                int y = Mathf.FloorToInt((cell.Position.Y - minY) / rangeY * (imageHeight - 1));

                if (IsOutsideTheImageLimits(x, y, imageWidth, imageHeight)) continue;

                image.SetPixel(x, y, new Color(intensity / 255f, 0, 0));
            }

            string safeName = biome.Name.ToLower(System.Globalization.CultureInfo.CurrentCulture).Replace(" ", "_");
            string filename = $"{OutputPath}/biome_mask_{biomeId}_{safeName}.png";
            _ = image.SavePng(filename);
            GD.Print($"✅ Máscara com bounding box para o bioma '{biome.Name}' salva em: {filename}");
        }


    }



}