@isTest
public with sharing class UserSelectorTest {

    @isTest
    static void getFederalTaxStatusOfUser() {
    
        User testUser = TestDataFactory.createUserWithTaxStatus('Married_Filing_Jointly');

        Test.startTest();
        String returnedTaxStatus = UserSelector.getFederalTaxStatusOfUser(testUser.Id);
        Test.stopTest();

        Assert.areEqual(testUser.Federal_Tax_Status__c, returnedTaxStatus, 'The expected Federal Tax Status was not returned');
    }

    @isTest
    static void getFederalTaxStatusOfUser_nullValue() {

        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            String returnedTaxStatus = UserSelector.getFederalTaxStatusOfUser(null);
        } catch (IllegalArgumentException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'An Illegal Argument Exception should have been thrown');
    }
}