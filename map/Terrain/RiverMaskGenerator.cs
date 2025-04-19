using Godot;
using System;

public partial class RiverMaskGenerator : Node
{
    [Export] public string inputMapPath = "res://assets/map/rivers/river_map.png";
    [Export] public string outputMaskPath = "res://assets/map/rivers/river_mask.png";
    [Export] public Color riverColor = new(0.0f, 0.0f, 1.0f); // Azul
    [Export] public float tolerance = 0.2f;
    [Export] public int blurRadius = 2;

    // Botão para gerar a máscara do editor
    [Export] public bool generateMask = false;

    [Obsolete]
    public override void _Process(double delta)
    {
        // Verifica se o botão foi pressionado no editor
        if (generateMask)
        {
            generateMask = false; // Reseta o botão
            GenerateRiverMask();
        }
    }

    [Obsolete]
    public void GenerateRiverMask()
    {
        GD.Print("Gerando máscara de rio...");

        // Verifica se o arquivo de mapa existe
        if (!ResourceLoader.Exists(inputMapPath))
        {
            GD.PrintErr($"Mapa não encontrado: {inputMapPath}");
            return;
        }

        // Carrega a imagem do mapa
        Image mapImage = Image.LoadFromFile(inputMapPath);
        if (mapImage == null)
        {
            GD.PrintErr($"Falha ao carregar mapa: {inputMapPath}");
            return;
        }

        // Cria uma nova imagem para a máscara
        Image maskImage = Image.Create(mapImage.GetWidth(), mapImage.GetHeight(), false, Image.Format.L8);

        // Define toda a máscara como preta/transparente
        maskImage.Fill(new Color(0, 0, 0, 1));

        // Processa cada pixel da imagem de mapa
        for (int x = 0; x < mapImage.GetWidth(); x++)
        {
            for (int y = 0; y < mapImage.GetHeight(); y++)
            {
                // Obtém a cor do pixel
                Color pixelColor = mapImage.GetPixel(x, y);

                // Verifica se a cor é próxima da cor do rio
                if (IsColorSimilar(pixelColor, riverColor, tolerance))
                {
                    // Define o pixel como branco na máscara (rio)
                    maskImage.SetPixel(x, y, new Color(1, 1, 1, 1));
                }
            }
        }

        // Aplica blur para suavizar a máscara (opcional)
        if (blurRadius > 0)
        {
            maskImage = ApplyBlur(maskImage, blurRadius);
        }

        // Salva a máscara
        Error err = maskImage.SavePng(outputMaskPath);
        if (err != Error.Ok)
        {
            GD.PrintErr($"Erro ao salvar máscara: {err}");
            return;
        }

        GD.Print($"Máscara de rio gerada com sucesso: {outputMaskPath}");
    }

    private static bool IsColorSimilar(Color a, Color b, float tolerance)
    {
        return Math.Abs(a.R - b.R) < tolerance &&
               Math.Abs(a.G - b.G) < tolerance &&
               Math.Abs(a.B - b.B) < tolerance;
    }

    [Obsolete]
    private static Image ApplyBlur(Image image, int radius)
    {
        // Cria uma nova imagem com o mesmo tamanho
        Image blurredImage = Image.Create(image.GetWidth(), image.GetHeight(), false, Image.Format.L8);

        // Copia o conteúdo da imagem original para a nova
        blurredImage.BlitRect(image, new Rect2I(0, 0, image.GetWidth(), image.GetHeight()), new Vector2I(0, 0));

        // Aplica blur simples (média de pixels vizinhos)
        for (int x = radius; x < image.GetWidth() - radius; x++)
        {
            for (int y = radius; y < image.GetHeight() - radius; y++)
            {
                float sum = 0;
                int count = 0;

                // Pega média dos pixels vizinhos
                for (int dx = -radius; dx <= radius; dx++)
                {
                    for (int dy = -radius; dy <= radius; dy++)
                    {
                        Color neighborColor = image.GetPixel(x + dx, y + dy);
                        sum += neighborColor.R; // Como é L8, só pegamos o canal vermelho
                        count++;
                    }
                }

                // Define o pixel com a média calculada
                float avgValue = sum / count;
                blurredImage.SetPixel(x, y, new Color(avgValue, avgValue, avgValue, 1));
            }
        }

        return blurredImage;
    }
}