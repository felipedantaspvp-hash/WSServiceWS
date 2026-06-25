// Pacote: carga Rio Grande - PARTE 2/2: RegrasSLACategorizacao__c (escopo Atendimento)
// Roda APOS a PARTE 1 (que ja criou as Categorizacao__c). Casa cada linha da planilha com a
// Categorizacao__c correspondente pela chave Tipo|Categoria|Assunto|Subassunto e cria uma
// RegrasSLACategorizacao__c por marco preenchido (Primeira Resposta N2, Atendimento,
// Atendimento N3, Retorno N3, SLA Total).
//
// Formato de cada linha do bloco de dados (19 campos, separados por TAB):
// TipoCaso Categoria Assunto Subassunto
// N2Alta N2Normal N2Baixa AtendAlta AtendNormal AtendBaixa
// AtendN3Alta AtendN3Normal AtendN3Baixa RetN3Alta RetN3Normal RetN3Baixa
// SLAAlta SLANormal SLABaixa
// Campos de tempo em minutos, vazio = marco nao se aplica aquela categorizacao/prioridade.

Id gestaoSlaId = 'a3Nbe000000Q1BlEAK';

// 1) Categorizacoes recem-criadas na PARTE 1, indexadas pela mesma chave usada nos dados abaixo.
Map<String, Id> catByKey = new Map<String, Id>();
for (Categorizacao__c c : [SELECT Id, TipoCaso__c, Categoria__c, Assunto__c, Subassunto__c FROM Categorizacao__c WHERE GestaoSLA__c = :gestaoSlaId]) {
    String key = c.TipoCaso__c + '|' + c.Categoria__c + '|' + c.Assunto__c + '|' + (c.Subassunto__c == null ? '' : c.Subassunto__c);
    catByKey.put(key, c.Id);
}
System.debug('CATEGORIZACOES_ENCONTRADAS=' + catByKey.size());

// 2) Mapa de MarcoSLA__c (todos ja existem e ativos para esta Gestao de SLA).
Map<String, Id> marcoByName = new Map<String, Id>();
for (MarcoSLA__c m : [SELECT Id, NomeMarco__c FROM MarcoSLA__c WHERE GestaoSLA__c = :gestaoSlaId]) {
    marcoByName.put(m.NomeMarco__c, m.Id);
}
System.debug('MARCOS_ENCONTRADOS=' + marcoByName.keySet());

