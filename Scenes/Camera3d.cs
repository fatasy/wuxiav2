using Godot;
using System;

public partial class Camera3d : Node3D
{
    [Export]
    public float MoveSpeed = 0.1f;
    [Export]
    public float MouseSensitivity = 0.002f;
    [Export]
    public float ZoomSpeed = 1.0f;
    [Export]
    public float MinZoom = 5.0f;
    [Export]
    public float MaxZoom = 50.0f;
    [Export]
    public float RotationSpeed = 0.01f;
    [Export]
    public float InitialHeight = 20.0f; // Altura inicial da câmera

    private Vector3 _position;
    private float _rotationX = 0.0f;
    private float _rotationY = 0.0f;
    private bool _isMoving = false;
    private Vector2 _lastMousePosition;

    public override void _Ready()
    {
        // Posição inicial da câmera
        _position = new Vector3(0, InitialHeight, 0);
        Position = _position;

        // Rotação inicial para olhar para baixo
        Rotation = new Vector3(Mathf.Pi / 4, 0, 0);
        Input.MouseMode = Input.MouseModeEnum.Visible;
    }

    public override void _Input(InputEvent @event)
    {
        if (@event is InputEventMouseButton mouseButton)
        {
            if (mouseButton.ButtonIndex == MouseButton.Left)
            {
                _isMoving = mouseButton.Pressed;
                if (_isMoving)
                {
                    _lastMousePosition = mouseButton.Position;
                }
            }
            else if (mouseButton.ButtonIndex == MouseButton.WheelUp)
            {
                _position.Y = Mathf.Clamp(_position.Y - ZoomSpeed, MinZoom, MaxZoom);
            }
            else if (mouseButton.ButtonIndex == MouseButton.WheelDown)
            {
                _position.Y = Mathf.Clamp(_position.Y + ZoomSpeed, MinZoom, MaxZoom);
            }
            else if (mouseButton.ButtonIndex == MouseButton.Right && mouseButton.Pressed)
            {
                _lastMousePosition = mouseButton.Position;
            }
        }
        else if (@event is InputEventMouseMotion mouseMotion)
        {
            if (_isMoving)
            {
                Vector2 delta = mouseMotion.Position - _lastMousePosition;
                _lastMousePosition = mouseMotion.Position;

                Vector3 direction = new Vector3(-delta.X, 0, -delta.Y) * MoveSpeed;
                _position += Transform.Basis * direction;
            }
            else if (Input.IsMouseButtonPressed(MouseButton.Right))
            {
                Vector2 delta = mouseMotion.Position - _lastMousePosition;
                _lastMousePosition = mouseMotion.Position;

                _rotationX -= delta.Y * RotationSpeed;
                _rotationY -= delta.X * RotationSpeed;

                // Limitar a rotação X para evitar a câmera virar de cabeça para baixo
                _rotationX = Mathf.Clamp(_rotationX, -Mathf.Pi / 2, Mathf.Pi / 2);

                Rotation = new Vector3(_rotationX, _rotationY, 0);
            }
        }
    }

    public override void _Process(double delta)
    {
        Vector3 direction = Vector3.Zero;

        if (Input.IsKeyPressed(Key.W))
            direction -= Transform.Basis.Z;
        if (Input.IsKeyPressed(Key.S))
            direction += Transform.Basis.Z;
        if (Input.IsKeyPressed(Key.A))
            direction -= Transform.Basis.X;
        if (Input.IsKeyPressed(Key.D))
            direction += Transform.Basis.X;

        if (direction != Vector3.Zero)
        {
            direction = direction.Normalized();
            _position += direction * MoveSpeed * (float)delta;
        }

        Position = _position;
    }
}
