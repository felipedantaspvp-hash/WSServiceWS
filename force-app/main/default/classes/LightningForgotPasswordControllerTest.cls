@IsTest(SeeAllData = true)
public with sharing class LightningForgotPasswordControllerTest {

 /* Verifies that ForgotPasswordController handles invalid usernames appropriately */
 @IsTest
 static void testLightningForgotPasswordControllerInvalidUserName() {
  Assert.areEqual(Label.Site.invalid_email, LightningForgotPasswordController.forgotPassword('fakeUser', 'http://a.com'));
  Assert.areEqual(Label.Site.invalid_email, LightningForgotPasswordController.forgotPassword(null, 'http://a.com'));
  Assert.areEqual(Label.Site.invalid_email, LightningForgotPasswordController.forgotPassword('a', '/home/home.jsp'));
 }

 /* Verifies that null checkEmailRef url throws proper exception. */
 @IsTest
 static void testLightningForgotPasswordControllerWithNullCheckEmailRef() {
  Assert.areEqual('Argument 1 cannot be null', LightningForgotPasswordController.forgotPassword('a', null));
  Assert.areEqual('Argument 1 cannot be null', LightningForgotPasswordController.forgotPassword('a@salesforce.com', null));
 }

 /* Verifies that LightningForgotPasswordController object is instantiated correctly. */
 @IsTest
 static void LightningForgotPasswordControllerInstantiation() {
  LightningForgotPasswordController controller = new LightningForgotPasswordController();
  Assert.isNotNull(controller);
 }

 @IsTest
 static void testSetExperienceIdWithNull() {
  Assert.areEqual(null, LightningForgotPasswordController.setExperienceId(null));
 }

 @IsTest
 static void testSetExperienceIdWithValue() {
  String result = LightningForgotPasswordController.setExperienceId('exp-id-test');
  Assert.areEqual(true, result == null || result.contains('community'));
 }

 @IsTest
 static void testForgotPasswordHandlesBlankUsernameWithValidRedirect() {
  Assert.areEqual(Label.Site.invalid_email, LightningForgotPasswordController.forgotPassword('', 'http://a.com'));
 }
}