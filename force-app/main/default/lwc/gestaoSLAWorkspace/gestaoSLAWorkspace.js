import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const PINNED_GESTAO_STORAGE_KEY = 'gestaoSLAWorkspace.pinnedGestaoId';
import categoryTabTitleLabel from '@salesforce/label/c.GestaoSLA_CategoryTabTitle';
import categoryReactivateButtonLabel from '@salesforce/label/c.GestaoSLA_CategoryReactivateButton';
import categoryNewButtonLabel from '@salesforce/label/c.GestaoSLA_CategoryNewButton';
import categorySearchPlaceholderLabel from '@salesforce/label/c.GestaoSLA_CategorySearchPlaceholder';
import categoryFilterButtonLabel from '@salesforce/label/c.GestaoSLA_CategoryFilterButton';
import categoryBusinessUnitLabel from '@salesforce/label/c.GestaoSLA_CategoryBusinessUnit';
import categoryCaseTypeLabel from '@salesforce/label/c.GestaoSLA_CategoryCaseType';
import categoryLabelLabel from '@salesforce/label/c.GestaoSLA_CategoryLabel';
import categorySubjectLabel from '@salesforce/label/c.GestaoSLA_CategorySubject';
import categorySubsubjectLabel from '@salesforce/label/c.GestaoSLA_CategorySubsubject';
import categorySuggestedPriorityLabel from '@salesforce/label/c.GestaoSLA_CategorySuggestedPriority';
import categoryActiveColumnLabel from '@salesforce/label/c.GestaoSLA_CategoryActiveColumn';
import categoryStatusFieldLabel from '@salesforce/label/c.GestaoSLA_CategoryStatusField';
import categorySlaRulesLabel from '@salesforce/label/c.GestaoSLA_CategorySlaRules';
import categoryActionsLabel from '@salesforce/label/c.GestaoSLA_CategoryActions';
import categoryEditLabel from '@salesforce/label/c.GestaoSLA_CategoryEdit';
import categoryDeactivateLabel from '@salesforce/label/c.GestaoSLA_CategoryDeactivate';
import categoryDeleteLabel from '@salesforce/label/c.GestaoSLA_CategoryDelete';
import categoryDistributeToQueueLabel from '@salesforce/label/c.GestaoSLA_CategoryDistributeToQueue';
import categoryByCustomFieldLabel from '@salesforce/label/c.GestaoSLA_CategoryByCustomField';
import categoryQueueLabel from '@salesforce/label/c.GestaoSLA_CategoryQueue';
import categoryQueuePlaceholderLabel from '@salesforce/label/c.GestaoSLA_CategoryQueuePlaceholder';
import categoryDistributionFieldLabel from '@salesforce/label/c.GestaoSLA_CategoryDistributionField';
import categoryDistributionFieldPlaceholderLabel from '@salesforce/label/c.GestaoSLA_CategoryDistributionFieldPlaceholder';
import categoryDistributionValueLabel from '@salesforce/label/c.GestaoSLA_CategoryDistributionValue';
import categoryDistributionValuePlaceholderLabel from '@salesforce/label/c.GestaoSLA_CategoryDistributionValuePlaceholder';
import ruleDeleteLabel from '@salesforce/label/c.GestaoSLA_RuleDelete';
import gestaoDeleteButtonLabel from '@salesforce/label/c.GestaoSLA_DeleteButton';
import confirmDeleteCategoryLabel from '@salesforce/label/c.GestaoSLA_ConfirmDeleteCategory';
import confirmDeleteRuleLabel from '@salesforce/label/c.GestaoSLA_ConfirmDeleteRule';
import confirmDeleteGestaoLabel from '@salesforce/label/c.GestaoSLA_ConfirmDeleteGestao';
import errorDeleteCategoryLabel from '@salesforce/label/c.GestaoSLA_ErrorDeleteCategory';
import errorDeleteRuleLabel from '@salesforce/label/c.GestaoSLA_ErrorDeleteRule';
import errorDeleteGestaoLabel from '@salesforce/label/c.GestaoSLA_ErrorDeleteGestao';
import toastCategoryDeletedLabel from '@salesforce/label/c.GestaoSLA_ToastCategoryDeleted';
import toastRuleDeletedLabel from '@salesforce/label/c.GestaoSLA_ToastRuleDeleted';
import toastGestaoDeletedLabel from '@salesforce/label/c.GestaoSLA_ToastGestaoDeleted';
import categoryConfigureSlaLabel from '@salesforce/label/c.GestaoSLA_CategoryConfigureSla';
import categoryPaginationFirstLabel from '@salesforce/label/c.GestaoSLA_CategoryPaginationFirst';
import categoryPaginationPreviousLabel from '@salesforce/label/c.GestaoSLA_CategoryPaginationPrevious';
import categoryPaginationNextLabel from '@salesforce/label/c.GestaoSLA_CategoryPaginationNext';
import categoryPaginationLastLabel from '@salesforce/label/c.GestaoSLA_CategoryPaginationLast';
import categoryEmptyStateLabel from '@salesforce/label/c.GestaoSLA_CategoryEmptyState';
import categoryFilterCaseTypeAllLabel from '@salesforce/label/c.GestaoSLA_CategoryFilterCaseTypeAll';
import categoryFilterCategoryAllLabel from '@salesforce/label/c.GestaoSLA_CategoryFilterCategoryAll';
import categoryFilterSubjectAllLabel from '@salesforce/label/c.GestaoSLA_CategoryFilterSubjectAll';
import categoryFilterStatusAllLabel from '@salesforce/label/c.GestaoSLA_CategoryFilterStatusAll';
import categoryStatusOptionActiveLabel from '@salesforce/label/c.GestaoSLA_CategoryStatusOptionActive';
import categoryStatusOptionInactiveLabel from '@salesforce/label/c.GestaoSLA_CategoryStatusOptionInactive';
import categoryNoSubsubjectLabel from '@salesforce/label/c.GestaoSLA_CategoryNoSubsubject';
import categoryNoPriorityLabel from '@salesforce/label/c.GestaoSLA_CategoryNoPriority';
import categoryModalNewTitleLabel from '@salesforce/label/c.GestaoSLA_CategoryModalNewTitle';
import categoryModalEditTitleLabel from '@salesforce/label/c.GestaoSLA_CategoryModalEditTitle';
import categoryModalSavingAltLabel from '@salesforce/label/c.GestaoSLA_CategoryModalSavingAlt';
import categoryModalSelectCaseTypeLabel from '@salesforce/label/c.GestaoSLA_CategoryModalSelectCaseType';
import categoryModalSelectCategoryLabel from '@salesforce/label/c.GestaoSLA_CategoryModalSelectCategory';
import categoryModalSelectSubjectLabel from '@salesforce/label/c.GestaoSLA_CategoryModalSelectSubject';
import categoryModalCancelLabel from '@salesforce/label/c.GestaoSLA_CategoryModalCancel';
import categoryModalSaveLabel from '@salesforce/label/c.GestaoSLA_CategoryModalSave';
import categoryReactivateModalTitleLabel from '@salesforce/label/c.GestaoSLA_CategoryReactivateModalTitle';
import categoryReactivateModalLoadingAltLabel from '@salesforce/label/c.GestaoSLA_CategoryReactivateModalLoadingAlt';
import categoryReactivateModalSelectLabel from '@salesforce/label/c.GestaoSLA_CategoryReactivateModalSelect';
import categoryReactivateModalEmptyLabel from '@salesforce/label/c.GestaoSLA_CategoryReactivateModalEmpty';
import categoryReactivateModalConfirmLabel from '@salesforce/label/c.GestaoSLA_CategoryReactivateModalConfirm';
import categorySummaryActiveLabel from '@salesforce/label/c.GestaoSLA_CategorySummaryActive';
import categoryRulesCountSuffixLabel from '@salesforce/label/c.GestaoSLA_CategoryRulesCountSuffix';
import commonOfLabel from '@salesforce/label/c.GestaoSLA_CommonOf';
import commonSuccessLabel from '@salesforce/label/c.GestaoSLA_CommonSuccess';
import commonErrorLabel from '@salesforce/label/c.GestaoSLA_CommonError';
import toastCategoryCreatedLabel from '@salesforce/label/c.GestaoSLA_ToastCategoryCreated';
import toastCategoryUpdatedLabel from '@salesforce/label/c.GestaoSLA_ToastCategoryUpdated';
import toastCategoryDeactivatedLabel from '@salesforce/label/c.GestaoSLA_ToastCategoryDeactivated';
import toastCategoryReactivatedLabel from '@salesforce/label/c.GestaoSLA_ToastCategoryReactivated';
import errorLoadCategoriesLabel from '@salesforce/label/c.GestaoSLA_ErrorLoadCategories';
import errorSaveCategoryLabel from '@salesforce/label/c.GestaoSLA_ErrorSaveCategory';
import errorDeactivateCategoryLabel from '@salesforce/label/c.GestaoSLA_ErrorDeactivateCategory';
import errorLoadInactiveCategoriesLabel from '@salesforce/label/c.GestaoSLA_ErrorLoadInactiveCategories';
import errorSelectInactiveCategoryLabel from '@salesforce/label/c.GestaoSLA_ErrorSelectInactiveCategory';
import errorReactivateCategoryLabel from '@salesforce/label/c.GestaoSLA_ErrorReactivateCategory';
import gestaoLabelLabel from '@salesforce/label/c.GestaoSLA_Label';
import gestaoPinButtonLabel from '@salesforce/label/c.GestaoSLA_PinButton';
import gestaoUnpinButtonLabel from '@salesforce/label/c.GestaoSLA_UnpinButton';
import gestaoNewButtonLabel from '@salesforce/label/c.GestaoSLA_NewButton';
import gestaoReactivateButtonLabel from '@salesforce/label/c.GestaoSLA_ReactivateButton';
import gestaoEditButtonLabel from '@salesforce/label/c.GestaoSLA_EditButton';
import gestaoEditSettingsButtonLabel from '@salesforce/label/c.GestaoSLA_EditSettingsButton';
import gestaoEntitlementProcessLabel from '@salesforce/label/c.GestaoSLA_EntitlementProcess';
import gestaoBusinessHoursLabel from '@salesforce/label/c.GestaoSLA_BusinessHours';
import gestaoMarcosUnicosSectionTitleLabel from '@salesforce/label/c.GestaoSLA_MarcosUnicosSectionTitle';
import gestaoTriageTimeLabel from '@salesforce/label/c.GestaoSLA_TriageTime';
import gestaoChatResponseTimeLabel from '@salesforce/label/c.GestaoSLA_ChatResponseTime';
import gestaoEmailQueueTimeLabel from '@salesforce/label/c.GestaoSLA_EmailQueueTime';
import usaTriageTimeLabel from '@salesforce/label/c.GestaoSLA_UsaTriageTime';
import usaChatResponseTimeLabel from '@salesforce/label/c.GestaoSLA_UsaChatResponseTime';
import usaEmailQueueTimeLabel from '@salesforce/label/c.GestaoSLA_UsaEmailQueueTime';
import gestaoSummaryTitleLabel from '@salesforce/label/c.GestaoSLA_SummaryTitle';
import gestaoSummaryAvailableMilestonesLabel from '@salesforce/label/c.GestaoSLA_SummaryAvailableMilestones';
import gestaoSummaryInternalAreasN3Label from '@salesforce/label/c.GestaoSLA_SummaryInternalAreasN3';
import gestaoSummaryLastUpdatedLabel from '@salesforce/label/c.GestaoSLA_SummaryLastUpdated';
import gestaoTodayLabel from '@salesforce/label/c.GestaoSLA_Today';
import gestaoViewReportsLabel from '@salesforce/label/c.GestaoSLA_ViewReports';
import gestaoBannerAltLabel from '@salesforce/label/c.GestaoSLA_BannerAlt';
import ruleScopeLabel from '@salesforce/label/c.GestaoSLA_RuleScope';
import rulePriorityHighMinLabel from '@salesforce/label/c.GestaoSLA_RulePriorityHighMin';
import rulePriorityMediumMinLabel from '@salesforce/label/c.GestaoSLA_RulePriorityMediumMin';
import rulePriorityLowMinLabel from '@salesforce/label/c.GestaoSLA_RulePriorityLowMin';
import spinnerLoadingLabel from '@salesforce/label/c.GestaoSLA_SpinnerLoading';
import spinnerSavingLabel from '@salesforce/label/c.GestaoSLA_SpinnerSaving';
import accessDeniedTitleLabel from '@salesforce/label/c.GestaoSLA_AccessDeniedTitle';
import accessDeniedMessageLabel from '@salesforce/label/c.GestaoSLA_AccessDeniedMessage';
import noManagementFoundAdminLabel from '@salesforce/label/c.GestaoSLA_NoManagementFoundAdmin';
import noManagementFoundUserLabel from '@salesforce/label/c.GestaoSLA_NoManagementFoundUser';
import rulesTabTitleLabel from '@salesforce/label/c.GestaoSLA_RulesTabTitle';
import technicalSettingsTabTitleLabel from '@salesforce/label/c.GestaoSLA_TechnicalSettingsTabTitle';
import ruleNewButtonLabel from '@salesforce/label/c.GestaoSLA_RuleNewButton';
import ruleModalEditTitleLabel from '@salesforce/label/c.GestaoSLA_RuleModalEditTitle';
import globalTimeLabel from '@salesforce/label/c.GestaoSLA_GlobalTime';
import milestoneTriageLabelLabel from '@salesforce/label/c.GestaoSLA_MilestoneTriageLabel';
import sourceManagementLabelLabel from '@salesforce/label/c.GestaoSLA_SourceManagementLabel';
import applicationEmailNewLabel from '@salesforce/label/c.GestaoSLA_ApplicationEmailNew';
import milestoneChatResponseLabelLabel from '@salesforce/label/c.GestaoSLA_MilestoneChatResponseLabel';
import applicationWhatsappChatNewLabel from '@salesforce/label/c.GestaoSLA_ApplicationWhatsappChatNew';
import milestoneEmailQueueLabelLabel from '@salesforce/label/c.GestaoSLA_MilestoneEmailQueueLabel';
import rulesFilteredForLabel from '@salesforce/label/c.GestaoSLA_RulesFilteredFor';
import rulesClearFilterLabel from '@salesforce/label/c.GestaoSLA_RulesClearFilter';
import ruleInternalAreaPlaceholderLabel from '@salesforce/label/c.GestaoSLA_RuleInternalAreaPlaceholder';
import rulesSpinnerLoadingLabel from '@salesforce/label/c.GestaoSLA_RulesSpinnerLoading';
import ruleColCategorizationLabel from '@salesforce/label/c.GestaoSLA_RuleColCategorization';
import ruleColMilestoneLabel from '@salesforce/label/c.GestaoSLA_RuleColMilestone';
import ruleColScopeLabel from '@salesforce/label/c.GestaoSLA_RuleColScope';
import ruleColInternalAreaLabel from '@salesforce/label/c.GestaoSLA_RuleColInternalArea';
import areaInternaHelpTitleLabel from '@salesforce/label/c.GestaoSLA_AreaInternaHelpTitle';
import areaInternaHelpReplicateRowLabel from '@salesforce/label/c.GestaoSLA_AreaInternaHelpReplicateRow';
import areaInternaHelpReplicateColumnLabel from '@salesforce/label/c.GestaoSLA_AreaInternaHelpReplicateColumn';
import areaInternaHelpCopyRowPriorityLabel from '@salesforce/label/c.GestaoSLA_AreaInternaHelpCopyRowPriority';
import ruleColTimeLowLabel from '@salesforce/label/c.GestaoSLA_RuleColTimeLow';
import ruleColTimeMediumLabel from '@salesforce/label/c.GestaoSLA_RuleColTimeMedium';
import ruleColTimeHighLabel from '@salesforce/label/c.GestaoSLA_RuleColTimeHigh';
import rulesEmptyStateLabel from '@salesforce/label/c.GestaoSLA_RulesEmptyState';
import reactivateModalTitleLabel from '@salesforce/label/c.GestaoSLA_ReactivateModalTitle';
import reactivateModalEmptyLabel from '@salesforce/label/c.GestaoSLA_ReactivateModalEmpty';
import fieldNameLabel from '@salesforce/label/c.GestaoSLA_FieldName';
import fieldTriageTimeMinLabel from '@salesforce/label/c.GestaoSLA_FieldTriageTimeMin';
import fieldChatResponseTimeMinLabel from '@salesforce/label/c.GestaoSLA_FieldChatResponseTimeMin';
import fieldEmailQueueTimeMinLabel from '@salesforce/label/c.GestaoSLA_FieldEmailQueueTimeMin';
import fieldDescriptionLabel from '@salesforce/label/c.GestaoSLA_FieldDescription';
import ruleFilterCategorizacaoAllLabel from '@salesforce/label/c.GestaoSLA_RuleFilterCategorizacaoAll';
import ruleSelectCategorizationLabel from '@salesforce/label/c.GestaoSLA_RuleSelectCategorization';
import ruleFilterMilestoneAllLabel from '@salesforce/label/c.GestaoSLA_RuleFilterMilestoneAll';
import ruleSelectMilestoneLabel from '@salesforce/label/c.GestaoSLA_RuleSelectMilestone';
import ruleFilterScopeAllLabel from '@salesforce/label/c.GestaoSLA_RuleFilterScopeAll';
import commonInfoLabel from '@salesforce/label/c.GestaoSLA_CommonInfo';
import errorLoadManagementLabel from '@salesforce/label/c.GestaoSLA_ErrorLoadManagement';
import errorSwitchManagementLabel from '@salesforce/label/c.GestaoSLA_ErrorSwitchManagement';
import errorLoadRulesLabel from '@salesforce/label/c.GestaoSLA_ErrorLoadRules';
import errorSaveRuleLabel from '@salesforce/label/c.GestaoSLA_ErrorSaveRule';
import toastRuleCreatedLabel from '@salesforce/label/c.GestaoSLA_ToastRuleCreated';
import toastRuleBulkSavedLabel from '@salesforce/label/c.GestaoSLA_ToastRuleBulkSaved';
import toastRuleUpdatedLabel from '@salesforce/label/c.GestaoSLA_ToastRuleUpdated';
import toastRuleDeactivatedLabel from '@salesforce/label/c.GestaoSLA_ToastRuleDeactivated';
import errorDeactivateRuleLabel from '@salesforce/label/c.GestaoSLA_ErrorDeactivateRule';
import confirmDeactivateRuleLabel from '@salesforce/label/c.GestaoSLA_ConfirmDeactivateRule';
import activateRuleLabel from '@salesforce/label/c.GestaoSLA_ActivateRule';
import toastRuleActivatedLabel from '@salesforce/label/c.GestaoSLA_ToastRuleActivated';
import confirmDeactivateCategoryLabel from '@salesforce/label/c.GestaoSLA_ConfirmDeactivateCategory';
import errorLoadInactiveManagementsLabel from '@salesforce/label/c.GestaoSLA_ErrorLoadInactiveManagements';
import errorSelectInactiveManagementLabel from '@salesforce/label/c.GestaoSLA_ErrorSelectInactiveManagement';
import toastManagementReactivatedLabel from '@salesforce/label/c.GestaoSLA_ToastManagementReactivated';
import errorReactivateManagementLabel from '@salesforce/label/c.GestaoSLA_ErrorReactivateManagement';
import toastManagementCreatedLabel from '@salesforce/label/c.GestaoSLA_ToastManagementCreated';
import errorCreateManagementLabel from '@salesforce/label/c.GestaoSLA_ErrorCreateManagement';
import toastManagementUpdatedLabel from '@salesforce/label/c.GestaoSLA_ToastManagementUpdated';
import errorUpdateManagementLabel from '@salesforce/label/c.GestaoSLA_ErrorUpdateManagement';
import errorRuleMilestoneRequiredLabel from '@salesforce/label/c.GestaoSLA_ErrorRuleMilestoneRequired';
import errorRuleScopeRequiredLabel from '@salesforce/label/c.GestaoSLA_ErrorRuleScopeRequired';
import errorRuleCategoryRequiredLabel from '@salesforce/label/c.GestaoSLA_ErrorRuleCategoryRequired';
import errorRuleInternalAreaRequiredLabel from '@salesforce/label/c.GestaoSLA_ErrorRuleInternalAreaRequired';
import errorRuleAtLeastOneTimeLabel from '@salesforce/label/c.GestaoSLA_ErrorRuleAtLeastOneTime';
import errorRuleTimesMustBePositiveLabel from '@salesforce/label/c.GestaoSLA_ErrorRuleTimesMustBePositive';
import getBootstrap from '@salesforce/apex/GestaoSLAController.getBootstrap';
import getGestaoDetail from '@salesforce/apex/GestaoSLAController.getGestaoDetail';
import getCategorias from '@salesforce/apex/GestaoSLAController.getCategorias';
import getMarcos from '@salesforce/apex/GestaoSLAController.getMarcos';
import getRegrasSLA from '@salesforce/apex/GestaoSLAController.getRegrasSLA';
import createRegraSLA from '@salesforce/apex/GestaoSLAController.createRegraSLA';
import updateRegraSLA from '@salesforce/apex/GestaoSLAController.updateRegraSLA';
import deactivateRegraSLA from '@salesforce/apex/GestaoSLAController.deactivateRegraSLA';
import activateRegraSLA from '@salesforce/apex/GestaoSLAController.activateRegraSLA';
import getAreasInternas from '@salesforce/apex/GestaoSLAController.getAreasInternas';
import createRegrasSLABulk from '@salesforce/apex/GestaoSLAController.createRegrasSLABulk';
import getInactiveGestoes from '@salesforce/apex/GestaoSLAController.getInactiveGestoes';
import createGestaoSLA from '@salesforce/apex/GestaoSLAController.createGestaoSLA';
import updateGestaoSLA from '@salesforce/apex/GestaoSLAController.updateGestaoSLA';
import reactivateGestaoSLA from '@salesforce/apex/GestaoSLAController.reactivateGestaoSLA';
import createCategoria from '@salesforce/apex/GestaoSLAController.createCategoria';
import updateCategoria from '@salesforce/apex/GestaoSLAController.updateCategoria';
import deactivateCategoria from '@salesforce/apex/GestaoSLAController.deactivateCategoria';
import getInactiveCategorias from '@salesforce/apex/GestaoSLAController.getInactiveCategorias';
import reactivateCategoria from '@salesforce/apex/GestaoSLAController.reactivateCategoria';
import deleteGestaoSLA from '@salesforce/apex/GestaoSLAController.deleteGestaoSLA';
import deleteCategoria from '@salesforce/apex/GestaoSLAController.deleteCategoria';
import deleteRegraSLA from '@salesforce/apex/GestaoSLAController.deleteRegraSLA';
import deleteRegrasSLABulk from '@salesforce/apex/GestaoSLAController.deleteRegrasSLABulk';
import getCasePicklistFields from '@salesforce/apex/CategorizacaoController.getCasePicklistFields';
import getQueuesForCategoria from '@salesforce/apex/CategorizacaoController.getQueues';

