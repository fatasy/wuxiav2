using Godot;
using System.Collections.Generic;
public partial class GenerateProvinceMap : Node
{
    public override void _Ready()
    {
        // GenerateWithViewport();
    }

    public async void GenerateWithViewport()
    {
        int imageWidth = 8535;
        int imageHeight = 4800;

        // SubViewport para renderização off-screen
        SubViewport viewport = new()
        {
            Size = new Vector2I(imageWidth, imageHeight),
            TransparentBg = false,
            Disable3D = true,
            RenderTargetUpdateMode = SubViewport.UpdateMode.Always,
            RenderTargetClearMode = SubViewport.ClearMode.Once
        };
        AddChild(viewport);

        // Canvas 2D onde desenharemos os polígonos
        Node2D canvas = new();
        viewport.AddChild(canvas);

        // Adiciona uma câmera 2D ao canvas
        Camera2D cam = new()
        {
            Zoom = new Vector2(1, 1),
            Position = new Vector2(imageWidth / 2f, imageHeight / 2f),
            Enabled = true
        };
        canvas.AddChild(cam);

        MapData data = MapData.Instance;
        List<Cell> cells = data.cells;

        float scaleX = (float)imageWidth / data.width;
        float scaleY = (float)imageHeight / data.height;

        Dictionary<int, Color> provinceColors = [];

        foreach (Cell cell in cells)
        {
            int provinceId = cell.Province;
            if (provinceId < 0 || cell.CValues == null || cell.CValues.Length < 3)
                continue;

            if (!provinceColors.TryGetValue(provinceId, out Color value))
            {
                // Usa System.Random para gerar cores mais variadas e potencialmente mais claras
                System.Random rand = new(provinceId); // Semeia com o ID da província
                float r = (float)rand.NextDouble();
                float g = (float)rand.NextDouble();
                float b = (float)rand.NextDouble();

                // Garante um brilho mínimo para evitar cores muito escuras
                float minBrightness = 0.2f;
                if (r < minBrightness && g < minBrightness && b < minBrightness)
                {
                    int componentToBoost = rand.Next(3); // Escolhe R, G ou B aleatoriamente para aumentar
                    if (componentToBoost == 0) r = minBrightness + ((float)rand.NextDouble() * (1.0f - minBrightness));
                    else if (componentToBoost == 1) g = minBrightness + ((float)rand.NextDouble() * (1.0f - minBrightness));
                    else b = minBrightness + ((float)rand.NextDouble() * (1.0f - minBrightness));
                }

                value = new Color(r, g, b, 1f); // Alpha 1
                provinceColors[provinceId] = value;
            }

            Color color = value;

            Vector2[] polygon = new Vector2[cell.CValues.Length];
            for (int i = 0; i < cell.CValues.Length; i++)
            {
                Vertex vertex = data.vertices[cell.CValues[i]];
                polygon[i] = new Vector2(vertex.Position.X * scaleX, vertex.Position.Y * scaleY);
            }

            Polygon2D poly = new()
            {
                Polygon = polygon,
                Color = color
            };
            canvas.AddChild(poly);
        }

        // Aguarda a renderização de pelo menos 2 frames
        _ = await ToSignal(GetTree(), SceneTree.SignalName.ProcessFrame);
        _ = await ToSignal(GetTree(), SceneTree.SignalName.ProcessFrame);

        // Troca para modo "Once" após renderização
        viewport.RenderTargetUpdateMode = SubViewport.UpdateMode.Once;

        // Extrai imagem da textura renderizada
        Image image = viewport.GetTexture().GetImage();
        _ = image.SavePng("res://assets/province_map.png");

        GD.Print("✔ Province map salvo com Viewport!");
        viewport.QueueFree();
    }
}

