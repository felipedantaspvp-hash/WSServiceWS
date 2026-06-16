Case c = new Case(
    Subject = '[TESTE 24A] Validacao syncMilestonesOnEntitlementAssignment',
    Status  = 'Em Aberto',
    Origin  = 'Web'
);
insert c;
System.debug('CASE_ID=' + c.Id);
