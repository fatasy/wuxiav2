using Godot;
using System.Collections.Generic;


public partial class AzgaarMapGenerator : Node3D
{
    [Export] public string JsonMapPath = "res://assets/map.json";
    [Export] public Material BaseMaterial;
    [Export] public PackedScene ProvinceMeshScene;

    private MapData MapData { get; set; }
    public override void _Ready()
    {

        GD.Print("Iniciando geração do mapa...");
        MapData = new MapData();
        GD.Print($"MapData criado. Vertices: {MapData.vertices?.Count ?? 0}, Células: {MapData.cells?.Count ?? 0}");
        GenerateCells(MapData);
    }

    internal void GenerateCells(MapData data)
    {
        if (data == null)
        {
            GD.PrintErr("MapData é nulo!");
            return;
        }

        if (data.vertices == null || data.vertices.Count == 0)
        {
            GD.PrintErr("Não há vértices para gerar!");
            return;
        }

        if (data.cells == null || data.cells.Count == 0)
        {
            GD.PrintErr("Não há células para gerar!");
            return;
        }

        GD.Print($"Iniciando geração de {data.cells.Count} células...");
        Dictionary<int, Vector2> vertLookup = [];

        foreach (Vertex v in data.vertices)
            vertLookup[v.Index] = new Vector2(v.Position.X, v.Position.Z);

        int cellasProcessadas = 0;
        foreach (Cell cell in data.cells)
        {
            if (cell.Vertices.Length < 3)
            {
                GD.PrintErr($"Célula {cellasProcessadas} ignorada - menos de 3 vértices");
                continue;
            }

            SurfaceTool surfaceTool = new();
            surfaceTool.Begin(Mesh.PrimitiveType.Triangles);
            surfaceTool.SetMaterial(BaseMaterial);

            // Criar um ponto central para triangulação em leque (fan triangulation)
            Vector2 center = new();
            foreach (int vi in cell.Vertices)
            {
                center += vertLookup[vi];
            }
            center /= cell.Vertices.Length;
            float height = cell.Height * 0.5f;

            // Adicionar vértices em formato de leque
            for (int i = 0; i < cell.Vertices.Length; i++)
            {
                int currentVertex = cell.Vertices[i];
                int nextVertex = cell.Vertices[(i + 1) % cell.Vertices.Length];

                Vector2 currentPos = vertLookup[currentVertex];
                Vector2 nextPos = vertLookup[nextVertex];

                // Adicionar o triângulo (centro, atual, próximo)
                surfaceTool.AddVertex(new Vector3(center.X, height, center.Y));
                surfaceTool.AddVertex(new Vector3(currentPos.X, height, currentPos.Y));
                surfaceTool.AddVertex(new Vector3(nextPos.X, height, nextPos.Y));
            }

            ArrayMesh mesh = surfaceTool.Commit();
            MeshInstance3D meshInstance = new()
            {
                Mesh = mesh,
                MaterialOverride = new StandardMaterial3D()
                {
                    AlbedoColor = Color.FromHtml(data.provinces[cell.Province].color)
                }
            };
            AddChild(meshInstance);
            cellasProcessadas++;
        }
        GD.Print($"Geração concluída. {cellasProcessadas} células processadas.");
    }




}