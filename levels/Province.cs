using Godot;




namespace World
{

    public partial class Province(int id, string name, string color) : Node
    {

        public int id { get; set; } = id;
        public string name { get; set; } = name;

        public string color { get; set; } = color;

        public static bool IsValidId(int id)
        {
            return id != 0;
        }

    }
}