@isTest
public with sharing class JobApplicationContactHelperTest {

    @TestSetup
    static void setupTestData(){
        Map<Id, Account> testAccountsById = TestDataFactory.generateAccountsById(200);
        TestDataFactory.generateJobAppsOnAccount(true, testAccountsById.values());
    }

    @isTest
    static void generateContactsForNewJobApplications_oneContact() {

        // Retrieve and create extra test data
        List<Account> testAccounts = [SELECT Id, Name FROM Account];
        List<Job_Application__c> testJobApps = [SELECT Id, Company__c FROM Job_Application__c];
        List<Contact> testContactsOnAccount = TestDataFactory.generateContactsOnAccounts(true, testAccounts);

        // Setup variables to pass to the method
        List<Account> testAccountsWithContacts = [
            SELECT Id, Name,
                (SELECT Id, AccountId, CreatedDate FROM Contacts ORDER BY CreatedDate ASC LIMIT 1)
            FROM Account
        ];
        Map<Id, String> accountNameById = new Map<Id, String>();
        Map<String, Account> accountsByCompanyName = new Map<String, Account>();
        for (Account acc : testAccountsWithContacts) {
            accountNameById.put(acc.Id, acc.Name);
            accountsByCompanyName.put(acc.Name, acc);
        }

        Test.startTest();
        List<Job_Application_Contact__c> returnedJobAppContacts = 
            JobApplicationContactHelper.generateContactsForNewJobApplications(
                testJobApps, accountNameById, accountsByCompanyName, 'Existing Contact');
        Test.stopTest();

        // Setup variables so we know which pair of Contacts and Job Applications should be the parent of each Job App Contact
        Map<Id, Id> jobAppIdByAccountId = new Map<Id, Id>();
        for (Job_Application__c jobApp : testJobApps) {
            jobAppIdByAccountId.put(jobApp.Company__c, jobApp.Id);
        }
        Map<Id, Id> expectedJobAppIdByContactId = new Map<Id, Id>();
        for (Account acc : testAccountsWithContacts) {
            Contact con = acc.Contacts.get(0);
            expectedJobAppIdByContactId.put(con.Id, jobAppIdByAccountId.get(con.AccountId));
        }

        // Assert that we have 200 Job App Contacts, they are associated with the correct Job App / Contact pair and have the correct role
        Assert.isTrue(returnedJobAppContacts.size() == 200, 'There should be 200 Job App Contacts. There are ' + returnedJobAppContacts.size());
        for (Job_Application_Contact__c jobAppContact : returnedJobAppContacts) {
            Id jobAppContactContact = jobAppContact.Contact__c;
            Id expectedJobApp = expectedJobAppIdByContactId.get(jobAppContactContact);
            Assert.areEqual(expectedJobApp, jobAppContact.Job_Application__c, 'The associated Contact and Job Application are not as expected');
            Assert.isTrue(jobAppContact.Role__c == 'Existing Contact', 'The Job App Contact Role should be Existing Contact. It is: ' + jobAppContact.Role__c);
        }
    }

    @isTest
    static void generateContactsForNewJobApplications_twoContacts() {

        // Retrieve and create extra test data
        List<Account> testAccounts = [SELECT Id, Name FROM Account];
        List<Job_Application__c> testJobApps = [SELECT Id, Company__c FROM Job_Application__c];
        List<Contact> testContactsOnAccount = TestDataFactory.generateContactsOnAccounts(true, testAccounts);
        List<Contact> newerContactsOnAccount = TestDataFactory.generateContactsOnAccounts(true, testAccounts);

        // Setup variables to pass to the method
        List<Account> testAccountsWithContacts = [
            SELECT Id, Name,
                (SELECT Id, AccountId, CreatedDate FROM Contacts ORDER BY CreatedDate ASC LIMIT 1)
            FROM Account
        ];
        Map<Id, String> accountNameById = new Map<Id, String>();
        Map<String, Account> accountsByCompanyName = new Map<String, Account>();
        for (Account acc : testAccountsWithContacts) {
            accountNameById.put(acc.Id, acc.Name);
            accountsByCompanyName.put(acc.Name, acc);
        }

        Test.startTest();
        List<Job_Application_Contact__c> returnedJobAppContacts = 
            JobApplicationContactHelper.generateContactsForNewJobApplications(
                testJobApps, accountNameById, accountsByCompanyName, 'Existing Contact');
        Test.stopTest();

        // Setup variables so we know which pair of Contacts and Job Applications should be the parent of each Job App Contact
        Map<Id, Id> jobAppIdByAccountId = new Map<Id, Id>();
        for (Job_Application__c jobApp : testJobApps) {
            jobAppIdByAccountId.put(jobApp.Company__c, jobApp.Id);
        }
        Map<Id, Id> olderContactIdByAccountId = new Map<Id, Id>();
        for (Contact con : testContactsOnAccount) {
            olderContactIdByAccountId.put(con.AccountId, con.Id);
        }
        Map<Id, Id> expectedJobAppIdByContactId = new Map<Id, Id>();
        for (Account acc : testAccountsWithContacts) {
            Id olderContactId = olderContactIdByAccountId.get(acc.Id);
            expectedJobAppIdByContactId.put(olderContactId, jobAppIdByAccountId.get(acc.Id));
        }

        // Assert that we have 200 Job App Contacts, they are associated with the correct Job App / Contact pair and have the correct role
        Assert.isTrue(returnedJobAppContacts.size() == 200, 'There should be 200 Job App Contacts. There are ' + returnedJobAppContacts.size());
        for (Job_Application_Contact__c jobAppContact : returnedJobAppContacts) {
            Id jobAppContactContact = jobAppContact.Contact__c;
            Id expectedJobApp = expectedJobAppIdByContactId.get(jobAppContactContact);
            Assert.areEqual(expectedJobApp, jobAppContact.Job_Application__c, 'The associated Contact and Job Application are not as expected');
            Assert.isTrue(jobAppContact.Role__c == 'Existing Contact', 'The Job App Contact Role should be Existing Contact. It is: ' + jobAppContact.Role__c);
        }
    }

    @isTest
    static void generateContactsForNewJobApplications_noContacts() {

        // Retrieve and create extra test data
        List<Account> testAccounts = [SELECT Id, Name FROM Account];
        List<Job_Application__c> testJobApps = [SELECT Id, Company__c FROM Job_Application__c];

        // Setup variables to pass to the method
        List<Account> testAccountsWithContacts = [
            SELECT Id, Name,
                (SELECT Id, AccountId, CreatedDate FROM Contacts ORDER BY CreatedDate ASC LIMIT 1)
            FROM Account
        ];
        Map<Id, String> accountNameById = new Map<Id, String>();
        Map<String, Account> accountsByCompanyName = new Map<String, Account>();
        for (Account acc : testAccountsWithContacts) {
            accountNameById.put(acc.Id, acc.Name);
            accountsByCompanyName.put(acc.Name, acc);
        }

        Test.startTest();
        List<Job_Application_Contact__c> returnedJobAppContacts = 
            JobApplicationContactHelper.generateContactsForNewJobApplications(
                testJobApps, accountNameById, accountsByCompanyName, 'Existing Contact');
        Test.stopTest();

        // Assert that we have 0 Job App Contacts, since no Accounts for the Job Apps had Contacts
        Assert.isTrue(returnedJobAppContacts.isEmpty(), 'There should be 0 Job App Contacts. There are ' + returnedJobAppContacts.size());
    }

    @isTest
    static void generateContactsForNewJobApplications_emptyJobApps() {

        // Setup variables to pass to the method but create an empty job app list
        List<Account> testAccounts = [SELECT Id, Name FROM Account];
        List<Job_Application__c> testJobApps = new List<Job_Application__c>();
        Map<Id, String> accountNameById = new Map<Id, String>();
        Map<String, Account> accountsByCompanyName = new Map<String, Account>();
        for (Account acc : testAccounts) {
            accountNameById.put(acc.Id, acc.Name);
            accountsByCompanyName.put(acc.Name, acc);
        }

        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            List<Job_Application_Contact__c> returnedJobAppContacts = 
                JobApplicationContactHelper.generateContactsForNewJobApplications(
                    testJobApps, accountNameById, accountsByCompanyName, 'Existing Contact');
        } catch (IllegalArgumentException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'An Illegal Argument Exception should have been thrown');
    }

    @isTest
    static void generateContactsForNewJobApplications_emptyAccountNameById() {

        // Setup variables to pass to the method but create an empty accountNameByIdMap
        List<Account> testAccounts = [SELECT Id, Name FROM Account];
        List<Job_Application__c> testJobApps = [SELECT Id, Company__c FROM Job_Application__c];
        Map<Id, String> accountNameById = new Map<Id, String>();
        Map<String, Account> accountsByCompanyName = new Map<String, Account>();
        for (Account acc : testAccounts) {
            accountsByCompanyName.put(acc.Name, acc);
        }

        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            List<Job_Application_Contact__c> returnedJobAppContacts = 
                JobApplicationContactHelper.generateContactsForNewJobApplications(
                    testJobApps, accountNameById, accountsByCompanyName, 'Existing Contact');
        } catch (IllegalArgumentException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'An Illegal Argument Exception should have been thrown');
    }

    @isTest
    static void generateContactsForNewJobApplications_emptyAccountsByCompanyName() {

        // Setup variables to pass to the method but create an empty accountNameByIdMap
        List<Account> testAccounts = [SELECT Id, Name FROM Account];
        List<Job_Application__c> testJobApps = [SELECT Id, Company__c FROM Job_Application__c];
        Map<Id, String> accountNameById = new Map<Id, String>();
        Map<String, Account> accountsByCompanyName = new Map<String, Account>();
        for (Account acc : testAccounts) {
            accountNameById.put(acc.Id, acc.Name);
        }

        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            List<Job_Application_Contact__c> returnedJobAppContacts = 
                JobApplicationContactHelper.generateContactsForNewJobApplications(
                    testJobApps, accountNameById, accountsByCompanyName, 'Existing Contact');
        } catch (IllegalArgumentException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'An Illegal Argument Exception should have been thrown');
    }

    @isTest
    static void generateContactsForNewJobApplications_nullJobAppContactRole() {

        // Setup variables to pass to the method but create an empty accountNameByIdMap
        List<Account> testAccounts = [SELECT Id, Name FROM Account];
        List<Job_Application__c> testJobApps = [SELECT Id, Company__c FROM Job_Application__c];
        Map<Id, String> accountNameById = new Map<Id, String>();
        Map<String, Account> accountsByCompanyName = new Map<String, Account>();
        for (Account acc : testAccounts) {
            accountNameById.put(acc.Id, acc.Name);
            accountsByCompanyName.put(acc.Name, acc);
        }

        String nullJobAppContactRole = null;
        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            List<Job_Application_Contact__c> returnedJobAppContacts = 
                JobApplicationContactHelper.generateContactsForNewJobApplications(
                    testJobApps, accountNameById, accountsByCompanyName, nullJobAppContactRole);
        } catch (IllegalArgumentException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'An Illegal Argument Exception should have been thrown');
    }

    @isTest
    static void enforceOneHiringManagerPerJobUpdate_notUpdatedToHiringManager() {

        // Generate Job App Contacts and associated records
        List<Account> testAccounts = [SELECT Id, Name FROM Account];
        List<Job_Application_Contact__c>  testJobAppContacts = 
            TestDataFactory.generateJobAppContactsWithRoleFromAccounts(testAccounts, 'Existing Contact', true);

        // Update Job App Contact role and put their Ids in Set so they can be queried after the test
        Set<Id> jobAppConIds = new Set<Id>();
        for(Job_Application_Contact__c jobAppCon : testJobAppContacts) {
            jobAppCon.Role__c = 'Recruiter';
            jobAppConIds.add(jobAppCon.Id);
        }

        Test.startTest();
        update testJobAppContacts;
        Test.stopTest();

        // Validate the role of the Job App Contacts
        List<Job_Application_Contact__c> updatedJobAppCons = [SELECT Id, Role__c FROM Job_Application_Contact__c WHERE Id IN :jobAppConIds];
        for (Job_Application_Contact__c updatedJobAppCon : updatedJobAppCons) {
            Assert.isTrue(updatedJobAppCon.Role__c == 'Recruiter', 'The role should have been set as Recruiter');
        }
    }

    @isTest
    static void enforceOneHiringManagerPerJobUpdate_updatedAwayFromHiringManager() {

        // Generate Job App Contacts and associated records
        List<Account> testAccounts = [SELECT Id, Name FROM Account];
        List<Job_Application_Contact__c>  testJobAppContacts = 
            TestDataFactory.generateJobAppContactsWithRoleFromAccounts(testAccounts, 'Hiring Manager', true);

        // Update Job App Contact role and put their Ids in Set so they can be queried after the test
        Set<Id> jobAppConIds = new Set<Id>();
        for(Job_Application_Contact__c jobAppCon : testJobAppContacts) {
            jobAppCon.Role__c = 'Recruiter';
            jobAppConIds.add(jobAppCon.Id);
        }

        Test.startTest();
        update testJobAppContacts;
        Test.stopTest();

        // Validate the role of the Job App Contacts
        List<Job_Application_Contact__c> updatedJobAppCons = [SELECT Id, Role__c FROM Job_Application_Contact__c WHERE Id IN :jobAppConIds];
        for (Job_Application_Contact__c updatedJobAppCon : updatedJobAppCons) {
            Assert.isTrue(updatedJobAppCon.Role__c == 'Recruiter', 'The role should have been set as Recruiter');
        }
    }

    @isTest
    static void enforceOneHiringManagerPerJobUpdate_updatedToHiringManager() {

        // Generate Job App Contacts and associated records
        List<Account> testAccounts = [SELECT Id, Name FROM Account];
        List<Job_Application_Contact__c>  testJobAppContacts = 
            TestDataFactory.generateJobAppContactsWithRoleFromAccounts(testAccounts, 'Recruiter', true);

        // Update Job App Contact role and put their Ids in Set so they can be queried after the test
        Set<Id> jobAppConIds = new Set<Id>();
        for(Job_Application_Contact__c jobAppCon : testJobAppContacts) {
            jobAppCon.Role__c = 'Hiring Manager';
            jobAppConIds.add(jobAppCon.Id);
        }

        Test.startTest();
        update testJobAppContacts;
        Test.stopTest();

        // Validate the role of the Job App Contacts
        List<Job_Application_Contact__c> updatedJobAppCons = [SELECT Id, Role__c FROM Job_Application_Contact__c WHERE Id IN :jobAppConIds];
        for (Job_Application_Contact__c updatedJobAppCon : updatedJobAppCons) {
            Assert.isTrue(updatedJobAppCon.Role__c == 'Hiring Manager', 'The role should have been set as Hiring Manager');
        }
    }

    @isTest
    static void enforceOneHiringManagerPerJobUpdate_twoUpdatedToHiringManagerInBatch() {

        // Generate 100 Job App Contacts and associated records.
        List<Account> testAccounts = [SELECT Id, Name FROM Account LIMIT 100];
        List<Job_Application_Contact__c>  testJobAppContacts = 
            TestDataFactory.generateJobAppContactsWithRoleFromAccounts(testAccounts, 'Recruiter', false);

        // Generate another Contact on each Account and set a different Contact on each Job App Contact before inserting all of them
        List<Contact> extraContacts = TestDataFactory.generateContactsOnAccounts(true, testAccounts);
        List<Job_Application_Contact__c> clonedJobAppContacts = TestDataFactory.cloneJobAppContactsAndSetToNewContacts(testJobAppContacts, extraContacts, false);
        testJobAppContacts.addAll(clonedJobAppContacts);
        insert testJobAppContacts;

        // Update Job App Contacts to the Hiring Manager Role
        Set<Id> jobAppConIds = new Set<Id>();
        for(Job_Application_Contact__c jobAppCon : testJobAppContacts) {
            jobAppCon.Role__c = 'Hiring Manager';
            jobAppConIds.add(jobAppCon.Id);
        }

        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            update testJobAppContacts;
        } catch (DmlException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        // Validate the role of the Job App Contacts
        Assert.isTrue(exceptionThrown, 'A DML Exception should have been thrown');
        List<Job_Application_Contact__c> errorJobAppContacts = [SELECT Id, Role__c FROM Job_Application_Contact__c WHERE Id IN :jobAppConIds];
        for (Job_Application_Contact__c errorJobAppCon : errorJobAppContacts) {
            Assert.isTrue(errorJobAppCon.Role__c == 'Recruiter', 'The role should still be recruiter due to duplicate hiring managers');
        }
    }

    @isTest
    static void enforceOneHiringManagerPerJobUpdate_oneUpdatedToHiringManagerWhenOneExists() {

        // Generate Job App Contacts and associated records.
        List<Account> testAccounts = [SELECT Id, Name FROM Account LIMIT 200];
        List<Job_Application_Contact__c>  testJobAppContacts = 
            TestDataFactory.generateJobAppContactsWithRoleFromAccounts(testAccounts, 'Hiring Manager', true);

        // Generate another Contact on each Account and set a different Contact with a different role on each Job App Contact before inserting
        List<Contact> extraContacts = TestDataFactory.generateContactsOnAccounts(true, testAccounts);
        List<Job_Application_Contact__c> clonedJobAppContacts = TestDataFactory.cloneJobAppContactsAndSetToNewContacts(testJobAppContacts, extraContacts, false);
        for (Job_Application_Contact__c clonedJobAppCon : clonedJobAppContacts) {
            clonedJobAppCon.Role__c = 'Recruiter';
        }
        insert clonedJobAppContacts;

        // Update Job App Contacts to the Hiring Manager Role
        Set<Id> jobAppConIds = new Set<Id>();
        for(Job_Application_Contact__c jobAppCon : clonedJobAppContacts) {
            jobAppCon.Role__c = 'Hiring Manager';
            jobAppConIds.add(jobAppCon.Id);
        }

        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            update clonedJobAppContacts;
        } catch (DmlException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        // Validate the role of the Job App Contacts
        Assert.isTrue(exceptionThrown, 'A DML Exception should have been thrown');
        List<Job_Application_Contact__c> errorJobAppContacts = [SELECT Id, Role__c FROM Job_Application_Contact__c WHERE Id IN :jobAppConIds];
        for (Job_Application_Contact__c errorJobAppCon : errorJobAppContacts) {
            Assert.isTrue(errorJobAppCon.Role__c == 'Recruiter', 'The role should still be recruiter due to duplicate hiring managers');
        }
    }

    @isTest
    static void enforceOneHiringManagerPerJobUpdate_emptyOldRecordMap() {

        List<Account> testAccounts = [SELECT Id, Name FROM Account LIMIT 1];
        List<Job_Application_Contact__c>  testJobAppContacts = 
            TestDataFactory.generateJobAppContactsWithRoleFromAccounts(testAccounts, 'Hiring Manager', true);

        Map<Id, Job_Application_Contact__c> emptyMap = new Map<Id, Job_Application_Contact__c>();

        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            JobApplicationContactHelper.enforceOneHiringManagerPerJobUpdate(testJobAppContacts, emptyMap);
        } catch (IllegalArgumentException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'An Illegal Argument Exception should have been thrown');
    }

    @isTest
    static void enforceOneHiringManagerPerJobUpdate_emptyJobAppContactsList() {

        List<Account> testAccounts = [SELECT Id, Name FROM Account LIMIT 1];
        List<Job_Application_Contact__c>  testJobAppContacts = 
            TestDataFactory.generateJobAppContactsWithRoleFromAccounts(testAccounts, 'Hiring Manager', true);
        Map<Id, Job_Application_Contact__c> jobAppContactMap = new Map<Id, Job_Application_Contact__c>();
        jobAppContactMap.put(testJobAppContacts.get(0).Id, testJobAppContacts.get(0));
        List<Job_Application_Contact__c> emptyList = new List<Job_Application_Contact__c>();

        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            JobApplicationContactHelper.enforceOneHiringManagerPerJobUpdate(emptyList, jobAppContactMap);
        } catch (IllegalArgumentException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'An Illegal Argument Exception should have been thrown');
    }

    @isTest
    static void enforceOneHiringManagerPerJobInsert_notHiringManager() {

        // Generate Job App Contacts and associated records
        List<Account> testAccounts = [SELECT Id, Name FROM Account];
        List<Job_Application_Contact__c>  testJobAppContacts = 
            TestDataFactory.generateJobAppContactsWithRoleFromAccounts(testAccounts, 'Existing Contact', false);

        Test.startTest();
        insert testJobAppContacts;
        Test.stopTest();

        // Validate the role of the Job App Contacts
        Set<Id> jobAppConIds = new Set<Id>();
        for (Job_Application_Contact__c jobAppCon : testJobAppContacts) {
            jobAppConIds.add(jobAppCon.Id);
        }

        List<Job_Application_Contact__c> insertedJobAppCons = [SELECT Id, Role__c FROM Job_Application_Contact__c WHERE Id IN :jobAppConIds];
        for (Job_Application_Contact__c insertedJobAppCon : insertedJobAppCons) {
            Assert.isTrue(insertedJobAppCon.Role__c == 'Existing Contact', 'The role should have been set as Existing Contact');
        }
    }

    @isTest
    static void enforceOneHiringManagerPerJobInsert_hiringManager() {

        // Generate Job App Contacts and associated records
        List<Account> testAccounts = [SELECT Id, Name FROM Account];
        List<Job_Application_Contact__c>  testJobAppContacts = 
            TestDataFactory.generateJobAppContactsWithRoleFromAccounts(testAccounts, 'Hiring Manager', false);

        Test.startTest();
        insert testJobAppContacts;
        Test.stopTest();

        // Validate the role of the Job App Contacts
        Set<Id> jobAppConIds = new Set<Id>();
        for (Job_Application_Contact__c jobAppCon : testJobAppContacts) {
            jobAppConIds.add(jobAppCon.Id);
        }

        List<Job_Application_Contact__c> insertedJobAppCons = [SELECT Id, Role__c FROM Job_Application_Contact__c WHERE Id IN :jobAppConIds];
        for (Job_Application_Contact__c insertedJobAppCon : insertedJobAppCons) {
            Assert.isTrue(insertedJobAppCon.Role__c == 'Hiring Manager', 'The role should have been set as Hiring Manager');
        }
    }

    @isTest
    static void enforceOneHiringManagerPerJobInsert_twoHiringManagersInBatch() {

        // Generate Job App Contacts and associated records
        List<Account> testAccounts = [SELECT Id, Name FROM Account LIMIT 100];
        List<Job_Application_Contact__c> testJobAppContacts = 
            TestDataFactory.generateJobAppContactsWithRoleFromAccounts(testAccounts, 'Hiring Manager', false);

        // Clone the 100 Job App Contacts, set to a different Contact so we have more than one Hiring Manager per job app
        List<Contact> extraContacts = TestDataFactory.generateContactsOnAccounts(true, testAccounts);
        List<Job_Application_Contact__c> clonedJobAppContacts = TestDataFactory.cloneJobAppContactsAndSetToNewContacts(testJobAppContacts, extraContacts, false);
        testJobAppContacts.addAll(clonedJobAppContacts);

        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            insert testJobAppContacts;
        } catch (DmlException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        // Validate that an exception was thrown none of the Job App Contacts have Ids
        Set<Id> jobAppConIds = new Set<Id>();
        Assert.isTrue(exceptionThrown, 'A DML Exception should have been thrown');
        for (Job_Application_Contact__c jobAppCon : testJobAppContacts) {
            Assert.isNull(jobAppCon.Id, 'The insert should have failed (meaning no Ids) due to two Hiring Managers per Job App');
        }
    }

    @isTest
    static void enforceOneHiringManagerPerJobInsert_oneHiringManagerExists() {

        // Generate Job App Contacts and associated records
        List<Account> testAccounts = [SELECT Id, Name FROM Account LIMIT 100];
        List<Job_Application_Contact__c> testJobAppContacts = 
            TestDataFactory.generateJobAppContactsWithRoleFromAccounts(testAccounts, 'Hiring Manager', true);

        // Clone the 100 Job App Contacts, set to a different Contact so we have more than one Hiring Manager per job app
        List<Contact> extraContacts = TestDataFactory.generateContactsOnAccounts(true, testAccounts);
        List<Job_Application_Contact__c> clonedJobAppContacts = TestDataFactory.cloneJobAppContactsAndSetToNewContacts(testJobAppContacts, extraContacts, false);

        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            insert clonedJobAppContacts;
        } catch (DmlException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        // Validate that an exception was thrown none of the Job App Contacts have Ids
        Set<Id> jobAppConIds = new Set<Id>();
        Assert.isTrue(exceptionThrown, 'A DML Exception should have been thrown');
        for (Job_Application_Contact__c jobAppCon : clonedJobAppContacts) {
            Assert.isNull(jobAppCon.Id, 'The insert should have failed (meaning no Ids) due to two Hiring Managers per Job App');
        }
    }

    @isTest
    static void enforceOneHiringManagerPerJobInsert_emptyJobAppContactsList() {

        List<Job_Application_Contact__c> emptyList = new List<Job_Application_Contact__c>();

        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            JobApplicationContactHelper.enforceOneHiringManagerPerJobInsert(emptyList);
        } catch (IllegalArgumentException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'An Illegal Argument Exception should have been thrown');
    }

    @isTest
    static void enforceOneHiringManagerPerJob_emptyJobAppContactsList() {

        List<Job_Application_Contact__c> emptyList = new List<Job_Application_Contact__c>();

        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            JobApplicationContactHelper.enforceOneHiringManagerPerJob(emptyList);
        } catch (IllegalArgumentException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'An Illegal Argument Exception should have been thrown');
    }

    @isTest 
    static void enforceOnePrimaryContactPerJobInsert_onePrimaryInBatch() {

        List<Job_Application_Contact__c> jobAppContacts = TestDataFactory.generateMultipleJobAppContactsWithOnePrimaryPerJobApp(100, 2);

        Test.startTest();
        insert jobAppContacts;
        Test.stopTest();

        Set<Id> jobApplicationIds = new Set<Id>();
        for(Job_Application_Contact__c jac : jobAppContacts) {
            jobApplicationIds.add(jac.Job_Application__c);
        }

        List<Job_Application__c> jobApps = [
            SELECT Id,
                (SELECT Id, Job_Application__c, Primary_Contact__c FROM Job_Application_Contacts__r)
            FROM Job_Application__c
            WHERE Id IN :jobApplicationIds
        ];

        for (Job_Application__c jobApp : jobApps) {
            List<Job_Application_Contact__c> childJobContacts = new List<Job_Application_Contact__c>();
            childJobContacts = jobApp.Job_Application_Contacts__r;
            Assert.isTrue(childJobContacts.size() == 2, 'The expected count of child Job Application Contacts is 2');
            Boolean hasPrimary = false;
            Boolean hasNonPrimary = false;
            for (Job_Application_Contact__c contact : childJobContacts) {
                if (contact.Primary_Contact__c) {
                    hasPrimary = true;
                } else {
                    hasNonPrimary = true;
                }
            }
            Assert.isTrue(hasPrimary, 'The Job Application should have a Primary Contact');
            Assert.isTrue(hasNonPrimary, 'The Job Application should have a non Primary Contact');
        }
    }

    @isTest 
    static void enforceOnePrimaryContactPerJobInsert_twoPrimariesInBatch() {

        List<Job_Application_Contact__c> jobAppContacts = TestDataFactory.generateMultipleJobAppContactsWithOnePrimaryPerJobApp(100, 2);

        Set<Id> jobAppIds = new Set<Id>();
        for (Job_Application_Contact__c jac : jobAppContacts) {
            jobAppIds.add(jac.Job_Application__c);
            if (!jac.Primary_Contact__c) {
                jac.Primary_Contact__c = true;
            }
        }

        Boolean exceptionThrown = false;
        String fullExceptionMessageReceived = null;

        Test.startTest();
        try {
            insert jobAppContacts;
        } catch (DmlException e) {
            exceptionThrown = true;
            fullExceptionMessageReceived = e.getMessage();
        }
        Test.stopTest();

        // Validate an exception was thrown as two Job App Contacts for the same Job App in the same batch tried to be set as Primary
        Assert.isTrue(exceptionThrown, 'A DML Exception should have been thrown');
        Assert.isTrue(fullExceptionMessageReceived.contains(JobApplicationContactHelper.MORE_THAN_1_PRIMARY_IN_BATCH_ERROR));
        List<Job_Application__c> jobAppsAfterTest = [
            SELECT Id
            FROM Job_Application__c
            WHERE Id IN: jobAppIds
            AND Id IN (
                SELECT Job_Application__c FROM Job_Application_Contact__c
            )
        ];
        Assert.isTrue(jobAppsAfterTest.isEmpty(), 'There should be no Job Apps with Job App Contacts');
    }

    @isTest 
    static void enforceOnePrimaryContactPerJobAppInsert_emptyList() {

        List<Job_Application_Contact__c> emptyList = new List<Job_Application_Contact__c>();
        Boolean exceptionThrown = true;

        Test.startTest();
        try {
            JobApplicationContactHelper.enforceOnePrimaryContactPerJobInsert(emptyList);
        } catch (IllegalArgumentException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'An Illegal Argument Exception should have been thrown');
    }

    @isTest 
    static void enforceOnePrimaryContactPerJobUpdate_oneUpdatedToPrimaryInBatch() {

        List<Job_Application_Contact__c> nonPrimaryJobAppContacts = TestDataFactory.insertJobAppContactsReturnNonPrimariesSetAsPrimary(100, 2);

        Set<Id> nonPrimaryIds = new Set<Id>();
        for (Job_Application_Contact__c jac : nonPrimaryJobAppContacts) {
            nonPrimaryIds.add(jac.Id);
        }

        Test.startTest();
        update nonPrimaryJobAppContacts;
        Test.stopTest();

        // Validate that the previously non Primary Contacts are now Primary. Note - other tests validate that the old Primary is no longer the primary
        List<Job_Application_Contact__c> newPrimaryContacts = [
            SELECT Id, Primary_Contact__c FROM Job_Application_Contact__c WHERE Id IN :nonPrimaryIds];
        for (Job_Application_Contact__c jac : newPrimaryContacts) {
            Assert.isTrue(jac.Primary_Contact__c, 'The Job Application Contact is not the Primary Contact as expected');
        }
    }

    @isTest
    static void enforceOnePrimaryContactPerJobUpdate_twoUpdatedToPrimaryInBatch() {

        List<Job_Application_Contact__c> nonPrimaryJobAppContacts = TestDataFactory.insertJobAppContactsReturnNonPrimariesSetAsPrimary(66, 3);

        Set<Id> nonPrimaryIds = new Set<Id>();
        for (Job_Application_Contact__c jac : nonPrimaryJobAppContacts) {
            nonPrimaryIds.add(jac.Id);
        }

        Boolean exceptionThrown = false;
        String fullExceptionMessageReceived = null;

        Test.startTest();
        try {
            update nonPrimaryJobAppContacts;
        } catch (DmlException e) {
            exceptionThrown = true;
            fullExceptionMessageReceived = e.getMessage();
        }
        Test.stopTest();

        // Validate an exception was thrown as two Job App Contacts for the same Job App in the same batch tried to be set as Primary
        Assert.isTrue(exceptionThrown, 'A DML Exception should have been thrown');
        Assert.isTrue(fullExceptionMessageReceived.contains(JobApplicationContactHelper.MORE_THAN_1_PRIMARY_IN_BATCH_ERROR));
        List<Job_Application_Contact__c> nonPrimaryCheck = [
            SELECT Id, Primary_Contact__c
            FROM Job_Application_Contact__c
            WHERE Id IN :nonPrimaryIds
        ];
        for (Job_Application_Contact__c nonPrimaryJac : nonPrimaryCheck) {
            Assert.IsTrue(nonPrimaryIds.contains(nonPrimaryJac.Id), 'A Job App Contact Id was not in the Set of expected Job App Contact non Primary Contact Ids');
            Assert.IsFalse(nonPrimaryJac.Primary_Contact__c, 'The Job App Contact should not be the Primary Contact');
            nonPrimaryIds.remove(nonPrimaryJac.Id);
        }
    }

    @isTest 
    static void enforceOnePrimaryContactPerJobAppUpdate_emptyList() {

        List<Job_Application_Contact__c> emptyList = new List<Job_Application_Contact__c>();

        Map<String, Account> testAccountByName = TestDataFactory.generateAccountsByName(true, 1);
        List<Job_Application_Contact__c> jobAppContacts = 
            TestDataFactory.generateJobAppContactsWithRoleFromAccounts(testAccountByName.values(), 'Existing Contact', true);
        Map<Id, Job_Application_Contact__c> jobAppContactMap = new Map<Id, Job_Application_Contact__c>();
        jobAppContactMap.put(jobAppContacts.get(0).Id, jobAppContacts.get(0));
        
        Boolean exceptionThrown = true;

        Test.startTest();
        try {
            JobApplicationContactHelper.enforceOnePrimaryContactPerJobUpdate(emptyList, jobAppContactMap);
        } catch (IllegalArgumentException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'An Illegal Argument Exception should have been thrown');
    }

    @isTest 
    static void enforceOnePrimaryContactPerJobAppUpdate_emptyMap() {

        Map<Id, Job_Application_Contact__c> emptyMap = new Map<Id, Job_Application_Contact__c>();
        
        Map<String, Account> testAccountByName = TestDataFactory.generateAccountsByName(true, 1);
        List<Job_Application_Contact__c> jobAppContacts = 
            TestDataFactory.generateJobAppContactsWithRoleFromAccounts(testAccountByName.values(), 'Existing Contact', true);
        
        Boolean exceptionThrown = true;

        Test.startTest();
        try {
            JobApplicationContactHelper.enforceOnePrimaryContactPerJobUpdate(jobAppContacts, emptyMap);
        } catch (IllegalArgumentException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'An Illegal Argument Exception should have been thrown');
    }

    @isTest 
    static void enforceOnePrimaryContact_emptyList() {

        List<Job_Application_Contact__c> emptyList = new List<Job_Application_Contact__c>();
        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            JobApplicationContactHelper.enforceOnePrimaryContact(emptyList);
        } catch (IllegalArgumentException e){
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'An Illegal Argument Exception should have been thrown');
    }

    @isTest
    static void defaultJobApplicationContactToPrimaryOnInsert_onePrimaryOneNotInBatch() {

        List<Job_Application_Contact__c> jobAppContacts = TestDataFactory.generateMultipleJobAppContactsWithOnePrimaryPerJobApp(100, 2);
        // Capture the Ids of the Contacts that should be Primary so we can assert after Job App Contact Insert
        Set<Id> primaryContactIds = new Set<Id>();
        Set<Id> allContactIds = new Set<Id>();
        for (Job_Application_Contact__c jac : jobAppContacts) {
            allContactIds.add(jac.Contact__c);
            if (jac.Primary_Contact__c) {
                primaryContactIds.add(jac.Contact__c);
            }
        }

        Test.startTest();
        insert jobAppContacts;
        Test.stopTest();

        List<Job_Application_Contact__c> jobAppContactsAfterInsert = [
            SELECT Id, Primary_Contact__c, Contact__c
            FROM Job_Application_Contact__c
            WHERE Contact__c IN :allContactIds
        ];

        for (Job_Application_Contact__c jac : jobAppContactsAfterInsert) {
            Assert.isTrue(allContactIds.contains(jac.Contact__c), 'The Job Application Contact is not associated with the correct Contact');
            if (primaryContactIds.contains(jac.Contact__c)) {
                Assert.isTrue(jac.Primary_Contact__c, 'The Job Application Contact should be the Primary Contact');
            } else {
                Assert.isFalse(jac.Primary_Contact__c, 'The Job Application Contact should not be a Primary Contact');
            }
        }
    }

    @isTest
    static void defaultJobApplicationContactToPrimaryOnInsert_twoNonPrimariesInBatch() {

        List<Job_Application_Contact__c> jobAppContacts = TestDataFactory.generateMultipleJobAppContactsWithOnePrimaryPerJobApp(100, 2);
        
        // Update all of the Job App Contact sObjects to not Primary and capture Contact Ids to help after the test
        Set<Id> allContactIds = new Set<Id>();
        for (Job_Application_Contact__c jac : jobAppContacts) {
            allContactIds.add(jac.Contact__c);
            if (!jac.Primary_Contact__c) {
                jac.Primary_Contact__c = false;
            }
        }

        Test.startTest();
        insert jobAppContacts;
        Test.stopTest();

        List<Job_Application_Contact__c> jobAppContactsAfterInsert = [
            SELECT Id, Primary_Contact__c, Contact__c, Job_Application__c
            FROM Job_Application_Contact__c
            WHERE Contact__c IN :allContactIds
        ];

        Set<Id> jobAppIdsWithPrimaryContact = new Set<Id>();
        Set<Id> jobAppIdsWithoutPrimaryContact = new Set<Id>();
        for (Job_Application_Contact__c jac : jobAppContactsAfterInsert) {
            if (jac.Primary_Contact__c) {
                jobAppIdsWithPrimaryContact.add(jac.Job_Application__c);
            } else {
                jobAppIdsWithoutPrimaryContact.add(jac.Job_Application__c);
            }
        }

        // Assert that all Job Apps have a Primary and non Primary Contact
        Assert.areEqual(jobAppIdsWithPrimaryContact, jobAppIdsWithoutPrimaryContact, 
            'All Job Apps should have a primary and non primary contact');
        Assert.areEqual(100, jobAppIdsWithPrimaryContact.size(), '100 Job Apps should have a Primary Contact');
        Assert.areEqual(100, jobAppIdsWithoutPrimaryContact.size(), '100 Job Apps should have a non Primary Contact');
    }

    @isTest
    static void defaultJobApplicationContactToPrimaryOnInsert_oneNonPrimaryInBatchOneAlreadyExists() {

        List<Job_Application_Contact__c> jobAppContacts = TestDataFactory.generateMultipleJobAppContactsWithOnePrimaryPerJobApp(100, 2);
        
        // Break the Job Application Contacts into two lists - one to Insert first and default to Primary and one to Insert after
        List<Job_Application_Contact__c> primaryJobAppContacts = new List<Job_Application_Contact__c>();
        List<Job_Application_Contact__c> nonPrimaryJobAppContacts = new List<Job_Application_Contact__c>();
        Set<Id> allContactIds = new Set<Id>();
        for (Job_Application_Contact__c jac : jobAppContacts) {
            allContactIds.add(jac.Contact__c);
            if (jac.Primary_Contact__c) {
                primaryJobAppContacts.add(jac);
            } else {
                nonPrimaryJobAppContacts.add(jac);
            }
        }
        insert primaryJobAppContacts;
        Set<Id> primaryJobAppContactIds = new Set<Id>();
        for(Job_Application_Contact__c jac : primaryJobAppContacts) {
            primaryJobAppContactIds.add(jac.Id);
        }

        Test.startTest();
        insert nonPrimaryJobAppContacts;
        Test.stopTest();

        List<Job_Application_Contact__c> jobAppContactsAfterInsert = [
            SELECT Id, Primary_Contact__c, Contact__c, Job_Application__c
            FROM Job_Application_Contact__c
            WHERE Contact__c IN :allContactIds
        ];

        for (Job_Application_Contact__c jac : jobAppContactsAfterInsert) {
            if (primaryJobAppContactIds.contains(jac.Id)) {
                Assert.isTrue(jac.Primary_Contact__c, 'A Job Application Contact that should be a Primary Contact is not');
            } else {
                Assert.isFalse(jac.Primary_Contact__c, 'A Job Application Contact that should not be a Primary Contact is one');
            }
        }
    }

    @isTest
    static void defaultJobApplicationContactToPrimaryOnInsert_missingList() {

        List<Job_Application_Contact__c> emptyList = new List<Job_Application_Contact__c>();
        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            JobApplicationContactHelper.defaultJobApplicationContactToPrimaryOnInsert(emptyList);
        } catch (IllegalArgumentException e){
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'An Illegal Arugment Exception should have been thrown');
    }

    @isTest
    static void replacePrimaryContactsOnInsert() {

        List<Job_Application_Contact__c> jobAppContacts = TestDataFactory.generateMultipleJobAppContactsWithOnePrimaryPerJobApp(100, 2);
        
        // Break the Job Application Contacts into two lists - one to Insert first and default to Primary and one to Insert after and replace as Primary
        List<Job_Application_Contact__c> firstPrimaryJobAppContacts = new List<Job_Application_Contact__c>();
        List<Job_Application_Contact__c> secondPrimaryJobAppContacts = new List<Job_Application_Contact__c>();
        Set<Id> allContactIds = new Set<Id>();
        for (Job_Application_Contact__c jac : jobAppContacts) {
            allContactIds.add(jac.Contact__c);
            if (jac.Primary_Contact__c) {
                firstPrimaryJobAppContacts.add(jac);
            } else {
                secondPrimaryJobAppContacts.add(jac);
            }
        }
        insert firstPrimaryJobAppContacts;
        Set<Id> firstPrimaryJobAppContactIds = new Set<Id>();
        for(Job_Application_Contact__c jac : firstPrimaryJobAppContacts) {
            firstPrimaryJobAppContactIds.add(jac.Id);
        }

        for (Job_Application_Contact__c jac : secondPrimaryJobAppContacts) {
            jac.Primary_Contact__c = true;
        }

        Test.startTest();
        insert secondPrimaryJobAppContacts;
        Test.stopTest();

        List<Job_Application_Contact__c> jobAppContactsAfterInsert = [
            SELECT Id, Primary_Contact__c, Contact__c, Job_Application__c
            FROM Job_Application_Contact__c
            WHERE Contact__c IN :allContactIds
        ];

        // Assert that the original Primary Contact is no longer the Primary and vice-versa
        for (Job_Application_Contact__c jac : jobAppContactsAfterInsert) {
            if (firstPrimaryJobAppContactIds.contains(jac.Id)) {
                Assert.isFalse(jac.Primary_Contact__c, 'A Job Application Contact that should no longer be Primary Contact still is');
            } else {
                Assert.isTrue(jac.Primary_Contact__c, 'A Job Application Contact that should have been updated to Primary has not');
            }
        }
    }

    @isTest
    static void replacePrimaryContactsOnInsert_emptyList() {

        List<Job_Application_Contact__c> emptyList = new List<Job_Application_Contact__c>();
        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            JobApplicationContactHelper.replacePrimaryContactsOnInsert(emptyList);
        } catch (IllegalArgumentException e){
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'An Illegal Arugment Exception should have been thrown');
    }

    @isTest
    static void replacePrimaryContactsOnUpdate() {

        List<Job_Application_Contact__c> jobAppContacts = TestDataFactory.generateMultipleJobAppContactsWithOnePrimaryPerJobApp(100, 2);
        
        // Insert the Job App Contacts which have one Primary and one non Primary on each app
        insert jobAppContacts;

        // Extract their Ids into Set tracking the current Primary, all Job App Contacts and also switch non Primaries to Primary
        Set<Id> firstPrimaryJobAppContactIds = new Set<Id>();
        Set<Id> allJobAppContactIds = new Set<Id>();

        List<Job_Application_Contact__c> jacUpdatedToPrimary = new List<Job_Application_Contact__c>();
        for (Job_Application_Contact__c jac : jobAppContacts){
            allJobAppContactIds.add(jac.Id);
            if (jac.Primary_Contact__c) {
                firstPrimaryJobAppContactIds.add(jac.Id);
            } else {
                jac.Primary_Contact__c = true;
                jacUpdatedToPrimary.add(jac);
            }
        }

        Test.startTest();
        update jacUpdatedToPrimary;
        Test.stopTest();

        List<Job_Application_Contact__c> jobAppContactsAfterUpdate = [
            SELECT Id, Primary_Contact__c, Contact__c, Job_Application__c
            FROM Job_Application_Contact__c
            WHERE Id IN :allJobAppContactIds
        ];

        // Assert that the original Primary Contact is no longer the Primary and vice-versa
        for (Job_Application_Contact__c jac : jobAppContactsAfterUpdate) {
            if (firstPrimaryJobAppContactIds.contains(jac.Id)) {
                Assert.isFalse(jac.Primary_Contact__c, 'A Job Application Contact that should no longer be Primary Contact still is');
            } else {
                Assert.isTrue(jac.Primary_Contact__c, 'A Job Application Contact that should have been updated to Primary has not');
            }
        }
    }

    @isTest 
    static void replacePrimaryContactsOnUpdate_emptyList() {

        List<Job_Application_Contact__c> emptyList = new List<Job_Application_Contact__c>();

        Map<String, Account> testAccountByName = TestDataFactory.generateAccountsByName(true, 1);
        List<Job_Application_Contact__c> jobAppContacts = 
            TestDataFactory.generateJobAppContactsWithRoleFromAccounts(testAccountByName.values(), 'Existing Contact', true);
        Map<Id, Job_Application_Contact__c> jobAppContactMap = new Map<Id, Job_Application_Contact__c>();
        jobAppContactMap.put(jobAppContacts.get(0).Id, jobAppContacts.get(0));
        
        Boolean exceptionThrown = true;

        Test.startTest();
        try {
            JobApplicationContactHelper.replacePrimaryContactsOnUpdate(emptyList, jobAppContactMap);
        } catch (IllegalArgumentException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'An Illegal Argument Exception should have been thrown');
    }

    @isTest 
    static void replacePrimaryContactsOnUpdate_emptyMap() {

        Map<Id, Job_Application_Contact__c> emptyMap = new Map<Id, Job_Application_Contact__c>();
        
        Map<String, Account> testAccountByName = TestDataFactory.generateAccountsByName(true, 1);
        List<Job_Application_Contact__c> jobAppContacts = 
            TestDataFactory.generateJobAppContactsWithRoleFromAccounts(testAccountByName.values(), 'Existing Contact', true);
        
        Boolean exceptionThrown = true;

        Test.startTest();
        try {
            JobApplicationContactHelper.replacePrimaryContactsOnUpdate(jobAppContacts, emptyMap);
        } catch (IllegalArgumentException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'An Illegal Argument Exception should have been thrown');
    }

    @isTest 
    static void replaceExistingPrimaryContact_emptyMap() {

        Map<Id, Job_Application_Contact__c> emptyMap = new Map<Id, Job_Application_Contact__c>();
        Boolean exceptionThrown = true;

        Test.startTest();
        try {
            JobApplicationContactHelper.replaceExistingPrimaryContact(emptyMap);
        } catch (IllegalArgumentException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'An Illegal Argument Exception should have been thrown');
    }

    // The tests for handlePrimaryContactDeselect handle the use case of a record being selected and deselected as Primary in the same batch
    // Some of the functionality of this method is tested by the above methods for replaceExistingPrimaryContact
    // This handles updating the existing Primary Contact from outside of the trigger when a new one has been selected and is in the trigger

    @isTest
    static void handlePrimaryContactDeselect_selectDeselectAtSameTime() {

        List<Job_Application_Contact__c> jobAppContacts = TestDataFactory.generateMultipleJobAppContactsWithOnePrimaryPerJobApp(100, 2);
        
        // Insert the Job App Contacts which have one Primary and one non Primary on each app
        insert jobAppContacts;

        // Extract their Ids into Set tracking the current Primary, all Job App Contacts and also switch non Primaries to Primary
        Set<Id> firstPrimaryJobAppContactIds = new Set<Id>();
        Set<Id> secondPrimaryJobAppContactIds = new Set<Id>();
        Set<Id> allJobAppContactIds = new Set<Id>();

        for (Job_Application_Contact__c jac : jobAppContacts){
            allJobAppContactIds.add(jac.Id);
            if (jac.Primary_Contact__c) {
                jac.Primary_Contact__c = false;
                firstPrimaryJobAppContactIds.add(jac.Id);
            } else {
                jac.Primary_Contact__c = true;
                secondPrimaryJobAppContactIds.add(jac.Id);
            }
        }

        Test.startTest();
        update jobAppContacts;
        Test.stopTest();

        List<Job_Application_Contact__c> jobAppContactsAfterUpdate = [
            SELECT Id, Primary_Contact__c, Contact__c, Job_Application__c
            FROM Job_Application_Contact__c
            WHERE Id IN :allJobAppContactIds
        ];

        // Assert that the original Primary Contact is no longer the Primary and vice-versa
        for (Job_Application_Contact__c jac : jobAppContactsAfterUpdate) {
            if (firstPrimaryJobAppContactIds.contains(jac.Id)) {
                Assert.isFalse(jac.Primary_Contact__c, 'A Job Application Contact that should no longer be Primary Contact still is');
            } else {
                Assert.isTrue(jac.Primary_Contact__c, 'A Job Application Contact that should have been updated to Primary has not');
            }
        }
    }

    @isTest
    static void handlePrimaryContactDeselect_noOtherPrimaries() {

        // Insert the Job App Contacts which have one Primary and one non Primary on each app
        List<Job_Application_Contact__c> jobAppContacts = TestDataFactory.generateMultipleJobAppContactsWithOnePrimaryPerJobApp(100, 2);
        insert jobAppContacts;

        // Extract their Ids into Set tracking the current Primary, all Job App Contacts and also switching from Primary to non Primary
        List<Job_Application_Contact__c> updatedToNonPrimary = new List<Job_Application_Contact__c>();
        Set<Id> firstPrimaryJobAppContactIds = new Set<Id>();

        for (Job_Application_Contact__c jac : jobAppContacts){
            if (jac.Primary_Contact__c) {
                jac.Primary_Contact__c = false;
                updatedToNonPrimary.add(jac);
                firstPrimaryJobAppContactIds.add(jac.Id);
            } 
        }

        Boolean exceptionThrown = false;
        String fullExceptionMessageReceived = null;

        Test.startTest();
        try {
            update updatedToNonPrimary;
        } catch (DmlException e) {
            exceptionThrown = true;
            fullExceptionMessageReceived = e.getMessage();
        }
        Test.stopTest();

        // Validate an exception was thrown as two Job App Contacts for the same Job App in the same batch tried to be set as Primary
        Assert.isTrue(exceptionThrown, 'A DML Exception should have been thrown');
        Assert.isTrue(fullExceptionMessageReceived.contains(JobApplicationContactHelper.SELECT_NEW_PRIMARY_ERROR));
        List<Job_Application_Contact__c> jobAppContactsAfterTest = [
            SELECT Id, Primary_Contact__c
            FROM Job_Application_Contact__c
            WHERE Id IN :firstPrimaryJobAppContactIds
        ];
        for (Job_Application_Contact__c jac : jobAppContactsAfterTest) {
            Assert.isTrue(jac.Primary_Contact__c, 'The Job App Contact should still be the Primary Contact');
        }
    } 

    @isTest 
    static void handlePrimaryContactDeselect_noOtherContacts() {

        // Generate Job App Contacts and set the Primary Contact field to true
        List<Account> testAccounts = [SELECT Id FROM Account LIMIT 200];
        List<Job_Application_Contact__c> jobAppContacts = TestDataFactory.generateJobAppContactsWithRoleFromAccounts (testAccounts, 'Existing Contact', false);
        for (Job_Application_Contact__c jac : jobAppContacts) {
            jac.Primary_Contact__c = true;
        }
        insert jobAppContacts;

        // Update the Job App Contacts so they ae no longer the Primary so we can test getting an error        
        Set<Id> jobAppContactIds = new Set<Id>();
        for (Job_Application_Contact__c jac : jobAppContacts) {
            jac.Primary_Contact__c = false;
            jobAppContactIds.add(jac.Id);
        }

        Boolean exceptionThrown = false;
        String fullExceptionMessageReceived = null;

        Test.startTest();
        try {
            update jobAppContacts;
        } catch (DmlException e) {
            exceptionThrown = true;
            fullExceptionMessageReceived = e.getMessage();
        }
        Test.stopTest();

        // Validate an exception was thrown as two Job App Contacts for the same Job App in the same batch tried to be set as Primary
        Assert.isTrue(exceptionThrown, 'A DML Exception should have been thrown');
        Assert.isTrue(fullExceptionMessageReceived.contains(JobApplicationContactHelper.SELECT_NEW_PRIMARY_ERROR));
        List<Job_Application_Contact__c> jobAppContactsAfterTest = [
            SELECT Id, Primary_Contact__c
            FROM Job_Application_Contact__c
            WHERE Id IN :jobAppContactIds
        ];
        for (Job_Application_Contact__c jac : jobAppContactsAfterTest) {
            Assert.isTrue(jac.Primary_Contact__c, 'The Job App Contact should still be the Primary Contact');
        }
    } 
    @isTest 
    static void handlePrimaryContactDeselect_emptyList() {

        List<Job_Application_Contact__c> emptyList = new List<Job_Application_Contact__c>();

        Map<String, Account> testAccountByName = TestDataFactory.generateAccountsByName(true, 1);
        List<Job_Application_Contact__c> jobAppContacts = 
            TestDataFactory.generateJobAppContactsWithRoleFromAccounts(testAccountByName.values(), 'Existing Contact', true);
        Map<Id, Job_Application_Contact__c> jobAppContactMap = new Map<Id, Job_Application_Contact__c>();
        jobAppContactMap.put(jobAppContacts.get(0).Id, jobAppContacts.get(0));
        
        Boolean exceptionThrown = true;

        Test.startTest();
        try {
            JobApplicationContactHelper.handlePrimaryContactDeselect(emptyList, jobAppContactMap);
        } catch (IllegalArgumentException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'An Illegal Argument Exception should have been thrown');
    }

    @isTest 
    static void handlePrimaryContactDeselect_emptyMap() {

        Map<Id, Job_Application_Contact__c> emptyMap = new Map<Id, Job_Application_Contact__c>();
        
        Map<String, Account> testAccountByName = TestDataFactory.generateAccountsByName(true, 1);
        List<Job_Application_Contact__c> jobAppContacts = 
            TestDataFactory.generateJobAppContactsWithRoleFromAccounts(testAccountByName.values(), 'Existing Contact', true);
        
        Boolean exceptionThrown = true;

        Test.startTest();
        try {
            JobApplicationContactHelper.handlePrimaryContactDeselect(jobAppContacts, emptyMap);
        } catch (IllegalArgumentException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'An Illegal Argument Exception should have been thrown');
    }
}