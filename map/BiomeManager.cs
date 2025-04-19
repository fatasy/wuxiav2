using Godot;
using System.Collections.Generic;



public class Biome
{
    public enum Type
    {
        Marine,
        HotDesert,
        ColdDesert,
        Savanna,
        Grassland,
        TropicalSeasonalForest,
        TemperateDeciduousForest,
        TropicalRainforest,
        TemperateRainforest,
        Taiga,
        Tundra,
        Glacier,
        Wetland
    }

    public static Dictionary<Type, float> Density = new()
    {
        { Type.Marine, 0.0f },   // Marine
        { Type.HotDesert, 0.1f },   // Hot desert
        { Type.ColdDesert, 0.1f },   // Cold desert
        { Type.Savanna, 0.6f },   // Savanna
        { Type.Grassland, 0.4f },   // Grassland
        { Type.TropicalSeasonalForest, 0.8f },   // Tropical seasonal forest
        { Type.TemperateDeciduousForest, 1.0f },   // Temperate deciduous forest
        { Type.TropicalRainforest, 1.0f },   // Tropical rainforest
        { Type.TemperateRainforest, 0.9f },   // Temperate rainforest
        { Type.Taiga, 0.6f },   // Taiga
        { Type.Tundra, 0.2f },  // Tundra
        { Type.Glacier, 0.0f },  // Glacier
        { Type.Wetland, 0.8f }   // Wetland
    };

    public Type Id { get; set; }
    public string Name { get; set; }
    public Color Color { get; set; }

    public float GetDensity()
    {
        return Density[Id];
    }
}

public class BiomeManager
{

    private readonly Dictionary<int, Biome> _biomes = [];
    private readonly Dictionary<int, float> _habitability = [];
    private readonly Dictionary<int, int> _iconsDensity = [];
    private readonly Dictionary<int, int> _cost = [];
    private readonly Dictionary<int, string[]> _icons = [];
    private readonly Dictionary<int, Dictionary<int, int>> _biomesMatrix = [];

    public Dictionary<int, Dictionary<int, int>> GetBiomesMatrix()
    {
        return _biomesMatrix;
    }

    public BiomeManager(Godot.Collections.Dictionary data)
    {
        LoadBiomesData(data);
    }

    private void LoadBiomesData(Godot.Collections.Dictionary data)
    {
        if (data == null)
        {
            GD.PrintErr("Dados de biomas não encontrados no JSON");
            return;
        }


        // Carregar dados básicos
        Godot.Collections.Array ids = data["i"].AsGodotArray();
        Godot.Collections.Array names = data["name"].AsGodotArray();
        Godot.Collections.Array colors = data["color"].AsGodotArray();

        for (int i = 0; i < ids.Count; i++)
        {
            int id = ids[i].AsInt32();
            _biomes[id] = new Biome
            {
                Id = (Biome.Type)id,
                Name = names[i].AsString(),
                Color = new Color(colors[i].AsString())
            };
        }

        // Carregar matriz de biomas
        Godot.Collections.Array matrix = data["biomesMartix"].AsGodotArray();
        for (int i = 0; i < matrix.Count; i++)
        {
            Godot.Collections.Dictionary row = matrix[i].AsGodotDictionary();
            Dictionary<int, int> rowDict = [];

            foreach (Variant key in row.Keys)
            {
                rowDict[int.Parse((string)key)] = row[key].AsInt32();
            }

            _biomesMatrix[i] = rowDict;
        }

        // Carregar habitabilidade
        Godot.Collections.Array habitability = data["habitability"].AsGodotArray();
        for (int i = 0; i < habitability.Count; i++)
        {
            _habitability[i] = habitability[i].AsSingle();
        }

        // Carregar densidade de ícones
        Godot.Collections.Array iconsDensity = data["iconsDensity"].AsGodotArray();
        for (int i = 0; i < iconsDensity.Count; i++)
        {
            _iconsDensity[i] = iconsDensity[i].AsInt32();
        }

        // Carregar custos
        Godot.Collections.Array cost = data["cost"].AsGodotArray();
        for (int i = 0; i < cost.Count; i++)
        {
            _cost[i] = cost[i].AsInt32();
        }

        // Carregar ícones
        Godot.Collections.Array icons = data["icons"].AsGodotArray();
        for (int i = 0; i < icons.Count; i++)
        {
            Godot.Collections.Array iconArray = icons[i].AsGodotArray();
            string[] iconList = new string[iconArray.Count];
            for (int j = 0; j < iconArray.Count; j++)
            {
                iconList[j] = iconArray[j].AsString();
            }
            _icons[i] = iconList;
        }

        GD.Print($"BiomeManager carregado com sucesso: {_biomes.Count} biomas");
    }

    public Dictionary<int, Biome> GetAllBiomes()
    {
        return _biomes;
    }

    public Biome GetBiome(int id)
    {
        return _biomes.TryGetValue(id, out Biome biome) ? biome : null;
    }

    public float GetHabitability(int biomeId)
    {
        return _habitability.TryGetValue(biomeId, out float value) ? value : 0;
    }

    public int GetIconsDensity(int biomeId)
    {
        return _iconsDensity.TryGetValue(biomeId, out int value) ? value : 0;
    }

    public int GetCost(int biomeId)
    {
        return _cost.TryGetValue(biomeId, out int value) ? value : 0;
    }

    public string[] GetIcons(int biomeId)
    {
        return _icons.TryGetValue(biomeId, out string[] value) ? value : [];
    }

    public int GetBiomeFromMatrix(int temperature, int precipitation)
    {
        if (_biomesMatrix.TryGetValue(temperature, out Dictionary<int, int> row) &&
            row.TryGetValue(precipitation, out int biomeId))
        {
            return biomeId;
        }
        return 0; // Retorna bioma padrão (Marine) se não encontrar
    }
}

