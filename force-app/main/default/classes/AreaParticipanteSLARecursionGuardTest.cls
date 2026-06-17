/**
 * @description       : Testes unitários de AreaParticipanteSLARecursionGuard.
 * @author            : Triscal
 * @group             : Área Participante
 * @last modified on  : 06-11-2026
 * @last modified by  : Jean Duarte
 **/
@IsTest
private class AreaParticipanteSLARecursionGuardTest {
    @IsTest
    static void testEnterLeave() {
        Assert.areEqual(true, AreaParticipanteSLARecursionGuard.enter('K1'));
        Assert.areEqual(false, AreaParticipanteSLARecursionGuard.enter('K1'));
        AreaParticipanteSLARecursionGuard.leave('K1');
        Assert.areEqual(true, AreaParticipanteSLARecursionGuard.enter('K1'));
    }
}