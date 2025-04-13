using Godot;

public partial class CameraIndicator : Node3D
{
    private MeshInstance3D _indicator;
    private StandardMaterial3D _material;
    private Label3D _positionLabel;

    public override void _Ready()
    {
        // Criar um cubo como indicador
        _indicator = new MeshInstance3D();
        _indicator.Mesh = new BoxMesh();
        _indicator.Mesh.Set("size", new Vector3(0.5f, 0.5f, 0.5f)); // Tamanho pequeno

        // Criar material vermelho brilhante
        _material = new StandardMaterial3D();
        _material.EmissionEnabled = true;
        _material.Emission = new Color(1, 0, 0); // Vermelho
        _material.EmissionEnergyMultiplier = 2.0f; // Brilho aumentado

        _indicator.MaterialOverride = _material;
        AddChild(_indicator);

        // Criar label 3D para mostrar a posição
        _positionLabel = new Label3D();
        _positionLabel.Text = "Posição da Câmera";
        _positionLabel.FontSize = 32;
        _positionLabel.Position = new Vector3(0, 1, 0); // Posicionar acima do cubo
        AddChild(_positionLabel);

        GD.Print("CameraIndicator inicializado");
    }

    public override void _Process(double delta)
    {
        // O indicador sempre seguirá a posição da câmera
        if (GetViewport().GetCamera3D() != null)
        {
            Position = GetViewport().GetCamera3D().GlobalPosition;
            _positionLabel.Text = $"Pos: {Position.X:F1}, {Position.Y:F1}, {Position.Z:F1}";
            GD.Print($"Posição da câmera: {Position}");
        }
        else
        {
            GD.Print("Câmera não encontrada!");
        }
    }
}