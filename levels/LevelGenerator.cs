using Godot;

public partial class LevelGenerator : Node3D
{
    public ShaderMaterial ProvinceSelectShaderMaterial;
    public float LevelHeightScale = 100f;
    public float TileSize = 1f;
    public int ChunkSize = 256;
    public int Step = 4;

    private int _imageWidth, _imageHeight;
    private Image _image;

    public LevelGenerator()
    {

        ProvinceSelectShaderMaterial = GD.Load<ShaderMaterial>("res://assets/Shaders/ProvinceSelectShaderMaterial.tres");
        Initialize(Image.LoadFromFile(Paths.Heightmap));
        GenerateChunks();
        ProvinceSelectShaderMaterial.SetShaderParameter("BaseTexture", this);
    }

    public void Initialize(Image heightmap)
    {
        _image = heightmap;
        _imageWidth = _image.GetWidth();
        _imageHeight = _image.GetHeight();

    }

    public void GenerateChunks()
    {
        int chunksX = Mathf.CeilToInt((float)_imageWidth / ChunkSize);
        int chunksY = Mathf.CeilToInt((float)_imageHeight / ChunkSize);

        for (int y = 0; y < chunksY; y++)
        {
            for (int x = 0; x < chunksX; x++)
            {
                GenerateChunk(x, y);
            }
        }
    }

    private Vector3 GetVertex(int x, int y)
    {
        int clampedX = Mathf.Clamp(x, 0, _imageWidth - 1);
        int clampedY = Mathf.Clamp(y, 0, _imageHeight - 1);

        float heightValue = _image.GetPixel(clampedX, clampedY).R;
        return new Vector3(x * TileSize, heightValue * LevelHeightScale, y * TileSize);
    }

    private void GenerateChunk(int chunkX, int chunkY)
    {
        int startX = chunkX * ChunkSize;
        int startY = chunkY * ChunkSize;

        SurfaceTool st = new();
        st.Begin(Mesh.PrimitiveType.Triangles);

        for (int y = 0; y < ChunkSize; y += Step)
        {
            for (int x = 0; x < ChunkSize; x += Step)
            {
                int px = startX + x;
                int py = startY + y;

                Vector3 v00 = GetVertex(px, py);
                Vector3 v10 = GetVertex(px + Step, py);
                Vector3 v01 = GetVertex(px, py + Step);
                Vector3 v11 = GetVertex(px + Step, py + Step);

                Vector2 uv00 = new((float)px / _imageWidth, (float)py / _imageHeight);
                Vector2 uv10 = new((float)(px + Step) / _imageWidth, (float)py / _imageHeight);
                Vector2 uv01 = new((float)px / _imageWidth, (float)(py + Step) / _imageHeight);
                Vector2 uv11 = new((float)(px + Step) / _imageWidth, (float)(py + Step) / _imageHeight);

                // Triângulo 1
                st.SetUV(uv00);
                st.AddVertex(v00);
                st.SetUV(uv10);
                st.AddVertex(v10);
                st.SetUV(uv11);
                st.AddVertex(v11);

                // Triângulo 2
                st.SetUV(uv00);
                st.AddVertex(v00);
                st.SetUV(uv11);
                st.AddVertex(v11);
                st.SetUV(uv01);
                st.AddVertex(v01);
            }
        }

        st.GenerateNormals(true);
        st.Index();
        ArrayMesh mesh = st.Commit();

        // Cria o MeshInstance3D do chunk

        MeshInstance3D chunk = new()
        {
            Mesh = mesh,
            MaterialOverride = ProvinceSelectShaderMaterial
        };

        // Adiciona colisor
        CollisionShape3D collisionShape = new()
        {
            Shape = chunk.Mesh.CreateTrimeshShape()
        };

        StaticBody3D staticBody = new();
        staticBody.AddChild(collisionShape);
        chunk.AddChild(staticBody);

        AddChild(chunk);
    }


}