// 3) Dados da planilha (273 linhas, aba Rio Grande), campos separados por TAB.
String dadosPlanilha =
    '''
Informação	Comercial	Valores/Serviços		60	60	60	360	360	360							720	720	720
Informação	Comercial	Cadastro Pessoa Física	Criação	60	60	60	360	360	360							720	720	720
Informação	Comercial	Cadastro Pessoa Física	Atualização	60	60	60	360	360	360							720	720	720
Informação	Comercial	Cadastro Pessoa Física	Status de aprovação	60	60	60	360	360	360							720	720	720
Informação	Comercial	Cadastro Pessoa Jurídica	Status de aprovação	60	60	60	360	360	360							720	720	720
Informação	Comercial	Cadastro Pessoa Jurídica	Criação	60	60	60	360	360	360							720	720	720
Informação	Comercial	Cadastro Pessoa Jurídica	Atualização	60	60	60	360	360	360							720	720	720
Informação	Marketing	Comunicados	Reenvio	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Informação	Marketing	Comunicados	Atualização de E-mail	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Informação	Comercial	Conversa externa	Cliente x Departamento	60	60	60	360	360	360							720	720	720
Informação	Comercial	Conversa externa	Cliente x Cliente	60	60	60	360	360	360							720	720	720
Informação	RH	Currículo		60	60	60	360	360	360							720	720	720
Informação	Comercial	Encaminhamento	Setor Responsável	60	60	60	360	360	360							720	720	720
Informação	Comercial	WS Acesso	Status de aprovação	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Informação	Comercial	WS Acesso	Criação	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Informação	Comercial	WS Acesso	Exclusão	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Informação	Comercial	WS Acesso	Atualização	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Informação	Faturamento	Nota Fiscal	Cancelamento	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Informação	Faturamento	Nota Fiscal	Informações	60	60	60	360	360	360							720	720	720
Informação	Faturamento	Nota Fiscal	Previsão de Emissão	60	60	60	360	360	360							720	720	720
Informação	Financeiro	Contas a pagar	Reembolso	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Informação	Financeiro	Contas a pagar	Cadastro Fornecedor	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Informação	Financeiro	Fatura	Detalhamento de Pendências	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Informação	Financeiro	Fatura	Identificação de Pagamentos	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Informação	Financeiro	Fatura	Prorrogação	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Informação	Financeiro	Fatura	Isenção de Juros	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Informação	Financeiro	Fatura	Reenvio de Nota Fiscal	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Informação	Financeiro	Fatura	Reenvio de Boleto	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Informação	SMS	Cargas perigosas / Especiais	Procedimentos	60	60	60	360	360	360							720	720	720
Informação	SMS	Cargas perigosas / Especiais	Cargas Aceitas/ Não Aceitas	60	60	60	360	360	360							720	720	720
Informação	SMS	Cargas perigosas / Especiais	Colocação / Remoção Label	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Informação	Santa Clara	Agendamento	Procedimentos	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Informação	Operação	Armazéns	Procedimentos	60	60	60	360	360	360							720	720	720
Informação	Operação	Armazéns	Lacres	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Informação	Operação	Pátio	Status de Atendimento	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Informação	Operação	Pátio	Confirmação de Posição	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Informação	Operação	Navio	Programação de Navios	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Informação	Operação	Navio	Status de Operação	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Informação	Operação	Navio	Alteração da Programação	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Informação	Operação	Navio	LAR	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
''' +
    '''
Informação	Operação	Agendamento	Alterações	60	60	60	360	360	360							720	720	720
Informação	Operação	Agendamento	Documentação	60	60	60	360	360	360							720	720	720
Informação	Operação	Agendamento	Entrega Antecipada	60	60	60	360	360	360							720	720	720
Informação	Operação	Agendamento	Gold	60	60	60	360	360	360							720	720	720
Informação	Operação	Agendamento	Liberação Especial	60	60	60	360	360	360							720	720	720
Informação	Operação	Agendamento	Vagas e Horários	60	60	60	360	360	360							720	720	720
Informação	Operação	Avaria	Registro de avaria	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Informação	Operação	Avaria	Contestação	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Informação	Operação	Avaria	Solicitação de vistoria	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Informação	Operação	Avaria	Indenização	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Informação	Operação	Booking	EDI	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Informação	Operação	Pesagem	Status	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Elogio	Faturamento	Ajustes de OS	Cancelamento	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Elogio	Comercial	Ajustes de OS	Valor	60	60	60	360	360	360							720	720	720
Elogio	Faturamento	Ajustes de OS	CNPJ	60	60	60	360	360	360							720	720	720
Elogio	Faturamento	Ajustes de OS	Criação	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Elogio	Comercial	Ajustes de OS	Descontos	60	60	60	360	360	360							720	720	720
Elogio	Comercial	Ajustes de OS	Isenções	60	60	60	360	360	360							720	720	720
Elogio	Comercial	Ajustes de OS	Descontos e Isenções	60	60	60	360	360	360							720	720	720
Elogio	Faturamento	Ajustes de OS	Nomenclatura	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Elogio	Comercial	Proposta Comercial	Alteração	60	60	60	360	360	360							720	720	720
Elogio	Comercial	Proposta Comercial	Criação	60	60	60	360	360	360							720	720	720
Elogio	Comercial	Proposta Comercial	Renovação	60	60	60	360	360	360							720	720	720
Elogio	Comercial	Valores/Serviços		60	60	60	360	360	360							720	720	720
Elogio	Comercial	Cadastro Pessoa Física	Criação	60	60	60	360	360	360							720	720	720
Elogio	Comercial	Cadastro Pessoa Física	Exclusão	60	60	60	360	360	360							720	720	720
Elogio	Comercial	Cadastro Pessoa Física	Atualização	60	60	60	360	360	360							720	720	720
Elogio	Comercial	Cadastro Pessoa Física	Status de aprovação	60	60	60	360	360	360							720	720	720
Elogio	Comercial	Cadastro Pessoa Jurídica	Status de aprovação	60	60	60	360	360	360							720	720	720
Elogio	Comercial	Cadastro Pessoa Jurídica	Criação	60	60	60	360	360	360							720	720	720
Elogio	Comercial	Cadastro Pessoa Jurídica	Exclusão	60	60	60	360	360	360							720	720	720
Elogio	Comercial	Cadastro Pessoa Jurídica	Atualização	60	60	60	360	360	360							720	720	720
Elogio	Inteligência de Mercado	Cadastro Pessoa Jurídica	Grupo Econômico	60	60	60	360	360	360							720	720	720
Elogio	Marketing	Comunicados	Reenvio	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Elogio	Marketing	Comunicados	Atualização de E-mail	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Elogio	Comercial	Conversa externa	Cliente x Departamento	60	60	60	360	360	360							720	720	720
Elogio	Comercial	Conversa externa	Cliente x Cliente	60	60	60	360	360	360							720	720	720
Elogio	RH	Currículo		60	60	60	360	360	360							720	720	720
Elogio	Comercial	Encaminhamento	Setor Responsável	60	60	60	360	360	360							720	720	720
Elogio	Comercial	Notificação automática		60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
''' +
    '''
Elogio	Comercial	WS Acesso	Status de aprovação	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Elogio	Comercial	WS Acesso	Criação	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Elogio	Comercial	WS Acesso	Exclusão	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Elogio	Comercial	WS Acesso	Atualização	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Elogio	Faturamento	Nota Fiscal	Cancelamento	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Elogio	Faturamento	Nota Fiscal	Informações	60	60	60	360	360	360							720	720	720
Elogio	Faturamento	PO / Draft	PO / Draft	60	60	60	360	360	360							720	720	720
Elogio	Faturamento	Nota Fiscal	Previsão de Emissão	60	60	60	360	360	360							720	720	720
Elogio	Faturamento	Solicitação para faturar	Solicitação para faturar	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Elogio	Financeiro	Fatura	Compensação de Pagamento	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Elogio	Financeiro	Contas a pagar	Reembolso	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Elogio	Financeiro	Contas a pagar	Cadastro Fornecedor	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Elogio	Financeiro	Fatura	Detalhamento de Pendências	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Elogio	Financeiro	Fatura	Identificação de Pagamentos	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Elogio	Financeiro	Fatura	Prorrogação	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Elogio	Financeiro	Fatura	Isenção de Juros	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Elogio	Financeiro	Fatura	Reenvio de Nota Fiscal	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Elogio	Financeiro	Fatura	Reenvio de Boleto	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Elogio	Sistema	Teconline	Instabilidade / Lentidão	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Elogio	Sistema	Teconline	Acesso indisponível	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Elogio	Sistema	Teconline	Informação inconsistente	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Elogio	Sistema	EDI	Falha de envio	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Elogio	Sistema	EDI	Falha de recebimento	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Elogio	Sistema	EDI	Integração com erro	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Elogio	Sistema	EDI	Divergência de dados	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Elogio	Sistema	EDI	Layout inválido	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Elogio	SMS	Cargas perigosas / Especiais	Procedimentos	60	60	60	360	360	360							720	720	720
Elogio	SMS	Cargas perigosas / Especiais	Cargas Aceitas/ Não Aceitas	60	60	60	360	360	360							720	720	720
Elogio	SMS	Cargas perigosas / Especiais	Colocação / Remoção Label	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Elogio	Santa Clara	Agendamento	Procedimentos	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Elogio	Santa Clara	Falha de Recebimento	Stiff Barcaça	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Elogio	Santa Clara	Falha de Recebimento	EDI Nfe	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Elogio	Operação	Armazéns	Procedimentos	60	60	60	360	360	360							720	720	720
Elogio	Operação	Armazéns	Lacres	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Elogio	Operação	Pátio	Morosidade	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Elogio	Operação	Pátio	Status de Atendimento	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Elogio	Operação	Pátio	Confirmação de Posição	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Elogio	Operação	Navio	Programação de Navios	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Elogio	Operação	Navio	Status de Operação	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Elogio	Operação	Navio	Alteração da Programação	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
''' +
    '''
Elogio	Operação	Navio	LAR	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Elogio	Operação	Agendamento	Alterações	60	60	60	360	360	360							720	720	720
Elogio	Operação	Agendamento	Documentação	60	60	60	360	360	360							720	720	720
Elogio	Operação	Agendamento	Entrega Antecipada	60	60	60	360	360	360							720	720	720
Elogio	Operação	Agendamento	Gold	60	60	60	360	360	360							720	720	720
Elogio	Operação	Agendamento	Liberação Especial	60	60	60	360	360	360							720	720	720
Elogio	Operação	Agendamento	Vagas e Horários	60	60	60	360	360	360							720	720	720
Elogio	Operação	Avaria	Registro de avaria	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Elogio	Operação	Avaria	Contestação	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Elogio	Operação	Avaria	Solicitação de vistoria	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Elogio	Operação	Avaria	Indenização	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Elogio	Operação	Booking	Criação	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Elogio	Operação	Booking	Alteração	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Elogio	Operação	Booking	EDI	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Elogio	Operação	Booking	Saldo	60	60	60	360	360	360							720	720	720
Elogio	Operação	Pesagem	Solicitação	60	60	60	360	360	360							720	720	720
Elogio	Operação	Pesagem	Status	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Elogio	Operação	Pesagem	Ticket	60	60	60	360	360	360							720	720	720
Elogio	Operação	Presença de carga	Status	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Elogio	Operação	Presença de carga	Alterações	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Elogio	Operação	Carta Protesto		60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Elogio	Operação	Relatórios	Ticket de Pesagem	60	60	60	360	360	360							720	720	720
Elogio	Operação	Relatórios	Relatório de Movimentações	60	60	60	360	360	360							720	720	720
Elogio	Operação	Relatórios	Consulta Contêiner	60	60	60	360	360	360							720	720	720
Elogio	Operação	Relatórios	Consulta Booking	60	60	60	360	360	360							720	720	720
Elogio	Operação	Relatórios	EIR	60	60	60	360	360	360							720	720	720
Elogio	Operação	Relatórios	Lista de navio	60	60	60	360	360	360							720	720	720
Solicitação	Faturamento	Ajustes de OS	Cancelamento	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Solicitação	Comercial	Ajustes de OS	Valor	60	60	60	360	360	360							720	720	720
Solicitação	Faturamento	Ajustes de OS	CNPJ	60	60	60	360	360	360							720	720	720
Solicitação	Faturamento	Ajustes de OS	Criação	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Solicitação	Comercial	Ajustes de OS	Descontos	60	60	60	360	360	360							720	720	720
Solicitação	Comercial	Ajustes de OS	Isenções	60	60	60	360	360	360							720	720	720
Solicitação	Comercial	Ajustes de OS	Descontos e Isenções	60	60	60	360	360	360							720	720	720
Solicitação	Faturamento	Ajustes de OS	Nomenclatura	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Solicitação	Comercial	Proposta Comercial	Alteração	60	60	60	360	360	360							720	720	720
Solicitação	Comercial	Proposta Comercial	Criação	60	60	60	360	360	360							720	720	720
Solicitação	Comercial	Proposta Comercial	Renovação	60	60	60	360	360	360							720	720	720
Solicitação	Comercial	Valores/Serviços		60	60	60	360	360	360							720	720	720
Solicitação	Comercial	Cadastro Pessoa Física	Criação	60	60	60	360	360	360							720	720	720
''' +
    '''
Solicitação	Comercial	Cadastro Pessoa Física	Exclusão	60	60	60	360	360	360							720	720	720
Solicitação	Comercial	Cadastro Pessoa Física	Atualização	60	60	60	360	360	360							720	720	720
Solicitação	Comercial	Cadastro Pessoa Jurídica	Criação	60	60	60	360	360	360							720	720	720
Solicitação	Comercial	Cadastro Pessoa Jurídica	Exclusão	60	60	60	360	360	360							720	720	720
Solicitação	Comercial	Cadastro Pessoa Jurídica	Atualização	60	60	60	360	360	360							720	720	720
Solicitação	Inteligência de Mercado	Cadastro Pessoa Jurídica	Grupo Econômico	60	60	60	360	360	360							720	720	720
Solicitação	Marketing	Comunicados	Reenvio	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Solicitação	Marketing	Comunicados	Atualização de E-mail	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Solicitação	Comercial	Conversa externa	Cliente x Departamento	60	60	60	360	360	360							720	720	720
Solicitação	Comercial	Conversa externa	Cliente x Cliente	60	60	60	360	360	360							720	720	720
Solicitação	RH	Currículo		60	60	60	360	360	360							720	720	720
Solicitação	Comercial	Encaminhamento	Setor Responsável	60	60	60	360	360	360							720	720	720
Solicitação	Comercial	Notificação automática		60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Solicitação	Comercial	WS Acesso	Atualização	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Solicitação	Faturamento	Nota Fiscal	Cancelamento	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Solicitação	Faturamento	PO / Draft	PO / Draft	60	60	60	360	360	360							720	720	720
Solicitação	Faturamento	Solicitação para faturar	Solicitação para faturar	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Solicitação	Financeiro	Fatura	Compensação de Pagamento	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Solicitação	Financeiro	Contas a pagar	Reembolso	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Solicitação	Financeiro	Contas a pagar	Cadastro Fornecedor	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Solicitação	Financeiro	Fatura	Detalhamento de Pendências	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Solicitação	Financeiro	Fatura	Identificação de Pagamentos	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Solicitação	Financeiro	Fatura	Prorrogação	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Solicitação	Financeiro	Fatura	Isenção de Juros	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Solicitação	Financeiro	Fatura	Reenvio de Nota Fiscal	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Solicitação	Financeiro	Fatura	Reenvio de Boleto	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Solicitação	SMS	Cargas perigosas / Especiais	Procedimentos	60	60	60	360	360	360							720	720	720
Solicitação	SMS	Cargas perigosas / Especiais	Cargas Aceitas/ Não Aceitas	60	60	60	360	360	360							720	720	720
Solicitação	SMS	Cargas perigosas / Especiais	Colocação / Remoção Label	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Solicitação	Santa Clara	Agendamento	Procedimentos	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Solicitação	Santa Clara	Falha de Recebimento	Stiff Barcaça	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Solicitação	Santa Clara	Falha de Recebimento	EDI Nfe	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Solicitação	Operação	Pátio	Status de Atendimento	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Solicitação	Operação	Pátio	Confirmação de Posição	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Solicitação	Operação	Navio	Alteração da Programação	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Solicitação	Operação	Navio	LAR	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Solicitação	Operação	Agendamento	Alterações	60	60	60	360	360	360							720	720	720
Solicitação	Operação	Agendamento	Documentação	60	60	60	360	360	360							720	720	720
Solicitação	Operação	Agendamento	Entrega Antecipada	60	60	60	360	360	360							720	720	720
Solicitação	Operação	Agendamento	Gold	60	60	60	360	360	360							720	720	720
''' +
    '''
Solicitação	Operação	Agendamento	Liberação Especial	60	60	60	360	360	360							720	720	720
Solicitação	Operação	Agendamento	Vagas e Horários	60	60	60	360	360	360							720	720	720
Solicitação	Operação	Booking	Criação	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Solicitação	Operação	Booking	Alteração	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Solicitação	Operação	Booking	EDI	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Solicitação	Operação	Pesagem	Status	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Solicitação	Operação	Pesagem	Ticket	60	60	60	360	360	360							720	720	720
Solicitação	Operação	Presença de carga	Alterações	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Solicitação	Operação	Carta Protesto		60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Solicitação	Operação	Relatórios	Ticket de Pesagem	60	60	60	360	360	360							720	720	720
Solicitação	Operação	Relatórios	Relatório de Movimentações	60	60	60	360	360	360							720	720	720
Solicitação	Operação	Relatórios	Consulta Contêiner	60	60	60	360	360	360							720	720	720
Solicitação	Operação	Relatórios	Consulta Booking	60	60	60	360	360	360							720	720	720
Solicitação	Operação	Relatórios	EIR	60	60	60	360	360	360							720	720	720
Solicitação	Operação	Relatórios	Lista de navio	60	60	60	360	360	360							720	720	720
Reclamação	Comercial	Valores/Serviços		60	60	60	360	360	360							720	720	720
Reclamação	Comercial	Cadastro Pessoa Física	Criação	60	60	60	360	360	360							720	720	720
Reclamação	Comercial	Cadastro Pessoa Física	Exclusão	60	60	60	360	360	360							720	720	720
Reclamação	Comercial	Cadastro Pessoa Física	Atualização	60	60	60	360	360	360							720	720	720
Reclamação	Comercial	Cadastro Pessoa Física	Status de aprovação	60	60	60	360	360	360							720	720	720
Reclamação	Comercial	Cadastro Pessoa Jurídica	Status de aprovação	60	60	60	360	360	360							720	720	720
Reclamação	Comercial	Cadastro Pessoa Jurídica	Criação	60	60	60	360	360	360							720	720	720
Reclamação	Comercial	Cadastro Pessoa Jurídica	Exclusão	60	60	60	360	360	360							720	720	720
Reclamação	Comercial	Cadastro Pessoa Jurídica	Atualização	60	60	60	360	360	360							720	720	720
Reclamação	Marketing	Comunicados	Reenvio	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Reclamação	Marketing	Comunicados	Atualização de E-mail	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Reclamação	RH	Currículo		60	60	60	360	360	360							720	720	720
Reclamação	Comercial	WS Acesso	Status de aprovação	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Reclamação	Comercial	WS Acesso	Criação	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Reclamação	Comercial	WS Acesso	Exclusão	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Reclamação	Comercial	WS Acesso	Atualização	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Reclamação	Faturamento	Nota Fiscal	Cancelamento	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Reclamação	Financeiro	Contas a pagar	Cadastro Fornecedor	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Reclamação	Financeiro	Fatura	Detalhamento de Pendências	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Reclamação	Financeiro	Fatura	Identificação de Pagamentos	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Reclamação	Financeiro	Fatura	Prorrogação	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Reclamação	Financeiro	Fatura	Isenção de Juros	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Reclamação	Financeiro	Fatura	Reenvio de Nota Fiscal	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Reclamação	Financeiro	Fatura	Reenvio de Boleto	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Reclamação	Sistema	Teconline	Instabilidade / Lentidão	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
''' +
    '''
Reclamação	Sistema	Teconline	Acesso indisponível	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Reclamação	Sistema	Teconline	Informação inconsistente	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Reclamação	Sistema	EDI	Falha de envio	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Reclamação	Sistema	EDI	Falha de recebimento	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Reclamação	Sistema	EDI	Integração com erro	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Reclamação	Sistema	EDI	Divergência de dados	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Reclamação	Sistema	EDI	Layout inválido	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Reclamação	SMS	Cargas perigosas / Especiais	Procedimentos	60	60	60	360	360	360							720	720	720
Reclamação	SMS	Cargas perigosas / Especiais	Cargas Aceitas/ Não Aceitas	60	60	60	360	360	360							720	720	720
Reclamação	SMS	Cargas perigosas / Especiais	Colocação / Remoção Label	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Reclamação	Santa Clara	Agendamento	Procedimentos	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Reclamação	Operação	Armazéns	Procedimentos	60	60	60	360	360	360							720	720	720
Reclamação	Operação	Armazéns	Lacres	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Reclamação	Operação	Pátio	Morosidade	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Reclamação	Operação	Agendamento	Entrega Antecipada	60	60	60	360	360	360							720	720	720
Reclamação	Operação	Agendamento	Gold	60	60	60	360	360	360							720	720	720
Reclamação	Operação	Agendamento	Liberação Especial	60	60	60	360	360	360							720	720	720
Reclamação	Operação	Agendamento	Vagas e Horários	60	60	60	360	360	360							720	720	720
Incidente	Faturamento	Nota Fiscal	Cancelamento	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Incidente	Faturamento	Nota Fiscal	Previsão de Emissão	60	60	60	360	360	360							720	720	720
Incidente	Sistema	Teconline	Instabilidade / Lentidão	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Incidente	Sistema	Teconline	Acesso indisponível	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Incidente	Sistema	Teconline	Informação inconsistente	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Incidente	Sistema	EDI	Falha de envio	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Incidente	Sistema	EDI	Falha de recebimento	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Incidente	Sistema	EDI	Integração com erro	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Incidente	Sistema	EDI	Divergência de dados	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Incidente	Sistema	EDI	Layout inválido	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Incidente	Operação	Avaria	Registro de avaria	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Incidente	Operação	Avaria	Contestação	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Incidente	Operação	Avaria	Solicitação de vistoria	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Incidente	Operação	Avaria	Indenização	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
Incidente	Operação	Booking	Criação	60	60	60	360	360	360	240	240	240	60	60	60	720	720	720
''';

