using Godot;
using System;

namespace Wuxia
{
    public partial class CameraManager : Node3D
    {
        private const float CameraMaxPitch = 70f * (float)Math.PI / 180f;
        private const float CameraMinPitch = -89.9f * (float)Math.PI / 180f;
        private const float CameraRatio = 0.625f;

        [Export]
        public float MouseSensitivity { get; set; } = 0.002f;

        [Export]
        public float MouseYInversion { get; set; } = -1.0f;

        private Node3D _cameraYaw;
        private Node3D _cameraPitch;

        public override void _Ready()
        {
            Input.MouseMode = Input.MouseModeEnum.Captured;

            _cameraYaw = this;
            _cameraPitch = GetNode<Node3D>("%Arm");
        }

        public override void _Input(InputEvent @event)
        {
            if (@event is InputEventMouseMotion mouseMotion && Input.MouseMode == Input.MouseModeEnum.Captured)
            {
                RotateCamera(mouseMotion.Relative);
                GetViewport().SetInputAsHandled();
                return;
            }
        }

        private void RotateCamera(Vector2 relative)
        {
            _cameraYaw.Rotation = new Vector3(
                _cameraYaw.Rotation.X,
                _cameraYaw.Rotation.Y - (relative.X * MouseSensitivity),
                _cameraYaw.Rotation.Z
            );

            _cameraYaw.Orthonormalize();

            _cameraPitch.Rotation = new Vector3(
                Mathf.Clamp(
                    _cameraPitch.Rotation.X + (relative.Y * MouseSensitivity * CameraRatio * MouseYInversion),
                    CameraMinPitch,
                    CameraMaxPitch
                ),
                _cameraPitch.Rotation.Y,
                _cameraPitch.Rotation.Z
            );
        }
    }
}