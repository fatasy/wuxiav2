using Godot;
using System.Linq;

public partial class Vertex : Node
{
    public int Index { get; set; }
    public int[] Vertices { get; set; }
    public int[] CValues { get; set; }
    public Vector3 Position { get; set; }

    public static Vertex FromJsonData(Godot.Collections.Dictionary jsonData)
    {
        Godot.Collections.Array verticesArray = (Godot.Collections.Array)jsonData["v"];
        Godot.Collections.Array cValuesArray = (Godot.Collections.Array)jsonData["c"];
        Godot.Collections.Array positionArray = (Godot.Collections.Array)jsonData["p"];

        return new Vertex
        {
            Index = (int)jsonData["i"],
            Vertices = verticesArray.Select(static v => (int)v).ToArray(),
            CValues = cValuesArray.Select(static c => (int)c).ToArray(),
            Position = new Vector3((float)positionArray[0], 0, (float)positionArray[1])
        };
    }
}
