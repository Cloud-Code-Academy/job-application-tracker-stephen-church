@isTest
public with sharing class SObjectSalaryConversionClassSelectorTest {

    @isTest
    static void getActiveSalaryConversions() {

        Test.startTest();
        List<SObject_Salary_Conversion_Class__mdt> salaryConversions = 
        SObjectSalaryConversionClassSelector.getActiveSalaryConversions();
        Test.stopTest();

        for (SObject_Salary_Conversion_Class__mdt conversion : salaryConversions) {
            Assert.isTrue(conversion.isActive__c, 'The query should have only got active conversions');
        }
    } 
}