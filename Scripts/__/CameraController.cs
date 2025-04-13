using Godot;
using System;

public partial class CameraController : Node3D
{
    [Export] public float RotationSpeed = 2.0f;
    [Export] public float ZoomSpeed = 2.0f;
    [Export] public float MinDistance = 5.0f;
    [Export] public float MaxDistance = 100.0f;
    [Export] public float MinPitch = -80.0f;
    [Export] public float MaxPitch = 80.0f;

    private Camera3D _camera;
    private float _distance = 50.0f;
    private float _yaw = 0.0f;
    private float _pitch = 45.0f;
    private Vector3 _targetPosition = Vector3.Zero;

    public override void _Ready()
    {
        _camera = GetNode<Camera3D>("Camera3D");
        UpdateCameraPosition();
    }

    public override void _Input(InputEvent @event)
    {
        if (@event is InputEventMouseMotion mouseMotion && Input.IsMouseButtonPressed(MouseButton.Right))
        {
            _yaw -= mouseMotion.Relative.X * RotationSpeed * 0.01f;
            _pitch = Mathf.Clamp(_pitch - mouseMotion.Relative.Y * RotationSpeed * 0.01f, MinPitch, MaxPitch);
            UpdateCameraPosition();
        }
        else if (@event is InputEventMouseButton mouseButton)
        {
            if (mouseButton.ButtonIndex == MouseButton.WheelUp)
            {
                _distance = Mathf.Max(_distance - ZoomSpeed, MinDistance);
                UpdateCameraPosition();
            }
            else if (mouseButton.ButtonIndex == MouseButton.WheelDown)
            {
                _distance = Mathf.Min(_distance + ZoomSpeed, MaxDistance);
                UpdateCameraPosition();
            }
        }
    }

    private void UpdateCameraPosition()
    {
        // Calcular posição da câmera baseada em yaw, pitch e distância
        float yawRad = Mathf.DegToRad(_yaw);
        float pitchRad = Mathf.DegToRad(_pitch);

        float x = _distance * Mathf.Cos(pitchRad) * Mathf.Sin(yawRad);
        float y = _distance * Mathf.Sin(pitchRad);
        float z = _distance * Mathf.Cos(pitchRad) * Mathf.Cos(yawRad);

        _camera.Position = new Vector3(x, y, z);
        _camera.LookAt(_targetPosition);
    }

    public void SetTargetPosition(Vector3 position)
    {
        _targetPosition = position;
        UpdateCameraPosition();
    }

    public void SetInitialDistance(float distance)
    {
        _distance = Mathf.Clamp(distance, MinDistance, MaxDistance);
        UpdateCameraPosition();
    }
}