const TAB_CATEGORIAS = 'categorias';
const TAB_REGRAS = 'regras';
const TAB_CONFIG = 'config';
const PAGE_SIZE_OPTIONS = [
    { label: '10', value: '10' },
    { label: '20', value: '20' },
    { label: '30', value: '30' },
    { label: '40', value: '40' },
    { label: '50', value: '50' }
];
const RULE_SCOPE_ATENDIMENTO = 'Atendimento';
const RULE_SCOPE_AREA_INTERNA = 'Area Interna';

export default class GestaoSLAWorkspace extends LightningElement {
    _sessionVersion = Date.now();
    @track loading = true;
    @track hasError = false;
    @track errorMessage = '';
    @track accessDenied = false;
    @track noGestao = false;

    @track permissions = {
        canAccessGestaoSLA: false,
        canManageCategories: false,
        canManageRules: false,
        canAdminTechnicalSettings: false
    };

    @track gestao = null;
    @track gestoes = [];
    @track selectedGestaoSLAId = null;
    @track pinnedGestaoRefreshToken = 0;
    @track summary = null;
    @track marcos = [];
    @track regrasSLA = [];
    @track categorias = [];
    @track filteredCategorias = [];
    @track pagedCategorias = [];
    @track showCategoriaModal = false;
    @track savingCategoria = false;
    @track categoriaModalMode = 'create';
    @track categoriaForm = {
        id: null,
        tipoCaso: '',
        categoria: '',
        assunto: '',
        subassunto: '',
        prioridadeSugerida: '',
        ativo: true,
        distribuirParaFila: false,
        porCampoCustomizado: false,
        filaDeveloperName: '',
        campoDistribuicao: '',
        valorDistribuicao: ''
    };
    @track casePicklistFieldsData = [];
    @track categoriaQueueOptionsData = [];
    @track showRegraModal = false;
    @track savingRegra = false;
    @track regraModalMode = 'create';
    @track regraForm = {
        id: null,
        categorizacaoId: '',
        marcoSLAId: '',
        escopoRegra: RULE_SCOPE_ATENDIMENTO,
        areaAtendimento: '',
        tempoBaixa: null,
        tempoMedia: null,
        tempoAlta: null,
        ativo: true
    };
    @track areasInternasRows = [];
    @track areasInternasPicklist = [];
    @track showAreaInternaBulkTable = false;
    @track activeTab = TAB_CATEGORIAS;

