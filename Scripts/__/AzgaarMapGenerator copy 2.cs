using Godot;
using System;
using System.Collections.Generic;
public partial class AzgaarMapGeneratorCopi : Node3D
{
    [Export] public string JsonMapPath = "res://assets/map.json";
    [Export] public float HeightMultiplier = 0.3f;
    [Export] public float CellSize = 1.0f;
    [Export] public Material BaseMaterial;
    [Export] public PackedScene ProvinceMeshScene;
    [Export] public float ScaleFactor = 0.1f; // Fator de escala para controlar o tamanho total do mapa

    // Parâmetros de suavização
    [Export] public float SmoothingPower = 0.4f;    // Reduzido para 0.4f
    [Export] public float SmoothingFactor = 0.7f;   // Aumentado para 0.7f
    [Export] public int SmoothingPasses = 5;        // Aumentado para 5 passes
    [Export] public float BiomeInfluence = 0.3f;    // Quanto o bioma influencia a topografia
    [Export] public float DetailNoise = 0.03f;      // Reduzido para 0.03f

    private readonly List<Vertex> vertices = [];
    private readonly List<Cell> cells = [];

    public event Action<Vector2> OnProviceSelected;


    private readonly Dictionary<int, Color> provinceColors = [];

    // Adicionar método para limitar os valores extremos de altura
    private static float ClampHeight(float height, float maxHeight)
    {
        // Aplicar curva logística para suavizar picos
        if (height > maxHeight * 0.5f) // Reduzido limiar para 0.5f
        {
            float excess = height - (maxHeight * 0.5f);
            float dampen = 1.0f - (1.0f / (1.0f + Mathf.Exp((-excess * 8f) + 2f))); // Ajustado fator para 8f
            height = (maxHeight * 0.5f) + (excess * dampen);
        }
        return Mathf.Min(height, maxHeight * 0.75f); // Limitação mais restritiva
    }

