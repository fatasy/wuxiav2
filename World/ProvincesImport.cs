using Godot;

namespace World
{
    public partial class ProvincesImport : Node
    {
        private const string DEFINITION_FILE_PATH = "res://assets/map/definition.csv";

        public override void _Ready()
        {
            if (!FileAccess.FileExists(DEFINITION_FILE_PATH))
            {
                GD.PrintErr($"Arquivo não encontrado: {DEFINITION_FILE_PATH}");
                return;
            }

            FileAccess file = FileAccess.Open(DEFINITION_FILE_PATH, FileAccess.ModeFlags.Read);
            string definition = file.GetAsText();
            file.Close();

            string[] definitionArray = definition.Split('\n');
            foreach (string definitionItem in definitionArray)
            {
                string[] definitionItemArray = definitionItem.Split(';');


                string id = definitionItemArray[0];
                string red = definitionItemArray[1];
                string green = definitionItemArray[2];
                string blue = definitionItemArray[3];
                string name = definitionItemArray[4];

                Province province = new(int.Parse(id), name, $"{red},{green},{blue}");
                AddChild(province);
            }
        }
    }
}
