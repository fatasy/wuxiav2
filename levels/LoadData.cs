using System.Collections.Generic;
using System.Linq;
using Godot;

public partial class LoadData : Node
{
    [Export]
    private string jsonPath = "res://assets/map/data.json";
    private readonly List<Cell> cells = [];
    public List<Cell> GetCells()
    {
        return cells;
    }

    public readonly List<Province> provinces = [];
    private CanvasLayer labelsLayer;
    private readonly Dictionary<string, Label> provinceLabels = [];

    public List<Province> GetProvinces()
    {
        return provinces;
    }


    private Godot.Collections.Dictionary LoadJsonData()
    {
        GD.Print("Tentando carregar JSON de: ", jsonPath);

        if (!FileAccess.FileExists(jsonPath))
        {
            GD.PrintErr("Arquivo JSON não encontrado: ", jsonPath);
            return null;
        }

        using FileAccess jsonFile = FileAccess.Open(jsonPath, FileAccess.ModeFlags.Read);
        if (jsonFile == null)
        {
            GD.PrintErr("Não foi possível abrir o arquivo JSON: ", jsonPath);
            return null;
        }

        string jsonText = jsonFile.GetAsText();
        Json json = new();
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

        GD.Print("Dados do mapa carregados com sucesso!");
        return data.AsGodotDictionary();
    }

    public override void _Ready()
    {
        Godot.Collections.Dictionary data = LoadJsonData();
        if (data == null)
        {
            return;
        }

        // Criar CanvasLayer para as labels
        labelsLayer = new CanvasLayer
        {
            Name = "ProvincesLabelsLayer"
        };
        AddChild(labelsLayer);

        Godot.Collections.Dictionary cellsData = data["cells"].AsGodotDictionary();
        GenereteCells(cellsData["cells"].AsGodotArray());
        GenereteProvices(cellsData["provinces"].AsGodotArray());
    }

    private void GenereteCells(Godot.Collections.Array cellsData)
    {
        foreach (Variant cell in cellsData)
        {
            cells.Add(Cell.FromJsonData(cell.AsGodotDictionary()));
        }
        GD.Print("Cells gerados com sucesso!");
    }


    public void GenereteProvices(Godot.Collections.Array provincesData)
    {
        foreach (Variant province in provincesData)
        {
            if (province.VariantType != Variant.Type.Dictionary)
            {
                continue;
            }

            Province provinceData = Province.FromJsonData(province.AsGodotDictionary());

            // Criar uma Label para cada província
            Label provinceLabel = new()
            {
                Text = provinceData.name,
                HorizontalAlignment = HorizontalAlignment.Center
            };
            provinceLabel.AddThemeColorOverride("font_color", Colors.Black);

            // Adicionar a label ao CanvasLayer
            labelsLayer.AddChild(provinceLabel);

            // Guardar referência à label para atualização
            provinceLabels[provinceData.id.ToString()] = provinceLabel;

            provinces.Add(provinceData);
            AddChild(provinceData);
        }
        GD.Print("Provinces gerados com sucesso!");
    }

    public override void _Process(double delta)
    {
        // Verificar se há uma câmera 2D na cena
        Camera2D camera = GetViewport().GetCamera2D();
        if (camera == null)
        {
            return; // Sem câmera, não podemos calcular a posição na tela
        }

        // Atualizar posições das labels
        foreach (Province province in provinces)
        {
            if (provinceLabels.TryGetValue(province.id.ToString(), out Label label))
            {
                // Coordenadas do mundo
                Vector2 worldPosition = new(province.pole[0], province.pole[1]);

                // Converter para posição na tela
                // Subtrair a posição da câmera e adicionar metade do tamanho da viewport
                Vector2 viewportSize = GetViewport().GetVisibleRect().Size;
                Vector2 screenPosition = worldPosition - camera.GlobalPosition + (viewportSize / 2);

                // Centralizar a label horizontalmente
                Vector2 labelSize = label.GetCombinedMinimumSize();
                screenPosition.X -= labelSize.X / 2;

                label.Position = screenPosition;
            }


        }
    }

    public Province GetProvinceById(int id)
    {

        return provinces.FirstOrDefault(p => p.id == id);
    }

    public List<Cell> GetCellsByProvinceId(int id)
    {
        return cells.Where(c => c.Province == id).ToList();
    }
}