List<String> linhas = dadosPlanilha.trim().split('\n');
System.debug('LINHAS_PLANILHA=' + linhas.size());

// indices dos campos de tempo (0-based) dentro de "campos", por marco: [alta, normal, baixa]
Map<String, List<Integer>> indicesPorMarco = new Map<String, List<Integer>>{
    'Primeira Resposta (Fila N2)' => new List<Integer>{4, 5, 6},
    'Atendimento' => new List<Integer>{7, 8, 9},
    'Atendimento N3' => new List<Integer>{10, 11, 12},
    'Retorno N3' => new List<Integer>{13, 14, 15},
    'SLA Total' => new List<Integer>{16, 17, 18}
};

List<RegrasSLACategorizacao__c> novasRegras = new List<RegrasSLACategorizacao__c>();
Integer naoEncontradas = 0;

for (String linha : linhas) {
    List<String> campos = linha.split('\t');
    String key = campos[0] + '|' + campos[1] + '|' + campos[2] + '|' + campos[3];
    Id categorizacaoId = catByKey.get(key);
    if (categorizacaoId == null) {
        naoEncontradas++;
        continue;
    }

    for (String nomeMarco : indicesPorMarco.keySet()) {
        List<Integer> idx = indicesPorMarco.get(nomeMarco);
        String alta = campos[idx[0]];
        String normal = campos[idx[1]];
        String baixa = campos[idx[2]];

        if (String.isBlank(alta) && String.isBlank(normal) && String.isBlank(baixa)) {
            continue;
        }

        RegrasSLACategorizacao__c regra = new RegrasSLACategorizacao__c();
        regra.Categorizacao__c = categorizacaoId;
        regra.GestaoSLA__c = gestaoSlaId;
        regra.MarcoSLA__c = marcoByName.get(nomeMarco);
        regra.EscopoRegra__c = 'Atendimento';
        regra.Ativo__c = true;
        regra.TempoAlta__c = String.isBlank(alta) ? null : Decimal.valueOf(alta);
        regra.TempoMedia__c = String.isBlank(normal) ? null : Decimal.valueOf(normal);
        regra.TempoBaixa__c = String.isBlank(baixa) ? null : Decimal.valueOf(baixa);
        novasRegras.add(regra);
    }
}

System.debug('LINHAS_SEM_CATEGORIZACAO_CORRESPONDENTE=' + naoEncontradas);
insert novasRegras;
System.debug('REGRAS_SLA_INSERIDAS=' + novasRegras.size());
System.debug('CARGA_RIO_GRANDE_CONCLUIDA');
