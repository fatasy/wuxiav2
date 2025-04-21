using System.Collections.Generic;
using System.Linq;
using Godot;
using Godot.Collections;

namespace World
{

    public partial class MapData : Node
    {
        public static MapData Instance { get; private set; }

        public int width { get; set; }
        public int height { get; set; }
        public List<Cell> cells { get; set; }
        public List<Vertex> vertices { get; set; }
        public List<Province> provinces { get; set; }
        public BiomeManager BiomeManager { get; private set; }

        private bool isLoaded;


        public override void _Ready()
        {
            // Inicializar as listas
            cells = [];
            vertices = [];
            provinces = [];



            Dictionary data = JsonHelper.Load("res://assets/map/map.json");
            Dictionary info = data["info"].AsGodotDictionary();
            width = (int)info["width"];
            height = (int)info["height"];
            Dictionary pack = data["pack"].AsGodotDictionary();
            AddCells(pack["cells"].AsGodotArray());
            AddVertexs(pack["vertices"].AsGodotArray());
            AddProvinces(pack["provinces"].AsGodotArray());

            BiomeManager = new BiomeManager(data["biomesData"].AsGodotDictionary());

            Instance = this;
        }

        public void AddCells(Array cells)
        {
            foreach (Dictionary cell in cells.Select(static v => (Dictionary)v))
            {
                this.cells.Add(Cell.FromJsonData(cell));
            }
        }

        public void AddVertexs(Array vertices)
        {
            foreach (Dictionary vertex in vertices.Select(static v => (Dictionary)v))
            {
                this.vertices.Add(Vertex.FromJsonData(vertex));
            }
        }

        public static void AddProvinces(Array provinces)
        {
            // foreach (Variant province in provinces)
            // {
            //     if (province.VariantType == Variant.Type.Dictionary)
            //     {
            //         this.provinces.Add(Province.FromJsonData((Dictionary)province));
            //     }
            // }
        }

    }

}