    public override void _Ready()
    {
        Godot.Collections.Dictionary doc = JsonHelper.Load(JsonMapPath);
        if (doc == null)
        {
            GD.PrintErr("Falha ao carregar o arquivo JSON");
            return;
        }

        if (!doc.ContainsKey("cells"))
        {
            GD.PrintErr("Estrutura do JSON inválida: chave 'cells' não encontrada");
            return;
        }

        Godot.Collections.Dictionary pack = doc["cells"].AsGodotDictionary();
        if (!pack.ContainsKey("provinces") || !pack.ContainsKey("vertices") || !pack.ContainsKey("cells"))
        {
            GD.PrintErr("Estrutura do JSON inválida: uma ou mais chaves necessárias não encontradas");
            return;
        }

        Godot.Collections.Array provinces = pack["provinces"].AsGodotArray();

        // Etapa 1: Carregar vértices - manter suas posições base
        foreach (Variant v in pack["vertices"].AsGodotArray())
        {
            vertices.Add(Vertex.FromJsonData(v.AsGodotDictionary()));
        }

        // Etapa 2: Carregar células e preparar para cálculo de alturas
        // Criar um dicionário para calcular alturas de vértices diretamente
        Dictionary<int, float> vertexHeights = [];
        Dictionary<int, int> vertexBiomes = [];
        Dictionary<int, (int type, int area)> vertexTypeInfo = [];

        // Processar células em um único passo
        foreach (Variant cellVariant in pack["cells"].AsGodotArray())
        {
            Cell cell = Cell.FromJsonData(cellVariant.AsGodotDictionary());
            cells.Add(cell);

            // Ignorar células de província 0
            if (cell.Province == 0) continue;

            // Calcular altura para mapeamento (sem multiplicador, será aplicado na suavização)
            float cellHeight = cell.Height;

            // Aplicar a altura diretamente a cada vértice usado pela célula
            foreach (int vIndex in cell.Vertices)
            {
                if (vIndex >= vertices.Count) continue;

                // Armazenar a altura máxima encontrada para este vértice
                if (!vertexHeights.TryGetValue(vIndex, out float currentHeight) || cellHeight > currentHeight)
                {
                    vertexHeights[vIndex] = cellHeight;
                }

                // Guardar informações de bioma do vértice (o mais comum ou o último)
                vertexBiomes[vIndex] = cell.Biome;

                // Guardar tipo e área da célula para uso posterior
                vertexTypeInfo[vIndex] = (cell.Type, cell.Area);
            }
        }

        // Etapa 3: Criar o array final de vértices com altura
        List<Vector3> verticesWithHeight = [];
        FastNoiseLite noise = new()
        {
            Seed = (int)Time.GetTicksMsec(),
            NoiseType = FastNoiseLite.NoiseTypeEnum.Perlin,
            Frequency = 0.05f
        };

        for (int i = 0; i < vertices.Count; i++)
        {
            // Obter altura ou usar 0 como fallback
            float height = vertexHeights.GetValueOrDefault(i, 0);

            // Obter bioma ou usar 0 como fallback (ajusta terreno baseado no bioma)
            int biome = vertexBiomes.GetValueOrDefault(i, 0);
            (int, int) typeInfo = vertexTypeInfo.GetValueOrDefault(i, (0, 1));

            // Modificar altura com base no bioma
            // Biomas diferentes têm características topográficas diferentes
            float biomeFactor = 1.0f;
            switch (biome)
            {
                case 1: // Montanha
                    biomeFactor = 1.15f; // Reduzido de 1.3f para 1.15f
                    break;
                case 2: // Floresta
                    biomeFactor = 1.05f; // Reduzido de 1.1f para 1.05f
                    break;
                case 3: // Deserto
                    biomeFactor = 0.7f;
                    break;
                case 4: // Pântano
                    biomeFactor = 0.2f;
                    break;
                default:
                    break;
                    // Adicione mais casos conforme necessário
            }

            // Ajustar altura baseado no tipo (água vs terra)
            if (typeInfo.Item1 == 0) // Água
            {
                height *= 0.1f; // Ainda mais plana (reduzido de 0.2f para 0.1f)
            }

            // Comprimir a faixa de altura para evitar valores extremos
            height = Mathf.Pow(height, 0.9f); // Comprime levemente valores altos

            // Aplicar fator de bioma
            height *= Mathf.Lerp(1.0f, biomeFactor, BiomeInfluence);

            // Adicionar ruído com base na posição para criar micro-detalhes
            Vector3 pos = vertices[i].Position;
            float detailNoiseValue = noise.GetNoise2D(pos.X * 1.5f, pos.Z * 1.5f);

            // Aplicar suavização à altura - usar uma curva mais natural
            height = Mathf.Pow(height, SmoothingPower) * HeightMultiplier * 0.5f;

            // Adicionar micro-detalhes através de ruído Perlin (com menos influência em valores altos)
            float noiseInfluence = Mathf.Lerp(DetailNoise, DetailNoise * 0.3f, Mathf.Min(1.0f, height / HeightMultiplier));
            height += detailNoiseValue * noiseInfluence * height;

            // Limitar valores extremos de altura
            height = ClampHeight(height, HeightMultiplier);

            // Aplicar fator de escala para controlar o tamanho geral
            verticesWithHeight.Add(new Vector3(
                pos.X * ScaleFactor,
                height * ScaleFactor,
                pos.Z * ScaleFactor
            ));
        }

        // Suavização adicional - fazer média com vizinhos
        Dictionary<int, List<int>> vertexNeighbors = [];

        // Coletar informação sobre vizinhos a partir das células
        foreach (Cell cell in cells)
        {
            for (int i = 0; i < cell.Vertices.Length; i++)
            {
                int current = cell.Vertices[i];
                if (current >= vertices.Count) continue;

                // Obter vizinhos (o anterior e o próximo no array de vértices da célula)
                int prev = cell.Vertices[(i + cell.Vertices.Length - 1) % cell.Vertices.Length];
                int next = cell.Vertices[(i + 1) % cell.Vertices.Length];

                if (!vertexNeighbors.TryGetValue(current, out List<int> neighbors))
                {
                    neighbors = [];
                    vertexNeighbors[current] = neighbors;
                }

                // Adicionar vizinhos se ainda não estiverem na lista
                if (!neighbors.Contains(prev) && prev < vertices.Count)
                    neighbors.Add(prev);

                if (!neighbors.Contains(next) && next < vertices.Count)
                    neighbors.Add(next);
            }
        }

        // Aplicar múltiplos passes de suavização
        List<Vector3> currentVertices = new(verticesWithHeight);

        // Detectar valores atípicos (outliers) antes da suavização
        // Vértices que são muito mais altos que seus vizinhos
        Dictionary<int, bool> outliers = [];
        foreach (KeyValuePair<int, List<int>> kvp in vertexNeighbors)
        {
            int vertexIdx = kvp.Key;
            List<int> neighbors = kvp.Value;

            if (neighbors.Count < 2) continue;

            float vertexHeight = currentVertices[vertexIdx].Y;
            float avgNeighborHeight = 0;

            foreach (int neighbor in neighbors)
            {
                avgNeighborHeight += currentVertices[neighbor].Y;
            }

            avgNeighborHeight /= neighbors.Count;

            // Se o vértice for significativamente mais alto que a média dos vizinhos,
            // marcar como outlier para suavização mais agressiva
            if (vertexHeight > avgNeighborHeight * 2.0f)
            {
                outliers[vertexIdx] = true;
            }
        }

        for (int pass = 0; pass < SmoothingPasses; pass++)
        {
            List<Vector3> smoothedVertices = new(currentVertices);

            for (int i = 0; i < vertices.Count; i++)
            {
                if (!vertexNeighbors.TryGetValue(i, out List<int> neighbors) || neighbors.Count == 0)
                    continue;

                // Calcular altura média dos vizinhos
                float sumHeight = 0;
                foreach (int neighbor in neighbors)
                {
                    if (neighbor < currentVertices.Count)
                        sumHeight += currentVertices[neighbor].Y;
                }

                float avgHeight = sumHeight / neighbors.Count;

                // Suavização adaptativa - áreas montanhosas (maior altura) ficam menos suavizadas
                // para preservar os detalhes das montanhas e picos
                float adaptiveFactor = SmoothingFactor;

                // Para outliers, aplicar suavização mais agressiva
                if (outliers.TryGetValue(i, out bool isOutlier) && isOutlier)
                {
                    adaptiveFactor = Mathf.Min(0.9f, adaptiveFactor * 1.5f);

                    // Para passes finais, reduzir ainda mais os outliers
                    if (pass >= SmoothingPasses / 2)
                    {
                        adaptiveFactor = Mathf.Min(0.95f, adaptiveFactor * 1.2f);
                    }
                }

                // Se for um vértice de alta elevação, reduzir a suavização
                float relativeHeight = currentVertices[i].Y / (HeightMultiplier * ScaleFactor);
                if (relativeHeight > 0.7f && !outliers.ContainsKey(i))
                {
                    // Diminuir progressivamente a suavização para terrenos mais altos (mas não outliers)
                    adaptiveFactor *= Mathf.Lerp(1.0f, 0.5f, (relativeHeight - 0.7f) / 0.3f);
                }

                // Se for parte de uma área de água, aumentar a suavização
                if (vertexTypeInfo.TryGetValue(i, out (int type, int area) info) && info.type == 0)
                {
                    adaptiveFactor = Mathf.Min(1.0f, adaptiveFactor * 1.5f);
                }

                // Se for uma área pequena, aplicar mais suavização para evitar picos estranhos
                if (vertexTypeInfo.TryGetValue(i, out (int type, int area) areaInfo) && areaInfo.area < 10)
                {
                    adaptiveFactor = Mathf.Min(1.0f, adaptiveFactor * 1.3f);
                }

                // Interpolar entre a altura atual e a média dos vizinhos
                float newHeight = Mathf.Lerp(currentVertices[i].Y, avgHeight, adaptiveFactor);

                // Atualizar com o valor suavizado
                Vector3 pos = smoothedVertices[i];
                smoothedVertices[i] = new Vector3(pos.X, newHeight, pos.Z);
            }

            // Usar resultado como entrada para o próximo passe
            currentVertices = smoothedVertices;
        }

        // Usar os vértices suavizados
        verticesWithHeight = currentVertices;

        GD.Print($"Calculados {vertexHeights.Count} vértices com altura suavizada ({SmoothingPasses} passes)");

        // Etapa 4: Processar cores de província
        foreach (Variant province in provinces)
        {
            if (province.VariantType != Variant.Type.Dictionary) continue;

            Godot.Collections.Dictionary pDict = province.AsGodotDictionary();
            if (!pDict.ContainsKey("i") || !pDict.ContainsKey("color")) continue;

            int id = (int)pDict["i"];
            string hex = (string)pDict["color"];

            // Converter hexadecimal para Color
            Color color;
            if (hex.StartsWith("#"))
            {
                hex = hex[1..];
                int colorInt = Convert.ToInt32(hex, 16);
                color = new Color(
                    ((colorInt >> 16) & 0xFF) / 255f,
                    ((colorInt >> 8) & 0xFF) / 255f,
                    (colorInt & 0xFF) / 255f
                );
            }
            else
            {
                color = new Color(hex);
            }

            provinceColors[id] = color;
        }

        // Etapa 5: Gerar meshes a partir das células
        foreach (Cell cell in cells)
        {
            // Ignorar células sem província
            // if (cell.Province == 0) continue;

            List<Vector3> cellVertices = [];
            foreach (int vIndex in cell.Vertices)
            {
                if (vIndex >= 0 && vIndex < verticesWithHeight.Count)
                {
                    cellVertices.Add(verticesWithHeight[vIndex]);
                }
            }

            // Ignorar células com menos de 3 vértices (não formam triângulos)
            if (cellVertices.Count < 3) continue;

            // Criar mesh
            ArrayMesh mesh = new();
            SurfaceTool surfaceTool = new();
            surfaceTool.Begin(Mesh.PrimitiveType.Triangles);
            surfaceTool.SetMaterial(BaseMaterial);

            // Obter cor para esta província
            Color color = provinceColors.GetValueOrDefault(cell.Province, Colors.Gray);

            // Calcular vetor normal médio para toda a célula para iluminação
            Vector3 cellNormal = Vector3.Up;
            if (cellVertices.Count >= 3)
            {
                Vector3 sum = Vector3.Zero;
                for (int i = 1; i < cellVertices.Count - 1; i++)
                {
                    Vector3 v1 = cellVertices[i] - cellVertices[0];
                    Vector3 v2 = cellVertices[i + 1] - cellVertices[0];
                    sum += v1.Cross(v2).Normalized();
                }
                if (sum.LengthSquared() > 0.01f)
                {
                    cellNormal = sum.Normalized();
                }
            }

            // Criar triângulos usando triangulação "fan"
            for (int i = 1; i < cellVertices.Count - 1; i++)
            {
                // Modificar cor baseado na altura, inclinação e bioma
                Color vertexColor = color;

                // Adicionar variação de cor baseada na altura
                float avgHeight = (cellVertices[0].Y + cellVertices[i].Y + cellVertices[i + 1].Y) / 3.0f;
                float heightFactor = Mathf.Clamp(avgHeight / (HeightMultiplier * ScaleFactor * 0.5f), 0, 1);

                // Terrenos mais altos ficam mais claros
                vertexColor = vertexColor.Lerp(Colors.White, heightFactor * 0.3f);

                // Áreas muito baixas são águas
                if (avgHeight < 0.1f * ScaleFactor)
                {
                    // Cores de água
                    vertexColor = Colors.DodgerBlue.Lerp(color, 0.3f);
                }

                // Aplicar cor
                surfaceTool.SetColor(vertexColor);

                // Adicionar coordenadas UV para texturização - baseadas na altura
                Vector2 uv0 = new(cellVertices[0].X / ScaleFactor * 0.01f, cellVertices[0].Z / ScaleFactor * 0.01f);
                Vector2 uvi = new(cellVertices[i].X / ScaleFactor * 0.01f, cellVertices[i].Z / ScaleFactor * 0.01f);
                Vector2 uvi1 = new(cellVertices[i + 1].X / ScaleFactor * 0.01f, cellVertices[i + 1].Z / ScaleFactor * 0.01f);

                // Adicionar normais personalizadas para melhor iluminação
                Vector3 normal1 = (cellVertices[i] - cellVertices[0]).Cross(cellVertices[i + 1] - cellVertices[0]).Normalized();
                if (normal1.LengthSquared() < 0.01f)
                {
                    normal1 = cellNormal;
                }

                // Adicionar vértices com normais e UVs
                surfaceTool.SetNormal(normal1);
                surfaceTool.SetUV(uv0);
                surfaceTool.AddVertex(cellVertices[0]);

                surfaceTool.SetNormal(normal1);
                surfaceTool.SetUV(uvi);
                surfaceTool.AddVertex(cellVertices[i]);

                surfaceTool.SetNormal(normal1);
                surfaceTool.SetUV(uvi1);
                surfaceTool.AddVertex(cellVertices[i + 1]);
            }

            // Finalizar mesh
            surfaceTool.GenerateTangents();
            _ = surfaceTool.Commit(mesh);

            // Criar instância para visualização
            StaticBody3D instance = ProvinceMeshScene.Instantiate<StaticBody3D>();
            MeshInstance3D meshInstance = instance.GetNode<MeshInstance3D>("MeshInstance3D") ??
                                         instance.FindChild("MeshInstance3D", true) as MeshInstance3D;

            if (meshInstance != null)
            {
                meshInstance.Mesh = mesh;
            }
            else
            {
                meshInstance = new MeshInstance3D { Mesh = mesh };
                instance.AddChild(meshInstance);
            }

            // Configurar colisão
            CollisionShape3D colShape = instance.GetNode<CollisionShape3D>("CollisionShape3D") ??
                                       instance.FindChild("CollisionShape3D", true) as CollisionShape3D;

            if (colShape != null)
            {
                colShape.Shape = mesh.CreateTrimeshShape();
            }
            else
            {
                colShape = new CollisionShape3D { Shape = mesh.CreateTrimeshShape() };
                instance.AddChild(colShape);
            }

            AddChild(instance);
        }

        GD.Print("Mapa gerado com sucesso.");
    }


}