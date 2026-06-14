# Evidencia 09 - Pendencias pos-deploy

Depois do deploy destrutivo bem-sucedido:

1. Remover do repositorio os 4 arquivos `field-meta.xml` listados em `scripts/04_arquivos_repositorio_para_remover.md`.
2. Atualizar o delta principal ou pacote subsequente para refletir a remocao desses arquivos-fonte.
3. Registrar a validacao pos-deploy conforme `scripts/03_validacao_pos_destructive.md`.
4. Se o deploy real precisar respeitar o gate de `RunLocalTests`, resolver antes o problema global ligado a `DataMass.remarkProductMass()` ou obter aceite formal de governanca para a limitacao conhecida.
