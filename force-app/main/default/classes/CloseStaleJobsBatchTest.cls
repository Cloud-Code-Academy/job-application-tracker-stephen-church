@isTest
public with sharing class CloseStaleJobsBatchTest {

    @IsTest
    static void closeStaleJobsBatch() {
        
        final Integer DAYS_AGO_TO_SET_FOLLOW_UP_DATE  = CloseStaleJobsBatch.DAYS_AGO_SINCE_FOLLOW_UP_TO_BE_STALE;
        final String EXPECTED_STALE_STATUS = CloseStaleJobsBatch.STATUS_TO_SET;

        // Create active user
        User activeUser = TestDataFactory.createUserWithTaxStatus('Single');

        // Create Job Apps with a follow up date over 30 ago and some with a follow up date less than 30 days ago
        Map<Id, Account> testAccounts = TestDataFactory.generateAccountsById(200);
        List<Job_Application__c> testJobApps = TestDataFactory.generateJobAppsOnAccount(false, testAccounts.values());
        Integer loopCount = 1;
        for (Job_Application__c jobApp : testJobApps) {
            if (loopCount < 100) {
                jobApp.Follow_Up_Date__c = Date.today();
                jobApp.OwnerId = activeUser.Id;
            } else {
                jobApp.Follow_Up_Date__c = Date.today().addDays(-DAYS_AGO_TO_SET_FOLLOW_UP_DATE);
                jobApp.OwnerId = activeUser.Id;
            }
            loopCount++;
        }
        insert testJobApps;

        // Get the Tasks on the Job Apps that may have opened and close them
        Set<Id> jobAppIds = new Set<Id>();
        for (Job_Application__c jobApp : testJobApps) {
            jobAppIds.add(jobApp.Id);
        }
        List<Task> tasksOnJobApps = [SELECT Id, Status, IsClosed FROM Task WHERE WhatId IN :jobAppIds];
        for (Task taskToClose : tasksOnJobApps) {
            taskToClose.Status = 'Completed';
        }
        update tasksOnJobApps;
        
        Test.startTest();
        CloseStaleJobsBatch batchJob = new CloseStaleJobsBatch();
        Id batchId = Database.executeBatch(batchJob);
        Test.stopTest();

        // Get the Job Applications and check if they have the correct status
        List<Job_Application__c> updatedJobApps = [
            SELECT Id, Follow_Up_Date__c, Application_Status__c 
            FROM Job_Application__c
            WHERE Id IN :jobAppIds
        ];

        for (Job_Application__c jobApp : updatedJobApps) {
            if (jobApp.Follow_Up_Date__c <= Date.today().addDays(-DAYS_AGO_TO_SET_FOLLOW_UP_DATE)) {
                Assert.areEqual(EXPECTED_STALE_STATUS, jobApp.Application_Status__c, 'The Job Application Status is not correct.');
            } else {
                Assert.isFalse(jobApp.Application_Status__c == EXPECTED_STALE_STATUS);
            }
        }
    }
}