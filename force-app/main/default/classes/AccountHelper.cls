public with sharing class AccountHelper {

    public static Map<String, Account> generateAccountsForNamesNotInSet (
        Set<String> namesNeedingAnAccount, 
        Map<String, Account> existingAccountsByName) {
        
        if (namesNeedingAnAccount.isEmpty()) {
            Utility.throwIllegalArgumentException('namesNeedingAnAccount argument was null.');
        }

        Map<String, Account> newAccountsByName = new Map<String, Account>();
        for (String name : namesNeedingAnAccount) {
            if (!existingAccountsByName.keySet().contains(name) && !newAccountsByName.keySet().contains(name)) {
                Account newAccountWithName = new Account (Name = name);
                newAccountsByName.put(name, newAccountWithName);
            }
        }
        return newAccountsByName;
    }
}
