using Godot;
using System.Threading.Tasks;

public partial class TerrainGenerator : Node3D
{
    [Export] public string HeightmapPath = Paths.Heightmap;
    public Image HeightMap;
    [Export] public string ProvinceImagePath = Paths.ProvinceMap;
    public Image ProvinceMap;
    [Export] public string NormalMapPath = Paths.NormalMap;
    public Image NormalMap;
    [Export] public ShaderMaterial ProvinceHighlightMaterial;
    [Export] public float HeightScale = 50f;
    [Export] public int SimplificationFactor = 4;
    [Export] public new float Scale = 1.0f;
    [Export] public int ChunkSize = 256;


    private Texture2D BaseTexture;

    public override void _Ready()
    {
        _ = LoadTerrainAsync();
    }

    private async Task LoadTerrainAsync()
    {
        HeightMap = await Task.Run(() => Image.LoadFromFile(HeightmapPath));
        ProvinceMap = await Task.Run(() => Image.LoadFromFile(ProvinceImagePath));
        NormalMap = await Task.Run(() => Image.LoadFromFile(NormalMapPath));

        if (HeightMap == null)
        {
            GD.PrintErr($"Erro ao carregar o heightmap: {HeightmapPath}");
            return;
        }

        if (NormalMap == null)
        {
            GD.PrintErr($"Erro ao carregar o normal map: {NormalMapPath}");
            return;
        }

        BaseTexture = new Texture2D();

        // ImageTexture normalTexture = ImageTexture.CreateFromImage(NormalMap);


        ProvinceHighlightMaterial = await Task.Run(() => GD.Load<ShaderMaterial>("res://Shaders/ProvinceHighlightMaterial.tres"));
        // ProvinceHighlightMaterial.SetShaderParameter("normal_texture", NormalMap);

        int width = HeightMap.GetWidth();
        int height = HeightMap.GetHeight();

        int chunksX = Mathf.CeilToInt((float)width / ChunkSize);
        int chunksY = Mathf.CeilToInt((float)height / ChunkSize);

        for (int cx = 0; cx < chunksX; cx++)
        {
            for (int cy = 0; cy < chunksY; cy++)
            {
                GenerateChunkAsync(cx, cy);
            }
        }
    }

    private async void GenerateChunkAsync(int chunkX, int chunkY)
    {
        ArrayMesh chunkMesh = await Task.Run(() => GenerateChunkMesh(chunkX, chunkY));

        // Criar texturas

        MeshInstance3D chunkInstance = new()
        {
            Name = $"Chunk_{chunkX}_{chunkY}",
            Mesh = chunkMesh,
            MaterialOverride = ProvinceHighlightMaterial
        };



        // ADICIONANDO COLISOR
        StaticBody3D staticBody = new();
        CollisionShape3D collisionShape = new()
        {
            Shape = chunkMesh.CreateTrimeshShape()
        };
        staticBody.AddChild(collisionShape);
        chunkInstance.AddChild(staticBody);

        AddChild(chunkInstance);
    }

    private ArrayMesh GenerateChunkMesh(int chunkX, int chunkY)
    {
        SurfaceTool surfaceTool = new();
        surfaceTool.Begin(Mesh.PrimitiveType.Triangles);

        int width = HeightMap.GetWidth();
        int height = HeightMap.GetHeight();

        int startX = chunkX * ChunkSize;
        int startY = chunkY * ChunkSize;

        int endX = Mathf.Min(startX + ChunkSize, width - SimplificationFactor);
        int endY = Mathf.Min(startY + ChunkSize, height - SimplificationFactor);

        for (int x = startX; x < endX; x += SimplificationFactor)
        {
            for (int y = startY; y < endY; y += SimplificationFactor)
            {
                float h1 = HeightMap.GetPixel(x, y).R * HeightScale;
                float h2 = HeightMap.GetPixel(x + SimplificationFactor, y).R * HeightScale;
                float h3 = HeightMap.GetPixel(x, y + SimplificationFactor).R * HeightScale;
                float h4 = HeightMap.GetPixel(x + SimplificationFactor, y + SimplificationFactor).R * HeightScale;

                Vector3 v1 = new((x * Scale) - (width * Scale / 2), h1, (y * Scale) - (height * Scale / 2));
                Vector3 v2 = new(((x + SimplificationFactor) * Scale) - (width * Scale / 2), h2, (y * Scale) - (height * Scale / 2));
                Vector3 v3 = new((x * Scale) - (width * Scale / 2), h3, ((y + SimplificationFactor) * Scale) - (height * Scale / 2));
                Vector3 v4 = new(((x + SimplificationFactor) * Scale) - (width * Scale / 2), h4, ((y + SimplificationFactor) * Scale) - (height * Scale / 2));

                // surfaceTool.AddVertex(v1); surfaceTool.AddVertex(v2); surfaceTool.AddVertex(v3);
                // surfaceTool.AddVertex(v2); surfaceTool.AddVertex(v4); surfaceTool.AddVertex(v3);

                Vector2 uv1 = new((float)x / width, (float)y / height);
                Vector2 uv2 = new((float)(x + SimplificationFactor) / width, (float)y / height);
                Vector2 uv3 = new((float)x / width, (float)(y + SimplificationFactor) / height);
                Vector2 uv4 = new((float)(x + SimplificationFactor) / width, (float)(y + SimplificationFactor) / height);

                // Primeiro triângulo
                surfaceTool.SetUV(uv1); surfaceTool.AddVertex(v1);
                surfaceTool.SetUV(uv2); surfaceTool.AddVertex(v2);
                surfaceTool.SetUV(uv3); surfaceTool.AddVertex(v3);

                // Segundo triângulo
                surfaceTool.SetUV(uv2); surfaceTool.AddVertex(v2);
                surfaceTool.SetUV(uv4); surfaceTool.AddVertex(v4);
                surfaceTool.SetUV(uv3); surfaceTool.AddVertex(v3);
            }
        }

        surfaceTool.GenerateNormals();
        return surfaceTool.Commit();
    }


    public void UpdateProvinceHighlight(Color provinceId)
    {
        foreach (Node child in GetChildren())
        {
            if (child is MeshInstance3D mi && mi.MaterialOverride is ShaderMaterial sm)
            {
                sm.SetShaderParameter("selected_province_color", provinceId);
                GD.Print($"Shader após setar cor: {sm.GetShaderParameter("selected_province_color")}");
            }
        }

    }
}
