# Evidencia 07 - UTF-8 sem BOM

Validacao requerida para todos os arquivos do pacote:

- XML, Markdown e SOQL salvos em UTF-8 sem BOM.
- Verificacao realizada em todos os arquivos da pasta `Deltas/delta_gestao_sla_destructive_campos_legados/`.
- Resultado: nenhum arquivo apresentou BOM (`False` para todos os arquivos inspecionados).
- `package.xml` nao usa wildcard.
- Todos os arquivos criados pertencem somente ao escopo do pacote destrutivo 16B.
