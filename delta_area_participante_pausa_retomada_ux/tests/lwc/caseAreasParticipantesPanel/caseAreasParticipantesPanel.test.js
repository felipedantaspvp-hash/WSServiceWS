import { createElement } from 'lwc';
import CaseAreasParticipantesPanel from 'c/caseAreasParticipantesPanel';
import getPanelDataFresh from '@salesforce/apex/AreaParticipanteController.getPanelDataFresh';
import pauseParticipation from '@salesforce/apex/AreaParticipanteController.pauseParticipation';
import resumeParticipation from '@salesforce/apex/AreaParticipanteController.resumeParticipation';

jest.mock(
    '@salesforce/apex/AreaParticipanteController.getPanelDataFresh',
    () => ({ default: jest.fn() }),
    { virtual: true }
);

jest.mock(
    '@salesforce/apex/AreaParticipanteController.closeParticipation',
    () => ({ default: jest.fn() }),
    { virtual: true }
);

jest.mock(
    '@salesforce/apex/AreaParticipanteController.getParticipationDetails',
    () => ({ default: jest.fn() }),
    { virtual: true }
);

jest.mock(
    '@salesforce/apex/AreaParticipanteController.addParticipation',
    () => ({ default: jest.fn() }),
    { virtual: true }
);

jest.mock(
    '@salesforce/apex/AreaParticipanteController.pauseParticipation',
    () => ({ default: jest.fn() }),
    { virtual: true }
);

jest.mock(
    '@salesforce/apex/AreaParticipanteController.resumeParticipation',
    () => ({ default: jest.fn() }),
    { virtual: true }
);

const flushPromises = () => new Promise((resolve) => {
    setTimeout(resolve, 0);
});

function baseItem(overrides = {}) {
    return {
        id: 'a01xx000000001AAA',
        areaLabel: 'Financeiro',
        statusLabel: 'Aberta',
        statusSLA: 'Dentro do Prazo',
        isConcluida: false,
        isCancelada: false,
        isVencida: false,
        canClose: true,
        canPause: true,
        canResume: false,
        caseMilestoneId: null,
        percentualDecorrido: 10,
        tempoSLAMinutos: 120,
        tempoConsumidoMinutos: 20,
        tempoRestanteMinutos: 100,
        tempoPausadoMinutos: 0,
        sequenciaAcionamento: 1,
        comentarioSolicitacao: 'Validar dados',
        ...overrides
    };
}

function panelWith(items) {
    return {
        caseId: '500xx000000001AAA',
        canManage: true,
        totalAbertas: items.length,
        totalVencidas: 0,
        items,
        areaOptions: []
    };
}

async function createComponent(items) {
    getPanelDataFresh.mockResolvedValue(panelWith(items));
    const element = createElement('c-case-areas-participantes-panel', {
        is: CaseAreasParticipantesPanel
    });
    element.recordId = '500xx000000001AAA';
    document.body.appendChild(element);
    await flushPromises();
    return element;
}

function getButtonByLabel(element, labels) {
    const expectedLabels = Array.isArray(labels) ? labels : [labels];
    return [...element.shadowRoot.querySelectorAll('lightning-button')].find((button) =>
        expectedLabels.includes(button.label)
    );
}

describe('c-case-areas-participantes-panel pause/resume UX', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    it('shows Pause for open Custom internal area', async () => {
        const element = await createComponent([baseItem()]);

        expect(getButtonByLabel(element, ['Pause', 'Pausar'])).not.toBeUndefined();
        expect(getButtonByLabel(element, ['Resume', 'Retomar'])).toBeUndefined();
    });

    it('shows Resume for paused Custom internal area', async () => {
        const element = await createComponent([
            baseItem({
                statusSLA: 'Pausado',
                canPause: false,
                canResume: true
            })
        ]);

        expect(getButtonByLabel(element, ['Resume', 'Retomar'])).not.toBeUndefined();
        expect(getButtonByLabel(element, ['Pause', 'Pausar'])).toBeUndefined();
    });

    it('does not show pause or resume actions for Standard mirrored area', async () => {
        const element = await createComponent([
            baseItem({
                canPause: false,
                canResume: false,
                caseMilestoneId: '557xx000000001AAA'
            })
        ]);

        expect(getButtonByLabel(element, ['Pause', 'Pausar'])).toBeUndefined();
        expect(getButtonByLabel(element, ['Resume', 'Retomar'])).toBeUndefined();
    });

    it('calls Apex pause action and refreshes the panel', async () => {
        pauseParticipation.mockResolvedValue({ success: true });
        const element = await createComponent([baseItem()]);

        getButtonByLabel(element, ['Pause', 'Pausar']).click();
        await flushPromises();
        await flushPromises();

        expect(pauseParticipation).toHaveBeenCalledWith({
            request: { areaParticipanteId: 'a01xx000000001AAA' }
        });
        expect(getPanelDataFresh).toHaveBeenCalledTimes(2);
    });

    it('calls Apex resume action and refreshes the panel', async () => {
        resumeParticipation.mockResolvedValue({ success: true });
        const element = await createComponent([
            baseItem({
                statusSLA: 'Pausado',
                canPause: false,
                canResume: true
            })
        ]);

        getButtonByLabel(element, ['Resume', 'Retomar']).click();
        await flushPromises();
        await flushPromises();

        expect(resumeParticipation).toHaveBeenCalledWith({
            request: { areaParticipanteId: 'a01xx000000001AAA' }
        });
        expect(getPanelDataFresh).toHaveBeenCalledTimes(2);
    });

    it('shows an error toast without clearing loaded data when pause fails', async () => {
        pauseParticipation.mockRejectedValue({ body: { message: 'Falha controlada' } });
        const element = await createComponent([baseItem()]);
        const toastHandler = jest.fn();
        element.addEventListener('lightning__showtoast', toastHandler);

        getButtonByLabel(element, ['Pause', 'Pausar']).click();
        await flushPromises();

        expect(toastHandler).toHaveBeenCalled();
        expect(getButtonByLabel(element, ['Pause', 'Pausar'])).not.toBeUndefined();
    });
});
