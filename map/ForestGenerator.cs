using Godot;
using System;
using System.Collections.Generic;

namespace Wuxia
{
    public partial class ForestGenerator : Node3D
    {
        [Export] public Texture2D ForestMask { get; set; }
        [Export] public float Density = 0.5f;
        [Export] public Mesh TreeMesh { get; set; }
        [Export] public Material TreeMaterial { get; set; }
        [Export] public int MaxTrees = 10000;
        [Export] public Vector2 ScaleRange = new Vector2(0.8f, 1.2f);
        [Export] public MapGenerator TerrainNode { get; set; }
        [Export] public float PositionVariation = 2.5f;

        private MultiMeshInstance3D _multiMesh;
        private Random _random = new Random();

        public override void _Ready()
        {
            if (!ValidateRequiredComponents())
                return;

            TerrainNode.OnFinishedGenerating += GenerateForest;
        }

        private bool ValidateRequiredComponents()
        {
            if (ForestMask == null || TreeMesh == null || TerrainNode == null)
            {
                GD.PrintErr("ForestGenerator: Mask, TreeMesh ou TerrainNode não definidos!");
                return false;
            }

            return true;
        }

        public void GenerateForest(bool success)
        {
            if (!success)
                return;

            GD.Print("Generating Forest");
            InitializeMultiMesh();
            GenerateTreeInstances();
            GD.Print("Forest generated");
        }

        private void InitializeMultiMesh()
        {
            if (_multiMesh != null)
                _multiMesh.QueueFree();

            _multiMesh = new MultiMeshInstance3D();
            AddChild(_multiMesh);

            var multiMesh = new MultiMesh
            {
                TransformFormat = MultiMesh.TransformFormatEnum.Transform3D,
                UseColors = false,
                Mesh = TreeMesh
            };

            _multiMesh.Multimesh = multiMesh;

            if (TreeMaterial != null)
                _multiMesh.MaterialOverride = TreeMaterial;
        }

        private void GenerateTreeInstances()
        {
            if (ForestMask == null)
                return;

            Image maskImage = ForestMask.GetImage();
            maskImage.Decompress();

            List<Transform3D> transforms = GenerateTreeTransforms(maskImage);
            ApplyTreeTransforms(transforms);
        }

        private List<Transform3D> GenerateTreeTransforms(Image maskImage)
        {
            List<Transform3D> transforms = new List<Transform3D>();
            int width = maskImage.GetWidth();
            int height = maskImage.GetHeight();

            float mapScale = TerrainNode.Scale;
            float halfWidth = width * mapScale / 2;
            float halfHeight = height * mapScale / 2;
            float terrainHeight = TerrainNode.HeightScale;

            GD.Print($"Map Scale: {mapScale}, Half Width: {halfWidth}, Half Height: {halfHeight}");

            int step = CalculateDistributionStep();
            transforms = PopulateForestRegions(maskImage, width, height, step, mapScale, halfWidth, halfHeight, terrainHeight);

            return transforms.Count > MaxTrees ? transforms.GetRange(0, MaxTrees) : transforms;
        }

        private int CalculateDistributionStep()
        {
            return Mathf.Max(1, (int)(1.0f / Density));
        }

        private List<Transform3D> PopulateForestRegions(
            Image maskImage, int width, int height, int step,
            float mapScale, float halfWidth, float halfHeight, float terrainHeight)
        {
            List<Transform3D> transforms = new List<Transform3D>();

            for (int x = 0; x < width; x += step)
            {
                for (int y = 0; y < height; y += step)
                {
                    Color pixelColor = maskImage.GetPixel(x, y);

                    if (pixelColor.R <= 0.5f)
                        continue;

                    Vector3 position = CalculateTreePosition(x, y, mapScale, halfWidth, halfHeight, pixelColor, terrainHeight);
                    Transform3D transform = CreateTreeTransform(position);
                    transforms.Add(transform);
                }
            }

            return transforms;
        }

        private Vector3 CalculateTreePosition(
            int x, int y, float mapScale, float halfWidth, float halfHeight,
            Color pixelColor, float terrainHeight)
        {
            Vector3 position = new Vector3(
                (x * mapScale) - halfWidth,
                0,
                (y * mapScale) - halfHeight
            );

            position.X += (float)_random.NextDouble() * PositionVariation * 2 - PositionVariation;
            position.Z += (float)_random.NextDouble() * PositionVariation * 2 - PositionVariation;

            float heightValue = pixelColor.R;
            position.Y = heightValue * terrainHeight;

            return position;
        }

        private Transform3D CreateTreeTransform(Vector3 position)
        {
            Transform3D transform = Transform3D.Identity;

            // Aplicar escala
            float randomScale = (float)_random.NextDouble() * (ScaleRange.Y - ScaleRange.X) + ScaleRange.X;
            transform = transform.Scaled(new Vector3(randomScale, randomScale, randomScale));

            // Rotação aleatória no eixo Y
            float randomYRotation = (float)_random.NextDouble() * Mathf.Pi * 2.0f;
            Basis rotatedYBasis = new Basis(Vector3.Up, randomYRotation);
            transform.Basis = rotatedYBasis * transform.Basis;

            // Definir posição
            transform.Origin = position;

            return transform;
        }

        private void ApplyTreeTransforms(List<Transform3D> transforms)
        {
            var multiMesh = _multiMesh.Multimesh;
            multiMesh.InstanceCount = transforms.Count;
            GD.Print($"Gerando {transforms.Count} árvores");

            for (int i = 0; i < transforms.Count; i++)
            {
                multiMesh.SetInstanceTransform(i, transforms[i]);
            }
        }

        public void UpdateForest()
        {
            GenerateForest(true);
        }
    }
}