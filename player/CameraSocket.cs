using Godot;

namespace Wuxia
{
    public partial class CameraSocket : Node3D
    {
        [Export] private float mouseSensitivity = 0.003f;
        [Export] private float minVerticalAngle = -1.5f;
        [Export] private float maxVerticalAngle = 1.5f;
        [Export] private float edgeScrollSpeed = 1000.0f;
        [Export] private float edgeScrollThreshold = 0.01f; // 1% da tela
        [Export] private float zoomIntensity = 0.5f; // Intensidade de cada passo de zoom
        [Export] private float zoomLerpSpeed = 5.0f; // Velocidade da interpolação do zoom
        [Export] private float minZoomDistance = float.NegativeInfinity; // Distância mínima do ponto de foco
        [Export] private float maxZoomDistance = float.PositiveInfinity; // Distância máxima do ponto de foco

        private const float WATER_LEVEL = 6.0f; // Nível de altura da água no mundo
        private const float MIN_HEIGHT_ABOVE_WATER = 4.0f; // Altura mínima acima da água
        private const float ZOOM_RAY_MAX_LENGTH = 2000.0f; // Comprimento máximo do raio de zoom
        private const float INTERPOLATION_STOP_THRESHOLD = 0.02f; // Limiar para parar a interpolação

        // Máscaras de colisão para o raycast
        private const uint TERRAIN_LAYER = 1; // Camada 1 - terreno
        private const uint RAYCAST_MASK = TERRAIN_LAYER; // Apenas detecta o terreno, ignora a água

        private const float MOVE_FORWARD = 1.0f; // Valor para movimento para frente (eixo Z negativo)
        private const float MOVE_BACKWARD = -1.0f; // Valor para movimento para trás (eixo Z positivo)
        private const float MOVE_RIGHT = 1.0f; // Valor para movimento para direita (eixo X positivo)
        private const float MOVE_LEFT = -1.0f; // Valor para movimento para esquerda (eixo X negativo)
        private const float VIEWPORT_MAX = 1.0f; // Valor máximo da viewport normalizada
        private const float MIN_DISTANCE_THRESHOLD = 0.001f; // Distância mínima para evitar divisão por zero
        private const float DIRECTION_NONE = 0.0f; // Valor para ausência de movimento em um eixo

        private const float CLOSE_HIT_ZOOM_STEP = 5.0f; // Distância a mover quando o hit do zoom é muito próximo
        private const float NO_HIT_ZOOM_STEP = 2000.0f; // Distância a mover quando o raycast do zoom não acerta nada

        private Camera3D camera;
        private float verticalRotation;
        private bool isRightMouseButtonPressed;

        // Variáveis para o zoom e movimento suaves
        private Vector3 targetGlobalPosition;
        private bool isMovingToTarget;

        public override void _Ready()
        {
            camera = GetNode<Camera3D>("Camera3D");
            Input.MouseMode = Input.MouseModeEnum.Visible;
            targetGlobalPosition = GlobalPosition;
        }

        public override void _Input(InputEvent @event)
        {
            HandleMouseButtonInput(@event);
            HandleMouseMotionInput(@event);
            HandleKeyInput(@event);
        }

        public override void _Process(double delta)
        {
            Vector3 edgeMovement = CalculateEdgeScrollMovement(delta, out bool edgeScrollActive);

            UpdateTargetPosition(edgeMovement, edgeScrollActive);

            InterpolateToTargetPosition(delta);

            ClampPositionAltitude();
        }

        private void HandleMouseButtonInput(InputEvent @event)
        {
            if (@event is not InputEventMouseButton mouseButton) return;

            if (mouseButton.ButtonIndex == MouseButton.Right)
            {
                isRightMouseButtonPressed = mouseButton.Pressed;
                Input.MouseMode = isRightMouseButtonPressed ? Input.MouseModeEnum.Captured : Input.MouseModeEnum.Visible;
            }
            else if (mouseButton.ButtonIndex is MouseButton.WheelUp or MouseButton.WheelDown)
            {
                HandleDirectionalZoom(mouseButton.ButtonIndex);
            }
        }

