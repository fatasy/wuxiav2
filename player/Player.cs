using Godot;
using System;

namespace Wuxia
{
    public partial class Player : Node3D
    {
        [Export]
        private Camera3D camera;

        public event Action<Vector3> OnProviceSelected;

        public override void _Ready()
        {
            camera = GetNode<Camera3D>("CameraSocket/Camera3D");
        }

        private void _unhandled_input(InputEvent @event)
        {
            if (@event is InputEventMouseButton mouseButton && mouseButton.ButtonIndex == MouseButton.Left && mouseButton.Pressed)
            {
                Camera3D camera = GetViewport().GetCamera3D();
                Vector2 mousePos = GetViewport().GetMousePosition();
                ShootRay(camera, mousePos);
            }
        }

        private void ShootRay(Camera3D camera, Vector2 mousePos)
        {
            Vector3 from = camera.ProjectRayOrigin(mousePos);
            Vector3 to = from + (camera.ProjectRayNormal(mousePos) * 10000);

            PhysicsRayQueryParameters3D query = new()
            {
                From = from,
                To = to,
                CollideWithAreas = false,
                CollideWithBodies = true
            };

            PhysicsDirectSpaceState3D spaceState = GetWorld3D().DirectSpaceState;
            Godot.Collections.Dictionary result = spaceState.IntersectRay(query);

            if (result.Count > 0 && result.ContainsKey("position"))
            {
                OnProviceSelected?.Invoke((Vector3)result["position"]);
            }
        }
    }
}
