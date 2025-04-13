using Godot;

public static class JsonHelper
{
    public static Godot.Collections.Dictionary Load(string path)
    {
        GD.Print("Tentando carregar JSON de: ", path);

        if (!FileAccess.FileExists(path))
        {
            GD.PrintErr("Arquivo JSON não encontrado: ", path);
            return null;
        }

        using FileAccess jsonFile = FileAccess.Open(path, FileAccess.ModeFlags.Read);
        if (jsonFile == null)
        {
            GD.PrintErr("Não foi possível abrir o arquivo JSON: ", path);
            return null;
        }

        string jsonText = jsonFile.GetAsText();
        var json = new Godot.Json();
        Error error = json.Parse(jsonText);

        if (error != Error.Ok)
        {
            GD.PrintErr("Erro ao analisar o JSON: ", json.GetErrorMessage());
            GD.PrintErr("Linha do erro: ", json.GetErrorLine());
            return null;
        }

        Variant data = json.Data;
        if (data.VariantType == Variant.Type.Nil)
        {
            GD.PrintErr("Dados JSON nulos após parsing");
            return null;
        }

        var result = data.AsGodotDictionary();

        GD.Print("Dados do mapa carregados com sucesso!");
        return result;
    }
}