    @track searchTerm = '';
    @track filtroTipoCaso = 'Todos';
    @track filtroCategoria = 'Todos';
    @track filtroAssunto = 'Todos';
    @track filtroAtivo = 'Ativo';
    @track regrasFiltroCategorizacaoId = 'Todos';
    @track regrasFiltroMarcoSLAId = 'Todos';
    @track regrasFiltroEscopo = 'Todos';
    @track regrasFiltroAreaAtendimento = 'Todos';
    @track regrasFiltroAtivo = 'Todos';
    @track regrasCategorizacaoContextLabel = '';
    @track loadingRegras = false;

    @track pageSize = '10';
    @track currentPage = 1;
    @track unidadeNegocioOptions = [];
    @track showCreateModal = false;
    @track savingGestao = false;
    @track showEditModal = false;
    @track savingEditGestao = false;
    @track showReactivateModal = false;
    @track loadingInactiveGestoes = false;
    @track reactivatingGestao = false;
    @track inactiveGestoes = [];
    @track selectedInactiveGestaoId = null;
    @track showReactivateCategoriaModal = false;
    @track loadingInactiveCategorias = false;
    @track reactivatingCategoria = false;
    @track inactiveCategorias = [];
    @track selectedInactiveCategoriaId = null;
    @track tipoCasoPicklistOptions = [];
    @track categoriaPicklistOptions = [];
    @track assuntoPicklistOptions = [];
    @track subassuntoPicklistOptions = [];
    @track createForm = {
        name: '',
        unidadeNegocio: '',
        entitlementProcessName: '',
        businessHoursName: '',
        usaTempoTriagem: false,
        tempoTriagemMinutos: null,
        usaTempoRespostaChat: false,
        tempoRespostaChatMinutos: null,
        usaTempoFilaEmail: false,
        tempoFilaEmailMinutos: null,
        descricao: '',
        staticResourceName: '',
        ativo: true
    };
    @track editForm = {
        id: null,
        name: '',
        unidadeNegocio: '',
        entitlementProcessName: '',
        businessHoursName: '',
        usaTempoTriagem: false,
        tempoTriagemMinutos: null,
        usaTempoRespostaChat: false,
        tempoRespostaChatMinutos: null,
        usaTempoFilaEmail: false,
        tempoFilaEmailMinutos: null,
        descricao: '',
        staticResourceName: '',
        ativo: true
    };
    labels = {
        categoryTabTitle: categoryTabTitleLabel,
        categoryReactivateButton: categoryReactivateButtonLabel,
        categoryNewButton: categoryNewButtonLabel,
        categorySearchPlaceholder: categorySearchPlaceholderLabel,
        categoryFilterButton: categoryFilterButtonLabel,
        categoryBusinessUnit: categoryBusinessUnitLabel,
        categoryCaseType: categoryCaseTypeLabel,
        categoryLabel: categoryLabelLabel,
        categorySubject: categorySubjectLabel,
        categorySubsubject: categorySubsubjectLabel,
        categorySuggestedPriority: categorySuggestedPriorityLabel,
        categoryActiveColumn: categoryActiveColumnLabel,
        categoryStatusField: categoryStatusFieldLabel,
        categorySlaRules: categorySlaRulesLabel,
        categoryActions: categoryActionsLabel,
        categoryEdit: categoryEditLabel,
        categoryDeactivate: categoryDeactivateLabel,
        categoryDelete: categoryDeleteLabel,
        categoryDistributeToQueue: categoryDistributeToQueueLabel,
        categoryByCustomField: categoryByCustomFieldLabel,
        categoryQueue: categoryQueueLabel,
        categoryQueuePlaceholder: categoryQueuePlaceholderLabel,
        categoryDistributionField: categoryDistributionFieldLabel,
        categoryDistributionFieldPlaceholder: categoryDistributionFieldPlaceholderLabel,
        categoryDistributionValue: categoryDistributionValueLabel,
        categoryDistributionValuePlaceholder: categoryDistributionValuePlaceholderLabel,
        ruleDelete: ruleDeleteLabel,
        gestaoDeleteButton: gestaoDeleteButtonLabel,
        confirmDeleteCategory: confirmDeleteCategoryLabel,
        confirmDeleteRule: confirmDeleteRuleLabel,
        confirmDeleteGestao: confirmDeleteGestaoLabel,
        errorDeleteCategory: errorDeleteCategoryLabel,
        errorDeleteRule: errorDeleteRuleLabel,
        errorDeleteGestao: errorDeleteGestaoLabel,
        toastCategoryDeleted: toastCategoryDeletedLabel,
        toastRuleDeleted: toastRuleDeletedLabel,
        toastGestaoDeleted: toastGestaoDeletedLabel,
        categoryConfigureSla: categoryConfigureSlaLabel,
        categoryPaginationFirst: categoryPaginationFirstLabel,
        categoryPaginationPrevious: categoryPaginationPreviousLabel,
        categoryPaginationNext: categoryPaginationNextLabel,
        categoryPaginationLast: categoryPaginationLastLabel,
        categoryEmptyState: categoryEmptyStateLabel,
        categoryFilterCaseTypeAll: categoryFilterCaseTypeAllLabel,
        categoryFilterCategoryAll: categoryFilterCategoryAllLabel,
        categoryFilterSubjectAll: categoryFilterSubjectAllLabel,
        categoryFilterStatusAll: categoryFilterStatusAllLabel,
        categoryStatusOptionActive: categoryStatusOptionActiveLabel,
        categoryStatusOptionInactive: categoryStatusOptionInactiveLabel,
        categoryNoSubsubject: categoryNoSubsubjectLabel,
        categoryNoPriority: categoryNoPriorityLabel,
        categoryModalNewTitle: categoryModalNewTitleLabel,
        categoryModalEditTitle: categoryModalEditTitleLabel,
        categoryModalSavingAlt: categoryModalSavingAltLabel,
        categoryModalSelectCaseType: categoryModalSelectCaseTypeLabel,
        categoryModalSelectCategory: categoryModalSelectCategoryLabel,
        categoryModalSelectSubject: categoryModalSelectSubjectLabel,
        categoryModalCancel: categoryModalCancelLabel,
        categoryModalSave: categoryModalSaveLabel,
        categoryReactivateModalTitle: categoryReactivateModalTitleLabel,
        categoryReactivateModalLoadingAlt: categoryReactivateModalLoadingAltLabel,
        categoryReactivateModalSelect: categoryReactivateModalSelectLabel,
        categoryReactivateModalEmpty: categoryReactivateModalEmptyLabel,
        categoryReactivateModalConfirm: categoryReactivateModalConfirmLabel,
        categorySummaryActive: categorySummaryActiveLabel,
        categoryRulesCountSuffix: categoryRulesCountSuffixLabel,
        commonOf: commonOfLabel,
        commonSuccess: commonSuccessLabel,
        commonError: commonErrorLabel,
        toastCategoryCreated: toastCategoryCreatedLabel,
        toastCategoryUpdated: toastCategoryUpdatedLabel,
        toastCategoryDeactivated: toastCategoryDeactivatedLabel,
        toastCategoryReactivated: toastCategoryReactivatedLabel,
        errorLoadCategories: errorLoadCategoriesLabel,
        errorSaveCategory: errorSaveCategoryLabel,
        errorDeactivateCategory: errorDeactivateCategoryLabel,
        errorLoadInactiveCategories: errorLoadInactiveCategoriesLabel,
        errorSelectInactiveCategory: errorSelectInactiveCategoryLabel,
        errorReactivateCategory: errorReactivateCategoryLabel,
        gestaoLabel: gestaoLabelLabel,
        gestaoPinButton: gestaoPinButtonLabel,
        gestaoUnpinButton: gestaoUnpinButtonLabel,
        gestaoNewButton: gestaoNewButtonLabel,
        gestaoReactivateButton: gestaoReactivateButtonLabel,
        gestaoEditButton: gestaoEditButtonLabel,
        gestaoEditSettingsButton: gestaoEditSettingsButtonLabel,
        gestaoEntitlementProcess: gestaoEntitlementProcessLabel,
        gestaoBusinessHours: gestaoBusinessHoursLabel,
        gestaoMarcosUnicosSectionTitle: gestaoMarcosUnicosSectionTitleLabel,
        gestaoTriageTime: gestaoTriageTimeLabel,
        gestaoEmailQueueTime: gestaoEmailQueueTimeLabel,
        usaTriageTime: usaTriageTimeLabel,
        usaChatResponseTime: usaChatResponseTimeLabel,
        usaEmailQueueTime: usaEmailQueueTimeLabel,
        gestaoChatResponseTime: gestaoChatResponseTimeLabel,
        gestaoSummaryTitle: gestaoSummaryTitleLabel,
        gestaoSummaryAvailableMilestones: gestaoSummaryAvailableMilestonesLabel,
        gestaoSummaryInternalAreasN3: gestaoSummaryInternalAreasN3Label,
        gestaoSummaryLastUpdated: gestaoSummaryLastUpdatedLabel,
        gestaoToday: gestaoTodayLabel,
        gestaoViewReports: gestaoViewReportsLabel,
        gestaoBannerAlt: gestaoBannerAltLabel,
        ruleScope: ruleScopeLabel,
        rulePriorityHighMin: rulePriorityHighMinLabel,
        rulePriorityMediumMin: rulePriorityMediumMinLabel,
        rulePriorityLowMin: rulePriorityLowMinLabel,
        spinnerLoading: spinnerLoadingLabel,
        spinnerSaving: spinnerSavingLabel,
        accessDeniedTitle: accessDeniedTitleLabel,
        accessDeniedMessage: accessDeniedMessageLabel,
        noManagementFoundAdmin: noManagementFoundAdminLabel,
        noManagementFoundUser: noManagementFoundUserLabel,
        rulesTabTitle: rulesTabTitleLabel,
        technicalSettingsTabTitle: technicalSettingsTabTitleLabel,
        ruleNewButton: ruleNewButtonLabel,
        ruleModalEditTitle: ruleModalEditTitleLabel,
        globalTime: globalTimeLabel,
        milestoneTriageLabel: milestoneTriageLabelLabel,
        sourceManagementLabel: sourceManagementLabelLabel,
        applicationEmailNew: applicationEmailNewLabel,
        milestoneChatResponseLabel: milestoneChatResponseLabelLabel,
        applicationWhatsappChatNew: applicationWhatsappChatNewLabel,
        milestoneEmailQueueLabel: milestoneEmailQueueLabelLabel,
        rulesFilteredFor: rulesFilteredForLabel,
        rulesClearFilter: rulesClearFilterLabel,
        ruleInternalAreaPlaceholder: ruleInternalAreaPlaceholderLabel,
        rulesSpinnerLoading: rulesSpinnerLoadingLabel,
        ruleColCategorization: ruleColCategorizationLabel,
        ruleColMilestone: ruleColMilestoneLabel,
        ruleColScope: ruleColScopeLabel,
        ruleColInternalArea: ruleColInternalAreaLabel,
        areaInternaHelpTitle: areaInternaHelpTitleLabel,
        areaInternaHelpReplicateRow: areaInternaHelpReplicateRowLabel,
        areaInternaHelpReplicateColumn: areaInternaHelpReplicateColumnLabel,
        areaInternaHelpCopyRowPriority: areaInternaHelpCopyRowPriorityLabel,
        ruleColTimeLow: ruleColTimeLowLabel,
        ruleColTimeMedium: ruleColTimeMediumLabel,
        ruleColTimeHigh: ruleColTimeHighLabel,
        rulesEmptyState: rulesEmptyStateLabel,
        reactivateModalTitle: reactivateModalTitleLabel,
        reactivateModalEmpty: reactivateModalEmptyLabel,
        fieldName: fieldNameLabel,
        fieldTriageTimeMin: fieldTriageTimeMinLabel,
        fieldChatResponseTimeMin: fieldChatResponseTimeMinLabel,
        fieldEmailQueueTimeMin: fieldEmailQueueTimeMinLabel,
        fieldDescription: fieldDescriptionLabel,
        ruleFilterCategorizacaoAll: ruleFilterCategorizacaoAllLabel,
        ruleSelectCategorization: ruleSelectCategorizationLabel,
        ruleFilterMilestoneAll: ruleFilterMilestoneAllLabel,
        ruleSelectMilestone: ruleSelectMilestoneLabel,
        ruleFilterScopeAll: ruleFilterScopeAllLabel,
        commonInfo: commonInfoLabel,
        errorLoadManagement: errorLoadManagementLabel,
        errorSwitchManagement: errorSwitchManagementLabel,
        errorLoadRules: errorLoadRulesLabel,
        errorSaveRule: errorSaveRuleLabel,
        toastRuleCreated: toastRuleCreatedLabel,
        toastRuleBulkSaved: toastRuleBulkSavedLabel,
        toastRuleUpdated: toastRuleUpdatedLabel,
        toastRuleDeactivated: toastRuleDeactivatedLabel,
        errorDeactivateRule: errorDeactivateRuleLabel,
        confirmDeactivateRule: confirmDeactivateRuleLabel,
        activateRule: activateRuleLabel,
        toastRuleActivated: toastRuleActivatedLabel,
        confirmDeactivateCategory: confirmDeactivateCategoryLabel,
        errorLoadInactiveManagements: errorLoadInactiveManagementsLabel,
        errorSelectInactiveManagement: errorSelectInactiveManagementLabel,
        toastManagementReactivated: toastManagementReactivatedLabel,
        errorReactivateManagement: errorReactivateManagementLabel,
        toastManagementCreated: toastManagementCreatedLabel,
        errorCreateManagement: errorCreateManagementLabel,
        toastManagementUpdated: toastManagementUpdatedLabel,
        errorUpdateManagement: errorUpdateManagementLabel,
        errorRuleMilestoneRequired: errorRuleMilestoneRequiredLabel,
        errorRuleScopeRequired: errorRuleScopeRequiredLabel,
        errorRuleCategoryRequired: errorRuleCategoryRequiredLabel,
        errorRuleInternalAreaRequired: errorRuleInternalAreaRequiredLabel,
        errorRuleAtLeastOneTime: errorRuleAtLeastOneTimeLabel,
        errorRuleTimesMustBePositive: errorRuleTimesMustBePositiveLabel
    };

