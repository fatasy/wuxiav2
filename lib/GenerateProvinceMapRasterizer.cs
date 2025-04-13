using Godot;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

public partial class GenerateProvinceMapRasterizer : Node
{
    // Estrutura para representar aresta do polígono para varredura horizontal
    private struct Edge
    {
        public int YMin;    // Y mínimo da aresta
        public int YMax;    // Y máximo da aresta
        public float X;     // Posição X atual durante varredura
        public float DX;    // Incremento de X por cada Y

        public Edge(Vector2 p1, Vector2 p2)
        {
            // Garantir que p1 é o ponto com Y menor
            if (p1.Y > p2.Y)
            {
                (p1, p2) = (p2, p1);  // Swap pontos
            }

            YMin = Mathf.FloorToInt(p1.Y);
            YMax = Mathf.FloorToInt(p2.Y);
            X = p1.X;

            // Evitar divisão por zero
            float dy = p2.Y - p1.Y;
            DX = (dy != 0) ? (p2.X - p1.X) / dy : 0;
        }
    }

    public override void _Ready()
    {
        // Generate();
    }

    public static void Generate()
    {
        MapData data = MapData.Instance;
        if (data == null || data.cells == null || data.vertices == null)
        {
            GD.PrintErr("✘ Dados do mapa não estão disponíveis.");
            return;
        }

        Image sizeReference = Image.LoadFromFile(Paths.ProvinceMap);
        int imageWidth = sizeReference.GetWidth();
        int imageHeight = sizeReference.GetHeight();
        float scaleX = (float)imageWidth / data.width;
        float scaleY = (float)imageHeight / data.height;

        Image image = Image.CreateEmpty(imageWidth, imageHeight, false, Image.Format.Rgb8);
        image.Fill(Colors.Black);

        Dictionary<int, Color> provinceColors = [];

        // Processar células em paralelo
        _ = Parallel.ForEach(data.cells, cell =>
        {
            ProcessCellWithRasterizer(cell, data, image, provinceColors, scaleX, scaleY);
        });

        _ = image.SavePng("res://assets/province_map.png");
        GD.Print("✔ Mapa de províncias rasterizado e salvo em res://assets/province_map.png");
    }

    private static void ProcessCellWithRasterizer(Cell cell, MapData data, Image image,
                                           Dictionary<int, Color> provinceColors,
                                           float scaleX, float scaleY)
    {
        int provinceId = cell.Province;
        if (provinceId < 0 || cell.CValues == null || cell.CValues.Length < 3)
            return;

        // Gerar cor única para província
        lock (provinceColors)
        {
            if (!provinceColors.ContainsKey(provinceId))
            {
                byte r = (byte)(provinceId & 0xFF);
                byte g = (byte)((provinceId >> 8) & 0xFF);
                byte b = (byte)((provinceId >> 16) & 0xFF);
                provinceColors[provinceId] = new Color(r / 255.0f, g / 255.0f, b / 255.0f);
            }
        }

        Color color = provinceColors[provinceId];

        // Preparar o polígono
        Vector2[] polygon = new Vector2[cell.CValues.Length];
        int minY = int.MaxValue;
        int maxY = int.MinValue;

        for (int i = 0; i < cell.CValues.Length; i++)
        {
            Vertex vertex = data.vertices[cell.CValues[i]];
            polygon[i] = new Vector2(vertex.Position.X * scaleX, vertex.Position.Y * scaleY);

            minY = Mathf.Min(minY, Mathf.FloorToInt(polygon[i].Y));
            maxY = Mathf.Max(maxY, Mathf.CeilToInt(polygon[i].Y));
        }

        // Limitar às dimensões da imagem
        minY = Mathf.Max(0, minY);
        maxY = Mathf.Min(image.GetHeight() - 1, maxY);

        // Criar lista de arestas do polígono
        List<Edge> edges = [];
        for (int i = 0; i < polygon.Length; i++)
        {
            Vector2 p1 = polygon[i];
            Vector2 p2 = polygon[(i + 1) % polygon.Length];

            // Ignorar linhas horizontais (não contribuem para intersecções)
            if (Mathf.IsEqualApprox(p1.Y, p2.Y))
                continue;

            edges.Add(new Edge(p1, p2));
        }

        // Varrer cada linha horizontal
        for (int y = minY; y <= maxY; y++)
        {
            // Filtrar arestas que intersectam com esta linha
            List<Edge> activeEdges = edges.Where(e => y >= e.YMin && y < e.YMax).ToList();

            // Calcular os pontos de interseção
            List<float> intersections = [];
            foreach (Edge edge in activeEdges)
            {
                // Calcular X onde aresta cruza com linha y
                float x = edge.X + ((y - edge.YMin) * edge.DX);
                intersections.Add(x);

                // Atualizar X (não é necessário aqui porque recalculamos para cada y)
            }

            // Ordenar pontos de interseção
            intersections.Sort();

            // Desenhar pares de interseções (dentro-fora)
            for (int i = 0; i < intersections.Count - 1; i += 2)
            {
                if (i + 1 >= intersections.Count)
                    break;

                int x1 = Mathf.FloorToInt(intersections[i]);
                int x2 = Mathf.CeilToInt(intersections[i + 1]);

                // Limitar às dimensões da imagem
                x1 = Mathf.Max(0, x1);
                x2 = Mathf.Min(image.GetWidth() - 1, x2);

                // Preencher entre os pontos de interseção
                lock (image)
                {
                    for (int x = x1; x <= x2; x++)
                    {
                        image.SetPixel(x, y, color);
                    }
                }
            }
        }
    }
}