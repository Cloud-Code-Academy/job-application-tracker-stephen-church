@isTest
public with sharing class StatusTMJobAppAcceptedTest {

    public static final String OBJECT_KEYWORD = 'Job Application';
    public static final String STATUS_KEYWORD = 'Applying';

    @isTest
    static void generateStatusTasks() {

        final Set<String> EXPECTED_TASK_SUBJECTS = new Set<String>{
            'Plan your resignation if applicable',
            'Take some time to relax and recharge',
            'Announce your new job on LinkedIn',
            'Prepare for your first day of onboarding'
        };
        final Integer JOB_COUNT = 200;
        final Integer TASKS_PER_JOB = EXPECTED_TASK_SUBJECTS.size();

        Status_Task_Manager__mdt stm = TestDataFactory.getStatusTaskManagerForTest(OBJECT_KEYWORD, STATUS_KEYWORD);
        Map<Id, Account> testAccountsById = TestDataFactory.generateAccountsById(JOB_COUNT);
        List<Job_Application__c> testJobApps = TestDataFactory.generateJobAppsOnAccount(true, testAccountsById.values());

        Test.startTest();
        StatusTMJobAppAccepted stmTaskGenerator = new StatusTMJobAppAccepted();
        List<Task> statusTasks = stmTaskGenerator.generateStatusTasks(testJobApps, stm);
        Test.stopTest();

        Map<Id, List<Task>> tasksByJobAppId = TestDataFactory.organizeTaskListByJobAppId(testJobApps, statusTasks);

        Assert.areEqual(tasksByJobAppId.size(), JOB_COUNT, 'The count of jobs with Tasks is incorrect');
        Assert.areEqual(JOB_COUNT * TASKS_PER_JOB, statusTasks.size(), 'The expected count of Tasks is incorrect');
        for (Id whatId : tasksByJobAppId.keySet()) {
            List<Task> jobTaskList = tasksByJobAppId.get(whatId);
            Assert.areEqual(TASKS_PER_JOB, jobTaskList.size());
            for (Task jobTask : jobTaskList) {
                Set<String> taskSubjectCheck = EXPECTED_TASK_SUBJECTS.clone();
                Assert.areEqual(
                    jobTask.ActivityDate, 
                    Date.today() + Integer.valueOf(stm.Default_Days_For_Task_Due_Date__c), 
                    'The Task does not have the expected Due Date');
                Assert.areEqual(
                    jobTask.Priority, 
                    stm.Default_Task_Priority__c, 
                    'The Task does not have the expected Priority');
                Assert.areEqual(
                    jobTask.Status, 
                    stm.Default_Task_Status__c, 
                    'The Task does not have the expected Status');
                Assert.isTrue(taskSubjectCheck.contains(jobTask.Subject), 'The Task does not have an expected Subject');
                taskSubjectCheck.remove(jobTask.Subject);
                Assert.areEqual(jobTask.WhatId, whatId, 'The WhatId on the Task is not correct');
            }
        }
    }

    @isTest
    static void generateStatusTasks_emptyJobs() {

        Status_Task_Manager__mdt stm = TestDataFactory.getStatusTaskManagerForTest(OBJECT_KEYWORD, STATUS_KEYWORD);
        List<Job_Application__c> emptyJobList = new List<Job_Application__c>();
        Boolean exceptionThrown = false;

        Test.startTest();
        StatusTMJobAppAccepted stmTaskGenerator = new StatusTMJobAppAccepted();
        try {
            List<Task> statusTasks = stmTaskGenerator.generateStatusTasks(emptyJobList, stm);
        } catch (IllegalArgumentException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'An Illegal Arugment Exception should have been thrown');
    }

    @isTest
    static void generateStatusTasks_emptyStatusTaskManager() {

        Status_Task_Manager__mdt stm = new Status_Task_Manager__mdt();
        Map<Id, Account> testAccountsById = TestDataFactory.generateAccountsById(1);
        List<Job_Application__c> testJobApps = TestDataFactory.generateJobAppsOnAccount(true, testAccountsById.values());
        Boolean exceptionThrown = false;

        Test.startTest();
        StatusTMJobAppAccepted stmTaskGenerator = new StatusTMJobAppAccepted();
        try {
            List<Task> statusTasks = stmTaskGenerator.generateStatusTasks(testJobApps, stm);
        } catch (Exception e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'An Exception should have been thrown');
    }
}