    connectedCallback() {
        this.initialize();
    }

    async initialize() {
        this.loading = true;
        this.hasError = false;
        this.errorMessage = '';
        this.accessDenied = false;
        this.noGestao = false;
        try {
            const [bootstrap, areasPicklist] = await Promise.all([getBootstrap(), getAreasInternas().catch(() => [])]);
            this.areasInternasPicklist = areasPicklist || [];
            this.permissions = { ...(bootstrap?.permissions || this.permissions) };
            this.unidadeNegocioOptions = bootstrap?.unidadeNegocioOptions || [];
            this.tipoCasoPicklistOptions = bootstrap?.tipoCasoOptions || [];
            this.categoriaPicklistOptions = bootstrap?.categoriaPicklistOptions || [];
            this.assuntoPicklistOptions = bootstrap?.assuntoOptions || [];
            this.subassuntoPicklistOptions = bootstrap?.subassuntoOptions || [];
            if (!this.permissions.canAccessGestaoSLA) {
                this.accessDenied = true;
                return;
            }

            this.gestoes = bootstrap?.gestoes || [];
            if (this.gestoes.length === 0) {
                this.noGestao = true;
                return;
            }

            this.selectedGestaoSLAId = this.resolveSelectedGestaoId();
            await this.loadSelectedGestaoData(this.selectedGestaoSLAId, true);
        } catch (error) {
            this.handleError(this.labels.errorLoadManagement, error);
        } finally {
            this.loading = false;
        }
    }

    async loadGestaoDetail(gestaoId) {
        const detail = await getGestaoDetail({ gestaoSLAId: gestaoId });
        this.permissions = { ...(detail?.permissions || this.permissions) };
        this.gestao = detail?.gestao || null;
        this.summary = detail?.summary || {
            totalCategorias: 0,
            totalMarcosAtivos: 0,
            totalRegrasAtivas: 0
        };
    }

    async loadCategorias(gestaoId) {
        const result = await getCategorias({
            gestaoSLAId: gestaoId,
            searchTerm: this.searchTerm || null,
            tipoCaso: this.filtroTipoCaso === 'Todos' ? null : this.filtroTipoCaso,
            categoria: this.filtroCategoria === 'Todos' ? null : this.filtroCategoria,
            assunto: this.filtroAssunto === 'Todos' ? null : this.filtroAssunto,
            ativo: this.filtroAtivo === 'Todos' ? null : this.filtroAtivo === 'Ativo'
        });
        this.permissions = { ...(result?.permissions || this.permissions) };
        this.categorias = (result?.categorias || []).map((row) => ({
            ...row,
            ...this.withCategoryLabels(row),
            prioridadeBadgeClass: this.getPriorityClass(row.prioridadeSugerida),
            ativoLabel: row.ativo ? this.labels.categoryStatusOptionActive : this.labels.categoryStatusOptionInactive,
            ativoClass: row.ativo ? 'status-badge status-active' : 'status-badge status-inactive',
            totalRegrasLabel: `${row.totalRegrasAtivas || 0} ${this.labels.categoryRulesCountSuffix}`
        }));
        this.filteredCategorias = [...this.categorias];
        this.currentPage = 1;
        this.applyPagination();
    }

    async loadMarcos(gestaoId) {
        const result = await getMarcos({ gestaoSLAId: gestaoId });
        this.permissions = { ...(result?.permissions || this.permissions) };
        this.marcos = result?.marcos || [];
    }

    async loadRegrasSLA(gestaoId) {
        if (!gestaoId) {
            this.regrasSLA = [];
            return;
        }
        this.loadingRegras = true;
        try {
            const result = await getRegrasSLA({
                gestaoSLAId: gestaoId,
                categorizacaoId: this.regrasFiltroCategorizacaoId === 'Todos' ? null : this.regrasFiltroCategorizacaoId,
                marcoSLAId: this.regrasFiltroMarcoSLAId === 'Todos' ? null : this.regrasFiltroMarcoSLAId,
                escopo: this.regrasFiltroEscopo === 'Todos' ? null : this.regrasFiltroEscopo,
                areaAtendimento: this.regrasFiltroAreaAtendimento === 'Todos' ? null : this.regrasFiltroAreaAtendimento || null,
                ativo: this.regrasFiltroAtivo === 'Todos' ? null : this.regrasFiltroAtivo === 'Ativo'
            });
            this.permissions = { ...(result?.permissions || this.permissions) };
            this.regrasSLA = (result?.regras || []).map((row) => ({
                ...row,
                tempoBaixaLabel: this.formatMinutes(row.tempoBaixa),
                tempoMediaLabel: this.formatMinutes(row.tempoMedia),
                tempoAltaLabel: this.formatMinutes(row.tempoAlta),
                ativoLabel: row.ativo ? this.labels.categoryStatusOptionActive : this.labels.categoryStatusOptionInactive,
                ativoClass: row.ativo ? 'status-badge status-active' : 'status-badge status-inactive'
            }));
        } catch (error) {
            this.showToast(this.labels.commonError, this.reduceError(error) || this.labels.errorLoadRules, 'error');
        } finally {
            this.loadingRegras = false;
        }
    }

    get hasGestao() {
        return !!this.gestao;
    }

    get showGestaoSelector() {
        return this.gestoes.length > 0;
    }

    get gestaoOptions() {
        return (this.gestoes || []).map((g) => ({ label: g.name, value: g.id }));
    }

    get isPinnedGestao() {
        // Referencia pinnedGestaoRefreshToken só para registrar a dependência reativa do LWC —
        // localStorage não é rastreável nativamente, então forçamos o recálculo via esse contador.
        return this.pinnedGestaoRefreshToken >= 0 &&
            !!this.selectedGestaoSLAId &&
            this.selectedGestaoSLAId === this.getPinnedGestaoId();
    }

    get pinIconName() {
        return this.isPinnedGestao ? 'utility:pinned' : 'utility:pin';
    }

    get pinIconVariant() {
        return this.isPinnedGestao ? 'brand' : 'border-filled';
    }

    get pinButtonLabel() {
        return this.isPinnedGestao ? this.labels.gestaoUnpinButton : this.labels.gestaoPinButton;
    }

    getPinnedGestaoId() {
        try {
            return window.localStorage.getItem(PINNED_GESTAO_STORAGE_KEY) || null;
        } catch (error) {
            return null;
        }
    }

    setPinnedGestaoId(gestaoId) {
        try {
            if (gestaoId) {
                window.localStorage.setItem(PINNED_GESTAO_STORAGE_KEY, gestaoId);
            } else {
                window.localStorage.removeItem(PINNED_GESTAO_STORAGE_KEY);
            }
        } catch (error) {
            // localStorage indisponível (ex.: navegação privada) — favorito não persiste, sem impacto funcional.
        }
    }

    togglePinGestao() {
        if (!this.selectedGestaoSLAId) return;
        this.setPinnedGestaoId(this.isPinnedGestao ? null : this.selectedGestaoSLAId);
        this.pinnedGestaoRefreshToken = (this.pinnedGestaoRefreshToken || 0) + 1;
    }

    get hasHeaderStaticImage() {
        const staticResourceName = this.gestao?.staticResourceName;
        return !!(staticResourceName && String(staticResourceName).trim());
    }

    get headerBannerImageUrl() {
        const staticResourceName = this.gestao?.staticResourceName;
        if (!staticResourceName) {
            return '';
        }
        const sanitized = String(staticResourceName).trim();
        if (!sanitized) {
            return '';
        }
        return `/resource/${sanitized}?v=${this._sessionVersion}`;
    }

    get statusLabel() {
        return this.gestao?.ativo ? this.labels.categoryStatusOptionActive : this.labels.categoryStatusOptionInactive;
    }

    get breadcrumbLabel() {
        return `${this.labels.gestaoLabel} / ${this.gestao?.name || ''}`;
    }

    get canShowTechnical() {
        return this.permissions.canAdminTechnicalSettings === true;
    }

    get showConfigTab() {
        return this.permissions.canAdminTechnicalSettings === true;
    }

    get pageSizeOptions() {
        return PAGE_SIZE_OPTIONS;
    }

    buildLabelLookup(picklistOptions) {
        return new Map((picklistOptions || []).map((o) => [o.value, o.label]));
    }

    withCategoryLabels(row) {
        const tipoCasoLabelByValue = this.buildLabelLookup(this.tipoCasoPicklistOptions);
        const categoriaLabelByValue = this.buildLabelLookup(this.categoriaPicklistOptions);
        const assuntoLabelByValue = this.buildLabelLookup(this.assuntoPicklistOptions);
        const subassuntoLabelByValue = this.buildLabelLookup(this.subassuntoPicklistOptions);
        return {
            tipoCasoLabel: tipoCasoLabelByValue.get(row.tipoCaso) || row.tipoCaso,
            categoriaLabel: categoriaLabelByValue.get(row.categoria) || row.categoria,
            assuntoLabel: assuntoLabelByValue.get(row.assunto) || row.assunto,
            subassuntoLabel: subassuntoLabelByValue.get(row.subassunto) || row.subassunto
        };
    }

    get tipoCasoOptions() {
        const labelByValue = this.buildLabelLookup(this.tipoCasoPicklistOptions);
        const values = Array.from(new Set((this.categorias || []).map((c) => c.tipoCaso).filter((v) => !!v)))
            .sort((a, b) => (labelByValue.get(a) || a).localeCompare(labelByValue.get(b) || b, 'pt-BR', { sensitivity: 'base' }));
        return [{ label: this.labels.categoryFilterCaseTypeAll, value: 'Todos' }, ...values.map((v) => ({ label: labelByValue.get(v) || v, value: v }))];
    }

    get categoriaOptions() {
        const labelByValue = this.buildLabelLookup(this.categoriaPicklistOptions);
        const values = Array.from(new Set((this.categorias || []).map((c) => c.categoria).filter((v) => !!v)))
            .sort((a, b) => (labelByValue.get(a) || a).localeCompare(labelByValue.get(b) || b, 'pt-BR', { sensitivity: 'base' }));
        return [{ label: this.labels.categoryFilterCategoryAll, value: 'Todos' }, ...values.map((v) => ({ label: labelByValue.get(v) || v, value: v }))];
    }

    get assuntoOptions() {
        const labelByValue = this.buildLabelLookup(this.assuntoPicklistOptions);
        const values = Array.from(new Set((this.categorias || []).map((c) => c.assunto).filter((v) => !!v)))
            .sort((a, b) => (labelByValue.get(a) || a).localeCompare(labelByValue.get(b) || b, 'pt-BR', { sensitivity: 'base' }));
        return [{ label: this.labels.categoryFilterSubjectAll, value: 'Todos' }, ...values.map((v) => ({ label: labelByValue.get(v) || v, value: v }))];
    }

    get categoriaTipoCasoOptions() {
        return this.withCurrentComboboxValue(this.tipoCasoPicklistOptions, this.categoriaForm?.tipoCaso);
    }

    get categoriaCategoriaOptions() {
        return this.withCurrentComboboxValue(this.categoriaPicklistOptions, this.categoriaForm?.categoria);
    }

