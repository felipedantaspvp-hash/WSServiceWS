# 02 - Metodos Apex reutilizados

Metodos existentes em `AreaParticipanteController`:

- `pauseParticipation(AreaParticipanteDTO.PauseResumeRequestDTO request)`
- `resumeParticipation(AreaParticipanteDTO.PauseResumeRequestDTO request)`

Contrato chamado pelo LWC:

```js
{ request: { areaParticipanteId: itemId } }
```

Nenhum metodo Apex novo foi criado.

As flags `canPause` e `canResume` sao calculadas no backend durante a montagem do `PanelDTO`, sem criar novo endpoint.
