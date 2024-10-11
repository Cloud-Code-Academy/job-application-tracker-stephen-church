@isTest
public with sharing class JobApplicationHelperTest {

    @TestSetup
    static void setupTestData(){
        Map<Id, Account> testAccounts = TestDataFactory.generateAccountsById(200);
    }

    @isTest
    static void generateJobApplicationsFromSelectedJobs() {

        // Create Account records for selected Jobs since they will be created by this point in the process
        List<Map<String, Object>> selectedJobs = TestDataFactory.generateLwcJobSelectionResponse(200);
        List<Account> accountsForSelectedJobs = new List<Account>();
        Boolean hasSetNameWithId = false;
        for (Map<String, Object> job : selectedJobs){
            Account acc = new Account();
            if (hasSetNameWithId) {
                String companyNameAsAccountName = String.valueOf(job.get('company'));
                acc.Name = companyNameAsAccountName;
            } else {
                String idAsAccountName = String.valueOf(job.get('id'));
                acc.Name = idAsAccountName;
                hasSetNameWithId = true;
            }
            accountsForSelectedJobs.add(acc);
        }
        insert accountsForSelectedJobs;

        // Get the Accounts by Company Name Map
        Map<String, Account> accountsByCompanyName = new Map<String, Account>();
        for (Account acc : accountsForSelectedJobs) {
            accountsByCompanyName.put(acc.Name, acc);
        }

        // Get the field mappings to pass to the method
        Callout_Configuration__mdt joobleCallout = Callout_Configuration__mdt.getInstance('Jooble_Post');
        List<Integration_Field_Mapping__mdt> mappings = [
            SELECT Id, DeveloperName, Salesforce_Object__c, Field_API_Name__c, Id_Field__c, Key__c, Callout_Configuration__c
            FROM Integration_Field_Mapping__mdt
            WHERE Callout_Configuration__c = :joobleCallout.Id
        ];
        String accountNameMapping = null;
        for (Integration_Field_Mapping__mdt mapping : mappings) {
            if (mapping.Salesforce_Object__c == 'Account' && mapping.Field_API_Name__c == 'Name') {
                accountNameMapping = mapping.Key__c;
                break;
            }
        }

        Test.startTest();
        List<Job_Application__c> jobApps = JobApplicationHelper.generateJobApplicationsFromSelectedJobs(
            selectedJobs, 
            accountNameMapping, 
            accountsByCompanyName,
            mappings
        );
        Test.stopTest();

        Assert.areEqual(selectedJobs.size(), jobApps.size(), 'The expected count of Job Applications was not generated');
        // Build a Map of Jooble Id by Job Application so that we can assert the fields were set correctly
        Map<String, Job_Application__c> jobAppByJoobleId = new Map<String, Job_Application__c>();
        for (Job_Application__c jobApp : jobApps) {
            jobAppByJoobleId.put(jobApp.Job_Posting_Id__c, jobApp);
        }

        for(Map<String, Object> job : selectedJobs) {
            Job_Application__c jobApp = jobAppByJoobleId.get(String.valueOf(job.get('id')));
            Assert.areEqual(job.get('id'), jobApp.Job_Posting_Id__c, 'The Job Posting Id field is not set correctly');
            Assert.areEqual(job.get('link'), jobApp.Job_Posting__c, 'The Job Posting field is not set correctly');
            Assert.areEqual(job.get('location'), jobApp.Job_Location__c, 'The Job Location field is not set correctly');
            Assert.areEqual(job.get('salary'), jobApp.Salary_From_Job_Board__c, 'The Salary From Job Board field is not set correctly');
            Assert.areEqual(job.get('title'), jobApp.Job_Title__c, 'The Job Title field is not set correctly');
            Assert.areEqual(job.get('type'), jobApp.Job_Type__c, 'The Job Type field is not set correctly');
        }
    }

    /* Since there is an interface and multiple classes that handle testing and converting salary strings, this is a simple test
    on one string to make sure all of the behaviors that create instances of the classes executes as expected*/
    @isTest
    static void setStringSalaryToDecimalSalary() {

        List<Account> testAccounts = [SELECT Id FROM Account LIMIT 200];
        Set<Id> accountIds = new Set<Id>();
        for(Account acc : testAccounts) {
            accountIds.add(acc.Id);
        }
        List<Job_Application__c> testJobApps = TestDataFactory.generateJobAppsOnAccount(false, testAccounts);
        for (Job_Application__c jobApp : testJobApps) {
            jobApp.Salary_From_Job_Board__c = '$100k';
        }

        Test.startTest();
        insert testJobApps;
        Test.stopTest();

        List<Job_Application__c> insertedJobApps = [SELECT Id, Salary__c FROM Job_Application__c WHERE Company__c IN :accountIds];
        for (Job_Application__c jobApp : insertedJobApps) {
            Assert.areEqual(100000, jobApp.Salary__c, 'The Salary should be 100000');
        }
    }

    @isTest
    static void setStringSalaryToDecimalSalary_noSalaryToConvert() {

        List<Account> testAccounts = [SELECT Id FROM Account LIMIT 200];
        Set<Id> accountIds = new Set<Id>();
        for(Account acc : testAccounts) {
            accountIds.add(acc.Id);
        }
        List<Job_Application__c> testJobApps = TestDataFactory.generateJobAppsOnAccount(false, testAccounts);

        Test.startTest();
        insert testJobApps;
        Test.stopTest();

        List<Job_Application__c> insertedJobApps = [SELECT Id, Salary__c FROM Job_Application__c WHERE Company__c IN :accountIds];
        for (Job_Application__c jobApp : insertedJobApps) {
            Assert.isNull(jobApp.Salary__c, 'The Salary should be null');
        }
    }

    /* A lot of the heavy lifing for testing tax calculations is done via the Federal Withholding Helper. To not repeat
    logic already tested, this will just insert / update records and validate that the take home amounts are correct based on
    the taxes. Actually curious what the best practice is here - this type of approach or "re-testing" calculations here because
    they call helper methods that do them*/
    @isTest 
    static void calculateTaxesAndTakeHome_insert() {

        // Generate Job Apps and put a Salary on them
        List<Account> testAccounts = [SELECT Id FROM Account LIMIT 200];
        Set<Id> accountIds = new Set<Id>();
        for(Account acc : testAccounts) {
            accountIds.add(acc.Id);
        }
        List<Job_Application__c> testJobApps = TestDataFactory.generateJobAppsOnAccount(false, testAccounts);
        for (Job_Application__c jobApp : testJobApps) {
            jobApp.Salary__c = 100000;
        }

        Test.startTest();
        insert testJobApps;
        Test.stopTest();

        List<Job_Application__c> insertedJobApps = [
            SELECT 
                Id, 
                Salary__c, 
                Estimated_Annual_Federal_Tax__c, 
                Estimated_Annual_Medicare_Tax__c, 
                Estimated_Annual_Social_Security_Tax__c,
                Estimated_Annual_Take_Home_Pay__c,
                Estimated_Monthly_Take_Home_Pay__c
            FROM Job_Application__c 
            WHERE Company__c IN :accountIds
        ];
        for (Job_Application__c jobApp : insertedJobApps) {
            Assert.isTrue(jobApp.Estimated_Annual_Federal_Tax__c > 0, 'There should be an Annual Federal Tax');
            Assert.isTrue(jobApp.Estimated_Annual_Medicare_Tax__c > 0, 'There should be an Annual Medicare Tax');
            Assert.isTrue(jobApp.Estimated_Annual_Social_Security_Tax__c > 0, 'There should be an Annual Social Security Tax');
            Assert.isTrue(jobApp.Estimated_Annual_Take_Home_Pay__c > 0, 'There should be an Annual Tax Home Pay');
            Assert.isTrue(jobApp.Estimated_Monthly_Take_Home_Pay__c > 0, 'There should be a Monthly Take Home Pay');
            Assert.areEqual(jobApp.Salary__c - (jobApp.Estimated_Annual_Federal_Tax__c + jobApp.Estimated_Annual_Medicare_Tax__c + jobApp.Estimated_Annual_Social_Security_Tax__c),
                jobApp.Estimated_Annual_Take_Home_Pay__c, 'The Annual Take Home Pay is not correct based on the Salary and taxes');
            Assert.areEqual(jobApp.Estimated_Annual_Take_Home_Pay__c / 12, jobApp.Estimated_Monthly_Take_Home_Pay__c,
            'The Monthly Take Home Pay is not correct based on the Annual Take Home Pay');
        }
    }

    @isTest 
    static void calculateTaxesAndTakeHome_insert_nullAndZeroes() {

        // Generate Job Apps and put a Salary on them
        List<Account> testAccounts = [SELECT Id FROM Account LIMIT 200];
        Set<Id> accountIds = new Set<Id>();
        for(Account acc : testAccounts) {
            accountIds.add(acc.Id);
        }
        List<Job_Application__c> testJobApps = TestDataFactory.generateJobAppsOnAccount(false, testAccounts);

        // Salary should be null by default. See 100 to have 0, so we test both scenarios
        Integer loopCount = 1;
        for (Job_Application__c jobApp : testJobApps) {
            jobApp.Salary__c = 0;
            if (loopCount == 100) {
                break;
            } else {
                loopCount += 1;
            }
        }

        Test.startTest();
        insert testJobApps;
        Test.stopTest();

        List<Job_Application__c> insertedJobApps = [
            SELECT 
                Id, 
                Salary__c, 
                Estimated_Annual_Federal_Tax__c, 
                Estimated_Annual_Medicare_Tax__c, 
                Estimated_Annual_Social_Security_Tax__c,
                Estimated_Annual_Take_Home_Pay__c,
                Estimated_Monthly_Take_Home_Pay__c
            FROM Job_Application__c 
            WHERE Company__c IN :accountIds
        ];
        for (Job_Application__c jobApp : insertedJobApps) {
            Assert.areEqual(0, jobApp.Estimated_Annual_Federal_Tax__c, 'The Annual Federal Tax should be 0');
            Assert.areEqual(0, jobApp.Estimated_Annual_Medicare_Tax__c, 'The Annual Medicare Tax should be 0');
            Assert.areEqual(0, jobApp.Estimated_Annual_Social_Security_Tax__c, 'The Annual Social Security Tax should be 0');
            Assert.areEqual(0, jobApp.Estimated_Annual_Take_Home_Pay__c, 'The Annual Take Home Pay should be 0');
            Assert.areEqual(0, jobApp.Estimated_Monthly_Take_Home_Pay__c, 'The Monthly Take Home Pay should be 0');
        }
    }

    @isTest 
    static void calculateTaxesAndTakeHome_update() {

        // Generate Job Apps and put a Salary on them
        List<Account> testAccounts = [SELECT Id FROM Account LIMIT 200];
        // Insert Job Apps with no salary information, meaning none of the tax / take home fields populated
        List<Job_Application__c> testJobApps = TestDataFactory.generateJobAppsOnAccount(true, testAccounts);
        Set<Id> jobAppIds = new Set<Id>();
        for (Job_Application__c jobApp : testJobApps) {
            jobApp.Salary__c = 100000;
            jobAppIds.add(jobApp.Id);
        }

        Test.startTest();
        update testJobApps;
        Test.stopTest();

        List<Job_Application__c> updatedJobApps = [
            SELECT 
                Id, 
                Salary__c, 
                Estimated_Annual_Federal_Tax__c, 
                Estimated_Annual_Medicare_Tax__c, 
                Estimated_Annual_Social_Security_Tax__c,
                Estimated_Annual_Take_Home_Pay__c,
                Estimated_Monthly_Take_Home_Pay__c
            FROM Job_Application__c 
            WHERE Id IN :jobAppIds
        ];
        for (Job_Application__c jobApp : updatedJobApps) {
            Assert.isTrue(jobApp.Estimated_Annual_Federal_Tax__c > 0, 'There should be an Annual Federal Tax');
            Assert.isTrue(jobApp.Estimated_Annual_Medicare_Tax__c > 0, 'There should be an Annual Medicare Tax');
            Assert.isTrue(jobApp.Estimated_Annual_Social_Security_Tax__c > 0, 'There should be an Annual Social Security Tax');
            Assert.isTrue(jobApp.Estimated_Annual_Take_Home_Pay__c > 0, 'There should be an Annual Tax Home Pay');
            Assert.isTrue(jobApp.Estimated_Monthly_Take_Home_Pay__c > 0, 'There should be a Monthly Take Home Pay');
            Assert.areEqual(jobApp.Salary__c - (jobApp.Estimated_Annual_Federal_Tax__c + jobApp.Estimated_Annual_Medicare_Tax__c + jobApp.Estimated_Annual_Social_Security_Tax__c),
                jobApp.Estimated_Annual_Take_Home_Pay__c, 'The Annual Take Home Pay is not correct based on the Salary and taxes');
            Assert.areEqual(jobApp.Estimated_Annual_Take_Home_Pay__c / 12, jobApp.Estimated_Monthly_Take_Home_Pay__c,
            'The Monthly Take Home Pay is not correct based on the Annual Take Home Pay');
        }
    }

    @isTest 
    static void calculateTaxesAndTakeHome_update_nullAndZeroes() {

        // Generate Job Apps and put a Salary on them that we will eventually zero out on the update
        List<Account> testAccounts = [SELECT Id FROM Account LIMIT 200];
        List<Job_Application__c> testJobApps = TestDataFactory.generateJobAppsOnAccount(false, testAccounts);
        for (Job_Application__c jobApp : testJobApps) {
            jobApp.Salary__c = 100000;
        }
        insert testJobApps;
        Set<Id> jobAppIds = new Set<Id>();
        for(Job_Application__c jobApp : testJobApps) {
            jobAppIds.add(jobApp.Id);
        }

        // Set half of the Job Apps to a null Salary and half to 0 to test the impact on taxes / take home
        Integer loopCount = 1;
        for (Job_Application__c jobApp : testJobApps) {
            if (loopCount <= 100) {
                jobApp.Salary__c = null;
            } else {
                jobApp.Salary__c = 0;
            }
            loopCount += 1;
        }

        Test.startTest();
        update testJobApps;
        Test.stopTest();

        List<Job_Application__c> updatedJobApps = [
            SELECT 
                Id, 
                Salary__c, 
                Estimated_Annual_Federal_Tax__c, 
                Estimated_Annual_Medicare_Tax__c, 
                Estimated_Annual_Social_Security_Tax__c,
                Estimated_Annual_Take_Home_Pay__c,
                Estimated_Monthly_Take_Home_Pay__c
            FROM Job_Application__c 
            WHERE Id IN :jobAppIds
        ];
        for (Job_Application__c jobApp : updatedJobApps) {
            Assert.areEqual(0, jobApp.Estimated_Annual_Federal_Tax__c, 'The Annual Federal Tax should be 0');
            Assert.areEqual(0, jobApp.Estimated_Annual_Medicare_Tax__c, 'The Annual Medicare Tax should be 0');
            Assert.areEqual(0, jobApp.Estimated_Annual_Social_Security_Tax__c, 'The Annual Social Security Tax should be 0');
            Assert.areEqual(0, jobApp.Estimated_Annual_Take_Home_Pay__c, 'The Annual Take Home Pay should be 0');
            Assert.areEqual(0, jobApp.Estimated_Monthly_Take_Home_Pay__c, 'The Monthly Take Home Pay should be 0');
        }
    }

    @isTest
    static void blockStatusChangesWhenOpenTasks() {

        // Get and Loop Custom Metadata to confirm a Status that generates Tasks. I couldn't query and avoid loop as I can't filter on long text areas in CMDT queries.
        List<Status_Task_Manager__mdt> statusConfigs = [
            SELECT Id, Status__c, Valid_Next_Status__c
            FROM Status_Task_Manager__mdt
            WHERE Active__c = true
            AND Process__c = 'Job Application'
            AND Task_Generation_Class__c != null 
            ORDER BY Order__c
        ];

        // Find one that has a valid next status so I can test changing the status
        Status_Task_Manager__mdt stmToSetAsStatus = new Status_Task_Manager__mdt();
        for (Status_Task_Manager__mdt stm : statusConfigs) {
            if (stm.Valid_Next_Status__c != null) {
                stmToSetAsStatus = stm;
                break;
            }
        }

        // Generate Job Apps and set the Status to the Status above that generates Tasks
        List<Account> testAccounts = [SELECT Id FROM Account LIMIT 200];
        List<Job_Application__c> testJobApps = TestDataFactory.generateJobAppsOnAccount(false, testAccounts);
        for (Job_Application__c jobApp : testJobApps) {
            jobApp.Application_Status__c = stmToSetAsStatus.Status__c;
        }

        insert testJobApps;

        // Split the valid next statuses into a List so we can set a valid next Status and set it on the Job Apps
        List<String> splitNextStatuses = stmToSetAsStatus.Valid_Next_Status__c.split('\\|\\|');
        String nextStatus = splitNextStatuses.get(0).trim();
        for (Job_Application__c jobApp : testJobApps) {
            jobApp.Application_Status__c = nextStatus;
        }

        Boolean exceptionThrown = false;
        String fullExceptionMessageReceived = null;

        Test.startTest();
        try {
            update testJobApps;
        } catch (DmlException e) {
            exceptionThrown = true;
            fullExceptionMessageReceived = e.getMessage();
        }
        Test.stopTest();

        // Validate an exception was thrown
        Assert.isTrue(exceptionThrown, 'A DML Exception should have been thrown');
        Assert.isTrue(fullExceptionMessageReceived.contains(JobApplicationHelper.OPEN_TASK_ERROR), 'The expected exception message was not received');    
    }

    @isTest
    static void blockStatusChangesWhenOpenTasks_irrelevantChange() {

        // Get and Loop Custom Metadata to confirm a Status that generates Tasks. I couldn't query and avoid loop as I can't filter on long text areas in CMDT queries.
        Status_Task_Manager__mdt statusConfig = [
            SELECT Id, Status__c
            FROM Status_Task_Manager__mdt
            WHERE Active__c = true
            AND Process__c = 'Job Application'
            AND Task_Generation_Class__c != null 
            ORDER BY Order__c
            LIMIT 1
        ];

        // Generate Job Apps and set the Status to the Status above that generates Tasks
        List<Account> testAccounts = [SELECT Id FROM Account LIMIT 200];
        List<Job_Application__c> testJobApps = TestDataFactory.generateJobAppsOnAccount(false, testAccounts);
        for (Job_Application__c jobApp : testJobApps) {
            jobApp.Application_Status__c = statusConfig.Status__c;
        }

        insert testJobApps;

        // Change a non status field on the Job App to confirm this logic doesn't interfere with irrelevant changes
        Set<Id> jobAppIds = new Set<Id>();
        for (Job_Application__c jobApp : testJobApps) {
            jobApp.Job_Title__c = 'Test Title';
        }

        Test.startTest();
        update testJobApps;
        Test.stopTest();

        // Query the Job Apps and make sure the title was changed and that they also have Tasks
        List<Job_Application__c> updatedJobApps = [
            SELECT Id, Job_Title__c,
                (SELECT Id, IsClosed FROM Tasks WHERE WhatId IN :jobAppIds AND IsClosed = FALSE)
            FROM Job_Application__c
            WHERE Id IN :jobAppIds
        ];
        for (Job_Application__c jobApp : updatedJobApps) {
            Assert.isFalse(jobApp.Tasks.isEmpty(), 'The Job App should have open Tasks for the test to be valid');
            Assert.areEqual('Test Title', jobApp.Job_Title__c, 'The Title was not updated as expected');
        }
    }

    @isTest
    static void blockStatusChangesWhenOpenTasks_closedTasksDontBlock() {

        // Get and Loop Custom Metadata to confirm a Status that generates Tasks. I couldn't query and avoid loop as I can't filter on long text areas in CMDT queries.
        List<Status_Task_Manager__mdt> statusConfigs = [
            SELECT Id, Status__c, Valid_Next_Status__c
            FROM Status_Task_Manager__mdt
            WHERE Active__c = true
            AND Process__c = 'Job Application'
            AND Task_Generation_Class__c != null 
            ORDER BY Order__c
        ];

        // Find one that has a valid next status so I can test changing the status
        Status_Task_Manager__mdt stmToSetAsStatus = new Status_Task_Manager__mdt();
        for (Status_Task_Manager__mdt stm : statusConfigs) {
            if (stm.Valid_Next_Status__c != null) {
                stmToSetAsStatus = stm;
                break;
            }
        }

        // Generate Job Apps and set the Status to the Status above that generates Tasks
        List<Account> testAccounts = [SELECT Id FROM Account LIMIT 200];
        List<Job_Application__c> testJobApps = TestDataFactory.generateJobAppsOnAccount(false, testAccounts);
        for (Job_Application__c jobApp : testJobApps) {
            jobApp.Application_Status__c = stmToSetAsStatus.Status__c;
        }

        insert testJobApps;

        // Get the Tasks on the Job Apps and close them
        Set<Id> jobAppIds = new Set<Id>();
        for (Job_Application__c jobApp : testJobApps) {
            jobAppIds.add(jobApp.Id);
        }
        List<Task> tasksOnJobApps = [SELECT Id, Status, IsClosed FROM Task WHERE WhatId IN :jobAppIds];
        for (Task taskToClose : tasksOnJobApps) {
            taskToClose.Status = 'Completed';
        }
        update tasksOnJobApps;

        // Split the valid next statuses into a List so we can set a valid next Status and set it on the Job Apps
        List<String> splitNextStatuses = stmToSetAsStatus.Valid_Next_Status__c.split('\\|\\|');
        String nextStatus = splitNextStatuses.get(0).trim();
        for (Job_Application__c jobApp : testJobApps) {
            jobApp.Application_Status__c = nextStatus;
        }

        Test.startTest();
        update testJobApps;
        Test.stopTest();

        // Query the Job Apps and make sure the Status was changed
        List<Job_Application__c> updatedJobApps = [
            SELECT Id, Application_Status__c
            FROM Job_Application__c
            WHERE Id IN :jobAppIds
        ];
        for (Job_Application__c jobApp : updatedJobApps) {
            Assert.areEqual(nextStatus, jobApp.Application_Status__c, 'The expected Status was not set on the Job Application');
        }
    }

    @isTest 
    static void blockUnauthorizedStatusChanges_hasValidNextStatuses_allowed() {
    
        // Get and Loop Custom Metadata to so I can find a record that has specified next statuses that are allowed
        List<Status_Task_Manager__mdt> statusConfigs = [
            SELECT Id, Status__c, Valid_Next_Status__c
            FROM Status_Task_Manager__mdt
            WHERE Active__c = true
            AND Process__c = 'Job Application'
            ORDER BY Order__c
        ];

        // Find one that has a valid next status so I can test changing the status
        Status_Task_Manager__mdt stmToSetAsStatus = new Status_Task_Manager__mdt();
        for (Status_Task_Manager__mdt stm : statusConfigs) {
            if (stm.Valid_Next_Status__c != null) {
                stmToSetAsStatus = stm;
                break;
            }
        }

        // Generate Job Apps and set the Status to the Status above that has valid next statuses to test
        List<Account> testAccounts = [SELECT Id FROM Account LIMIT 200];
        List<Job_Application__c> testJobApps = TestDataFactory.generateJobAppsOnAccount(false, testAccounts);
        for (Job_Application__c jobApp : testJobApps) {
            jobApp.Application_Status__c = stmToSetAsStatus.Status__c;
        }

        insert testJobApps;

        // Get the Tasks on that would likely have been generated on the status being set and close them
        Set<Id> jobAppIds = new Set<Id>();
        for (Job_Application__c jobApp : testJobApps) {
            jobAppIds.add(jobApp.Id);
        }
        List<Task> tasksOnJobApps = [SELECT Id, Status, IsClosed FROM Task WHERE WhatId IN :jobAppIds];
        for (Task taskToClose : tasksOnJobApps) {
            taskToClose.Status = 'Completed';
        }
        if (!tasksOnJobApps.isEmpty()) {
            update tasksOnJobApps;
        }

        // Split the valid next statuses into a List so we can set a valid next Status and set it on the Job Apps
        List<String> splitNextStatuses = stmToSetAsStatus.Valid_Next_Status__c.split('\\|\\|');
        String nextStatus = splitNextStatuses.get(0).trim();
        for (Job_Application__c jobApp : testJobApps) {
            jobApp.Application_Status__c = nextStatus;
        }

        Test.startTest();
        update testJobApps;
        Test.stopTest();

        // Query the Job Apps and validate that they have the valid next status
        List<Job_Application__c> updatedJobApps = [SELECT Id, Application_Status__c FROM Job_Application__c WHERE Id IN :jobAppIds];
        for (Job_Application__c jobApp : updatedJobApps) {
            Assert.areEqual(nextStatus, jobApp.Application_Status__c);
        }
    }

    @isTest 
    static void blockUnauthorizedStatusChanges_hasValidNextStatuses_notAllowed() {
    
        // Get and Loop Custom Metadata to so I can find a record that has specified next statuses that are allowed
        List<Status_Task_Manager__mdt> statusConfigs = [
            SELECT Id, Status__c, Valid_Next_Status__c
            FROM Status_Task_Manager__mdt
            WHERE Active__c = true
            AND Process__c = 'Job Application'
            ORDER BY Order__c
        ];

        // Find one that has a valid next status so I can test changing the status
        Status_Task_Manager__mdt stmToSetAsStatus = new Status_Task_Manager__mdt();
        for (Status_Task_Manager__mdt stm : statusConfigs) {
            if (stm.Valid_Next_Status__c != null) {
                stmToSetAsStatus = stm;
                break;
            }
        }

        // Generate Job Apps and set the Status to the Status above that has valid next statuses to test
        List<Account> testAccounts = [SELECT Id FROM Account LIMIT 200];
        List<Job_Application__c> testJobApps = TestDataFactory.generateJobAppsOnAccount(false, testAccounts);
        for (Job_Application__c jobApp : testJobApps) {
            jobApp.Application_Status__c = stmToSetAsStatus.Status__c;
        }

        insert testJobApps;

        // Get the Tasks on that would likely have been generated on the status being set and close them
        Set<Id> jobAppIds = new Set<Id>();
        for (Job_Application__c jobApp : testJobApps) {
            jobAppIds.add(jobApp.Id);
        }
        List<Task> tasksOnJobApps = [SELECT Id, Status, IsClosed FROM Task WHERE WhatId IN :jobAppIds];
        for (Task taskToClose : tasksOnJobApps) {
            taskToClose.Status = 'Completed';
        }
        if (!tasksOnJobApps.isEmpty()) {
            update tasksOnJobApps;
        }

        // Loop the status configs to find an invalid status I shouldn't be allowed to change to and set this on the Job Apps
        String invalidNextStatus = null;
        for (Status_Task_Manager__mdt stm : statusConfigs) {
            if (stm.Id != stmToSetAsStatus.Id && !stmToSetAsStatus.Valid_Next_Status__c.contains(stm.Status__c)) {
                invalidNextStatus = stm.Status__c;
            }
        }
        for (Job_Application__c jobApp : testJobApps) {
            jobApp.Application_Status__c = invalidNextStatus;
        }

        Boolean exceptionThrown = false;
        String fullExceptionMessage = null;

        Test.startTest();
        try {
            update testJobApps;
        } catch (DmlException e) {
            exceptionThrown = true;
            fullExceptionMessage = e.getMessage();
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'A DML Exception should have been thrown');
        Assert.isTrue(fullExceptionMessage.contains(JobApplicationHelper.INVALID_STATUS_CHANGE_START), 'The error did not contain the expected message');
    }

    @isTest 
    static void blockUnauthorizedStatusChanges_hasValidNextStatuses_irrelevantChange() {
    
        // Get and Loop Custom Metadata to so I can find a record that has specified next statuses
        List<Status_Task_Manager__mdt> statusConfigs = [
            SELECT Id, Status__c, Valid_Next_Status__c
            FROM Status_Task_Manager__mdt
            WHERE Active__c = true
            AND Process__c = 'Job Application'
            ORDER BY Order__c
        ];

        // Find one that has a valid next status so I can test changing another field
        Status_Task_Manager__mdt stmToSetAsStatus = new Status_Task_Manager__mdt();
        for (Status_Task_Manager__mdt stm : statusConfigs) {
            if (stm.Valid_Next_Status__c != null) {
                stmToSetAsStatus = stm;
                break;
            }
        }

        // Generate Job Apps and set the Status to the Status above
        List<Account> testAccounts = [SELECT Id FROM Account LIMIT 200];
        List<Job_Application__c> testJobApps = TestDataFactory.generateJobAppsOnAccount(false, testAccounts);
        for (Job_Application__c jobApp : testJobApps) {
            jobApp.Application_Status__c = stmToSetAsStatus.Status__c;
        }

        insert testJobApps;

        // Change an irrelevant field to confirm no issues arise
        Set<Id> jobAppIds = new Set<Id>();
        for (Job_Application__c jobApp : testJobApps) {
            jobApp.Job_Title__c = 'Test Title';
            jobAppIds.add(jobApp.Id);
        }

        Test.startTest();
        update testJobApps;
        Test.stopTest();

        // Query the Job Apps and make sure the title was changed and that they also have Tasks
        List<Job_Application__c> updatedJobApps = [
            SELECT Id, Job_Title__c
            FROM Job_Application__c
            WHERE Id IN :jobAppIds
        ];
        for (Job_Application__c jobApp : updatedJobApps) {
            Assert.areEqual('Test Title', jobApp.Job_Title__c, 'The Title was not updated as expected');
        }
    }

    @isTest 
    static void blockUnauthorizedStatusChanges_hasNoNextStatuses_notAllowed() {
    
        // Get and Loop Custom Metadata to so I can find a record that has no allowed next statuses
        List<Status_Task_Manager__mdt> statusConfigs = [
            SELECT Id, Status__c, Valid_Next_Status__c
            FROM Status_Task_Manager__mdt
            WHERE Active__c = true
            AND Process__c = 'Job Application'
            ORDER BY Order__c
        ];

        // Find one that has no valid next status so I can test changing the status
        Status_Task_Manager__mdt stmToSetAsStatus = new Status_Task_Manager__mdt();
        for (Status_Task_Manager__mdt stm : statusConfigs) {
            if (stm.Valid_Next_Status__c == null) {
                stmToSetAsStatus = stm;
                break;
            }
        }

        // Generate Job Apps and set the Status to the Status above that has valid next statuses to test
        List<Account> testAccounts = [SELECT Id FROM Account LIMIT 200];
        List<Job_Application__c> testJobApps = TestDataFactory.generateJobAppsOnAccount(false, testAccounts);
        for (Job_Application__c jobApp : testJobApps) {
            jobApp.Application_Status__c = stmToSetAsStatus.Status__c;
        }

        insert testJobApps;

        // Get the Tasks on that would likely have been generated on the status being set and close them so they don't interfere
        Set<Id> jobAppIds = new Set<Id>();
        for (Job_Application__c jobApp : testJobApps) {
            jobAppIds.add(jobApp.Id);
        }
        List<Task> tasksOnJobApps = [SELECT Id, Status, IsClosed FROM Task WHERE WhatId IN :jobAppIds];
        for (Task taskToClose : tasksOnJobApps) {
            taskToClose.Status = 'Completed';
        }
        if (!tasksOnJobApps.isEmpty()) {
            update tasksOnJobApps;
        }

        // Loop the status configs to find any other status I can set and then set it on the Job App
        String invalidNextStatus = null;
        for (Status_Task_Manager__mdt stm : statusConfigs) {
            if (stm.Id != stmToSetAsStatus.Id) {
                invalidNextStatus = stm.Status__c;
            }
        }
        for (Job_Application__c jobApp : testJobApps) {
            jobApp.Application_Status__c = invalidNextStatus;
        }

        Boolean exceptionThrown = false;
        String fullExceptionMessage = null;

        Test.startTest();
        try {
            update testJobApps;
        } catch (DmlException e) {
            exceptionThrown = true;
            fullExceptionMessage = e.getMessage();
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'A DML Exception should have been thrown');
        Assert.isTrue(fullExceptionMessage.contains(JobApplicationHelper.INVALID_STATUS_CHANGE_START), 'The error did not contain the expected message');
    }

    @isTest 
    static void blockUnauthorizedStatusChanges_hasNoNextStatuses_irrelevantChange() {
    
        // Get and Loop Custom Metadata to so I can find a record that has no allowed next statuses
        List<Status_Task_Manager__mdt> statusConfigs = [
            SELECT Id, Status__c, Valid_Next_Status__c
            FROM Status_Task_Manager__mdt
            WHERE Active__c = true
            AND Process__c = 'Job Application'
            ORDER BY Order__c
        ];

        // Find one that has no valid next status so I can test changing the status
        Status_Task_Manager__mdt stmToSetAsStatus = new Status_Task_Manager__mdt();
        for (Status_Task_Manager__mdt stm : statusConfigs) {
            if (stm.Valid_Next_Status__c == null) {
                stmToSetAsStatus = stm;
                break;
            }
        }

        // Generate Job Apps and set the Status to the Status above
        List<Account> testAccounts = [SELECT Id FROM Account LIMIT 200];
        List<Job_Application__c> testJobApps = TestDataFactory.generateJobAppsOnAccount(false, testAccounts);
        for (Job_Application__c jobApp : testJobApps) {
            jobApp.Application_Status__c = stmToSetAsStatus.Status__c;
        }

        insert testJobApps;

        // Change an irrelevant field to confirm no issues arise
        Set<Id> jobAppIds = new Set<Id>();
        for (Job_Application__c jobApp : testJobApps) {
            jobApp.Job_Title__c = 'Test Title';
            jobAppIds.add(jobApp.Id);
        }

        Test.startTest();
        update testJobApps;
        Test.stopTest();

        // Query the Job Apps and make sure the title was changed and that they also have Tasks
        List<Job_Application__c> updatedJobApps = [
            SELECT Id, Job_Title__c
            FROM Job_Application__c
            WHERE Id IN :jobAppIds
        ];
        for (Job_Application__c jobApp : updatedJobApps) {
            Assert.areEqual('Test Title', jobApp.Job_Title__c, 'The Title was not updated as expected');
        }
    }

    @isTest
    static void setSubmissionDateWhenStatusIsApplied() {

        // Get and Loop Custom Metadata to so I can find a status that lets me change to Applied
        List<Status_Task_Manager__mdt> statusConfigs = [
            SELECT Id, Status__c, Valid_Next_Status__c
            FROM Status_Task_Manager__mdt
            WHERE Active__c = true
            AND Process__c = 'Job Application'
            ORDER BY Order__c
        ];

        // Find one that will let me change to applied and use that as the status to set on insert
        Status_Task_Manager__mdt stmToSetAsStatus = new Status_Task_Manager__mdt();
        for (Status_Task_Manager__mdt stm : statusConfigs) {
            if (stm.Valid_Next_Status__c != null && stm.Valid_Next_Status__c.contains('Applied')) {
                stmToSetAsStatus = stm;
                break;
            }
        }

        // Generate Job Apps and set the Status as the one above
        List<Account> testAccounts = [SELECT Id FROM Account LIMIT 200];
        List<Job_Application__c> testJobApps = TestDataFactory.generateJobAppsOnAccount(false, testAccounts);
        for (Job_Application__c jobApp : testJobApps) {
            jobApp.Application_Status__c = stmToSetAsStatus.Status__c;
        }
        insert testJobApps;

        // Extract the Ids and set the Status to Applied
        Set<Id> jobAppIds = new Set<Id>();
        for (Job_Application__c jobApp : testJobApps) {
            jobApp.Application_Status__c = 'Applied';
            jobAppIds.add(jobApp.Id);
        }

        // Get the Tasks on that may have been generated on the status being set and close them so the validations don't interfere
        List<Task> tasksOnJobApps = [SELECT Id, Status, IsClosed FROM Task WHERE WhatId IN :jobAppIds];
        for (Task taskToClose : tasksOnJobApps) {
            taskToClose.Status = 'Completed';
        }
        if (!tasksOnJobApps.isEmpty()) {
            update tasksOnJobApps;
        }

        Test.startTest();
        update testJobApps;
        Test.stopTest();
        
        // Assert the Submission Date is today
        List<Job_Application__c> updatedJobApps = [SELECT Id, Application_Submission_Date__c FROM Job_Application__c WHERE Id IN :jobAppIds];
        for (Job_Application__c jobApp : updatedJobApps) {
            Assert.areEqual(Date.today(), jobApp.Application_Submission_Date__c);
        }
    }

    /* Since all the classes that implement this interface have their own test classes testing the task details, this test method is
    really to just ensure no errors occur when handling a status that should or should not invoke tasks*/
    @isTest 
    static void generateTasksForStatus() {

        // Get and Loop Custom Metadata to so I can find a status that does and does not invoke tasks
        List<Status_Task_Manager__mdt> statusConfigs = [
            SELECT Id, Status__c, Task_Generation_Class__c
            FROM Status_Task_Manager__mdt
            WHERE Active__c = true
            AND Process__c = 'Job Application'
            ORDER BY Order__c
        ];
        String statusToInvokeTasks = null;
        String statusToNotInvokeTasks = null;
        for (Status_Task_Manager__mdt stm : statusConfigs) {
            if (statusToInvokeTasks != null && statusToNotInvokeTasks != null) {
                break;
            }
            else if (statusToInvokeTasks == null && stm.Task_Generation_Class__c != null) {
                statusToInvokeTasks = stm.Status__c;
            } else if (statusToNotInvokeTasks == null && stm.Task_Generation_Class__c == null) {
                statusToNotInvokeTasks = stm.Status__c;
            }
        }
        // Generate Job Apps and set the Status as the one above
        List<Account> testAccounts = [SELECT Id FROM Account LIMIT 200];
        List<Job_Application__c> testJobApps = TestDataFactory.generateJobAppsOnAccount(false, testAccounts);
        Integer i = 1;
        for (Job_Application__c jobApp : testJobApps) {
            if (i <= 100) {
                jobApp.Application_Status__c = statusToInvokeTasks;
            } else {
                jobApp.Application_Status__c = statusToNotInvokeTasks;
            }
        }

        Test.startTest();
        insert testJobApps;
        Test.stopTest();

        Set<Id> jobAppIds = new Set<Id>();
        for (Job_Application__c jobApp : testJobApps) {
            jobAppIds.add(jobApp.Id);
        }

        // Query the Job Apps and child Tasks to assert the expected ones have Tasks
        List<Job_Application__c> insertedJobAppsWithTasks = [
            SELECT Id, Application_Status__c,
                (SELECT Id FROM Tasks WHERE WhatId IN :jobAppIds)
            FROM Job_Application__c
            WHERE Id IN :jobAppIds
        ];
        for (Job_Application__c jobApp : insertedJobAppsWithTasks) {
            if (jobApp.Application_Status__c == statusToInvokeTasks) {
                Assert.isFalse(jobApp.Tasks.isEmpty(), 'The Job App should have Tasks based on its status');
            } else {
                Assert.isTrue(jobApp.Tasks.isEmpty(), 'The Job App should not have Tasks based on its status');
            }
        }
    }
}

