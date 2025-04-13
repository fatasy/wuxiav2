using Godot;
using System.Collections.Generic;
using System.Threading.Tasks;

public partial class GenerateProvinceMapFast : Node
{
    public override void _Ready()
    {
        // _ = GenerateFast();
    }

    public async Task GenerateFast()
    {
        MapData data = MapData.Instance;
        if (data == null || data.cells == null || data.vertices == null)
        {
            GD.PrintErr("✘ Dados do mapa não estão disponíveis.");
            return;
        }

        // Tamanho da textura de saída baseado na imagem existente
        Image sizeReference = Image.LoadFromFile(Paths.ProvinceMap);
        int imageWidth = sizeReference.GetWidth();
        int imageHeight = sizeReference.GetHeight();
        float scaleX = (float)imageWidth / data.width;
        float scaleY = (float)imageHeight / data.height;

        // Criar uma SubViewport para renderizar os polígonos
        SubViewport viewport = new()
        {
            Size = new Vector2I(imageWidth, imageHeight),
            RenderTargetUpdateMode = SubViewport.UpdateMode.Once,
            RenderTargetClearMode = SubViewport.ClearMode.Always,
            TransparentBg = true
        };

        // Criar um Control para desenhar os polígonos
        ProvinceRenderer renderer = new(data, scaleX, scaleY);
        viewport.AddChild(renderer);

        // Adicionar à árvore temporariamente
        AddChild(viewport);

        // Renderizar uma vez
        viewport.RenderTargetUpdateMode = SubViewport.UpdateMode.Once;

        // Esperamos um quadro para garantir que a renderização seja concluída
        _ = await ToSignal(GetTree(), "process_frame");
        _ = await ToSignal(GetTree(), "process_frame");

        // Obter a textura renderizada
        ViewportTexture viewportTexture = viewport.GetTexture();
        Image image = viewportTexture.GetImage();

        // Salvar a imagem
        _ = image.SavePng("res://assets/province_map.png");

        // Limpar
        viewport.QueueFree();

        GD.Print("✔ Mapa de províncias gerado rapidamente e salvo em res://assets/province_map.png");
    }
}

// Classe auxiliar para desenhar os polígonos
public partial class ProvinceRenderer(MapData data, float scaleX, float scaleY) : Control
{
    private readonly MapData _data = data;
    private readonly float _scaleX = scaleX;
    private readonly float _scaleY = scaleY;
    private readonly Dictionary<int, Color> _provinceColors = [];

    public override void _Draw()
    {
        // Primeiro preencher um fundo preto
        DrawRect(new Rect2(0, 0, GetViewportRect().Size.X, GetViewportRect().Size.Y), Colors.Black);

        foreach (Cell cell in _data.cells)
        {
            int provinceId = cell.Province;
            if (provinceId < 0 || cell.CValues == null || cell.CValues.Length < 3)
                continue;

            // Gerar cor única para província
            if (!_provinceColors.TryGetValue(provinceId, out Color value))
            {
                byte r = (byte)(provinceId & 0xFF);
                byte g = (byte)((provinceId >> 8) & 0xFF);
                byte b = (byte)((provinceId >> 16) & 0xFF);
                value = new Color(r / 255.0f, g / 255.0f, b / 255.0f);
                _provinceColors[provinceId] = value;
            }

            Color color = value;

            // Construir o polígono escalado
            Vector2[] polygonPoints = new Vector2[cell.CValues.Length];
            for (int i = 0; i < cell.CValues.Length; i++)
            {
                Vertex vertex = _data.vertices[cell.CValues[i]];
                polygonPoints[i] = new Vector2(
                    vertex.Position.X * _scaleX,
                    vertex.Position.Y * _scaleY
                );
            }

            // Desenhar o polígono usando a API de desenho do Godot
            DrawPolygon(polygonPoints, [color]);
        }
    }
}