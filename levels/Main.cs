using Godot;

public partial class Main : Node3D
{
    [Export]
    private Player player;


    private TerrainGenerator Terrain;

    public override void _Ready()
    {

        Terrain = new TerrainGenerator();
        AddChild(Terrain);

        player.OnProviceSelected += HandleProvinceSelected;
    }

    private void HandleProvinceSelected(Vector3 position)
    {

        float width = Terrain.HeightMap.GetWidth();
        float height = Terrain.HeightMap.GetHeight();

        float x = (position.X + (width * Terrain.Scale / 2f)) / (width * Terrain.Scale);
        float y = (position.Z + (height * Terrain.Scale / 2f)) / (height * Terrain.Scale);

        int pixelX = Mathf.Clamp((int)(x * width), 0, Terrain.ProvinceMap.GetWidth() - 1);
        int pixelY = Mathf.Clamp((int)(y * height), 0, Terrain.ProvinceMap.GetHeight() - 1);

        Color pixelColor = Terrain.ProvinceMap.GetPixel(pixelX, pixelY);

        Vector3 selectedColor = new(
            Mathf.Round(pixelColor.R * 255) / 255.0f,
            Mathf.Round(pixelColor.G * 255) / 255.0f,
            Mathf.Round(pixelColor.B * 255) / 255.0f
        );
        GD.Print($"Setando cor: {selectedColor}");
        // string color = pixelColor.ToHtml();
        // GD.Print(color);
        Terrain.UpdateProvinceHighlight(pixelColor);
    }

    public override void _ExitTree()
    {
        if (player != null)
        {
            player.OnProviceSelected -= HandleProvinceSelected;
        }
    }
}

