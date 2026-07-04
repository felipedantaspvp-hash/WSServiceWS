global class LightningForgotPasswordController {
    private static final String GENERIC_PUBLIC_ERROR = Label.ExperienceAuth_GenericError;

    public LightningForgotPasswordController() {

    }

    @AuraEnabled
    public static String forgotPassword(String username, String checkEmailUrl) {
        try {
            Site.forgotPassword(username);
            ApexPages.PageReference checkEmailRef = new PageReference(checkEmailUrl);
            if(!Site.isValidUsername(username)) {
                return Label.Site.invalid_email;
            }
            aura.redirect(checkEmailRef);
            return null;
        }
        catch (Exception ex) {
            return logAndReturnFriendlyError('LightningForgotPasswordController.forgotPassword', ex);
        }
    }

    @AuraEnabled
    global static String setExperienceId(String expId) {    
        // Return null if there is no error, else it will return the error message 
        try {
            if (expId != null) {
                Site.setExperienceId(expId);               
            }
            return null; 
        } catch (Exception ex) {
            return logAndReturnFriendlyError('LightningForgotPasswordController.setExperienceId', ex);
        }        
    }

    private static String logAndReturnFriendlyError(String context, Exception ex) {
        System.debug(LoggingLevel.ERROR, context + ': ' + ex.getTypeName() + ' - ' + ex.getMessage() + '\n' + ex.getStackTraceString());
        return GENERIC_PUBLIC_ERROR;
    }
}