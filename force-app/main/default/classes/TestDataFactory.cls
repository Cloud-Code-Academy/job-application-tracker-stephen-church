@isTest
public with sharing class TestDataFactory {

    public static final String JOOBLE_CALLOUT_JOB_FORMAT = '{"title":"Test Job ***","location":"Test Remote ***","snippet":"Test Snippet ***","salary":"***","source":"Test Source ***","type":"Test Type ***","link":"www.test***.com","company":"Test Company ***","updated":"2024-01-01T00:00:00.0000000","id":"***"},';
    public static final String JOOBLE_CALLOUT_TOTAL_JOBS_KEY_START = '{"totalCount":"';
    public static final String JOOBLE_CALLOUT_JOB_KEY_START = '","jobs":[';
    public static final String JOOBLE_CALLOUT_END_OF_RESPONSE = ']}';
    
    public static Map<String, Account> generateAccountsByName (Boolean doInsert, Integer countToGenerate) {

        Map<String, Account> accountsByName = new Map<String, Account>();
        for(Integer i = 0; i < countToGenerate; i++) {
            Account testAccount = new Account();
            testAccount.Name = 'Test Account ' + i;
            accountsByName.put(testAccount.Name, testAccount);
        }
        if (doInsert) {
            insert accountsByName.values();
        }
        return accountsByName;
    }

    public static Map<Id, Account> generateAccountsById (Integer countToGenerate) {

        // Generate the specified amount of Accounts
        List<Account> newAccounts = new List<Account>();
        for(Integer i = 0; i < countToGenerate; i++) {
            Account testAccount = new Account();
            testAccount.Name = 'Test Account ' + i;
            newAccounts.add(testAccount);
        }
        insert newAccounts;

        // Build a Map of Accounts by Id
        Map<Id, Account> accountsById = new Map<Id, Account>();
        for (Account newAcc : newAccounts) {
            accountsById.put(newAcc.Id, newAcc);
        }
        return accountsById;
    }

    public static List<Contact> generateContactsOnAccounts (Boolean doInsert, List<Account> accountsToCreateContactsOn) {

        List<Contact> newContacts = new List<Contact>();
        for (Account acc : accountsToCreateContactsOn) {
            Contact newContact = new Contact();
            newContact.AccountId = acc.Id;
            newContact.LastName = 'Test ' + acc.Id;
            newContacts.add(newContact);
        }
        if (doInsert) {
            insert newContacts;
        }
        return newContacts;
    }

    public static List<Job_Application__c> generateJobAppsOnAccount (Boolean doInsert, List<Account> accountsToCreateJobAppsOn) {

        List<Job_Application__c> newJobApps = new List<Job_Application__c>();
        for (Account acc : accountsToCreateJobAppsOn) {
            Job_Application__c jobApp = new Job_Application__c();
            jobApp.Company__c = acc.Id;
            jobApp.Job_Title__c = 'Test Title';
            newJobApps.add(jobApp);
        }
        if (doInsert) {
            insert newJobApps;
        }
        return newJobApps;
    }

    public static List<Job_Application_Contact__c> generateJobAppContacts (Map<Id, Id> jobAppIdByContactId, String roleToSet, Boolean doInsert) {

        Set<Id> contactIdKeys = jobAppIdByContactId.keySet();
        List<Job_Application_Contact__c> newJobAppContacts = new List<Job_Application_Contact__c>();
        for (Id contactId : contactIdKeys) {
            Job_Application_Contact__c jobAppContact = new Job_Application_Contact__c();
            jobAppContact.Contact__c = contactId;
            jobAppContact.Job_Application__c = jobAppIdByContactId.get(contactId);
            jobAppContact.Role__c = roleToSet;
            newJobAppContacts.add(jobAppContact);
        }
        if (doInsert) {
            insert newJobAppContacts;
        }
        return newJobAppContacts;
    }

    public static Map<Id, Id> getJobAppIdByContactIdMapForJobAppContacts (List<Job_Application__c> jobApps, List<Contact> contacts) {
        
        Map<Id, Id> jobAppIdByContactId = new Map<Id, Id>();
        Map<Id, Id> jobAppIdByAccountId = new Map<Id, Id>();
        Map<Id, Id> contactIdByAccountId = new Map<Id, Id>();
        for (Job_Application__c jobApp : jobApps) {
            jobAppIdByAccountId.put(jobApp.Company__c, jobApp.Id);
        }
        for (Contact con : contacts) {
            contactIdByAccountId.put(con.AccountId, con.Id);
        }
        Set<Id> accountIds = new Set<Id>();
        accountIds.addAll(jobAppIdByAccountId.keySet());
        accountIds.addAll(contactIdByAccountId.keySet());
        for (Id accId : accountIds) {
            Id jobAppId = jobAppIdByAccountId.get(accId);
            Id conId = contactIdByAccountId.get(accId);
            jobAppIdByContactId.put(conId, jobAppId);
        }
        return jobAppIdByContactId;
    }

    public static List<Job_Application_Contact__c> generateJobAppContactsWithRoleFromAccounts (List<Account> testAccounts, String role, Boolean doJobAppContactInsert) {

        List<Contact> testContacts = generateContactsOnAccounts(true, testAccounts);
        List<Job_Application__c> testJobApps = generateJobAppsOnAccount(true, testAccounts);
        Map<Id, Id> jobAppIdByConIdForJobAppContacts = getJobAppIdByContactIdMapForJobAppContacts(testJobApps, testContacts);
        List<Job_Application_Contact__c>  testJobAppContacts = generateJobAppContacts(jobAppIdByConIdForJobAppContacts, role, doJobAppContactInsert);
        return testJobAppContacts;
    }

    public static List<Job_Application_Contact__c> cloneJobAppContactsAndSetToNewContacts (List<Job_Application_Contact__c> jobAppConsToClone, List<Contact> contactsToSet, Boolean doInsert) {
        List<Job_Application_Contact__c> clonedJobAppContacts = jobAppConsToClone.deepClone();
        Integer i = 0;
        for (Job_Application_Contact__c clonedJobAppCon : clonedJobAppContacts) {
            clonedJobAppCon.Contact__c = contactsToSet.get(i).Id;
            i++;
        }
        if (doInsert) {
            insert clonedJobAppContacts;
        }
        return clonedJobAppContacts;
    }

    public static List<Job_Application_Contact__c> generateMultipleJobAppContactsWithOnePrimaryPerJobApp(Integer countAccountsAndJobApps, Integer jobAppContactsPerApp) {

        // Generate Accounts and Job Apps
        Map<Id, Account> accountsById = generateAccountsById(countAccountsAndJobApps);
        List<Job_Application__c> testJobApps = generateJobAppsOnAccount(true, accountsById.values());
        Map<Id, Job_Application__c> jobAppIdByAccountId = new Map<Id, Job_Application__c>();
        for (Job_Application__c jobApp : testJobApps) {
            jobAppIdByAccountId.put(jobApp.Company__c, jobApp);
        }

        // Generate 3 Contacts per Account and build a Map of Account Id by Contact List
        Set<Id> accountIds = jobAppIdByAccountId.keySet();
        List<Contact> contactsOnAccount = new List<Contact>();
        for (Id accId : accountIds) {
            for (Integer i = 0; i < jobAppContactsPerApp; i++) {
                Contact newContact = new Contact();
                newContact.AccountId = accId;
                newContact.LastName = accId + ' - ' + i;
                contactsOnAccount.add(newContact);
            }
        }
        insert contactsOnAccount;
        Map<Id, List<Contact>> contactsByAccountId = new Map<Id, List<Contact>>();
        for (Contact con : contactsOnAccount) {
            if (contactsByAccountId.containsKey(con.AccountId)) {
                List<Contact> existingContactList = contactsByAccountId.get(con.AccountId);
                existingContactList.add(con);
                contactsByAccountId.put(con.AccountId, existingContactList);
            } else {
                List<Contact> newContactList = new List<Contact>();
                newContactList.add(con);
                contactsByAccountId.put(con.AccountId, newContactList);
            }
        }

        // Loop the Accounts, extract the Contacts and Job Apps and create multiple Job App Contacts on the Job App, setting one as Primary
        Boolean primaryContactSet = false;
        List<Job_Application_Contact__c> jobAppContacts = new List<Job_Application_Contact__c>();
        Set<Id> contactIds = new Set<Id>();
        Set<Id> jobAppIds = new Set<Id>();
        for (Id accId : accountIds) {
            Job_Application__c jobApp = jobAppIdByAccountId.get(accId);
            jobAppIds.add(jobApp.Id);
            List<Contact> childContacts = contactsByAccountId.get(accId);
            for (Contact con : childContacts) {
                contactIds.add(con.Id);
                Job_Application_Contact__c jac = new Job_Application_Contact__c();
                jac.Job_Application__c = jobApp.Id;
                jac.Contact__c = con.Id;
                jac.Role__c = 'Existing Contact';
                if (!primaryContactSet) {
                    jac.Primary_Contact__c = true;
                    primaryContactSet = true;
                } else {
                    jac.Primary_Contact__c = false;
                }
                jobAppContacts.add(jac);
            }
            primaryContactSet = false;
        }
        return jobAppContacts;
    }

    public static List<Job_Application_Contact__c> insertJobAppContactsReturnNonPrimariesSetAsPrimary(Integer countAccountsAndJobApps, Integer jobAppContactsPerApp) {

        List<Job_Application_Contact__c> jobAppContacts = generateMultipleJobAppContactsWithOnePrimaryPerJobApp(countAccountsAndJobApps, jobAppContactsPerApp);
        insert jobAppContacts;
        Set<Id> contactIds = new Set<Id>();
        Set<Id> jobAppIds = new Set<Id>();
        for (Job_Application_Contact__c jac : jobAppContacts) {
            contactIds.add(jac.Contact__c);
            jobAppIds.add(jac.Job_Application__c);
        }

        // Get the non Primary Contacts and update them all to Primary
        List<Job_Application_Contact__c> nonPrimaryJobAppContacts = [
            SELECT Id, Primary_Contact__c
            FROM Job_Application_Contact__c
            WHERE Contact__c IN :contactIds
            AND Job_Application__c IN :jobAppIds
            AND Primary_Contact__c = FALSE
        ];
        Set<Id> nonPrimaryIds = new Set<Id>();
        for (Job_Application_Contact__c nonPrimary : nonPrimaryJobAppContacts) {
            nonPrimary.Primary_Contact__c = true;
            nonPrimaryIds.add(nonPrimary.Id);
        }
        return nonPrimaryJobAppContacts;
    }

    public static User createUserWithTaxStatus(String taxStatus) {

        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        User testUser = new User(
            Alias = 'testuser',
            Email = 'testuser@testuser.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = standardProfile.Id,
            TimeZoneSidKey = 'America/Chicago',
            UserName = 'testuser@testuser13215654.com',
            Federal_Tax_Status__c = taxStatus
        );

        insert testUser;
        return testUser;
    }

    public static Status_Task_Manager__mdt getStatusTaskManagerForTest(String process, String status) {

        Status_Task_Manager__mdt stm = [
            SELECT Id, Default_Task_Status__c, Default_Days_For_Task_Due_Date__c, Default_Task_Priority__c
            FROM Status_Task_Manager__mdt
            WHERE Process__c = :process
            AND Status__c = :status
            LIMIT 1
        ];
        return stm;
    }

    public static Map<Id, List<Task>> organizeTaskListByJobAppId (List<Job_Application__c> jobApps, List<Task> tasks) {

        Map<Id, List<Task>> tasksByJobAppId = new Map<Id, List<Task>>();
        for (Job_Application__c job : jobApps) {
            List<Task> emptyTaskList = new List<Task>();
            tasksByJobAppId.put(job.Id, emptyTaskList);
        }
        for (Task task : tasks) {
            List<Task> taskListForJobApp = tasksByJobAppId.get(task.WhatId);
            taskListForJobApp.add(task);
            tasksByJobAppId.put(task.WhatId, taskListForJobApp);
        }
        return tasksByJobAppId;
    }
    
    public static List<Map<String, Object>> generateListOfMapsForUtilityTests(String targetKeyName, String otherKeyName) {

        List<Map<String, Object>> listOfMaps = new List<Map<String, Object>>();
        Map<String, Object> firstMap = new Map<String, Object>();
        firstMap.put(targetKeyName, 'Target Value 1');
        firstMap.put(otherKeyName, 'Not Target Value 1');
        Map<String, Object> secondMap = new Map<String, Object>();
        secondMap.put(targetKeyName, 'Target Value 2');
        secondMap.put(otherKeyName, 'Not Target Value 2');
        listOfMaps.add(firstMap);
        listOfMaps.add(secondMap);
        return listOfMaps;
    }

    public static String generateTestJoobleCalloutString(Integer countOfJobsToGenerate) {

        String joobleCalloutString = 
            JOOBLE_CALLOUT_TOTAL_JOBS_KEY_START + String.valueOf(countOfJobsToGenerate) + JOOBLE_CALLOUT_JOB_KEY_START;
        String jobFormat = JOOBLE_CALLOUT_JOB_FORMAT;
        String endOfString = JOOBLE_CALLOUT_END_OF_RESPONSE;

        Integer jobsGenerated = 0;
        do {
            joobleCalloutString += jobFormat.replace('***', String.valueOf(jobsGenerated));
            jobsGenerated++;
        } while (jobsGenerated < countOfJobsToGenerate);

        joobleCalloutString = joobleCalloutString.removeEnd(',');
        joobleCalloutString += endOfString;

        return joobleCalloutString;
    }

    public static List<Map<String, Object>> generateLwcJobSelectionResponse(Integer countOfJobsToGenerate) {

        List<Map<String, Object>> selectedJobs = new List<Map<String, Object>>();
        Integer jobsGenerated = 0;
        do {
            Map<String, Object> job = new Map<String, Object>();
            job.put('company', 'Test Company ' + String.valueOf(jobsGenerated));
            job.put('id', String.valueOf(jobsGenerated));
            job.put('link', String.valueOf('www.test' + String.valueOf(jobsGenerated) + '.com'));
            job.put('location', 'Test Remote ' + String.valueOf(jobsGenerated));
            job.put('salary', String.valueOf(jobsGenerated));
            job.put('title', 'Test Title ' + String.valueOf(jobsGenerated));
            job.put('type', 'Test Type ' + String.valueOf(jobsGenerated));
            job.put('updated', '2024-01-01T00:00:00.0000000');
            selectedJobs.add(job);
            jobsGenerated++;
        } while (jobsGenerated < countOfJobsToGenerate);

        return selectedJobs;
    }
}
