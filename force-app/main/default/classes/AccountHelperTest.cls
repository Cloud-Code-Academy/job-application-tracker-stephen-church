@isTest
public with sharing class AccountHelperTest {

    @isTest
    static void generateAccountsForNamesNotInSet(){

        // Setup 100 Account sObjects and 100 Account Names that isn't used on the sObjects
        Set<String> allAccountNames = new Set<String>();
        Set<String> extraAccountNames = new Set<String>();
        Map<String, Account> existingAccounts = TestDataFactory.generateAccountsByName(false, 100);
        allAccountNames.addAll(existingAccounts.keySet());
        for(Integer i = 0; i < 100; i++) {
            String extraAccountName = 'Extra Account Name ' + i;
            allAccountNames.add(extraAccountName);
            extraAccountNames.add(extraAccountName);
        }

        Test.startTest();
        Map<String, Object> accountSObjectsFromExtraNames = 
            AccountHelper.generateAccountsForNamesNotInSet(allAccountNames, existingAccounts);
        Test.stopTest();

        // Validate that the method returned 100 Account sOjects for the names that didn't correspond to an Account sObject
        Set<String> accountNameKeys = accountSObjectsFromExtraNames.keySet();
        Assert.isTrue(accountSObjectsFromExtraNames.size() == 100, '100 sObjects should have been generated. ' + accountSObjectsFromExtraNames.size() + ' were generated.');
        for (String accName : accountNameKeys) {
            Assert.isTrue(extraAccountNames.contains(accName), 'The Account Name ' + accName + ' should be in the extraAccountNames Set');
            Account accountForKey = (Account)accountSObjectsFromExtraNames.get(accName);
            Assert.isTrue(accountForKey.Name == accName, 'The Account sObject name ' + accountForKey.Name + ' should have a key with that name.');
        }
    }

    @isTest
    static void generateAccountsForNamesNotInSet_missingArgument(){

        // Create a Map with Account sObjects and an empty Set
        Map<String, Account> existingAccounts = TestDataFactory.generateAccountsByName(false, 1);
        Set<String> allAccountNames = new Set<String>();
        Boolean exceptionThrown = false;

        // Call the method and try to catch the expected exception
        Test.startTest();
        try{
            Map<String, Object> accountSObjectsFromExtraNames = 
                AccountHelper.generateAccountsForNamesNotInSet(allAccountNames, existingAccounts);
        } catch (IllegalArgumentException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        // Assert the exception was thrown
        Assert.isTrue(exceptionThrown, 'An Illegal Argument Exception should have been thrown.');
    }
}