using Godot;

namespace Wuxia
{
    public partial class RiverGenerator : Node3D
    {
        [Export] public Texture2D RiversMaskTexture { get; set; }
        [Export] public Texture2D HeightmapTexture { get; set; }
        [Export] public float HeightScale { get; set; } = 100.0f;
        [Export] public float RiverDepth { get; set; } = 2.0f;
        [Export] public ShaderMaterial RiverMaterial { get; set; }
        [Export] public new float Scale { get; set; } = 1.0f;

        public override void _Ready()
        {
            if (RiversMaskTexture == null || HeightmapTexture == null)
            {
                GD.PrintErr("Texturas de máscara de rios ou heightmap não atribuídas!");
                return;
            }

            GenerateRivers();
        }

        private void GenerateRivers()
        {
            // Obter imagens
            Image riverMask = RiversMaskTexture.GetImage();
            Image heightmap = HeightmapTexture.GetImage();

            // Garantir que as dimensões são compatíveis
            if (riverMask.GetWidth() != heightmap.GetWidth() || riverMask.GetHeight() != heightmap.GetHeight())
            {
                GD.PrintErr("Dimensões de máscara de rios e heightmap não coincidem!");
                return;
            }

            int width = riverMask.GetWidth();
            int height = riverMask.GetHeight();

            // Criar malha
            SurfaceTool surfaceTool = new SurfaceTool();
            surfaceTool.Begin(Mesh.PrimitiveType.Triangles);

            // Percorrer a imagem e criar vértices apenas onde há rios
            for (int z = 0; z < height - 1; z++)
            {
                for (int x = 0; x < width - 1; x++)
                {
                    Color maskColor = riverMask.GetPixel(x, z);

                    // Verificar se este pixel é parte de um rio (R > 0.5 por exemplo)
                    if (maskColor.R > 0.5f)
                    {
                        // Obter altura dos quatro cantos deste quad
                        float h00 = heightmap.GetPixel(x, z).R * HeightScale;
                        float h10 = heightmap.GetPixel(x + 1, z).R * HeightScale;
                        float h01 = heightmap.GetPixel(x, z + 1).R * HeightScale;
                        float h11 = heightmap.GetPixel(x + 1, z + 1).R * HeightScale;

                        // Subtrair a profundidade do rio (ajustar conforme necessário)
                        h00 -= RiverDepth;
                        h10 -= RiverDepth;
                        h01 -= RiverDepth;
                        h11 -= RiverDepth;

                        // Calcular posições dos vértices
                        Vector3 p00 = new Vector3(x - width / 2.0f, h00, z - height / 2.0f) * Scale;
                        Vector3 p10 = new Vector3(x + 1 - width / 2.0f, h10, z - height / 2.0f) * Scale;
                        Vector3 p01 = new Vector3(x - width / 2.0f, h01, z + 1 - height / 2.0f) * Scale;
                        Vector3 p11 = new Vector3(x + 1 - width / 2.0f, h11, z + 1 - height / 2.0f) * Scale;

                        // Coordenadas UV
                        Vector2 uv00 = new Vector2((float)x / width, (float)z / height);
                        Vector2 uv10 = new Vector2((float)(x + 1) / width, (float)z / height);
                        Vector2 uv01 = new Vector2((float)x / width, (float)(z + 1) / height);
                        Vector2 uv11 = new Vector2((float)(x + 1) / width, (float)(z + 1) / height);

                        // Primeiro triângulo
                        surfaceTool.SetUV(uv00);
                        surfaceTool.AddVertex(p00);
                        surfaceTool.SetUV(uv10);
                        surfaceTool.AddVertex(p10);
                        surfaceTool.SetUV(uv11);
                        surfaceTool.AddVertex(p11);

                        // Segundo triângulo
                        surfaceTool.SetUV(uv00);
                        surfaceTool.AddVertex(p00);
                        surfaceTool.SetUV(uv11);
                        surfaceTool.AddVertex(p11);
                        surfaceTool.SetUV(uv01);
                        surfaceTool.AddVertex(p01);
                    }
                }
            }

            // Gerar normais
            surfaceTool.GenerateNormals();
            surfaceTool.GenerateTangents();

            // Criar malha
            ArrayMesh mesh = surfaceTool.Commit();

            // Criar instância de MeshInstance3D
            MeshInstance3D riverMeshInstance = new MeshInstance3D
            {
                Name = "RiverMesh",
                Mesh = mesh,
                MaterialOverride = RiverMaterial
            };

            // Adicionar à cena
            AddChild(riverMeshInstance);
        }
    }
}