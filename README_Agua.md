# Sistema de Água Estilo CK3 para Godot 4 C#

Este sistema de água foi inspirado nos parâmetros do arquivo `water.settings` do Crusader Kings III, adaptado para funcionar no motor Godot 4 com C#.

## Configuração

Para configurar o sistema de água no seu projeto:

1. **Adicione os arquivos necessários ao seu projeto:**
   - `WaterShader.gdshader` - Shader para renderização da água
   - `WaterManager.cs` - Script para gerenciar as propriedades da água

2. **Crie as texturas necessárias:**
   - Textura de normais para ondas (2 texturas)
   - Textura de espuma
   - Textura de ruído

3. **Configure a cena:**

```gdscript
# Exemplo de estrutura de cena
- World (Node3D)
  - Terrain (MeshInstance3D)
  - Water (MeshInstance3D + WaterManager)
    - Configure o material do shader
    - Configure as referências de textura
```

## Uso

1. Crie uma malha plana para a água (pode usar um `PlaneMesh` ou um modelo personalizado)
2. Crie um novo material `ShaderMaterial` e atribua o shader `WaterShader.gdshader`
3. Anexe o script `WaterManager.cs` ao nó da água
4. Configure as referências e parâmetros no inspetor
5. Ajuste os valores para combinar com o estilo visual do seu jogo

## Parâmetros Importantes

Os parâmetros foram adaptados diretamente do arquivo `water.settings` do CK3:

- **Cores:**
  - `waterColorShallow` - Cor em águas rasas
  - `waterColorDeep` - Cor em águas profundas

- **Reflexão/Refração:**
  - `waterFresnelBias` - Afeta como a luz é refletida na água
  - `waterFresnelPow` - Controla a intensidade do efeito fresnel
  - `waterRefractionScale` - Controla quanto a água refrata

- **Ondas:**
  - Parâmetros para 2 camadas de ondas (scale, rotation, speed, flatten)
  - Baseados nos parâmetros WaterWave1, WaterWave2 e WaterWave3 do CK3

- **Espuma:**
  - `waterFoamScale` - Tamanho da espuma, valor menor = espuma maior
  - `waterFoamStrength` - Intensidade da espuma

## Extensão

Para expandir esse sistema, você pode:

1. Adicionar suporte para caustics (efeito de luz no fundo da água)
2. Implementar ondas dinâmicas que reagem a objetos
3. Adicionar sistema de partículas para salpicos

## Dicas de Otimização

- Para mapas grandes, use níveis de detalhe (LOD) para a malha de água
- Reduza a complexidade do shader em dispositivos de baixo desempenho
- Use uma resolução menor para texturas em dispositivos móveis 