    get categoriaAssuntoOptions() {
        return this.withCurrentComboboxValue(this.assuntoPicklistOptions, this.categoriaForm?.assunto);
    }

    get categoriaSubassuntoOptions() {
        return [
            { label: this.labels.categoryNoSubsubject, value: '' },
            ...this.withCurrentComboboxValue(this.subassuntoPicklistOptions, this.categoriaForm?.subassunto)
        ];
    }

    get ativoOptions() {
        return [
            { label: this.labels.categoryFilterStatusAll, value: 'Todos' },
            { label: this.labels.categoryStatusOptionActive, value: 'Ativo' },
            { label: this.labels.categoryStatusOptionInactive, value: 'Inativo' }
        ];
    }

    get regrasCategorizacaoOptions() {
        const options = (this.categorias || []).map((c) => ({
            label: this.buildCategoriaDisplay(c),
            value: c.id
        }));
        return [{ label: this.labels.ruleFilterCategorizacaoAll, value: 'Todos' }, ...options];
    }

    get regraCategorizacaoOptions() {
        return [{ label: this.labels.ruleSelectCategorization, value: '' }, ...(this.categorias || []).map((c) => ({
            label: this.buildCategoriaDisplay(c),
            value: c.id
        }))];
    }

    get regrasMarcoOptions() {
        const options = (this.marcos || []).map((m) => ({
            label: m.nomeMarco || m.name,
            value: m.id
        }));
        return [{ label: this.labels.ruleFilterMilestoneAll, value: 'Todos' }, ...options];
    }

    get regraMarcoOptions() {
        return [{ label: this.labels.ruleSelectMilestone, value: '' }, ...(this.marcos || []).map((m) => ({
            label: m.nomeMarco || m.name,
            value: m.id
        }))];
    }

    get regrasEscopoOptions() {
        return [
            { label: this.labels.ruleFilterScopeAll, value: 'Todos' },
            { label: RULE_SCOPE_ATENDIMENTO, value: RULE_SCOPE_ATENDIMENTO },
            { label: RULE_SCOPE_AREA_INTERNA, value: RULE_SCOPE_AREA_INTERNA }
        ];
    }

    get regrasFiltroAreaAtendimentoOptions() {
        return [
            { label: this.labels.ruleFilterCategorizacaoAll, value: 'Todos' },
            ...(this.areasInternasPicklist || []).map((a) => ({ label: a, value: a }))
        ];
    }

    get showAreaInternasFilter() {
        return this.regrasFiltroEscopo === RULE_SCOPE_AREA_INTERNA;
    }

    get statusClass() {
        return this.gestao?.ativo ? 'status-badge status-active' : 'status-badge status-inactive';
    }

    get regraEscopoOptions() {
        return [
            { label: RULE_SCOPE_ATENDIMENTO, value: RULE_SCOPE_ATENDIMENTO },
            { label: RULE_SCOPE_AREA_INTERNA, value: RULE_SCOPE_AREA_INTERNA }
        ];
    }

    get isRegraModalCreate() {
        return this.regraModalMode === 'create';
    }

    get regraModalTitle() {
        return this.isRegraModalCreate ? this.labels.ruleNewButton : this.labels.ruleModalEditTitle;
    }

    get regraCategoriaRequired() {
        return true;
    }

    get isTipoAtendimento() {
        return this.regraForm?.escopoRegra === RULE_SCOPE_ATENDIMENTO;
    }

    get isTipoAreaInterna() {
        return this.regraForm?.escopoRegra === RULE_SCOPE_AREA_INTERNA;
    }

    get prioridadeCategoriaOptions() {
        return [
            { label: this.labels.categoryNoPriority, value: '' },
            { label: 'Low', value: 'Low' },
            { label: 'Medium', value: 'Medium' },
            { label: 'High', value: 'High' }
        ];
    }

    get isCategoriaModalCreate() {
        return this.categoriaModalMode === 'create';
    }

    get categoriaModalTitle() {
        return this.isCategoriaModalCreate ? this.labels.categoryModalNewTitle : this.labels.categoryModalEditTitle;
    }

    get categoriaSubassuntoRequired() {
        return false;
    }

    get categoriaPrioridadeRequired() {
        return false;
    }

    get categoriaAtivoValue() {
        return this.categoriaForm?.ativo === true ? 'true' : 'false';
    }

    get statusEditOptions() {
        return [
            { label: this.labels.categoryStatusOptionActive, value: 'true' },
            { label: this.labels.categoryStatusOptionInactive, value: 'false' }
        ];
    }

    get editStatusValue() {
        return this.editForm?.ativo === true ? 'true' : 'false';
    }

    get hasCategorias() {
        return this.filteredCategorias.length > 0;
    }

    get hasRegrasSLA() {
        return (this.regrasSLA || []).length > 0;
    }

    get hasRegrasCategorizacaoContext() {
        return !!this.regrasCategorizacaoContextLabel;
    }

    get totalCategoriasLabel() {
        return `${this.filteredCategorias.length}`;
    }

    get totalMarcosLabel() {
        return `${this.summary?.totalMarcosAtivos || 0}`;
    }

    get totalAreasInternasLabel() {
        const total = this.summary?.totalAreasInternas;
        return total === null || total === undefined ? '--' : String(total);
    }

    get totalPages() {
        return Math.max(1, Math.ceil(this.filteredCategorias.length / Number(this.pageSize)));
    }

    get canGoPrevious() {
        return this.currentPage > 1;
    }

    get canGoNext() {
        return this.currentPage < this.totalPages;
    }

    get firstRecordNumber() {
        if (this.filteredCategorias.length === 0) return 0;
        return (this.currentPage - 1) * Number(this.pageSize) + 1;
    }

    get lastRecordNumber() {
        return Math.min(this.currentPage * Number(this.pageSize), this.filteredCategorias.length);
    }

    get rangeLabel() {
        return `${this.firstRecordNumber}-${this.lastRecordNumber} ${this.labels.commonOf} ${this.totalCategoriasLabel}`;
    }

    get activeIsCategorias() {
        return this.activeTab === TAB_CATEGORIAS;
    }

    get activeIsRegras() {
        return this.activeTab === TAB_REGRAS;
    }

    get activeIsConfig() {
        return this.activeTab === TAB_CONFIG;
    }

    get categoriasTabClass() {
        return this.activeIsCategorias ? 'tab active' : 'tab';
    }

    get regrasTabClass() {
        return this.activeIsRegras ? 'tab active' : 'tab';
    }

    get configTabClass() {
        return this.activeIsConfig ? 'tab active' : 'tab';
    }

    get disableManageCategories() {
        return this.permissions.canManageCategories !== true;
    }

    get disableManageRules() {
        return this.permissions.canManageRules !== true;
    }

    get disableGoPrevious() {
        return !this.canGoPrevious;
    }

    get disableGoNext() {
        return !this.canGoNext;
    }

    get noGestaoMessage() {
        if (this.permissions.canAdminTechnicalSettings) {
            return this.labels.noManagementFoundAdmin;
        }
        return this.labels.noManagementFoundUser;
    }

    get canCreateGestao() {
        return this.permissions.canAdminTechnicalSettings === true;
    }

    get canReactivateGestao() {
        return this.permissions.canAdminTechnicalSettings === true;
    }

    get canEditGestao() {
        return this.permissions.canAdminTechnicalSettings === true || this.permissions.canManageCategories === true;
    }

    // Campos estruturais (Nome, Unidade, Entitlement Process, Business Hours, Status, Descrição,
    // Static Resource) e os checkboxes "Usa Tempo de X?" só podem ser editados pelo Admin Técnico.
    // O Gestor (GestaoSLAConfigurador / canManageCategories) só edita os valores de tempo dos
    // marcos já habilitados — espelha a blindagem feita no servidor em GestaoSLAService.updateGestaoSLA.
    get isCamposEstruturaisReadOnly() {
        return this.permissions.canAdminTechnicalSettings !== true;
    }

    get hasInactiveGestoes() {
        return (this.inactiveGestoes || []).length > 0;
    }

    get hasInactiveCategorias() {
        return (this.inactiveCategorias || []).length > 0;
    }

    async handleTabClick(event) {
        this.activeTab = event.currentTarget.dataset.tab;
        if (this.activeTab === TAB_REGRAS) {
            await this.loadRegrasSLA(this.selectedGestaoSLAId);
        }
    }

    handleSearchChange(event) {
        this.searchTerm = event.target.value || '';
    }

    async handleApplyFilters() {
        if (!this.selectedGestaoSLAId) return;
        this.loading = true;
        try {
            await this.loadCategorias(this.selectedGestaoSLAId);
        } catch (error) {
            this.handleError(this.labels.errorLoadCategories, error);
        } finally {
            this.loading = false;
        }
    }

    async handleFilterTipoCaso(event) {
        this.filtroTipoCaso = event.detail.value;
        await this.handleApplyFilters();
    }

    async handleFilterCategoria(event) {
        this.filtroCategoria = event.detail.value;
        await this.handleApplyFilters();
    }

    async handleFilterAssunto(event) {
        this.filtroAssunto = event.detail.value;
        await this.handleApplyFilters();
    }

    async handleFilterAtivo(event) {
        this.filtroAtivo = event.detail.value;
        await this.handleApplyFilters();
    }

    async handleRegraFilterChange(event) {
        const field = event.target?.name;
        if (!field) return;
        this[field] = event.detail?.value ?? event.target?.value ?? '';
        if (field === 'regrasFiltroCategorizacaoId' && this.regrasFiltroCategorizacaoId === 'Todos') {
            this.regrasCategorizacaoContextLabel = '';
        }
        if (field === 'regrasFiltroEscopo' && this[field] !== RULE_SCOPE_AREA_INTERNA) {
            this.regrasFiltroAreaAtendimento = 'Todos';
        }
        await this.loadRegrasSLA(this.selectedGestaoSLAId);
    }

    async handleApplyRegrasFilters() {
        await this.loadRegrasSLA(this.selectedGestaoSLAId);
    }

    async handleClearRegrasCategoriaFilter() {
        this.regrasFiltroCategorizacaoId = 'Todos';
        this.regrasCategorizacaoContextLabel = '';
        await this.loadRegrasSLA(this.selectedGestaoSLAId);
    }

    openCreateRegraModal() {
        if (!this.permissions.canManageRules || !this.selectedGestaoSLAId) return;
        const contextCategoriaId = this.regrasFiltroCategorizacaoId !== 'Todos' ? this.regrasFiltroCategorizacaoId : '';
        this.regraModalMode = 'create';
        this.regraForm = {
            id: null,
            categorizacaoId: contextCategoriaId,
            marcoSLAId: '',
            escopoRegra: RULE_SCOPE_ATENDIMENTO,
            areaAtendimento: '',
            tempoBaixa: null,
            tempoMedia: null,
            tempoAlta: null,
            ativo: true
        };
        this.areasInternasRows = [];
        this.showAreaInternaBulkTable = false;
        this.showRegraModal = true;
    }

    openEditRegraModal(event) {
        if (!this.permissions.canManageRules) return;
        const regraId = event.currentTarget?.dataset?.id;
        const row = (this.regrasSLA || []).find((r) => r.id === regraId);
        if (!row) return;
        this.regraModalMode = 'edit';
        this.regraForm = {
            id: row.id,
            categorizacaoId: row.categorizacaoId || '',
            marcoSLAId: row.marcoSLAId || '',
            escopoRegra: row.escopoRegra || RULE_SCOPE_ATENDIMENTO,
            areaAtendimento: row.areaAtendimento || '',
            tempoBaixa: row.tempoBaixa ?? null,
            tempoMedia: row.tempoMedia ?? null,
            tempoAlta: row.tempoAlta ?? null,
            ativo: row.ativo === true
        };
        if (this.regraForm.escopoRegra === RULE_SCOPE_AREA_INTERNA) {
            this.showAreaInternaBulkTable = true;
            this.loadAreasInternas(this.regraForm.categorizacaoId);
        } else {
            this.showAreaInternaBulkTable = false;
            this.areasInternasRows = [];
        }
        this.showRegraModal = true;
    }

    closeRegraModal() {
        this.showRegraModal = false;
        this.savingRegra = false;
        this.areasInternasRows = [];
        this.showAreaInternaBulkTable = false;
    }

    handleRegraInputChange(event) {
        const field = event.target?.name;
        if (!field) return;
        let value = event.detail?.value ?? event.target?.value;
        if (['tempoBaixa', 'tempoMedia', 'tempoAlta'].includes(field)) {
            value = value === null || value === '' ? null : Number(value);
        }
        const nextForm = { ...this.regraForm, [field]: value };
        if (field === 'escopoRegra') {
            if (value !== RULE_SCOPE_AREA_INTERNA) {
                nextForm.areaAtendimento = '';
                this.areasInternasRows = [];
                this.showAreaInternaBulkTable = false;
            }
            if (value !== RULE_SCOPE_ATENDIMENTO) {
                nextForm.marcoSLAId = '';
            }
            if (value === RULE_SCOPE_AREA_INTERNA && this.regraModalMode === 'create') {
                this.showAreaInternaBulkTable = true;
                this.loadAreasInternas(nextForm.categorizacaoId);
            }
        }
        if (field === 'categorizacaoId' && this.showAreaInternaBulkTable) {
            this.loadAreasInternas(value);
        }
        this.regraForm = nextForm;
    }

