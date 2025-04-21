using Godot;
using System;
using System.Linq;
using System.Threading.Tasks;

namespace Wuxia
{
    [Tool]
    public partial class MapGenerator : Node3D
    {
        [Export] public string HeightmapPath;
        [Export] public string ProvinceImagePath;
        [Export] public string NormalMapPath;
        [Export] public ShaderMaterial TerrainMaterial;
        [Export] public float HeightScale = 50f;
        [Export] public int SimplificationFactor = 1;
        [Export] public new float Scale = 1.0f;
        [Export] public int ChunkSize = 64;
        [Export] public Mesh ScatterMesh;

        public event Action<Boolean> OnFinishedGenerating;

        private bool isGenerating;

        public override void _Ready()
        {
            _ = LoadTerrainAsync();
        }

        private async Task LoadTerrainAsync()
        {
            if (isGenerating) return;
            isGenerating = true;

            using Image heightMap = Image.LoadFromFile(HeightmapPath);
            if (heightMap == null)
            {
                GD.PrintErr($"Erro ao carregar o heightmap: {HeightmapPath}");
                isGenerating = false;
                return;
            }

            // ProvinceHighlightMaterial = await Task.Run(static () => new TerrainInkMaterial());

            int width = heightMap.GetWidth();
            int height = heightMap.GetHeight();

            int chunksX = Mathf.CeilToInt((float)width / ChunkSize);
            int chunksY = Mathf.CeilToInt((float)height / ChunkSize);

            // Gerar chunks em lotes para controlar memória
            const int BATCH_SIZE = 4;
            for (int cx = 0; cx < chunksX; cx += BATCH_SIZE)
            {
                for (int cy = 0; cy < chunksY; cy += BATCH_SIZE)
                {
                    Task[] tasks = new Task[BATCH_SIZE * BATCH_SIZE];
                    int taskIndex = 0;

                    for (int x = 0; x < BATCH_SIZE && (cx + x) < chunksX; x++)
                    {
                        for (int y = 0; y < BATCH_SIZE && (cy + y) < chunksY; y++)
                        {
                            tasks[taskIndex++] = GenerateChunkAsync(cx + x, cy + y, heightMap);
                        }
                    }

                    await Task.WhenAll(tasks.Where(static t => t != null));
                    GC.Collect(); // Força coleta de lixo após cada lote
                }
            }

            isGenerating = false;
            OnFinishedGenerating?.Invoke(true);
        }

        private async Task GenerateChunkAsync(int chunkX, int chunkY, Image heightMap)
        {
            ArrayMesh chunkMesh = await Task.Run(() => GenerateChunkMesh(chunkX, chunkY, heightMap));

            _ = CallDeferred(nameof(CreateChunkInstance), chunkMesh, chunkX, chunkY);
        }

        private void CreateChunkInstance(ArrayMesh chunkMesh, int chunkX, int chunkY)
        {
            MeshInstance3D chunkInstance = new()
            {
                Name = $"Chunk_{chunkX}_{chunkY}",
                Mesh = chunkMesh,
                MaterialOverride = TerrainMaterial
            };

            // Usar shape box para colisão ao invés de trimesh
            StaticBody3D staticBody = new();
            Aabb bounds = chunkMesh.GetAabb();
            BoxShape3D boxShape = new()
            {
                Size = bounds.Size
            };

            CollisionShape3D collisionShape = new()
            {
                Shape = boxShape,
                Position = bounds.Position + (bounds.Size / 2)
            };

            staticBody.AddChild(collisionShape);
            chunkInstance.AddChild(staticBody);
            AddChild(chunkInstance);
        }

        private ArrayMesh GenerateChunkMesh(int chunkX, int chunkY, Image heightMap)
        {
            SurfaceTool surfaceTool = new();
            surfaceTool.Begin(Mesh.PrimitiveType.Triangles);

            int width = heightMap.GetWidth();
            int height = heightMap.GetHeight();

            int startX = chunkX * ChunkSize;
            int startY = chunkY * ChunkSize;

            int endX = Mathf.Min(startX + ChunkSize, width - SimplificationFactor);
            int endY = Mathf.Min(startY + ChunkSize, height - SimplificationFactor);

            // Otimização: Pré-calcular valores constantes
            float halfWidth = width * Scale / 2;
            float halfHeight = height * Scale / 2;
            float widthRatio = 1.0f / width;
            float heightRatio = 1.0f / height;

            for (int x = startX; x < endX; x += SimplificationFactor)
            {
                for (int y = startY; y < endY; y += SimplificationFactor)
                {
                    GenerateTerrainQuad(surfaceTool, x, y, heightMap, width, height,
                        halfWidth, halfHeight, widthRatio, heightRatio);
                }
            }

            surfaceTool.GenerateNormals();
            return surfaceTool.Commit();
        }

        private void GenerateTerrainQuad(SurfaceTool surfaceTool, int x, int y, Image heightMap,
    int width, int height, float halfWidth, float halfHeight, float widthRatio, float heightRatio)
        {
            float h1 = GetPackedHeight(heightMap.GetPixel(x, y)) * HeightScale;
            float h2 = GetPackedHeight(heightMap.GetPixel(x + SimplificationFactor, y)) * HeightScale;
            float h3 = GetPackedHeight(heightMap.GetPixel(x, y + SimplificationFactor)) * HeightScale;
            float h4 = GetPackedHeight(heightMap.GetPixel(x + SimplificationFactor, y + SimplificationFactor)) * HeightScale;

            Vector3 v1 = new((x * Scale) - halfWidth, h1, (y * Scale) - halfHeight);
            Vector3 v2 = new(((x + SimplificationFactor) * Scale) - halfWidth, h2, (y * Scale) - halfHeight);
            Vector3 v3 = new((x * Scale) - halfWidth, h3, ((y + SimplificationFactor) * Scale) - halfHeight);
            Vector3 v4 = new(((x + SimplificationFactor) * Scale) - halfWidth, h4, ((y + SimplificationFactor) * Scale) - halfHeight);

            Vector2 uv1 = new(x * widthRatio, y * heightRatio);
            Vector2 uv2 = new((x + SimplificationFactor) * widthRatio, y * heightRatio);
            Vector2 uv3 = new(x * widthRatio, (y + SimplificationFactor) * heightRatio);
            Vector2 uv4 = new((x + SimplificationFactor) * widthRatio, (y + SimplificationFactor) * heightRatio);

            // Primeiro triângulo
            surfaceTool.SetUV(uv1); surfaceTool.AddVertex(v1);
            surfaceTool.SetUV(uv2); surfaceTool.AddVertex(v2);
            surfaceTool.SetUV(uv3); surfaceTool.AddVertex(v3);

            // Segundo triângulo
            surfaceTool.SetUV(uv2); surfaceTool.AddVertex(v2);
            surfaceTool.SetUV(uv4); surfaceTool.AddVertex(v4);
            surfaceTool.SetUV(uv3); surfaceTool.AddVertex(v3);
        }

        private static float GetPackedHeight(Color color)
        {
            int r = (int)(color.R * 255.0f);
            int g = (int)(color.G * 255.0f);
            int b = (int)(color.B * 255.0f);

            int value = (r << 16) | (g << 8) | b;
            return value / 16777215.0f;
        }

        public void UpdateProvinceHighlight(Color provinceId)
        {
            foreach (Node child in GetChildren())
            {
                if (child is MeshInstance3D mi && mi.MaterialOverride is ShaderMaterial sm)
                {
                    sm.SetShaderParameter("selected_province_color", provinceId);
                }
            }
        }
    }
}
