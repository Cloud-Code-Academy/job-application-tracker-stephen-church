public with sharing class SObjectSalaryConversionClassSelector {

    public static List<SObject_Salary_Conversion_Class__mdt> getActiveSalaryConversions() {

        List<SObject_Salary_Conversion_Class__mdt> activeSalaryConversions = [
            SELECT Id, DeveloperName, isActive__c
            FROM SObject_Salary_Conversion_Class__mdt
            WHERE isActive__c = TRUE
        ];
        return activeSalaryConversions;
    }
}