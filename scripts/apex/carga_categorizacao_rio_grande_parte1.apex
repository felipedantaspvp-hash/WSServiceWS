// Pacote: carga Rio Grande - PARTE 1/2: Gestao de SLA + Categorizacao__c
// Recarrega a Gestao de SLA "Atendimento Rio Grande" e as Categorizacoes a partir da planilha
// "Arvore x SLA (11-06-2026).xlsx" (aba Rio Grande, 273 linhas). EscopoRegra__c='Area Interna'
// (fora do escopo da planilha) NAO e preservado, por decisao explicita do usuario.
// Dividido em 2 partes por limite de tamanho do bloco anonimo de Apex; rodar a PARTE 2 logo apos.
//
// Formato de cada linha do bloco de dados (5 campos, separados por TAB): TipoCaso Categoria Assunto Subassunto PrioridadePadrao

Id gestaoSlaId = 'a3Nbe000000Q1BlEAK';
Id recordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Categorizacao__c' AND DeveloperName = 'AtendimentoTeconRioGrande' LIMIT 1].Id;

// 1) Gestao de SLA: liga Triagem (60min) e corrige Resposta Chat para 5min, conforme planilha.
GestaoSLA__c gestao = [SELECT Id, UsaTempoTriagem__c, TempoTriagemMinutos__c, UsaTempoRespostaChat__c, TempoRespostaChatMinutos__c FROM GestaoSLA__c WHERE Id = :gestaoSlaId];
gestao.UsaTempoTriagem__c = true;
gestao.TempoTriagemMinutos__c = 60;
gestao.UsaTempoRespostaChat__c = true;
gestao.TempoRespostaChatMinutos__c = 5;
update gestao;
System.debug('GESTAO_SLA_ATUALIZADA: Triagem=60min RespostaChat=5min');

// 2) Apaga a carga anterior. Filtra por UnidadeNegocios__c (e nao so por GestaoSLA__c) porque
//    existem 259 Categorizacoes legadas de Rio Grande (criadas em 22/05, sem GestaoSLA__c
//    preenchido) que colidem por chave natural com as novas linhas da planilha; o usuario
//    confirmou explicitamente que essas legadas tambem devem ser removidas nesta carga.
//    Cascata Master-Detail remove tambem as RegrasSLACategorizacao__c filhas (incluindo as de
//    escopo "Area Interna", que o usuario decidiu nao preservar).
List<Categorizacao__c> antigas = [SELECT Id FROM Categorizacao__c WHERE UnidadeNegocios__c = 'Atendimento Tecon Rio Grande'];
System.debug('CATEGORIZACOES_ANTIGAS_REMOVIDAS=' + antigas.size());
delete antigas;

// 3) Mapa de prioridade da planilha (PT) para o valor de picklist (API).
Map<String, String> prioridadeMap = new Map<String, String>{
    'Baixa' => 'Low',
    'Média' => 'Medium',
    'Alta' => 'High'
};