        private void HandleDirectionalZoom(MouseButton buttonIndex)
        {
            float zoomDirection = (buttonIndex == MouseButton.WheelUp) ? MOVE_BACKWARD : MOVE_FORWARD; // -1 para zoom in, 1 para zoom out

            if (TryGetZoomHitPosition(out Vector3 hitPosition))
            {
                // Lógica original: Zoom em direção/afastando-se do ponto de colisão
                Vector3 currentCamPos = GlobalPosition;
                Vector3 dirToHit = hitPosition - currentCamPos;
                float distanceToHit = dirToHit.Length();

                // Calcula o fator de zoom multiplicativo
                // Garante que o zoomIntensity não cause fator <= 0 (idealmente, mantenha zoomIntensity < 1.0)
                float zoomFactor = Mathf.Max(0.1f, VIEWPORT_MAX + (zoomDirection * zoomIntensity));

                float newDistance = distanceToHit * zoomFactor;
                newDistance = Mathf.Clamp(newDistance, minZoomDistance, maxZoomDistance);

                if (distanceToHit > MIN_DISTANCE_THRESHOLD)
                {
                    targetGlobalPosition = hitPosition - (dirToHit.Normalized() * newDistance);
                    isMovingToTarget = true;
                }
                else
                {
                    // Fallback quando o hit é muito próximo: move ao longo do eixo da câmera
                    Vector3 zoomMovement = -camera.GlobalBasis.Z * zoomDirection * CLOSE_HIT_ZOOM_STEP;
                    targetGlobalPosition = GlobalPosition + zoomMovement;
                    isMovingToTarget = true;
                }
            }
            else
            {
                // Fallback quando o raycast não acerta nada: move ao longo do eixo da câmera
                Vector3 zoomMovement = -camera.GlobalBasis.Z * zoomDirection * NO_HIT_ZOOM_STEP;
                targetGlobalPosition = GlobalPosition - zoomMovement;
                isMovingToTarget = true;
            }
        }

        private bool TryGetZoomHitPosition(out Vector3 hitPosition)
        {
            hitPosition = Vector3.Zero;
            Vector2 mousePos = GetViewport().GetMousePosition();
            PhysicsDirectSpaceState3D spaceState = GetWorld3D().DirectSpaceState;
            if (spaceState == null) return false;

            Vector3 rayOrigin = camera.ProjectRayOrigin(mousePos);
            Vector3 rayNormal = camera.ProjectRayNormal(mousePos);

            PhysicsRayQueryParameters3D query = PhysicsRayQueryParameters3D.Create(
                rayOrigin,
                rayOrigin + (rayNormal * ZOOM_RAY_MAX_LENGTH)
            );

            // Configura a máscara de colisão para ignorar a água
            query.CollisionMask = RAYCAST_MASK;

            Godot.Collections.Dictionary result = spaceState.IntersectRay(query);

            if (result.Count > 0)
            {
                hitPosition = (Vector3)result["position"];
                return true;
            }
            return false;
        }

        private void HandleMouseMotionInput(InputEvent @event)
        {
            if (@event is InputEventMouseMotion mouseMotion && isRightMouseButtonPressed)
            {
                // Rotação horizontal (eixo Y do CameraSocket)
                RotateY(-mouseMotion.Relative.X * mouseSensitivity);

                // Rotação vertical (eixo X da Camera3D)
                verticalRotation += -mouseMotion.Relative.Y * mouseSensitivity;
                verticalRotation = Mathf.Clamp(verticalRotation, minVerticalAngle, maxVerticalAngle);
                camera.Rotation = new Vector3(verticalRotation, 0, 0); // Aplicar diretamente na câmera filha
            }
        }

        private void HandleKeyInput(InputEvent @event)
        {
            // Tecla ESC para liberar o mouse
            if (@event is InputEventKey keyEvent && keyEvent.Pressed && keyEvent.Keycode == Key.Escape)
            {
                if (Input.MouseMode == Input.MouseModeEnum.Captured)
                {
                    Input.MouseMode = Input.MouseModeEnum.Visible;
                    isRightMouseButtonPressed = false; // Garante que o estado seja consistente
                }
            }
        }

