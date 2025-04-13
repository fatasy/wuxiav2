using Godot;
using System.Linq;

public partial class Cell : Node
{
    public int Index { get; set; }
    public int[] Vertices { get; set; }
    public int[] CValues { get; set; }
    public Vector2 Position { get; set; }
    public int G { get; set; }
    public int Height { get; set; }
    public int Area { get; set; }
    public int Flag { get; set; }
    public int Type { get; set; }
    public int Haven { get; set; }
    public int Harbor { get; set; }
    public int Fl { get; set; }
    public int R { get; set; }
    public int Conf { get; set; }
    public int Biome { get; set; }
    public int S { get; set; }
    public int Population { get; set; }
    public int Culture { get; set; }
    public int Burg { get; set; }
    public int State { get; set; }
    public int Religion { get; set; }
    public int Province { get; set; }

    public static Cell FromJsonData(Godot.Collections.Dictionary jsonData)
    {
        Godot.Collections.Array verticesArray = (Godot.Collections.Array)jsonData["v"];
        Godot.Collections.Array cValuesArray = (Godot.Collections.Array)jsonData["c"];
        Godot.Collections.Array positionArray = (Godot.Collections.Array)jsonData["p"];

        return new Cell
        {
            Index = (int)jsonData["i"],
            Vertices = verticesArray.Select(static v => (int)v).ToArray(),
            CValues = cValuesArray.Select(static c => (int)c).ToArray(),
            Position = new Vector2((float)positionArray[0], (float)positionArray[1]),
            G = (int)jsonData["g"],
            Height = (int)jsonData["h"],
            Area = (int)jsonData["area"],
            Flag = (int)jsonData["f"],
            Type = (int)jsonData["t"],
            Haven = (int)jsonData["haven"],
            Harbor = (int)jsonData["harbor"],
            Fl = (int)jsonData["fl"],
            R = (int)jsonData["r"],
            Conf = (int)jsonData["conf"],
            Biome = (int)jsonData["biome"],
            S = (int)jsonData["s"],
            Population = (int)jsonData["pop"],
            Culture = (int)jsonData["culture"],
            Burg = (int)jsonData["burg"],
            State = (int)jsonData["state"],
            Religion = (int)jsonData["religion"],
            Province = (int)jsonData["province"]
        };
    }
}