    async loadAreasInternas(categorizacaoId) {
        try {
            const [areas, existingResponse] = await Promise.all([
                getAreasInternas(),
                categorizacaoId
                    ? getRegrasSLA({
                          gestaoSLAId: this.selectedGestaoSLAId,
                          categorizacaoId,
                          marcoSLAId: null,
                          escopo: RULE_SCOPE_AREA_INTERNA,
                          areaAtendimento: null,
                          ativo: true
                      })
                    : Promise.resolve(null)
            ]);
            const existingByArea = new Map(
                (existingResponse?.regras || []).map((r) => [r.areaAtendimento, r])
            );
            this.areasInternasRows = (areas || []).map((area) => {
                const existing = existingByArea.get(area);
                return {
                    area,
                    existingId: existing?.id ?? null,
                    tempoAlta: existing?.tempoAlta ?? null,
                    tempoMedia: existing?.tempoMedia ?? null,
                    tempoBaixa: existing?.tempoBaixa ?? null
                };
            });
        } catch (error) {
            this.showToast(this.labels.commonError, this.reduceError(error) || this.labels.errorLoadRules, 'error');
        }
    }

    handleAreaRowChange(event) {
        const area = event.currentTarget?.dataset?.area;
        const field = event.currentTarget?.dataset?.field;
        if (!area || !field) return;
        const rawValue = event.detail?.value ?? event.target?.value;
        const value = rawValue === null || rawValue === '' ? null : Number(rawValue);
        this.areasInternasRows = this.areasInternasRows.map((row) =>
            row.area === area ? { ...row, [field]: value } : row
        );
    }

    handleCopyRowPriorityHigh(event) {
        const area = event.currentTarget?.dataset?.area;
        if (!area) return;
        this.areasInternasRows = this.areasInternasRows.map((row) =>
            row.area === area ? { ...row, tempoMedia: row.tempoAlta, tempoBaixa: row.tempoAlta } : row
        );
    }

    handleReplicateColumn(event) {
        const field = event.currentTarget?.dataset?.field;
        if (!field || this.areasInternasRows.length === 0) return;
        const sourceValue = this.areasInternasRows[0][field];
        if (sourceValue === null || sourceValue === undefined) return;
        this.areasInternasRows = this.areasInternasRows.map((row) => ({ ...row, [field]: sourceValue }));
    }

    handleReplicateFirstRow() {
        if (this.areasInternasRows.length === 0) return;
        const { tempoAlta, tempoMedia, tempoBaixa } = this.areasInternasRows[0];
        this.areasInternasRows = this.areasInternasRows.map((row) => ({
            ...row,
            tempoAlta,
            tempoMedia,
            tempoBaixa
        }));
    }

    async handleSaveRegra() {
        if (!this.permissions.canManageRules) return;

        if (this.showAreaInternaBulkTable) {
            if (!this.regraForm.categorizacaoId) {
                this.showToast(this.labels.commonError, this.labels.errorRuleCategoryRequired, 'error');
                return;
            }
            const allRows = this.areasInternasRows || [];
            const filledRows = allRows.filter((row) => row.tempoAlta || row.tempoMedia || row.tempoBaixa);
            const clearedRows = allRows.filter(
                (row) => row.existingId && !row.tempoAlta && !row.tempoMedia && !row.tempoBaixa
            );
            if (filledRows.length === 0 && clearedRows.length === 0) {
                this.showToast(this.labels.commonError, this.labels.errorRuleAtLeastOneTime, 'error');
                return;
            }
            const hasNonPositive = filledRows.some((row) => {
                const times = [row.tempoAlta, row.tempoMedia, row.tempoBaixa].filter(
                    (v) => v !== null && v !== undefined
                );
                return times.some((v) => Number(v) <= 0);
            });
            if (hasNonPositive) {
                this.showToast(this.labels.commonError, this.labels.errorRuleTimesMustBePositive, 'error');
                return;
            }
            this.savingRegra = true;
            try {
                const requests = filledRows.map((row) => ({
                    gestaoSLAId: this.selectedGestaoSLAId,
                    categorizacaoId: this.regraForm.categorizacaoId || null,
                    escopoRegra: RULE_SCOPE_AREA_INTERNA,
                    areaAtendimento: row.area,
                    tempoBaixa: row.tempoBaixa ? Number(row.tempoBaixa) : null,
                    tempoMedia: row.tempoMedia ? Number(row.tempoMedia) : null,
                    tempoAlta: row.tempoAlta ? Number(row.tempoAlta) : null,
                    ativo: true
                }));
                const tasks = [];
                if (requests.length > 0) tasks.push(createRegrasSLABulk({ requests }));
                if (clearedRows.length > 0) {
                    tasks.push(deleteRegrasSLABulk({ regraIds: clearedRows.map((row) => row.existingId) }));
                }
                await Promise.all(tasks);
                this.showToast(this.labels.commonSuccess, this.labels.toastRuleBulkSaved, 'success');
                await Promise.all([
                    this.loadGestaoDetail(this.selectedGestaoSLAId),
                    this.loadCategorias(this.selectedGestaoSLAId),
                    this.loadRegrasSLA(this.selectedGestaoSLAId)
                ]);
                this.closeRegraModal();
            } catch (error) {
                this.showToast(this.labels.commonError, this.reduceError(error) || this.labels.errorSaveRule, 'error');
            } finally {
                this.savingRegra = false;
            }
            return;
        }

        if (!this.validateRegraForm()) return;
        this.savingRegra = true;
        try {
            const request = this.buildRegraPayload();
            if (this.isRegraModalCreate) {
                await createRegraSLA({ request });
                this.showToast(this.labels.commonSuccess, this.labels.toastRuleCreated, 'success');
            } else {
                await updateRegraSLA({ request });
                this.showToast(this.labels.commonSuccess, this.labels.toastRuleUpdated, 'success');
            }
            await Promise.all([
                this.loadGestaoDetail(this.selectedGestaoSLAId),
                this.loadCategorias(this.selectedGestaoSLAId),
                this.loadRegrasSLA(this.selectedGestaoSLAId)
            ]);
            this.closeRegraModal();
        } catch (error) {
            this.showToast(this.labels.commonError, this.reduceError(error) || this.labels.errorSaveRule, 'error');
        } finally {
            this.savingRegra = false;
        }
    }

    async handleDeactivateRegra(event) {
        if (!this.permissions.canManageRules) return;
        const regraId = event.currentTarget?.dataset?.id;
        if (!regraId) return;
        const confirmed = window.confirm(this.labels.confirmDeactivateRule);
        if (!confirmed) return;
        try {
            await deactivateRegraSLA({ regraSLAId: regraId });
            this.showToast(this.labels.commonSuccess, this.labels.toastRuleDeactivated, 'success');
            await Promise.all([
                this.loadGestaoDetail(this.selectedGestaoSLAId),
                this.loadCategorias(this.selectedGestaoSLAId),
                this.loadRegrasSLA(this.selectedGestaoSLAId)
            ]);
        } catch (error) {
            this.showToast(this.labels.commonError, this.reduceError(error) || this.labels.errorDeactivateRule, 'error');
        }
    }

    async handleGestaoChange(event) {
        const nextId = event.detail.value;
        if (!nextId || nextId === this.selectedGestaoSLAId) {
            return;
        }
        this.loading = true;
        try {
            this.selectedGestaoSLAId = nextId;
            this.resetRegrasFilters();
            await this.loadSelectedGestaoData(nextId, true);
        } catch (error) {
            this.handleError(this.labels.errorSwitchManagement, error);
        } finally {
            this.loading = false;
        }
    }

    handlePageSizeChange(event) {
        const value = event?.detail?.value ?? event?.target?.value;
        this.pageSize = String(value);
        this.currentPage = 1;
        this.applyPagination();
    }

    handleFirstPage() {
        this.currentPage = 1;
        this.applyPagination();
    }

    handlePreviousPage() {
        if (!this.canGoPrevious) return;
        this.currentPage -= 1;
        this.applyPagination();
    }

    handleNextPage() {
        if (!this.canGoNext) return;
        this.currentPage += 1;
        this.applyPagination();
    }

    handleLastPage() {
        this.currentPage = this.totalPages;
        this.applyPagination();
    }

    openCreateModal() {
        this.createForm = {
            name: '',
            unidadeNegocio: '',
            entitlementProcessName: '',
            businessHoursName: '',
            usaTempoTriagem: false,
            tempoTriagemMinutos: null,
            usaTempoRespostaChat: false,
            tempoRespostaChatMinutos: null,
            usaTempoFilaEmail: false,
            tempoFilaEmailMinutos: null,
            descricao: '',
            staticResourceName: '',
            ativo: true
        };
        this.showCreateModal = true;
    }

    closeCreateModal() {
        this.showCreateModal = false;
        this.savingGestao = false;
    }

    openEditModal() {
        if (!this.gestao) return;
        this.editForm = {
            id: this.gestao.id,
            name: this.gestao.name || '',
            unidadeNegocio: this.gestao.unidadeNegocio || '',
            entitlementProcessName: this.gestao.entitlementProcessName || '',
            businessHoursName: this.gestao.businessHoursName || '',
            usaTempoTriagem: this.gestao.usaTempoTriagem === true,
            tempoTriagemMinutos: this.gestao.tempoTriagemMinutos ?? null,
            usaTempoRespostaChat: this.gestao.usaTempoRespostaChat === true,
            tempoRespostaChatMinutos: this.gestao.tempoRespostaChatMinutos ?? null,
            usaTempoFilaEmail: this.gestao.usaTempoFilaEmail === true,
            tempoFilaEmailMinutos: this.gestao.tempoFilaEmailMinutos ?? null,
            descricao: this.gestao.descricao || '',
            staticResourceName: this.gestao.staticResourceName || '',
            ativo: this.gestao.ativo === true
        };
        this.showEditModal = true;
    }

    closeEditModal() {
        this.showEditModal = false;
        this.savingEditGestao = false;
    }

    async openCreateCategoriaModal() {
        if (!this.permissions.canManageCategories || !this.selectedGestaoSLAId) return;
        this.categoriaModalMode = 'create';
        this.categoriaForm = {
            id: null,
            tipoCaso: '',
            categoria: '',
            assunto: '',
            subassunto: '',
            prioridadeSugerida: '',
            ativo: true,
            distribuirParaFila: false,
            porCampoCustomizado: false,
            filaDeveloperName: '',
            campoDistribuicao: '',
            valorDistribuicao: ''
        };
        this.showCategoriaModal = true;
        await this.loadCategoriaDistribuicaoData();
    }

    async openEditCategoriaModal(event) {
        if (!this.permissions.canManageCategories) return;
        const categoriaId = event.currentTarget?.dataset?.id;
        const row = (this.categorias || []).find((c) => c.id === categoriaId);
        if (!row) return;
        this.categoriaModalMode = 'edit';
        this.categoriaForm = {
            id: row.id,
            tipoCaso: row.tipoCaso || '',
            categoria: row.categoria || '',
            assunto: row.assunto || '',
            subassunto: row.subassunto || '',
            prioridadeSugerida: row.prioridadeSugerida || '',
            ativo: row.ativo === true,
            distribuirParaFila: row.distribuirParaFila === true,
            porCampoCustomizado: row.porCampoCustomizado === true,
            filaDeveloperName: row.filaDeveloperName || '',
            campoDistribuicao: row.campoDistribuicao || '',
            valorDistribuicao: row.valorDistribuicao || ''
        };
        this.showCategoriaModal = true;
        await this.loadCategoriaDistribuicaoData();
    }

    async loadCategoriaDistribuicaoData() {
        try {
            const [fields, queues] = await Promise.all([
                this.casePicklistFieldsData.length ? Promise.resolve(this.casePicklistFieldsData) : getCasePicklistFields(),
                getQueuesForCategoria({ unidadeNegocio: this.gestao?.unidadeNegocio })
            ]);
            this.casePicklistFieldsData = fields || [];
            this.categoriaQueueOptionsData = queues || [];
        } catch (error) {
            this.showToast(this.labels.commonError, this.reduceError(error), 'error');
        }
    }

    closeCategoriaModal() {
        this.showCategoriaModal = false;
        this.savingCategoria = false;
    }

