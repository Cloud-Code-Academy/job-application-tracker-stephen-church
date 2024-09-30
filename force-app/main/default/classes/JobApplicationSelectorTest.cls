@isTest
public with sharing class JobApplicationSelectorTest {

    @TestSetup
    static void createAccounts(){
        TestDataFactory.generateAccountsById(200);
    }

    @isTest
    static void getJobAppsWithExternalJobId() {

        List<Account> testAccounts = [SELECT Id FROM Account];
        List<Job_Application__c> jobApps = TestDataFactory.generateJobAppsOnAccount(false, testAccounts);
        Set<String> externalJobAppIds = new Set<String>();
        Integer loopCount = 1;
        for (Job_Application__c jobApp : jobApps) {
            if (loopCount <= 100) {
                jobApp.Job_Posting_Id__c = String.valueOf(loopCount);
                externalJobAppIds.add(String.valueOf(loopCount));
                loopCount++;
            } else {
                break;
            }
        }
        insert jobApps;
        Set<Id> jobAppIdsWithExternalIds = new Set<Id>();
        for (Job_Application__c jobApp : jobApps) {
            if (jobApp.Job_Posting_Id__c != null) {
                jobAppIdsWithExternalIds.add(jobApp.Id);
            }
        }
        Test.startTest();
        List<Job_Application__c> queryResults = JobApplicationSelector.getJobAppsWithExternalJobId(externalJobAppIds);
        Test.stopTest();

        Assert.areEqual(externalJobAppIds.size(), queryResults.size(), 'The expected amount of Job Apps was not returned');
        for (Job_Application__c jobApp : queryResults) {
            Assert.isTrue(jobAppIdsWithExternalIds.contains(jobApp.Id));
        }
    }

    @isTest
    static void getJobAppsWithOpenTasks() {

        // Create Account and Job Apps with a status that will generate open Tasks
        List<Account> testAccounts = [SELECT Id FROM Account];
        List<Job_Application__c> jobApps = TestDataFactory.generateJobAppsOnAccount(false, testAccounts);
        Status_Task_Manager__mdt stm = [
            SELECT Id, Status__c
            FROM Status_Task_Manager__mdt
            WHERE Task_Generation_Class__c != null
            LIMIT 1
        ];
        for (Job_Application__c jobApp : jobApps) {
            jobApp.Application_Status__c = stm.Status__c;
        }
        insert jobApps;
        Set<Id> jobAppIds = new Set<Id>();
        for (Job_Application__c jobApp : jobApps) {
            jobAppIds.add(jobApp.Id);
        }
        
        Test.startTest();
        List<Job_Application__c> queryResults = JobApplicationSelector.getJobAppsWithOpenTasks(jobAppIds);
        Test.stopTest();

        for (Job_Application__c jobApp : queryResults) {
            List<Task> childTasks = jobApp.Tasks;
            Assert.isFalse(childTasks.isEmpty(), 'The Job App does not have any Tasks');
            Integer countOfOpenTasks = 0;
            for (Task childTask : childTasks) {
                if (!childTask.isClosed) {
                    countOfOpenTasks++;
                }
            }
            Assert.isTrue(countOfOpenTasks >= 1, 'The Job App does not have child Tasks');
        }
    }
}