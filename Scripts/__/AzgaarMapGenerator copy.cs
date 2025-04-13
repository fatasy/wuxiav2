using Godot;
using System;
using System.Collections.Generic;
public partial class AzgaarMapGeneratorCopy : Node3D
{
    [Export] public string JsonMapPath = "res://assets/map.json";
    [Export] public float HeightMultiplier = 1.5f;
    [Export] public float CellSize = 1.0f;
    [Export] public Material BaseMaterial;
    [Export] public PackedScene ProvinceMeshScene;

    private readonly List<Vertex> vertices = [];
    private readonly List<Cell> cells = [];

    public event Action<Vector2> OnProviceSelected;


    private readonly Dictionary<int, Color> provinceColors = [];

    public override void _Ready()
    {

        Godot.Collections.Dictionary doc = JsonHelper.Load(JsonMapPath);
        Godot.Collections.Dictionary pack = doc["cells"].AsGodotDictionary();

        Godot.Collections.Array provinces = pack["provinces"].AsGodotArray();


        // 1. Primeiro, coletar todas as posições base dos vértices

        foreach (Variant v in pack["vertices"].AsGodotArray())
        {
            vertices.Add(Vertex.FromJsonData(v.AsGodotDictionary()));
        }

        // 2. Criar um dicionário para rastrear células que usam cada vértice
        Dictionary<int, (float totalHeight, int count)> vertexHeights = [];

        // 3. Calcular a altura média de cada vértice com base nas células que o usam
        foreach (Variant cellVariant in pack["cells"].AsGodotArray())
        {
            Cell cell = Cell.FromJsonData(cellVariant.AsGodotDictionary());
            cells.Add(cell);



            if (cell.Province == 0)
            {
                continue;
            }

            float cellHeight = cell.Height * HeightMultiplier;

            foreach (int vIndex in cell.Vertices)
            {
                if (vIndex > vertices.Count) continue;


                // Adicionar a altura desta célula ao vértice
                bool found = vertexHeights.TryGetValue(vIndex, out (float totalHeight, int count) existingValue);
                float totalHeight = existingValue.totalHeight;
                int count = existingValue.count;


                vertexHeights[vIndex] = found ? (totalHeight + cellHeight, count + 1) : (cellHeight, 1);


            }
        }

        // 4. Aplicar as alturas médias calculadas aos vértices
        List<Vector3> verticesWithHeight = [];
        for (int i = 0; i < vertices.Count; i++)
        {
            Vector3 position = vertices[i].Position;
            float height = 0;

            if (vertexHeights.TryGetValue(i, out (float totalHeight, int count) value))
            {
                (float totalHeight, int count) = value;
                height = totalHeight / count; // Altura média
            }

            verticesWithHeight.Add(new Vector3(position.X, height, position.Z));
        }

        GD.Print($"Calculadas alturas médias para {vertexHeights.Count} vértices");

        // Criar províncias com cores
        foreach (Variant province in provinces)
        {
            if (province.VariantType != Variant.Type.Dictionary)
            {
                continue;
            }
            Godot.Collections.Dictionary pDict = province.AsGodotDictionary();
            int id = (int)pDict["i"];
            string hex = (string)pDict["color"];

            // Converter cor hexadecimal para Color do Godot
            Color color;
            if (hex.StartsWith("#"))
            {
                hex = hex[1..];
                int colorInt = Convert.ToInt32(hex, 16);
                byte r = (byte)((colorInt >> 16) & 0xFF);
                byte g = (byte)((colorInt >> 8) & 0xFF);
                byte b = (byte)(colorInt & 0xFF);
                color = new Color(r / 255f, g / 255f, b / 255f);
            }
            else
            {
                color = new Color(hex);
            }

            provinceColors[id] = color;
        }


        foreach (Cell cell in cells)
        {
            ArrayMesh mesh = new();
            SurfaceTool surfaceTool = new();
            surfaceTool.Begin(Mesh.PrimitiveType.Triangles);
            surfaceTool.SetMaterial(BaseMaterial);


            int provinceId = cell.Province;


            // if (provinceId == 0)
            // {
            //     continue;
            // }

            List<Vector3> cellVertices = [];
            foreach (int vIndex in cell.Vertices)
            {
                if (vIndex >= 0 && vIndex < verticesWithHeight.Count)
                {
                    // Usar a altura pré-calculada para cada vértice
                    cellVertices.Add(verticesWithHeight[vIndex]);
                }
            }

            // Triangulação simples (fan)
            if (cellVertices.Count < 3)
            {
                continue;
            }

            for (int i = 1; i < cellVertices.Count - 1; i++)
            {
                Color color = provinceColors.GetValueOrDefault(provinceId, Colors.Gray);
                surfaceTool.SetColor(color);

                // Adicionar coordenadas UV para permitir tangentes e texturas
                Vector2 uv0 = new(cellVertices[0].X * 0.01f, cellVertices[0].Z * 0.01f);
                Vector2 uvi = new(cellVertices[i].X * 0.01f, cellVertices[i].Z * 0.01f);
                Vector2 uvi1 = new(cellVertices[i + 1].X * 0.01f, cellVertices[i + 1].Z * 0.01f);

                surfaceTool.SetUV(uv0);
                surfaceTool.AddVertex(cellVertices[0]);

                surfaceTool.SetUV(uvi);
                surfaceTool.AddVertex(cellVertices[i]);

                surfaceTool.SetUV(uvi1);
                surfaceTool.AddVertex(cellVertices[i + 1]);
            }


            surfaceTool.GenerateNormals();
            surfaceTool.GenerateTangents();
            _ = surfaceTool.Commit(mesh);

            // Instanciar a cena como StaticBody3D
            StaticBody3D instance = ProvinceMeshScene.Instantiate<StaticBody3D>();

            // Encontrar o MeshInstance3D dentro da cena instanciada
            // Assumindo que o MeshInstance3D é um filho direto ou neto
            MeshInstance3D meshInstance = instance.GetNode<MeshInstance3D>("MeshInstance3D") ?? instance.FindChild("MeshInstance3D", true) as MeshInstance3D;

            if (meshInstance != null)
            {
                meshInstance.Mesh = mesh;
            }
            else
            {
                GD.PrintErr("Não foi possível encontrar MeshInstance3D na cena ProvinceMeshScene");
                // Se não encontrar, criar um MeshInstance3D manualmente e adicionar
                meshInstance = new MeshInstance3D { Mesh = mesh };
                instance.AddChild(meshInstance);
            }

            // Adicionar a instância completa (StaticBody3D) à cena principal
            AddChild(instance);

            // Configurar a colisão no CollisionShape3D dentro da cena instanciada
            CollisionShape3D colShape = instance.GetNode<CollisionShape3D>("CollisionShape3D") ?? instance.FindChild("CollisionShape3D", true) as CollisionShape3D;
            if (colShape != null)
            {
                colShape.Shape = mesh.CreateTrimeshShape();
            }
            else
            {
                GD.PrintErr("Não foi possível encontrar CollisionShape3D na cena ProvinceMeshScene. Criando um novo.");
                colShape = new CollisionShape3D { Shape = mesh.CreateTrimeshShape() };
                instance.AddChild(colShape);
            }
        }

        GD.Print("Mapa gerado com sucesso.");
    }


}