// 4) Dados da planilha (273 linhas, aba Rio Grande), campos separados por TAB.
String dadosPlanilha =
    '''
Informação	Comercial	Valores/Serviços		Média
Informação	Comercial	Cadastro Pessoa Física	Criação	Média
Informação	Comercial	Cadastro Pessoa Física	Atualização	Média
Informação	Comercial	Cadastro Pessoa Física	Status de aprovação	Média
Informação	Comercial	Cadastro Pessoa Jurídica	Status de aprovação	Média
Informação	Comercial	Cadastro Pessoa Jurídica	Criação	Média
Informação	Comercial	Cadastro Pessoa Jurídica	Atualização	Média
Informação	Marketing	Comunicados	Reenvio	Média
Informação	Marketing	Comunicados	Atualização de E-mail	Média
Informação	Comercial	Conversa externa	Cliente x Departamento	Média
Informação	Comercial	Conversa externa	Cliente x Cliente	Média
Informação	RH	Currículo		Média
Informação	Comercial	Encaminhamento	Setor Responsável	Média
Informação	Comercial	WS Acesso	Status de aprovação	Média
Informação	Comercial	WS Acesso	Criação	Média
Informação	Comercial	WS Acesso	Exclusão	Média
Informação	Comercial	WS Acesso	Atualização	Média
Informação	Faturamento	Nota Fiscal	Cancelamento	Média
Informação	Faturamento	Nota Fiscal	Informações	Média
Informação	Faturamento	Nota Fiscal	Previsão de Emissão	Média
Informação	Financeiro	Contas a pagar	Reembolso	Média
Informação	Financeiro	Contas a pagar	Cadastro Fornecedor	Média
Informação	Financeiro	Fatura	Detalhamento de Pendências	Média
Informação	Financeiro	Fatura	Identificação de Pagamentos	Média
Informação	Financeiro	Fatura	Prorrogação	Média
Informação	Financeiro	Fatura	Isenção de Juros	Média
Informação	Financeiro	Fatura	Reenvio de Nota Fiscal	Média
Informação	Financeiro	Fatura	Reenvio de Boleto	Média
Informação	SMS	Cargas perigosas / Especiais	Procedimentos	Média
Informação	SMS	Cargas perigosas / Especiais	Cargas Aceitas/ Não Aceitas	Média
Informação	SMS	Cargas perigosas / Especiais	Colocação / Remoção Label	Média
Informação	Santa Clara	Agendamento	Procedimentos	Média
Informação	Operação	Armazéns	Procedimentos	Média
Informação	Operação	Armazéns	Lacres	Média
Informação	Operação	Pátio	Status de Atendimento	Média
Informação	Operação	Pátio	Confirmação de Posição	Média
Informação	Operação	Navio	Programação de Navios	Média
Informação	Operação	Navio	Status de Operação	Média
Informação	Operação	Navio	Alteração da Programação	Média
Informação	Operação	Navio	LAR	Média
''' +
    '''
Informação	Operação	Agendamento	Alterações	Média
Informação	Operação	Agendamento	Documentação	Média
Informação	Operação	Agendamento	Entrega Antecipada	Média
Informação	Operação	Agendamento	Gold	Média
Informação	Operação	Agendamento	Liberação Especial	Média
Informação	Operação	Agendamento	Vagas e Horários	Média
Informação	Operação	Avaria	Registro de avaria	Média
Informação	Operação	Avaria	Contestação	Média
Informação	Operação	Avaria	Solicitação de vistoria	Média
Informação	Operação	Avaria	Indenização	Média
Informação	Operação	Booking	EDI	Média
Informação	Operação	Pesagem	Status	Média
Elogio	Faturamento	Ajustes de OS	Cancelamento	Média
Elogio	Comercial	Ajustes de OS	Valor	Média
Elogio	Faturamento	Ajustes de OS	CNPJ	Média
Elogio	Faturamento	Ajustes de OS	Criação	Média
Elogio	Comercial	Ajustes de OS	Descontos	Média
Elogio	Comercial	Ajustes de OS	Isenções	Média
Elogio	Comercial	Ajustes de OS	Descontos e Isenções	Média
Elogio	Faturamento	Ajustes de OS	Nomenclatura	Média
Elogio	Comercial	Proposta Comercial	Alteração	Média
Elogio	Comercial	Proposta Comercial	Criação	Média
Elogio	Comercial	Proposta Comercial	Renovação	Média
Elogio	Comercial	Valores/Serviços		Média
Elogio	Comercial	Cadastro Pessoa Física	Criação	Média
Elogio	Comercial	Cadastro Pessoa Física	Exclusão	Média
Elogio	Comercial	Cadastro Pessoa Física	Atualização	Média
Elogio	Comercial	Cadastro Pessoa Física	Status de aprovação	Média
Elogio	Comercial	Cadastro Pessoa Jurídica	Status de aprovação	Média
Elogio	Comercial	Cadastro Pessoa Jurídica	Criação	Média
Elogio	Comercial	Cadastro Pessoa Jurídica	Exclusão	Média
Elogio	Comercial	Cadastro Pessoa Jurídica	Atualização	Média
Elogio	Inteligência de Mercado	Cadastro Pessoa Jurídica	Grupo Econômico	Média
Elogio	Marketing	Comunicados	Reenvio	Média
Elogio	Marketing	Comunicados	Atualização de E-mail	Média
Elogio	Comercial	Conversa externa	Cliente x Departamento	Média
Elogio	Comercial	Conversa externa	Cliente x Cliente	Média
Elogio	RH	Currículo		Média
Elogio	Comercial	Encaminhamento	Setor Responsável	Média
Elogio	Comercial	Notificação automática		Média
''' +
    '''
Elogio	Comercial	WS Acesso	Status de aprovação	Média
Elogio	Comercial	WS Acesso	Criação	Média
Elogio	Comercial	WS Acesso	Exclusão	Média
Elogio	Comercial	WS Acesso	Atualização	Média
Elogio	Faturamento	Nota Fiscal	Cancelamento	Média
Elogio	Faturamento	Nota Fiscal	Informações	Média
Elogio	Faturamento	PO / Draft	PO / Draft	Média
Elogio	Faturamento	Nota Fiscal	Previsão de Emissão	Média
Elogio	Faturamento	Solicitação para faturar	Solicitação para faturar	Média
Elogio	Financeiro	Fatura	Compensação de Pagamento	Média
Elogio	Financeiro	Contas a pagar	Reembolso	Média
Elogio	Financeiro	Contas a pagar	Cadastro Fornecedor	Média
Elogio	Financeiro	Fatura	Detalhamento de Pendências	Média
Elogio	Financeiro	Fatura	Identificação de Pagamentos	Média
Elogio	Financeiro	Fatura	Prorrogação	Média
Elogio	Financeiro	Fatura	Isenção de Juros	Média
Elogio	Financeiro	Fatura	Reenvio de Nota Fiscal	Média
Elogio	Financeiro	Fatura	Reenvio de Boleto	Média
Elogio	Sistema	Teconline	Instabilidade / Lentidão	Média
Elogio	Sistema	Teconline	Acesso indisponível	Média
Elogio	Sistema	Teconline	Informação inconsistente	Média
Elogio	Sistema	EDI	Falha de envio	Média
Elogio	Sistema	EDI	Falha de recebimento	Média
Elogio	Sistema	EDI	Integração com erro	Média
Elogio	Sistema	EDI	Divergência de dados	Média
Elogio	Sistema	EDI	Layout inválido	Média
Elogio	SMS	Cargas perigosas / Especiais	Procedimentos	Média
Elogio	SMS	Cargas perigosas / Especiais	Cargas Aceitas/ Não Aceitas	Média
Elogio	SMS	Cargas perigosas / Especiais	Colocação / Remoção Label	Média
Elogio	Santa Clara	Agendamento	Procedimentos	Média
Elogio	Santa Clara	Falha de Recebimento	Stiff Barcaça	Média
Elogio	Santa Clara	Falha de Recebimento	EDI Nfe	Média
Elogio	Operação	Armazéns	Procedimentos	Média
Elogio	Operação	Armazéns	Lacres	Média
Elogio	Operação	Pátio	Morosidade	Média
Elogio	Operação	Pátio	Status de Atendimento	Média
Elogio	Operação	Pátio	Confirmação de Posição	Média
Elogio	Operação	Navio	Programação de Navios	Média
Elogio	Operação	Navio	Status de Operação	Média
Elogio	Operação	Navio	Alteração da Programação	Média
''' +
    '''
Elogio	Operação	Navio	LAR	Média
Elogio	Operação	Agendamento	Alterações	Média
Elogio	Operação	Agendamento	Documentação	Média
Elogio	Operação	Agendamento	Entrega Antecipada	Média
Elogio	Operação	Agendamento	Gold	Média
Elogio	Operação	Agendamento	Liberação Especial	Média
Elogio	Operação	Agendamento	Vagas e Horários	Média
Elogio	Operação	Avaria	Registro de avaria	Média
Elogio	Operação	Avaria	Contestação	Média
Elogio	Operação	Avaria	Solicitação de vistoria	Média
Elogio	Operação	Avaria	Indenização	Média
Elogio	Operação	Booking	Criação	Média
Elogio	Operação	Booking	Alteração	Média
Elogio	Operação	Booking	EDI	Média
Elogio	Operação	Booking	Saldo	Média
Elogio	Operação	Pesagem	Solicitação	Média
Elogio	Operação	Pesagem	Status	Média
Elogio	Operação	Pesagem	Ticket	Média
Elogio	Operação	Presença de carga	Status	Média
Elogio	Operação	Presença de carga	Alterações	Média
Elogio	Operação	Carta Protesto		Média
Elogio	Operação	Relatórios	Ticket de Pesagem	Média
Elogio	Operação	Relatórios	Relatório de Movimentações	Média
Elogio	Operação	Relatórios	Consulta Contêiner	Média
Elogio	Operação	Relatórios	Consulta Booking	Média
Elogio	Operação	Relatórios	EIR	Média
Elogio	Operação	Relatórios	Lista de navio	Média
Solicitação	Faturamento	Ajustes de OS	Cancelamento	Média
Solicitação	Comercial	Ajustes de OS	Valor	Média
Solicitação	Faturamento	Ajustes de OS	CNPJ	Média
Solicitação	Faturamento	Ajustes de OS	Criação	Média
Solicitação	Comercial	Ajustes de OS	Descontos	Média
Solicitação	Comercial	Ajustes de OS	Isenções	Média
Solicitação	Comercial	Ajustes de OS	Descontos e Isenções	Média
Solicitação	Faturamento	Ajustes de OS	Nomenclatura	Média
Solicitação	Comercial	Proposta Comercial	Alteração	Média
Solicitação	Comercial	Proposta Comercial	Criação	Média
Solicitação	Comercial	Proposta Comercial	Renovação	Média
Solicitação	Comercial	Valores/Serviços		Média
Solicitação	Comercial	Cadastro Pessoa Física	Criação	Média
''' +
    '''
Solicitação	Comercial	Cadastro Pessoa Física	Exclusão	Média
Solicitação	Comercial	Cadastro Pessoa Física	Atualização	Média
Solicitação	Comercial	Cadastro Pessoa Jurídica	Criação	Média
Solicitação	Comercial	Cadastro Pessoa Jurídica	Exclusão	Média
Solicitação	Comercial	Cadastro Pessoa Jurídica	Atualização	Média
Solicitação	Inteligência de Mercado	Cadastro Pessoa Jurídica	Grupo Econômico	Média
Solicitação	Marketing	Comunicados	Reenvio	Média
Solicitação	Marketing	Comunicados	Atualização de E-mail	Média
Solicitação	Comercial	Conversa externa	Cliente x Departamento	Média
Solicitação	Comercial	Conversa externa	Cliente x Cliente	Média
Solicitação	RH	Currículo		Média
Solicitação	Comercial	Encaminhamento	Setor Responsável	Média
Solicitação	Comercial	Notificação automática		Média
Solicitação	Comercial	WS Acesso	Atualização	Média
Solicitação	Faturamento	Nota Fiscal	Cancelamento	Média
Solicitação	Faturamento	PO / Draft	PO / Draft	Média
Solicitação	Faturamento	Solicitação para faturar	Solicitação para faturar	Média
Solicitação	Financeiro	Fatura	Compensação de Pagamento	Média
Solicitação	Financeiro	Contas a pagar	Reembolso	Média
Solicitação	Financeiro	Contas a pagar	Cadastro Fornecedor	Média
Solicitação	Financeiro	Fatura	Detalhamento de Pendências	Média
Solicitação	Financeiro	Fatura	Identificação de Pagamentos	Média
Solicitação	Financeiro	Fatura	Prorrogação	Média
Solicitação	Financeiro	Fatura	Isenção de Juros	Média
Solicitação	Financeiro	Fatura	Reenvio de Nota Fiscal	Média
Solicitação	Financeiro	Fatura	Reenvio de Boleto	Média
Solicitação	SMS	Cargas perigosas / Especiais	Procedimentos	Média
Solicitação	SMS	Cargas perigosas / Especiais	Cargas Aceitas/ Não Aceitas	Média
Solicitação	SMS	Cargas perigosas / Especiais	Colocação / Remoção Label	Média
Solicitação	Santa Clara	Agendamento	Procedimentos	Média
Solicitação	Santa Clara	Falha de Recebimento	Stiff Barcaça	Média
Solicitação	Santa Clara	Falha de Recebimento	EDI Nfe	Média
Solicitação	Operação	Pátio	Status de Atendimento	Média
Solicitação	Operação	Pátio	Confirmação de Posição	Média
Solicitação	Operação	Navio	Alteração da Programação	Média
Solicitação	Operação	Navio	LAR	Média
Solicitação	Operação	Agendamento	Alterações	Média
Solicitação	Operação	Agendamento	Documentação	Média
Solicitação	Operação	Agendamento	Entrega Antecipada	Média
Solicitação	Operação	Agendamento	Gold	Média
''' +
    '''
Solicitação	Operação	Agendamento	Liberação Especial	Média
Solicitação	Operação	Agendamento	Vagas e Horários	Média
Solicitação	Operação	Booking	Criação	Média
Solicitação	Operação	Booking	Alteração	Média
Solicitação	Operação	Booking	EDI	Média
Solicitação	Operação	Pesagem	Status	Média
Solicitação	Operação	Pesagem	Ticket	Média
Solicitação	Operação	Presença de carga	Alterações	Média
Solicitação	Operação	Carta Protesto		Média
Solicitação	Operação	Relatórios	Ticket de Pesagem	Média
Solicitação	Operação	Relatórios	Relatório de Movimentações	Média
Solicitação	Operação	Relatórios	Consulta Contêiner	Média
Solicitação	Operação	Relatórios	Consulta Booking	Média
Solicitação	Operação	Relatórios	EIR	Média
Solicitação	Operação	Relatórios	Lista de navio	Média
Reclamação	Comercial	Valores/Serviços		Média
Reclamação	Comercial	Cadastro Pessoa Física	Criação	Média
Reclamação	Comercial	Cadastro Pessoa Física	Exclusão	Média
Reclamação	Comercial	Cadastro Pessoa Física	Atualização	Média
Reclamação	Comercial	Cadastro Pessoa Física	Status de aprovação	Média
Reclamação	Comercial	Cadastro Pessoa Jurídica	Status de aprovação	Média
Reclamação	Comercial	Cadastro Pessoa Jurídica	Criação	Média
Reclamação	Comercial	Cadastro Pessoa Jurídica	Exclusão	Média
Reclamação	Comercial	Cadastro Pessoa Jurídica	Atualização	Média
Reclamação	Marketing	Comunicados	Reenvio	Média
Reclamação	Marketing	Comunicados	Atualização de E-mail	Média
Reclamação	RH	Currículo		Média
Reclamação	Comercial	WS Acesso	Status de aprovação	Média
Reclamação	Comercial	WS Acesso	Criação	Média
Reclamação	Comercial	WS Acesso	Exclusão	Média
Reclamação	Comercial	WS Acesso	Atualização	Média
Reclamação	Faturamento	Nota Fiscal	Cancelamento	Média
Reclamação	Financeiro	Contas a pagar	Cadastro Fornecedor	Média
Reclamação	Financeiro	Fatura	Detalhamento de Pendências	Média
Reclamação	Financeiro	Fatura	Identificação de Pagamentos	Média
Reclamação	Financeiro	Fatura	Prorrogação	Média
Reclamação	Financeiro	Fatura	Isenção de Juros	Média
Reclamação	Financeiro	Fatura	Reenvio de Nota Fiscal	Média
Reclamação	Financeiro	Fatura	Reenvio de Boleto	Média
Reclamação	Sistema	Teconline	Instabilidade / Lentidão	Média
''' +
    '''
Reclamação	Sistema	Teconline	Acesso indisponível	Média
Reclamação	Sistema	Teconline	Informação inconsistente	Média
Reclamação	Sistema	EDI	Falha de envio	Média
Reclamação	Sistema	EDI	Falha de recebimento	Média
Reclamação	Sistema	EDI	Integração com erro	Média
Reclamação	Sistema	EDI	Divergência de dados	Média
Reclamação	Sistema	EDI	Layout inválido	Média
Reclamação	SMS	Cargas perigosas / Especiais	Procedimentos	Média
Reclamação	SMS	Cargas perigosas / Especiais	Cargas Aceitas/ Não Aceitas	Média
Reclamação	SMS	Cargas perigosas / Especiais	Colocação / Remoção Label	Média
Reclamação	Santa Clara	Agendamento	Procedimentos	Média
Reclamação	Operação	Armazéns	Procedimentos	Média
Reclamação	Operação	Armazéns	Lacres	Média
Reclamação	Operação	Pátio	Morosidade	Média
Reclamação	Operação	Agendamento	Entrega Antecipada	Média
Reclamação	Operação	Agendamento	Gold	Média
Reclamação	Operação	Agendamento	Liberação Especial	Média
Reclamação	Operação	Agendamento	Vagas e Horários	Média
Incidente	Faturamento	Nota Fiscal	Cancelamento	Média
Incidente	Faturamento	Nota Fiscal	Previsão de Emissão	Média
Incidente	Sistema	Teconline	Instabilidade / Lentidão	Média
Incidente	Sistema	Teconline	Acesso indisponível	Média
Incidente	Sistema	Teconline	Informação inconsistente	Média
Incidente	Sistema	EDI	Falha de envio	Média
Incidente	Sistema	EDI	Falha de recebimento	Média
Incidente	Sistema	EDI	Integração com erro	Média
Incidente	Sistema	EDI	Divergência de dados	Média
Incidente	Sistema	EDI	Layout inválido	Média
Incidente	Operação	Avaria	Registro de avaria	Média
Incidente	Operação	Avaria	Contestação	Média
Incidente	Operação	Avaria	Solicitação de vistoria	Média
Incidente	Operação	Avaria	Indenização	Média
Incidente	Operação	Booking	Criação	Média
''';

List<String> linhas = dadosPlanilha.trim().split('\n');
System.debug('LINHAS_PLANILHA=' + linhas.size());

List<Categorizacao__c> novasCats = new List<Categorizacao__c>();

for (String linha : linhas) {
    List<String> campos = linha.split('\t');

    Categorizacao__c cat = new Categorizacao__c();
    cat.RecordTypeId = recordTypeId;
    cat.TipoCaso__c = campos[0];
    cat.Categoria__c = campos[1];
    cat.Assunto__c = campos[2];
    cat.Subassunto__c = String.isBlank(campos[3]) ? null : campos[3];
    cat.GestaoSLA__c = gestaoSlaId;
    cat.UnidadeNegocios__c = 'Atendimento Tecon Rio Grande';
    cat.Ativo__c = true;
    String prioridadePlanilha = campos[4];
    cat.Prioridade__c = prioridadeMap.containsKey(prioridadePlanilha) ? prioridadeMap.get(prioridadePlanilha) : null;
    novasCats.add(cat);
}

insert novasCats;
System.debug('CATEGORIZACOES_INSERIDAS=' + novasCats.size());
System.debug('PARTE_1_CONCLUIDA');
