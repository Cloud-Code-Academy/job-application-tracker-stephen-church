public with sharing class UserSelector {

    public static String getFederalTaxStatusOfUser(Id userId) {
        
        if (userId == null) {
            Utility.throwIllegalArgumentException('The userId argument passed to the method was null');
        }

        String federalTaxStatus = null;
        User u = [SELECT Id, Federal_Tax_Status__c FROM User WHERE Id = :userId];
        if (u.Federal_Tax_Status__c != null) {
            federalTaxStatus = u.Federal_Tax_Status__c;
        }
        return federalTaxStatus;
    }
}