    handleCategoriaInputChange(event) {
        const field = event.target?.name;
        if (!field) return;
        const isToggle = field === 'distribuirParaFila' || field === 'porCampoCustomizado';
        let value = isToggle ? event.target?.checked : event.detail?.value ?? event.target?.value;
        if (field === 'ativo') {
            value = value === true || value === 'true';
        }
        this.categoriaForm = { ...this.categoriaForm, [field]: value };

        if (field === 'distribuirParaFila' && value === false) {
            this.categoriaForm = {
                ...this.categoriaForm,
                porCampoCustomizado: false,
                filaDeveloperName: '',
                campoDistribuicao: '',
                valorDistribuicao: ''
            };
        }
        if (field === 'porCampoCustomizado' && value === false) {
            this.categoriaForm = { ...this.categoriaForm, campoDistribuicao: '', valorDistribuicao: '' };
        }
        if (field === 'campoDistribuicao') {
            this.categoriaForm = { ...this.categoriaForm, valorDistribuicao: '' };
        }
    }

    get showCategoriaDistribuicao() {
        return this.categoriaForm?.distribuirParaFila === true;
    }

    get showCategoriaCampoValor() {
        return this.showCategoriaDistribuicao && this.categoriaForm?.porCampoCustomizado === true;
    }

    get categoriaFilaRequired() {
        return this.showCategoriaDistribuicao;
    }

    get categoriaCampoValorRequired() {
        return this.showCategoriaCampoValor;
    }

    get categoriaQueueOptions() {
        return (this.categoriaQueueOptionsData || []).map((q) => ({ label: `${q.name} (${q.developerName})`, value: q.developerName }));
    }

    get categoriaCasePicklistFieldOptions() {
        return (this.casePicklistFieldsData || []).map((f) => ({ label: f.label, value: f.apiName }));
    }

    get categoriaCasePicklistValueOptions() {
        const field = (this.casePicklistFieldsData || []).find((f) => f.apiName === this.categoriaForm?.campoDistribuicao);
        return (field?.values || []).map((v) => ({ label: v.label, value: v.value }));
    }

    async handleSaveCategoria() {
        if (!this.permissions.canManageCategories) return;
        this.savingCategoria = true;
        try {
            const distribuirParaFila = this.categoriaForm?.distribuirParaFila === true;
            const porCampoCustomizado = distribuirParaFila && this.categoriaForm?.porCampoCustomizado === true;
            const request = {
                ...this.categoriaForm,
                prioridadeSugerida: this.categoriaForm?.prioridadeSugerida ? this.categoriaForm.prioridadeSugerida : null,
                gestaoSLAId: this.selectedGestaoSLAId,
                distribuirParaFila,
                porCampoCustomizado,
                filaDeveloperName: distribuirParaFila ? this.categoriaForm?.filaDeveloperName : null,
                campoDistribuicao: distribuirParaFila && porCampoCustomizado ? this.categoriaForm?.campoDistribuicao : null,
                valorDistribuicao: distribuirParaFila && porCampoCustomizado ? this.categoriaForm?.valorDistribuicao : null
            };
            if (this.isCategoriaModalCreate) {
                await createCategoria({ request });
                this.showToast(this.labels.commonSuccess, this.labels.toastCategoryCreated, 'success');
            } else {
                await updateCategoria({ request });
                this.showToast(this.labels.commonSuccess, this.labels.toastCategoryUpdated, 'success');
            }
            await this.loadCategorias(this.selectedGestaoSLAId);
            this.closeCategoriaModal();
        } catch (error) {
            this.showToast(this.labels.commonError, this.reduceError(error) || this.labels.errorSaveCategory, 'error');
        } finally {
            this.savingCategoria = false;
        }
    }

    async handleDeactivateCategoria(event) {
        if (!this.permissions.canManageCategories) return;
        const categoriaId = event.currentTarget?.dataset?.id;
        if (!categoriaId) return;
        const confirmed = window.confirm(this.labels.confirmDeactivateCategory);
        if (!confirmed) return;
        try {
            await deactivateCategoria({ categoriaId });
            this.showToast(this.labels.commonSuccess, this.labels.toastCategoryDeactivated, 'success');
            await this.loadCategorias(this.selectedGestaoSLAId);
        } catch (error) {
            this.showToast(this.labels.commonError, this.reduceError(error) || this.labels.errorDeactivateCategory, 'error');
        }
    }

    async handleDeleteCategoria(event) {
        if (!this.permissions.canAdminTechnicalSettings) return;
        const categoriaId = event.currentTarget?.dataset?.id;
        if (!categoriaId) return;
        const confirmed = window.confirm(this.labels.confirmDeleteCategory);
        if (!confirmed) return;
        try {
            await deleteCategoria({ categoriaId });
            this.showToast(this.labels.commonSuccess, this.labels.toastCategoryDeleted, 'success');
            await Promise.all([
                this.loadGestaoDetail(this.selectedGestaoSLAId),
                this.loadCategorias(this.selectedGestaoSLAId),
                this.loadRegrasSLA(this.selectedGestaoSLAId)
            ]);
        } catch (error) {
            this.showToast(this.labels.commonError, this.reduceError(error) || this.labels.errorDeleteCategory, 'error');
        }
    }

    async handleDeleteRegra(event) {
        if (!this.permissions.canAdminTechnicalSettings) return;
        const regraId = event.currentTarget?.dataset?.id;
        if (!regraId) return;
        const confirmed = window.confirm(this.labels.confirmDeleteRule);
        if (!confirmed) return;
        try {
            await deleteRegraSLA({ regraSLAId: regraId });
            this.showToast(this.labels.commonSuccess, this.labels.toastRuleDeleted, 'success');
            await Promise.all([
                this.loadGestaoDetail(this.selectedGestaoSLAId),
                this.loadCategorias(this.selectedGestaoSLAId),
                this.loadRegrasSLA(this.selectedGestaoSLAId)
            ]);
        } catch (error) {
            this.showToast(this.labels.commonError, this.reduceError(error) || this.labels.errorDeleteRule, 'error');
        }
    }

    async handleDeleteGestao() {
        if (!this.permissions.canAdminTechnicalSettings || !this.selectedGestaoSLAId) return;
        const confirmed = window.confirm(this.labels.confirmDeleteGestao);
        if (!confirmed) return;
        try {
            await deleteGestaoSLA({ gestaoSLAId: this.selectedGestaoSLAId });
            this.showToast(this.labels.commonSuccess, this.labels.toastGestaoDeleted, 'success');
            await this.initialize();
        } catch (error) {
            this.showToast(this.labels.commonError, this.reduceError(error) || this.labels.errorDeleteGestao, 'error');
        }
    }

    async handleConfigurarSLAFromCategoria(event) {
        if (!this.permissions.canManageRules) return;
        const categoriaId = event.currentTarget?.dataset?.id;
        const row = (this.categorias || []).find((c) => c.id === categoriaId);
        if (!categoriaId || !row) return;

        this.regrasFiltroCategorizacaoId = categoriaId;
        this.regrasCategorizacaoContextLabel = this.buildCategoriaDisplay(row);
        this.activeTab = TAB_REGRAS;
        await this.loadRegrasSLA(this.selectedGestaoSLAId);
    }

    handleCategoriaAction(event) {
        const action = event.detail.value;
        const id = event.currentTarget?.dataset?.id;
        const syntheticEvent = { currentTarget: { dataset: { id } } };
        if (action === 'edit') {
            this.openEditCategoriaModal(syntheticEvent);
        } else if (action === 'deactivate') {
            this.handleDeactivateCategoria(syntheticEvent);
        } else if (action === 'configure-sla') {
            this.handleConfigurarSLAFromCategoria(syntheticEvent);
        } else if (action === 'delete') {
            this.handleDeleteCategoria(syntheticEvent);
        }
    }

    handleRegraAction(event) {
        const action = event.detail.value;
        const id = event.currentTarget?.dataset?.id;
        const syntheticEvent = { currentTarget: { dataset: { id } } };
        if (action === 'edit') {
            this.openEditRegraModal(syntheticEvent);
        } else if (action === 'deactivate') {
            this.handleDeactivateRegra(syntheticEvent);
        } else if (action === 'activate') {
            this.handleActivateRegra(syntheticEvent);
        } else if (action === 'delete') {
            this.handleDeleteRegra(syntheticEvent);
        }
    }

    async handleActivateRegra(event) {
        if (!this.permissions.canManageRules) return;
        const regraId = event.currentTarget?.dataset?.id;
        if (!regraId) return;
        try {
            await activateRegraSLA({ regraSLAId: regraId });
            this.showToast(this.labels.commonSuccess, this.labels.toastRuleActivated, 'success');
            await Promise.all([
                this.loadGestaoDetail(this.selectedGestaoSLAId),
                this.loadCategorias(this.selectedGestaoSLAId),
                this.loadRegrasSLA(this.selectedGestaoSLAId)
            ]);
        } catch (error) {
            this.showToast(this.labels.commonError, this.reduceError(error) || this.labels.errorDeactivateRule, 'error');
        }
    }

    async openReactivateCategoriaModal() {
        if (!this.permissions.canManageCategories || !this.selectedGestaoSLAId) return;
        this.showReactivateCategoriaModal = true;
        this.loadingInactiveCategorias = true;
        this.selectedInactiveCategoriaId = null;
        try {
            const result = await getInactiveCategorias({ gestaoSLAId: this.selectedGestaoSLAId });
            this.permissions = { ...(result?.permissions || this.permissions) };
            this.inactiveCategorias = (result?.categoriasInativas || []).map((c) => ({
                ...c,
                ...this.withCategoryLabels(c),
                selected: false
            }));
        } catch (error) {
            this.showToast(this.labels.commonError, this.reduceError(error) || this.labels.errorLoadInactiveCategories, 'error');
            this.showReactivateCategoriaModal = false;
        } finally {
            this.loadingInactiveCategorias = false;
        }
    }

    closeReactivateCategoriaModal() {
        this.showReactivateCategoriaModal = false;
        this.loadingInactiveCategorias = false;
        this.reactivatingCategoria = false;
        this.selectedInactiveCategoriaId = null;
        this.inactiveCategorias = [];
    }

    handleSelectInactiveCategoria(event) {
        this.selectedInactiveCategoriaId = event.target?.value || null;
        this.inactiveCategorias = (this.inactiveCategorias || []).map((c) => ({
            ...c,
            selected: c.id === this.selectedInactiveCategoriaId
        }));
    }

    async handleConfirmReactivateCategoria() {
        if (!this.selectedInactiveCategoriaId) {
            this.showToast(this.labels.commonError, this.labels.errorSelectInactiveCategory, 'error');
            return;
        }
        this.reactivatingCategoria = true;
        try {
            await reactivateCategoria({ categoriaId: this.selectedInactiveCategoriaId });
            this.showToast(this.labels.commonSuccess, this.labels.toastCategoryReactivated, 'success');
            await this.loadCategorias(this.selectedGestaoSLAId);
            this.closeReactivateCategoriaModal();
        } catch (error) {
            this.showToast(this.labels.commonError, this.reduceError(error) || this.labels.errorReactivateCategory, 'error');
        } finally {
            this.reactivatingCategoria = false;
        }
    }

    async openReactivateModal() {
        this.showReactivateModal = true;
        this.loadingInactiveGestoes = true;
        this.selectedInactiveGestaoId = null;
        try {
            const result = await getInactiveGestoes();
            this.permissions = { ...(result?.permissions || this.permissions) };
            this.inactiveGestoes = (result?.gestoesInativas || []).map((g) => ({
                ...g,
                selected: false
            }));
        } catch (error) {
            this.showToast(this.labels.commonError, this.reduceError(error) || this.labels.errorLoadInactiveManagements, 'error');
            this.showReactivateModal = false;
        } finally {
            this.loadingInactiveGestoes = false;
        }
    }

    closeReactivateModal() {
        this.showReactivateModal = false;
        this.loadingInactiveGestoes = false;
        this.reactivatingGestao = false;
        this.selectedInactiveGestaoId = null;
        this.inactiveGestoes = [];
    }

    handleSelectInactiveGestao(event) {
        this.selectedInactiveGestaoId = event.target?.value || null;
        this.inactiveGestoes = (this.inactiveGestoes || []).map((g) => ({
            ...g,
            selected: g.id === this.selectedInactiveGestaoId
        }));
    }

