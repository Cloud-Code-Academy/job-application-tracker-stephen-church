@isTest
public with sharing class AccountSelectorTest {

    @isTest
    static void getAccountsAndOldestContact() {

        // Insert Accounts and extract their names into a Set that can be passed to the method
        Map<Id, Account> accountsById = TestDataFactory.generateAccountsById(200);
        Set<String> accountNames = new Set<String>();
        for(Account acc : accountsById.values()) {
            accountNames.add(acc.Name);
        }

        // Insert the first Contact on each Account and build a Map of the oldest Contact Id by Account Id
        List<Contact> contactsOnAccount = TestDataFactory.generateContactsOnAccounts(true, accountsById.values());
        Map<Id, Id> contactIdByAccountId = new Map<Id, Id>();
        for (Contact con : contactsOnAccount) {
            contactIdByAccountId.put(accountsById.get(con.AccountId).Id, con.Id);
        }

        // Insert another Contact on each Account, which we shouldn't expect in the query results since it isn't the oldest
        List<Contact> secondContactOnAccount = TestDataFactory.generateContactsOnAccounts(true, accountsById.values());

        Test.startTest();
        List<Account> accountsFromQuery = AccountSelector.getAccountsAndOldestContact(accountNames);
        Test.stopTest();

        // Loop the Accounts returned from the query and perform assertions
        for (Account accFromQuery : accountsFromQuery) {
            Assert.isTrue(accFromQuery.Contacts.size() == 1, 'Only 1 Contact should be returned for each Account. ' + accFromQuery.Contacts.size() + ' were returned.');
            Id expectedContactId = contactIdByAccountId.get(accFromQuery.Id);
            Assert.isTrue(accFromQuery.Contacts.get(0).Id == expectedContactId, 'The oldest Contact Id (' + expectedContactId + ') was not returned as expected.');
            Assert.isTrue(accountNames.contains(accFromQuery.Name), 'The Account Name ' + accFromQuery.Name + ' is not one that was passed to the method');
        }
    }

    @isTest
    static void getAccountsAndOldestContact_missingArgument(){

        // Create an empty Set, call the method and validate an exception is thrown
        Set<String> accountNames = new Set<String>();
        Boolean exceptionThrown = false;

        // Call the method and try to catch the expected exception
        Test.startTest();
        try{
            List<Account> accountsFromQuery = AccountSelector.getAccountsAndOldestContact(accountNames);
        } catch (IllegalArgumentException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        // Assert the exception was thrown
        Assert.isTrue(exceptionThrown, 'An Illegal Argument Exception should have been thrown');
    }
}