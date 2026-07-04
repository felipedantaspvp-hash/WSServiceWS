/**
 * @description       : Classe do modulo Email-to-Case no padrao Triscal.
 * @author            : Triscal Salesforce Team
 * @group             :
 * @last modified on  : 05-19-2026
 * @last modified by  : jduarte@wilsonsons.com.br.service
**/
public inherited sharing class WS_EmailToCaseConstants {
    public static final String ACTION_NEW_CASE = 'NEW_CASE';
    public static final String ACTION_APPEND_OPEN_CASE = 'APPEND_OPEN_CASE';
    public static final String ACTION_REOPEN_CLOSED_CASE = 'REOPEN_CLOSED_CASE';
    public static final String ACTION_NEW_AFTER_REOPEN_WINDOW = 'NEW_AFTER_REOPEN_WINDOW';
    public static final String ACTION_DUPLICATE_IGNORED = 'DUPLICATE_IGNORED';
    public static final String ACTION_ERROR = 'ERROR';

    public static final String OWNER_TYPE_QUEUE = 'QUEUE';
    public static final String OWNER_TYPE_USER = 'USER';

    public static final String BEHAVIOR_REOPEN = 'REOPEN';
    public static final String BEHAVIOR_CREATE_NEW = 'CREATE_NEW';

    public static final String MATCH_ENVELOPE_TO = 'ENVELOPE_TO';
    public static final String MATCH_TO_ADDRESSES = 'TO_ADDRESSES';
    public static final String MATCH_CC_ADDRESSES = 'CC_ADDRESSES';
    public static final String MATCH_ANY_RECIPIENT = 'ANY_RECIPIENT';

    public static final String NO_ROUTE_KEY = '_NO_ROUTE';
    public static final String NO_SUBJECT_FALLBACK = 'Inbound Email - Sem Assunto';
    public static final String NO_BODY_FALLBACK = 'E-mail recebido sem conteúdo no corpo.';

    public static final Integer HASH_BODY_SLICE = 500;
    public static final String EMAIL_MESSAGE_STATUS_INBOUND = '3';
}