    async handleConfirmReactivateGestao() {
        if (!this.selectedInactiveGestaoId) {
            this.showToast(this.labels.commonError, this.labels.errorSelectInactiveManagement, 'error');
            return;
        }
        this.reactivatingGestao = true;
        try {
            const detail = await reactivateGestaoSLA({ gestaoSLAId: this.selectedInactiveGestaoId });
            this.permissions = { ...(detail?.permissions || this.permissions) };
            await this.refreshBootstrapAndSelect(detail?.gestao?.id);
            this.showToast(this.labels.commonSuccess, this.labels.toastManagementReactivated, 'success');
            this.closeReactivateModal();
        } catch (error) {
            this.showToast(this.labels.commonError, this.reduceError(error) || this.labels.errorReactivateManagement, 'error');
        } finally {
            this.reactivatingGestao = false;
        }
    }

    handleCreateInputChange(event) {
        const field = event.target?.name || event.currentTarget?.name || event.currentTarget?.dataset?.field;
        if (!field) return;
        const isUsaToggle = field === 'usaTempoTriagem' || field === 'usaTempoRespostaChat' || field === 'usaTempoFilaEmail';
        let value = isUsaToggle
            ? event.target?.checked ?? event.currentTarget?.checked
            : event.detail?.value ?? event.target?.value ?? event.currentTarget?.value;
        if (field === 'tempoTriagemMinutos' || field === 'tempoRespostaChatMinutos' || field === 'tempoFilaEmailMinutos') {
            value = value === null || value === '' ? null : Number(value);
        }
        this.createForm = { ...this.createForm, [field]: value };
        if (!value && isUsaToggle) {
            const tempoFieldByUsa = { usaTempoTriagem: 'tempoTriagemMinutos', usaTempoRespostaChat: 'tempoRespostaChatMinutos', usaTempoFilaEmail: 'tempoFilaEmailMinutos' };
            this.createForm = { ...this.createForm, [tempoFieldByUsa[field]]: null };
        }
    }

    handleEditInputChange(event) {
        const field = event.target?.name || event.currentTarget?.name || event.currentTarget?.dataset?.field;
        if (!field) return;
        const isUsaToggle = field === 'usaTempoTriagem' || field === 'usaTempoRespostaChat' || field === 'usaTempoFilaEmail';
        let value = isUsaToggle
            ? event.target?.checked ?? event.currentTarget?.checked
            : event.detail?.value ?? event.target?.value ?? event.currentTarget?.value;
        if (field === 'tempoTriagemMinutos' || field === 'tempoRespostaChatMinutos' || field === 'tempoFilaEmailMinutos') {
            value = value === null || value === '' ? null : Number(value);
        } else if (field === 'ativo') {
            value = value === true || value === 'true';
        }
        this.editForm = { ...this.editForm, [field]: value };
        if (!value && isUsaToggle) {
            const tempoFieldByUsa = { usaTempoTriagem: 'tempoTriagemMinutos', usaTempoRespostaChat: 'tempoRespostaChatMinutos', usaTempoFilaEmail: 'tempoFilaEmailMinutos' };
            this.editForm = { ...this.editForm, [tempoFieldByUsa[field]]: null };
        }
    }

    async handleCreateGestao() {
        this.savingGestao = true;
        try {
            const createPayload = this.buildCreatePayloadFromRefs();
            const detail = await createGestaoSLA({
                request: createPayload
            });

            this.permissions = { ...(detail?.permissions || this.permissions) };
            await this.refreshBootstrapAndSelect(detail?.gestao?.id);

            this.showToast(this.labels.commonSuccess, this.labels.toastManagementCreated, 'success');
            this.closeCreateModal();
        } catch (error) {
            this.showToast(this.labels.commonError, this.reduceError(error) || this.labels.errorCreateManagement, 'error');
        } finally {
            this.savingGestao = false;
        }
    }

    async handleUpdateGestao() {
        this.savingEditGestao = true;
        try {
            const updatePayload = { ...this.editForm };
            const detail = await updateGestaoSLA({
                request: updatePayload
            });
            this.permissions = { ...(detail?.permissions || this.permissions) };
            this.gestao = detail?.gestao || this.gestao;
            this.summary = detail?.summary || this.summary;

            if (this.selectedGestaoSLAId) {
                await Promise.all([
                    this.loadCategorias(this.selectedGestaoSLAId),
                    this.loadMarcos(this.selectedGestaoSLAId)
                ]);
            }
            this.showToast(this.labels.commonSuccess, this.labels.toastManagementUpdated, 'success');
            this.closeEditModal();
        } catch (error) {
            this.showToast(this.labels.commonError, this.reduceError(error) || this.labels.errorUpdateManagement, 'error');
        } finally {
            this.savingEditGestao = false;
        }
    }

    applyPagination() {
        const pageSize = Number(this.pageSize);
        const start = (this.currentPage - 1) * pageSize;
        const end = start + pageSize;
        this.pagedCategorias = this.filteredCategorias.slice(start, end);
    }

    handleError(defaultMessage, error) {
        this.hasError = true;
        this.errorMessage = this.reduceError(error) || defaultMessage;
        this.showToast(this.labels.commonError, defaultMessage, 'error');
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    withCurrentComboboxValue(options, currentValue) {
        const normalizedValue = currentValue === null || currentValue === undefined ? '' : String(currentValue);
        const normalizedOptions = [...(options || [])];
        if (normalizedValue && !normalizedOptions.some((option) => option.value === normalizedValue)) {
            normalizedOptions.unshift({ label: normalizedValue, value: normalizedValue });
        }
        return normalizedOptions;
    }

    reduceError(error) {
        if (Array.isArray(error?.body)) {
            return error.body.map((e) => e.message).join(', ');
        }
        return error?.body?.message || error?.message || '';
    }

    getPriorityClass(priority) {
        const normalized = String(priority || '').toLowerCase();
        if (normalized.includes('high') || normalized.includes('alta')) return 'priority-high';
        if (normalized.includes('medium') || normalized.includes('media') || normalized.includes('média')) return 'priority-medium';
        if (normalized.includes('low') || normalized.includes('baixa')) return 'priority-low';
        return 'priority-default';
    }

    buildCreatePayloadFromRefs() {
        const scope = this.template.querySelector('.create-form-scope');
        const valuesByField = {};
        if (scope) {
            const fields = scope.querySelectorAll('lightning-input, lightning-textarea, lightning-combobox');
            fields.forEach((cmp) => {
                const field = cmp?.dataset?.field;
                if (!field) return;
                valuesByField[field] = cmp.type === 'toggle' || cmp.type === 'checkbox' ? cmp.checked : cmp.value;
            });
        }
        const toIntOrNull = (value) => (value === null || value === undefined || value === '' ? null : Number(value));
        const payload = {
            name: valuesByField.name ?? this.createForm.name,
            unidadeNegocio: valuesByField.unidadeNegocio ?? this.createForm.unidadeNegocio,
            entitlementProcessName: valuesByField.entitlementProcessName ?? this.createForm.entitlementProcessName,
            businessHoursName: valuesByField.businessHoursName ?? this.createForm.businessHoursName,
            usaTempoTriagem: valuesByField.usaTempoTriagem ?? this.createForm.usaTempoTriagem,
            tempoTriagemMinutos: toIntOrNull(valuesByField.tempoTriagemMinutos ?? this.createForm.tempoTriagemMinutos),
            usaTempoRespostaChat: valuesByField.usaTempoRespostaChat ?? this.createForm.usaTempoRespostaChat,
            tempoRespostaChatMinutos: toIntOrNull(valuesByField.tempoRespostaChatMinutos ?? this.createForm.tempoRespostaChatMinutos),
            usaTempoFilaEmail: valuesByField.usaTempoFilaEmail ?? this.createForm.usaTempoFilaEmail,
            tempoFilaEmailMinutos: toIntOrNull(valuesByField.tempoFilaEmailMinutos ?? this.createForm.tempoFilaEmailMinutos),
            descricao: valuesByField.descricao ?? this.createForm.descricao,
            staticResourceName: valuesByField.staticResourceName ?? this.createForm.staticResourceName,
            ativo: true
        };
        this.createForm = { ...payload };
        return payload;
    }

    resolveSelectedGestaoId() {
        if (this.selectedGestaoSLAId && this.gestoes.some((g) => g.id === this.selectedGestaoSLAId)) {
            return this.selectedGestaoSLAId;
        }
        const pinnedId = this.getPinnedGestaoId();
        if (pinnedId && this.gestoes.some((g) => g.id === pinnedId)) {
            return pinnedId;
        }
        return this.gestoes[0]?.id || null;
    }

    async loadSelectedGestaoData(gestaoId, resetPagination) {
        if (!gestaoId) {
            this.gestao = null;
            this.summary = null;
            this.categorias = [];
            this.filteredCategorias = [];
            this.pagedCategorias = [];
            this.marcos = [];
            this.regrasSLA = [];
            return;
        }
        await Promise.all([
            this.loadGestaoDetail(gestaoId),
            this.loadCategorias(gestaoId),
            this.loadMarcos(gestaoId),
            this.loadRegrasSLA(gestaoId)
        ]);
        if (resetPagination) {
            this.currentPage = 1;
            this.applyPagination();
        }
    }

    async refreshBootstrapAndSelect(preferredGestaoId) {
        const bootstrap = await getBootstrap();
        this.permissions = { ...(bootstrap?.permissions || this.permissions) };
        this.gestoes = bootstrap?.gestoes || [];
        this.noGestao = this.gestoes.length === 0;

        if (this.noGestao) {
            this.selectedGestaoSLAId = null;
            this.gestao = null;
            this.summary = null;
            this.categorias = [];
            this.filteredCategorias = [];
            this.pagedCategorias = [];
            this.marcos = [];
            this.regrasSLA = [];
            return;
        }

        if (preferredGestaoId && this.gestoes.some((g) => g.id === preferredGestaoId)) {
            this.selectedGestaoSLAId = preferredGestaoId;
        } else {
            this.selectedGestaoSLAId = this.resolveSelectedGestaoId();
        }

        await this.loadSelectedGestaoData(this.selectedGestaoSLAId, true);
    }

    formatMinutes(value) {
        return value === null || value === undefined || value === '' ? '-' : `${value} min`;
    }

    buildCategoriaDisplay(categoria) {
        if (!categoria) {
            return '';
        }
        return [categoria.categoria, categoria.assunto, categoria.subassunto].filter((part) => !!part).join(' / ') || categoria.name;
    }

    buildRegraPayload() {
        return {
            id: this.regraForm.id || null,
            gestaoSLAId: this.selectedGestaoSLAId,
            categorizacaoId: this.regraForm.categorizacaoId || null,
            marcoSLAId: this.regraForm.marcoSLAId || null,
            escopoRegra: this.regraForm.escopoRegra,
            areaAtendimento: this.regraForm.areaAtendimento || null,
            tempoBaixa: this.regraForm.tempoBaixa === null || this.regraForm.tempoBaixa === '' ? null : Number(this.regraForm.tempoBaixa),
            tempoMedia: this.regraForm.tempoMedia === null || this.regraForm.tempoMedia === '' ? null : Number(this.regraForm.tempoMedia),
            tempoAlta: this.regraForm.tempoAlta === null || this.regraForm.tempoAlta === '' ? null : Number(this.regraForm.tempoAlta),
            ativo: this.isRegraModalCreate ? true : null
        };
    }

    validateRegraForm() {
        const request = this.buildRegraPayload();
        if (!request.escopoRegra) {
            this.showToast(this.labels.commonError, this.labels.errorRuleScopeRequired, 'error');
            return false;
        }
        if (!request.categorizacaoId) {
            this.showToast(this.labels.commonError, this.labels.errorRuleCategoryRequired, 'error');
            return false;
        }
        if (request.escopoRegra === RULE_SCOPE_ATENDIMENTO && !request.marcoSLAId) {
            this.showToast(this.labels.commonError, this.labels.errorRuleMilestoneRequired, 'error');
            return false;
        }
        if (request.escopoRegra === RULE_SCOPE_AREA_INTERNA && !request.areaAtendimento) {
            this.showToast(this.labels.commonError, this.labels.errorRuleInternalAreaRequired, 'error');
            return false;
        }
        const times = [request.tempoBaixa, request.tempoMedia, request.tempoAlta].filter((value) => value !== null && value !== undefined);
        if (times.length === 0 || !times.some((value) => Number(value) > 0)) {
            this.showToast(this.labels.commonError, this.labels.errorRuleAtLeastOneTime, 'error');
            return false;
        }
        if (times.some((value) => Number(value) <= 0)) {
            this.showToast(this.labels.commonError, this.labels.errorRuleTimesMustBePositive, 'error');
            return false;
        }
        return true;
    }

    resetRegrasFilters() {
        this.regrasFiltroCategorizacaoId = 'Todos';
        this.regrasFiltroMarcoSLAId = 'Todos';
        this.regrasFiltroEscopo = 'Todos';
        this.regrasFiltroAreaAtendimento = 'Todos';
        this.regrasFiltroAtivo = 'Todos';
        this.regrasCategorizacaoContextLabel = '';
    }

}