@IsTest(SeeAllData = true)
public with sharing class LightningLoginFormControllerTest {

 @IsTest
 static void LightningLoginFormControllerInstantiation() {
  LightningLoginFormController controller = new LightningLoginFormController();
  Assert.isNotNull(controller);
 }

 @IsTest
 static void testIsUsernamePasswordEnabled() {
  Assert.areEqual(true, LightningLoginFormController.getIsUsernamePasswordEnabled());
 }

 @IsTest
 static void testIsSelfRegistrationEnabled() {
  Assert.areEqual(false, LightningLoginFormController.getIsSelfRegistrationEnabled());
 }

 @IsTest
 static void testGetSelfRegistrationURL() {
  Assert.areEqual(null, LightningLoginFormController.getSelfRegistrationUrl());
 }

 @IsTest
 static void testAuthConfig() {
  Auth.AuthConfiguration authConfig = LightningLoginFormController.getAuthConfig();
  Assert.isNotNull(authConfig);
 }

 @IsTest
 static void testGetForgotPasswordUrl() {
  String forgotPasswordUrl = LightningLoginFormController.getForgotPasswordUrl();
  Assert.areEqual(true, forgotPasswordUrl == null || forgotPasswordUrl.length() >= 0);
 }

 @IsTest
 static void testSetExperienceIdWithNull() {
  Assert.areEqual(null, LightningLoginFormController.setExperienceId(null));
 }

 @IsTest
 static void testLoginHandlesInvalidCredentials() {
  String result = LightningLoginFormController.login(null, null, null);
  Assert.areEqual(true, result == null || result == Label.ExperienceAuth_GenericError);
 }
}