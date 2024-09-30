@isTest
public with sharing class JobApplicationContactSelectorTest {

    @TestSetup
    static void createJobAppContacts(){

        List<Job_Application_Contact__c> jobAppContacts = 
            TestDataFactory.generateMultipleJobAppContactsWithOnePrimaryPerJobApp(100, 2);
        insert jobAppContacts;

        // Update 100 of the Job App Contacts to Recruiter Role and 100 to Existing Contact so we can test getting different roles
        Integer i = 1;
        for (Job_Application_Contact__c jac : jobAppContacts) {
            if (i <= 100) {
                jac.Role__c = 'Existing Contact';
            } else {
                jac.Role__c = 'Recruiter';
            }
            i +=1 ;
        }
        update jobAppContacts;
    }

    @isTest
    static void getJobApplicationContactsByRole() {

        List<Job_Application__c> testSetupJobApps = [SELECT Id FROM Job_Application__c];
        Set<Id> jobAppIds = new Set<Id>();
        for (Job_Application__c jobApp : testSetupJobApps) {
            jobAppIds.add(jobApp.Id);
        }

        Test.startTest();
        List<Job_Application_Contact__c> recruiterContacts = 
            JobApplicationContactSelector.getJobApplicationContactsByRole(jobAppIds, 'Recruiter');
        Test.stopTest();

        // Test setup created 100 Job Apps with the Recruiter role
        Assert.isTrue(recruiterContacts.size() == 100, 'There should be 100 Recruiter Job App Contacts');
        for (Job_Application_Contact__c jac : recruiterContacts) {
            Assert.areEqual('Recruiter', jac.Role__c, 'The returned Job App Contact does not have the role of Recruiter');
        }
    }

    @isTest
    static void getJobApplicationContactsByRole_missingSet() {

        List<Job_Application__c> testSetupJobApps = [SELECT Id FROM Job_Application__c];
        Set<Id> jobAppIds = new Set<Id>();
        for (Job_Application__c jobApp : testSetupJobApps) {
            jobAppIds.add(jobApp.Id);
        }

        Boolean exceptionThrown = true;

        Test.startTest();
        try {
            List<Job_Application_Contact__c> recruiterContacts = 
                JobApplicationContactSelector.getJobApplicationContactsByRole(jobAppIds, 'Recruiter');
        } catch (IllegalArgumentException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'An Illegal Argument Exception should have been thrown');
    }

    @isTest
    static void getJobApplicationContactsByRole_missingRole() {

        Set<Id> jobAppIds = new Set<Id>();
        Boolean exceptionThrown = true;

        Test.startTest();
        try {
            List<Job_Application_Contact__c> recruiterContacts = 
                JobApplicationContactSelector.getJobApplicationContactsByRole(jobAppIds, null);
        } catch (IllegalArgumentException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'An Illegal Argument Exception should have been thrown');
    }


    @isTest
    static void getPrimaryContactsForJobApps() {

        List<Job_Application__c> testSetupJobApps = [SELECT Id FROM Job_Application__c];
        Set<Id> jobAppIds = new Set<Id>();
        for (Job_Application__c jobApp : testSetupJobApps) {
            jobAppIds.add(jobApp.Id);
        }

        Test.startTest();
        List<Job_Application_Contact__c> primaryContacts = JobApplicationContactSelector.getPrimaryContactsForJobApps(jobAppIds);
        Test.stopTest();

        // Test setup created 100 Job Apps with one Primary per job app
        Assert.isTrue(primaryContacts.size() == 100, 'There should be 100 Primary Contacts');
        for (Job_Application_Contact__c jac : primaryContacts) {
            Assert.isTrue(jac.Primary_Contact__c, 'The returned Job App Contact is not a Primary Contact');
        }
    }

    @isTest
    static void getPrimaryContactsForJobApps_missingSet() {

        Set<Id> emptySet = new Set<Id>();
        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            JobApplicationContactSelector.getPrimaryContactsForJobApps(emptySet);
        } catch (IllegalArgumentException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'An Illegal Argument Exception should have been thrown');
    }

    @isTest
    static void getPrimaryContactsForJobAppsExcludingCertainContacts() {

        List<Job_Application_Contact__c> testSetupJobAppContacts = [
            SELECT Id, Job_Application__c
            FROM Job_Application_Contact__c
            WHERE Primary_Contact__c = TRUE
        ];

        // Split the returned Ids into two Sets for assertions
        Set<Id> jobAppContactIdsToGet = new Set<Id>();
        Set<Id> jobAppContactIdsToNotGet = new Set<Id>();
        Set<Id> jobAppIds = new Set<Id>();
        Integer i = 0;
        for (Job_Application_Contact__c jac : testSetupJobAppContacts) {
            jobAppIds.add(jac.Job_Application__c);
            if (Math.mod(i, 2) == 0) {
                jobAppContactIdsToGet.add(jac.Id);
            } else {
                jobAppContactIdsToNotGet.add(jac.Id);
            }
            i += 1;
        }

        Test.startTest();
        List<Job_Application_Contact__c> returnedJobAppContacts = 
            JobApplicationContactSelector.getPrimaryContactsForJobAppsExcludingCertainContacts(jobAppIds, jobAppContactIdsToNotGet);
        Test.stopTest();

        // Validate all of the Job App Contact Ids from the to get set are returned
        for (Job_Application_Contact__c jac : returnedJobAppContacts) {
            Assert.isTrue(jobAppContactIdsToGet.contains(jac.Id), 'An unexpected Job App Contact Id was returned');
            jobAppContactIdsToGet.remove(jac.Id);
        }
        // There should be no Job App Contact Ids left in the set after the above.
        Assert.isTrue(jobAppContactIdsToGet.size() == 0, 'Not all expected Job App Contact Ids were returned');
    }

    @isTest
    static void getPrimaryContactsForJobAppsExcludingCertainContacts_missingJobAppSet() {

        Set<Id> emptyJobAppSet = new Set<Id>();
        Job_Application_Contact__c jac = [SELECT Id FROM Job_Application_Contact__c LIMIT 1];
        Set<Id> jobAppContactSet = new Set<Id>();
        jobAppContactSet.add(jac.Id);

        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            JobApplicationContactSelector.getPrimaryContactsForJobAppsExcludingCertainContacts(emptyJobAppSet, jobAppContactSet);
        } catch (IllegalArgumentException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'An Illegal Argument Exception should have been thrown');
    }

    @isTest
    static void getPrimaryContactsForJobAppsExcludingCertainContacts_missingJobAppConSet() {

        Set<Id> emptyJobAppConSet = new Set<Id>();
        Job_Application__c ja = [SELECT Id FROM Job_Application__c LIMIT 1];
        Set<Id> jobAppSet = new Set<Id>();
        jobAppSet.add(ja.Id);

        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            JobApplicationContactSelector.getPrimaryContactsForJobAppsExcludingCertainContacts(jobAppSet, emptyJobAppConSet);
        } catch (IllegalArgumentException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'An Illegal Argument Exception should have been thrown');
    }
}