        private Vector3 CalculateEdgeScrollMovement(double delta, out bool isActive)
        {
            isActive = false;
            if (isRightMouseButtonPressed) return Vector3.Zero; // Não faz edge scroll se o mouse está capturado

            Vector2 mousePosition = GetViewport().GetMousePosition();
            Vector2 viewportSize = GetViewport().GetVisibleRect().Size;
            Vector2 normalizedMousePos = new(
                mousePosition.X / viewportSize.X,
                mousePosition.Y / viewportSize.Y
            );

            Vector3 moveDirection = Vector3.Zero;
            if (normalizedMousePos.X < edgeScrollThreshold) moveDirection.X = MOVE_LEFT;
            else if (normalizedMousePos.X > VIEWPORT_MAX - edgeScrollThreshold) moveDirection.X = MOVE_RIGHT;
            if (normalizedMousePos.Y < edgeScrollThreshold) moveDirection.Z = MOVE_FORWARD; // Eixo Z para profundidade (para frente da câmera)
            else if (normalizedMousePos.Y > VIEWPORT_MAX - edgeScrollThreshold) moveDirection.Z = MOVE_BACKWARD; // Eixo Z para profundidade (para trás da câmera)

            if (moveDirection != Vector3.Zero)
            {
                isActive = true;
                moveDirection = moveDirection.Normalized();
                // Transforma a direção local (baseada nos eixos X/Z) para direção global
                Vector3 forward = -GlobalTransform.Basis.Z * moveDirection.Z; // Frente/Trás relativo à câmera
                Vector3 right = GlobalTransform.Basis.X * moveDirection.X;   // Esquerda/Direita relativo à câmera
                Vector3 worldMove = (forward + right).Normalized();
                // Ignora componente Y para manter movimento no plano horizontal
                worldMove.Y = DIRECTION_NONE;
                // Normaliza novamente caso Y fosse significativo, para manter velocidade constante
                if (worldMove.LengthSquared() > MIN_DISTANCE_THRESHOLD) worldMove = worldMove.Normalized();

                return worldMove * edgeScrollSpeed * (float)delta;
            }

            return Vector3.Zero;
        }

        private void UpdateTargetPosition(Vector3 edgeMovement, bool edgeScrollActive)
        {
            if (edgeScrollActive)
            {
                // Adiciona o movimento da borda à posição alvo
                targetGlobalPosition += edgeMovement;

                // Se não estávamos interpolando o zoom, movemos a câmera diretamente
                // e atualizamos o alvo para a nova posição para evitar 'drift'
                if (!isMovingToTarget)
                {
                    GlobalPosition += edgeMovement;
                    targetGlobalPosition = GlobalPosition; // Sincroniza o alvo com a posição atual
                }
                // Se estávamos interpolando (isMovingToTarget == true), o edgeMovement já foi adicionado
                // ao targetGlobalPosition, então a interpolação vai naturalmente seguir na nova direção.
                isMovingToTarget = true; // Garante que a interpolação continue ou comece
            }
        }

        private void InterpolateToTargetPosition(double delta)
        {
            if (isMovingToTarget)
            {
                GlobalPosition = GlobalPosition.Lerp(targetGlobalPosition, zoomLerpSpeed * (float)delta);

                const float stopThresholdSq = INTERPOLATION_STOP_THRESHOLD * INTERPOLATION_STOP_THRESHOLD;
                if (GlobalPosition.DistanceSquaredTo(targetGlobalPosition) < stopThresholdSq)
                {
                    GlobalPosition = targetGlobalPosition;
                    isMovingToTarget = false;
                }
            }
        }

        private void ClampPositionAltitude()
        {
            float minAllowedY = WATER_LEVEL + MIN_HEIGHT_ABOVE_WATER;

            if (targetGlobalPosition.Y < minAllowedY)
            {
                targetGlobalPosition.Y = minAllowedY;
            }
            if (GlobalPosition.Y < minAllowedY)
            {
                GlobalPosition = new Vector3(GlobalPosition.X, minAllowedY, GlobalPosition.Z);
                // Se a posição atual foi forçada para cima, atualiza o alvo também
                // para evitar que a interpolação tente descer novamente.
                if (targetGlobalPosition.Y < GlobalPosition.Y)
                {
                    targetGlobalPosition.Y = GlobalPosition.Y;
                }
            }
        }
    }
}