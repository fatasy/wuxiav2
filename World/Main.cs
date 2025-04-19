using Godot;

namespace Wuxia
{
    public partial class Main : Node3D
    {
        [Export] public Player player;
        [Export] public MapGenerator Map;
        [Export] public Texture2D ProvinceMap;
        public override void _Ready()
        {

            player.OnProviceSelected += HandleProvinceSelected;
        }

        private void HandleProvinceSelected(Vector3 position)
        {

            float width = ProvinceMap.GetWidth();
            float height = ProvinceMap.GetHeight();

            float x = (position.X + (width * Map.Scale / 2f)) / (width * Map.Scale);
            float y = (position.Z + (height * Map.Scale / 2f)) / (height * Map.Scale);

            int pixelX = Mathf.Clamp((int)(x * width), 0, ProvinceMap.GetWidth() - 1);
            int pixelY = Mathf.Clamp((int)(y * height), 0, ProvinceMap.GetHeight() - 1);

            Color pixelColor = ProvinceMap.GetImage().GetPixel(pixelX, pixelY);


            string color = pixelColor.ToHtml();
            GD.Print(color);
            Map.UpdateProvinceHighlight(pixelColor);
        }

        public override void _ExitTree()
        {
            if (player != null)
            {
                // player.OnProviceSelected -= HandleProvinceSelected;
            }
        }
    }
}

