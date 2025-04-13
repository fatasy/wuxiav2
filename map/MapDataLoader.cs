using Godot;

public static class MapDataLoader
{
    private static bool _isLoaded;
    private static string _lastLoadedPath;

    public static void LoadMapData(string jsonPath)
    {
        if (_isLoaded && _lastLoadedPath == jsonPath)
        {
            GD.Print("Dados do mapa já carregados anteriormente");
            return;
        }

        var jsonData = JsonHelper.Load(jsonPath);
        if (jsonData == null)
        {
            GD.PrintErr("Falha ao carregar dados do mapa");
            return;
        }




        _isLoaded = true;
        _lastLoadedPath = jsonPath;
        GD.Print("Dados do mapa carregados com sucesso");
    }

    public static void ReloadMapData()
    {
        if (string.IsNullOrEmpty(_lastLoadedPath))
        {
            GD.PrintErr("Nenhum caminho de arquivo anterior encontrado para recarregar");
            return;
        }

        _isLoaded = false;
        LoadMapData(_lastLoadedPath);
    }
}