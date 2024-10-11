public with sharing class AccountSelector {

    public static List<Account> getAccountsAndOldestContact (Set<String> accountNames) {

        if (accountNames.isEmpty()) {
            Utility.throwIllegalArgumentException('accountNames argument was null.');
        }

        List<Account> accountsAndContactsFromNames = [
            SELECT Id, Name,
                (SELECT Id, CreatedDate FROM Contacts ORDER BY CreatedDate ASC LIMIT 1)
            FROM Account 
            WHERE Name IN :accountNames
        ];
        return accountsAndContactsFromNames;
    }
}