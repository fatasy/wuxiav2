using Godot;
using System.Linq;
using System.Collections.Generic;

namespace Wuxia
{
    public partial class TerrainInkMaterial : ShaderMaterial
    {
        private const string BasePath = "res://assets/map/terrain";

        public TerrainInkMaterial()
        {
            Shader = GD.Load<Shader>("res://Shaders/TerrainInk.gdshader");

            // Definir valores padrão para os parâmetros do shader
            // SetShaderParameter("base_texture", new Texture2D());
            SetShaderParameter("base_normal_map", GD.Load<Texture2D>(Paths.NormalMap));
            SetShaderParameter("province_map", GD.Load<Texture2D>(Paths.ProvinceMap));
            SetShaderParameter("highlight_color", new Color(1.0f, 0.5f, 0.0f, 0.5f));
            SetShaderParameter("selected_province_color", -1);

            // Carregar todas as texturas ao inicializar
            LoadAllTextures();
        }

        private void LoadAllTextures()
        {
            // Obter todos os nomes base a partir dos arquivos diffuse
            List<string> baseNames = GetBaseNames();

            if (baseNames.Count == 0)
            {
                GD.PrintErr("Nenhuma textura de terreno encontrada em: " + BasePath);
                return;
            }

            // Carregar todas as texturas na mesma ordem
            Texture2D[] diffuseTextures = new Texture2D[baseNames.Count];
            Texture2D[] normalTextures = new Texture2D[baseNames.Count];
            Texture2D[] maskTextures = new Texture2D[baseNames.Count];
            Texture2D[] propertyTextures = new Texture2D[baseNames.Count];

            for (int i = 0; i < baseNames.Count; i++)
            {
                string baseName = baseNames[i];
                string diffusePath = $"{BasePath}/{baseName}_diffuse.png";
                string normalPath = $"{BasePath}/{baseName}_normal.png";
                string maskPath = $"{BasePath}/{baseName}_mask.png";
                string propertyPath = $"{BasePath}/{baseName}_properties.png";

                // Carregar as texturas ou usar fallbacks se não existirem
                diffuseTextures[i] = FileExists(diffusePath) ? GD.Load<Texture2D>(diffusePath) : new Texture2D();
                normalTextures[i] = FileExists(normalPath) ? GD.Load<Texture2D>(normalPath) : new Texture2D();
                maskTextures[i] = FileExists(maskPath) ? GD.Load<Texture2D>(maskPath) : new Texture2D();
                propertyTextures[i] = FileExists(propertyPath) ? GD.Load<Texture2D>(propertyPath) : new Texture2D();

                GD.Print($"Carregado conjunto de texturas para: {baseName}");
            }

            // Definir os parâmetros do shader
            SetShaderParameter("layer_textures", diffuseTextures);
            SetShaderParameter("layer_normal_maps", normalTextures);
            SetShaderParameter("layer_masks", maskTextures);
            SetShaderParameter("layer_properties", propertyTextures);
        }

        private static List<string> GetBaseNames()
        {
            List<string> baseNames = [];
            string[] diffuseFiles = GetSortedFiles(BasePath, "*_diffuse.png");

            foreach (string file in diffuseFiles)
            {
                // Extrair o nome base do caminho completo do arquivo
                string fileName = System.IO.Path.GetFileName(file);
                string baseName = fileName.Replace("_diffuse.png", "");
                baseNames.Add(baseName);
            }

            return baseNames;
        }

        private static bool FileExists(string path)
        {
            return FileAccess.FileExists(path);
        }

        private static string[] GetSortedFiles(string directory, string pattern)
        {
            DirAccess dir = DirAccess.Open(directory);
            if (dir == null)
            {
                GD.PrintErr($"Não foi possível abrir o diretório: {directory}");
                return [];
            }

            _ = dir.ListDirBegin();

            List<string> files = [];
            string fileName = dir.GetNext();

            while (!string.IsNullOrEmpty(fileName))
            {
                if (!dir.CurrentIsDir() && FileMatchesPattern(fileName, pattern))
                {
                    files.Add($"{directory}/{fileName}");
                }
                fileName = dir.GetNext();
            }

            dir.ListDirEnd();

            return [.. files.OrderBy(static f => f)];
        }

        private static bool FileMatchesPattern(string fileName, string pattern)
        {
            // Converte o padrão glob para regex simples
            string regexPattern = "^" + pattern.Replace(".", "\\.").Replace("*", ".*") + "$";
            return System.Text.RegularExpressions.Regex.IsMatch(fileName, regexPattern);
        }
    }
}
