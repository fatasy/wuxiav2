using Godot;
using Godot.Collections;

public static class VariantExtensions
{
    public static int[] AsInt32Array(this Variant variant)
    {
        Array array = variant.AsGodotArray();
        int[] result = new int[array.Count];
        for (int i = 0; i < array.Count; i++)
        {
            result[i] = array[i].AsInt32();
        }
        return result;
    }
}

public partial class Province : Node
{

    public int id { get; set; }
    public string name { get; set; }
    public string fullName { get; set; }
    public string slug { get; set; }
    public string region { get; set; }
    public string regionSlug { get; set; }
    public string regionName { get; set; }
    public string color { get; set; }
    public int state { get; set; }
    public int center { get; set; }
    public int burg { get; set; }
    public string formName { get; set; }
    public dynamic coa { get; set; }
    public int[] pole { get; set; }

    public static Province FromJsonData(Dictionary jsonData)
    {
        return new Province
        {
            id = (int)jsonData["i"],
            name = (string)jsonData["name"],
            fullName = (string)jsonData["fullName"],
            color = (string)jsonData["color"],
            state = (int)jsonData["state"],
            center = (int)jsonData["center"],
            burg = (int)jsonData["burg"],
            formName = (string)jsonData["formName"],
            coa = jsonData["coa"],
            pole = (int[])jsonData["pole"]
        };
    }

    public static bool IsValidId(int id)
    {
        return id != 0;
    }
}
