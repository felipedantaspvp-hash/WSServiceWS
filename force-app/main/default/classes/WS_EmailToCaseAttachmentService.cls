/**
 * @description       : Classe do modulo Email-to-Case no padrao Triscal.
 * @author            : Triscal Salesforce Team
 * @group             :
 * @last modified on  : 05-19-2026
 * @last modified by  : jduarte@wilsonsons.com.br.service
**/
public inherited sharing class WS_EmailToCaseAttachmentService {
    public Integer publishAttachmentsToCase(Messaging.InboundEmail email, Id caseId) {
        if (email == null || caseId == null) {
            return 0;
        }
        if (!Schema.sObjectType.ContentVersion.isCreateable()) {
            throw new WS_EmailToCaseConfigException('Sem permissão para criar ContentVersion.');
        }

        List<ContentVersion> versions = new List<ContentVersion>();

        if (email.binaryAttachments != null) {
            for (Messaging.InboundEmail.BinaryAttachment bin : email.binaryAttachments) {
                if (bin == null || bin.body == null) {
                    continue;
                }
                ContentVersion cv = new ContentVersion();
                cv.Title = deriveTitle(bin.fileName, 'email-binary-attachment');
                cv.PathOnClient = derivePath(bin.fileName, 'email-binary-attachment.bin');
                cv.VersionData = bin.body;
                cv.FirstPublishLocationId = caseId;
                versions.add(cv);
            }
        }

        if (email.textAttachments != null) {
            for (Messaging.InboundEmail.TextAttachment txt : email.textAttachments) {
                if (txt == null || txt.body == null) {
                    continue;
                }
                ContentVersion cv = new ContentVersion();
                cv.Title = deriveTitle(txt.fileName, 'email-text-attachment');
                cv.PathOnClient = derivePath(txt.fileName, 'email-text-attachment.txt');
                cv.VersionData = Blob.valueOf(txt.body);
                cv.FirstPublishLocationId = caseId;
                versions.add(cv);
            }
        }

        if (!versions.isEmpty()) {
            insert versions;
        }
        return versions.size();
    }

    private String deriveTitle(String fileName, String fallback) {
        if (String.isBlank(fileName)) {
            return fallback;
        }
        String clean = fileName;
        if (clean.contains('.')) {
            clean = clean.substringBeforeLast('.');
        }
        return String.isBlank(clean) ? fallback : clean;
    }

    private String derivePath(String fileName, String fallback) {
        return String.isBlank(fileName) ? fallback : fileName;
    }
}
