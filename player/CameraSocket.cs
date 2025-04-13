using Godot;

public partial class CameraSocket : Node3D
{
    [Export]
    private float mouseSensitivity = 0.003f;

    [Export]
    private float minVerticalAngle = -1.5f;

    [Export]
    private float maxVerticalAngle = 1.5f;

    [Export]
    private float edgeScrollSpeed = 550.0f;

    [Export]
    private float edgeScrollThreshold = 0.05f; // 5% da tela

    [Export]
    private float zoomSpeed = 0.5f;

    [Export]
    private float minZoom = -6.0f;

    [Export]
    private float maxZoom = 100.0f;

    [Export]
    private float currentZoom = 6.0f;

    private Camera3D camera;
    private float verticalRotation;

    private bool isRightMouseButtonPressed;

    public override void _Ready()
    {
        camera = GetNode<Camera3D>("Camera3D");
        Input.MouseMode = Input.MouseModeEnum.Captured;

        // Configura o zoom inicial

        camera.GlobalPosition = new Vector3(0, 10, -10);
        camera.LookAt(Vector3.Zero, Vector3.Up);
    }

    private void UpdateCameraZoom()
    {
        if (camera != null)
        {
            camera.Position = new Vector3(0, 0, currentZoom);
        }
    }

    public override void _Input(InputEvent @event)
    {
        if (@event is InputEventMouseButton mouseButton)
        {
            if (mouseButton.ButtonIndex == MouseButton.Right)
            {
                isRightMouseButtonPressed = mouseButton.Pressed;
                Input.MouseMode = isRightMouseButtonPressed ?
                    Input.MouseModeEnum.Captured :
                    Input.MouseModeEnum.Visible;
            }
            // Detecta o scroll do mouse
            else if (mouseButton.ButtonIndex == MouseButton.WheelUp)
            {
                currentZoom = Mathf.Clamp(currentZoom - zoomSpeed, minZoom, maxZoom);
                UpdateCameraZoom();
            }
            else if (mouseButton.ButtonIndex == MouseButton.WheelDown)
            {
                currentZoom = Mathf.Clamp(currentZoom + zoomSpeed, minZoom, maxZoom);
                UpdateCameraZoom();
            }
        }

        if (@event is InputEventMouseMotion mouseMotion && isRightMouseButtonPressed)
        {
            // Rotação horizontal (eixo Y)
            RotateY(-mouseMotion.Relative.X * mouseSensitivity);

            // Rotação vertical (eixo X)
            verticalRotation += -mouseMotion.Relative.Y * mouseSensitivity;
            verticalRotation = Mathf.Clamp(verticalRotation, minVerticalAngle, maxVerticalAngle);

            // Aplica a rotação vertical na câmera
            camera.Rotation = new Vector3(verticalRotation, 0, 0);
        }

        // Tecla ESC para liberar o mouse
        if (@event is InputEventKey keyEvent && keyEvent.Keycode == Key.Escape)
        {
            Input.MouseMode = Input.MouseModeEnum.Visible;
        }
    }

    public override void _Process(double delta)
    {
        if (!isRightMouseButtonPressed)
        {
            Vector2 mousePosition = GetViewport().GetMousePosition();
            Vector2 viewportSize = GetViewport().GetVisibleRect().Size;

            // Calcula a posição normalizada do mouse (0 a 1)
            Vector2 normalizedMousePos = new(
                mousePosition.X / viewportSize.X,
                mousePosition.Y / viewportSize.Y
            );

            // Calcula a direção do movimento baseado na posição do mouse
            Vector3 moveDirection = Vector3.Zero;

            // Verifica as bordas da tela
            if (normalizedMousePos.X < edgeScrollThreshold)
            {
                moveDirection.X -= 1;
            }
            else if (normalizedMousePos.X > 1 - edgeScrollThreshold)
            {
                moveDirection.X += 1;
            }

            if (normalizedMousePos.Y < edgeScrollThreshold)
            {
                moveDirection.Z -= 1; // Usa o eixo Z para evitar movimento vertical incorreto
            }
            else if (normalizedMousePos.Y > 1 - edgeScrollThreshold)
            {
                moveDirection.Z += 1; // Usa o eixo Z para evitar movimento vertical incorreto
            }

            // Normaliza o vetor de movimento
            if (moveDirection != Vector3.Zero)
            {
                moveDirection = moveDirection.Normalized();

                // Obtém o plano horizontal (XZ) da transformação global
                Vector3 right = new Vector3(GlobalTransform.Basis.X.X, 0, GlobalTransform.Basis.X.Z).Normalized();
                Vector3 forward = new Vector3(GlobalTransform.Basis.Z.X, 0, GlobalTransform.Basis.Z.Z).Normalized();

                // Calcula o movimento no plano horizontal (XZ)
                Vector3 movement = ((right * moveDirection.X) + (forward * moveDirection.Z)) * edgeScrollSpeed * (float)delta;

                // Mantém a altura (Y) constante
                movement.Y = 0;

                // Move o nó em relação ao mundo
                GlobalPosition += movement;
            }
        }
    }
}
