@isTest
public with sharing class JobBoardCalloutTest {

    /* Since the getJobs method largely calls a serious of helper methods that are tested on their own, the getJobs test
    methods largely test if the high-level outputs (volume of jobs, jobCount and maxPages) are correct*/

    @isTest
    static void getJobs(){

        Callout_Configuration__mdt joobleCallout = Callout_Configuration__mdt.getInstance('Jooble_Post');

        Test.setMock(HttpCalloutMock.class, new JoobleCalloutMockGenerator());

        Test.startTest();
        Map<String, Object> processedResponse = JobBoardCallout.getJobs('Salesforce Developer', 'remote', '1');
        Test.stopTest();

        // Determine the max jobs we'll display across all pages based on configuration in the Custom Metadata
        Integer maxJobsToGetInOneCall = Integer.valueOf(joobleCallout.Record_Count_To_Get__c);
        Integer maxPagesToEverDisplay = Integer.valueOf(joobleCallout.Max_Pages__c);
        Integer maxJobsToDisplay = Integer.valueOf(joobleCallout.Record_Count_To_Get__c) * Integer.valueOf(joobleCallout.Max_Pages__c);

        // Extract the total jobs meeting the search criteria (this is likely more than the actual amount processed due to the API not returning all of them in one go)
        Integer totalJobs = Integer.valueOf(processedResponse.get('jobCount'));

        // Extract the total jobs returned from this callout (this is likely less than the total jobs that meet the keywords since the API won't return all in one go)
        List<Map<String, String>> jobsProcessed = (List<Map<String, String>>)processedResponse.get('jobs');
        Integer totalJobsProcessed = jobsProcessed.size();

        // Assert Max Pages received back
        Integer maxPagesOfJobs = 0;
        if (totalJobs >= maxJobsToDisplay) {
            maxPagesOfJobs = maxPagesToEverDisplay;
        } else {
            maxPagesOfJobs = (Integer)Math.ceil((totalJobs / maxJobsToGetInOneCall));
        }
        Assert.areEqual(maxPagesOfJobs, processedResponse.get('maxPages'), 'The expected Max Pages is not correct');

        // Assert totalJobsProcessed
        if (totalJobs >= maxJobsToGetInOneCall) {
            Assert.areEqual(maxJobsToGetInOneCall, totalJobsProcessed, 'The amount of processed jobs is not correct');
        } else {
            Assert.areEqual(totalJobs, totalJobsProcessed, 'The amount of processed jobs is not correct');
        }
    }

    @isTest
    static void getJobs_someAlreadySaved() {

        Callout_Configuration__mdt joobleCallout = Callout_Configuration__mdt.getInstance('Jooble_Post');
        Integer maxJobsToGetInOneCall = Integer.valueOf(joobleCallout.Record_Count_To_Get__c);

        // Create Accounts and Job App sObjects that will represent already saved jobs
        Map<Id, Account> testAccounts = TestDataFactory.generateAccountsById(maxJobsToGetInOneCall / 2);
        List<Job_Application__c> existingJobApps = TestDataFactory.generateJobAppsOnAccount(false, testAccounts.values());

        // Loop each Job Application and give it a Jooble Id from 0-99 so some Jobs returned by the mock will have the same Id
        Integer i = 0;
        for (Job_Application__c jobApp : existingJobApps) {
            jobApp.Job_Posting_Id__c = String.valueOf(i);
            i++;
        }
        insert existingJobApps;
        Map<String, Job_Application__c> jobAppsByJoobleId = new Map<String, Job_Application__c>();
        for (Job_Application__c jobApp : existingJobApps) {
            jobAppsByJoobleId.put(jobApp.Job_Posting_Id__c, jobApp);
        }

        Test.setMock(HttpCalloutMock.class, new JoobleCalloutMockGenerator());

        Test.startTest();
        Map<String, Object> processedResponse = JobBoardCallout.getJobs('Salesforce Developer', 'remote', '1');
        Test.stopTest();

        // Extract the total jobs meeting the search criteria (this is likely more than the actual amount processed due to the API not returning all of them in one go)
        Integer totalJobs = Integer.valueOf(processedResponse.get('jobCount'));

        // Extract the total jobs returned from this callout (this is likely less than the total jobs that meet the keywords since the API won't return all in one go)
        List<Map<String, String>> jobsProcessed = (List<Map<String, String>>)processedResponse.get('jobs');
        Integer totalJobsProcessed = jobsProcessed.size();

        // Assert that the count of Jobs are correct based on the already created Jobs
        Integer countOfAlreadySavedJobs = existingJobApps.size();
        Integer processedJobsPlusSavedJobs = totalJobsProcessed + countOfAlreadySavedJobs;
        if (totalJobs >= maxJobsToGetInOneCall) {
            Assert.areEqual(maxJobsToGetInOneCall, processedJobsPlusSavedJobs);
            Assert.areEqual(maxJobsToGetInOneCall - countOfAlreadySavedJobs, totalJobsProcessed);
        } else {
            Assert.areEqual(totalJobsProcessed, maxJobsToGetInOneCall - countOfAlreadySavedJobs);
        }

        List<Map<String, String>> returnedJobs = (List<Map<String, String>>)processedResponse.get('jobs');
        for (Map<String, String> job : returnedJobs) {
            String jobId = job.get('id');
            Assert.isFalse(jobAppsByJoobleId.containsKey(jobId), 'The Job Id should not have been returned since it should exist in Salesforce');
        }
    }

    @isTest
    static void getJobs_AllAlreadySaved() {

        Callout_Configuration__mdt joobleCallout = Callout_Configuration__mdt.getInstance('Jooble_Post');
        Integer maxJobsToGetInOneCall = Integer.valueOf(joobleCallout.Record_Count_To_Get__c);

        // Create Accounts and Job App sObjects that will represent already saved jobs
        Map<Id, Account> testAccounts = TestDataFactory.generateAccountsById(maxJobsToGetInOneCall);
        List<Job_Application__c> existingJobApps = TestDataFactory.generateJobAppsOnAccount(false, testAccounts.values());

        // Loop each Job Application and give it a Jooble Id from 0-99 so some Jobs returned by the mock will have the same Id
        Integer i = 0;
        for (Job_Application__c jobApp : existingJobApps) {
            jobApp.Job_Posting_Id__c = String.valueOf(i);
            i++;
        }
        insert existingJobApps;

        Test.setMock(HttpCalloutMock.class, new JoobleCalloutMockGenerator());
        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            Map<String, Object> processedResponse = JobBoardCallout.getJobs('Salesforce Developer', 'remote', '1');
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'An Aura Handled Exception should have been thrown');
    }

    @isTest
    static void performJoobleCallout_success() {

        Callout_Configuration__mdt joobleCallout = Callout_Configuration__mdt.getInstance('Jooble_Post');
        Test.setMock(HttpCalloutMock.class, new JoobleCalloutMockGenerator());

        Test.startTest();
        HttpResponse joobleResponse = 
            JobBoardCallout.performJoobleCallout('Salesforce Developer', 'remote', '1', joobleCallout);
        Test.stopTest();

        Assert.isTrue(joobleResponse.getBody() != null, 'A response was not received');
    }

    @isTest
    static void performJoobleCallout_failed() {

        Boolean exceptionThrown = false;
        Callout_Configuration__mdt joobleCallout = Callout_Configuration__mdt.getInstance('Jooble_Post');
        Test.setMock(HttpCalloutMock.class, new JoobleCalloutMockGeneratorFailed());

        Test.startTest();
        try {
            HttpResponse joobleResponse = 
                JobBoardCallout.performJoobleCallout('Salesforce Developer', 'remote', '1', joobleCallout);
        } catch (CalloutException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'A Callout Exception should have been thrown');
    }

    @isTest
    static void performJoobleCallout_nullKeywords() {

        Boolean exceptionThrown = false;
        Callout_Configuration__mdt joobleCallout = Callout_Configuration__mdt.getInstance('Jooble_Post');

        Test.startTest();
        try {
            JobBoardCallout.performJoobleCallout(null, 'remote', '1', joobleCallout);
        } catch (IllegalArgumentException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'An Illegal Argument Exception should have been thrown');
    }

    @isTest
    static void performJoobleCallout_nullLocation() {

        Boolean exceptionThrown = false;
        Callout_Configuration__mdt joobleCallout = Callout_Configuration__mdt.getInstance('Jooble_Post');

        Test.startTest();
        try {
            JobBoardCallout.performJoobleCallout('Salesforce Developer', null, '1', joobleCallout);
        } catch (IllegalArgumentException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'An Illegal Argument Exception should have been thrown');
    }

    @isTest
    static void performJoobleCallout_nullPage() {

        Boolean exceptionThrown = false;
        Callout_Configuration__mdt joobleCallout = Callout_Configuration__mdt.getInstance('Jooble_Post');

        Test.startTest();
        try {
            JobBoardCallout.performJoobleCallout('Salesforce Developer', 'remote', null, joobleCallout);
        } catch (IllegalArgumentException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'An Illegal Argument Exception should have been thrown');
    }

    @isTest
    static void performJoobleCallout_nullCalloutDetails() {

        Boolean exceptionThrown = false;
        Callout_Configuration__mdt joobleCallout = Callout_Configuration__mdt.getInstance('Jooble_Post');

        Test.startTest();
        try {
            JobBoardCallout.performJoobleCallout('Salesforce Developer', 'remote', '1', null);
        } catch (IllegalArgumentException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'An Illegal Argument Exception should have been thrown');
    }

    @isTest
    static void deserializeJsonAndCheckForKeys() {

        String calloutResponseMock = TestDataFactory.generateTestJoobleCalloutString(5);

        Test.startTest();
        Map<String, Object> deserializedJson = JobBoardCallout.deserializeJsonAndCheckForKeys(calloutResponseMock);
        Test.stopTest();

        Assert.isTrue(deserializedJson.containsKey('totalCount'), 'The totalCount key was not found');
        Assert.isTrue(deserializedJson.containsKey('jobs'), 'The jobs key was not found');
    }

    @isTest
    static void deserializeJsonAndCheckForKeys_missingTotalCountKey() {

        String calloutResponseMock = TestDataFactory.JOOBLE_CALLOUT_JOB_FORMAT;
        calloutResponseMock = calloutResponseMock.removeEnd(',');
        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            Map<String, Object> deserializedJson = JobBoardCallout.deserializeJsonAndCheckForKeys(calloutResponseMock);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'An AuraHandled Exception should have been thrown');
    }

    @isTest
    static void deserializeJsonAndCheckForKeys_missingJobsKey() {

        String calloutResponseMock = TestDataFactory.JOOBLE_CALLOUT_TOTAL_JOBS_KEY_START + '5"}';
        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            Map<String, Object> deserializedJson = JobBoardCallout.deserializeJsonAndCheckForKeys(calloutResponseMock);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'An AuraHandled Exception should have been thrown');
    }

    @isTest
    static void extractListOfJobsFromJson() {

        Callout_Configuration__mdt joobleCallout = Callout_Configuration__mdt.getInstance('Jooble_Post');
        Integer jobsToGenerate = Integer.valueOf(joobleCallout.Record_Count_To_Get__c);
        String calloutResponseMock = TestDataFactory.generateTestJoobleCalloutString(jobsToGenerate);
        Map<String, Object> deserializedResponse = (Map<String, Object>)JSON.deserializeUntyped(calloutResponseMock);

        Test.startTest();
        List<Map<String, Object>> jobList = JobBoardCallout.extractListOfJobsFromJson(deserializedResponse, 'jobs');
        Test.stopTest();

        Set<String> stringNumbersOnJobs = new Set<String>();
        for (Integer i = 0; i < jobsToGenerate; i++) {
            stringNumbersOnJobs.add(String.valueOf(i));
        }

        for(Map<String, Object> job : jobList) {
            String jobIdString = String.valueOf(job.get('id'));
            Assert.areEqual('Test Job ' + jobIdString, String.valueOf(job.get('title')), 'The title is not correct');
            Assert.areEqual('Test Remote ' + jobIdString, String.valueOf(job.get('location')), 'The location is not correct');
            Assert.areEqual('Test Snippet ' + jobIdString, String.valueOf(job.get('snippet')), 'The snippet is not correct');
            Assert.areEqual(jobIdString, String.valueOf(job.get('salary')), 'The salary is not correct');
            Assert.areEqual('Test Source ' + jobIdString, String.valueOf(job.get('source')), 'The source is not correct');
            Assert.areEqual('Test Type ' + jobIdString, String.valueOf(job.get('type')), 'The type is not correct');
            Assert.areEqual('www.test' + jobIdString + '.com', String.valueOf(job.get('link')), 'The link is not correct');
            Assert.areEqual('Test Company ' + jobIdString, String.valueOf(job.get('company')), 'The company is not correct');
            Assert.areEqual('2024-01-01T00:00:00.0000000', String.valueOf(job.get('updated')), 'The updated is not correct');
            stringNumbersOnJobs.remove(jobIdString);
        }
        Assert.isTrue(stringNumbersOnJobs.isEmpty(), 'Not all of the expected jobs were received');
    }

    @isTest
    static void checkJobDataForMissingInfo_emptyList (){

        List<Map<String, Object>> emptyList = new List<Map<String, Object>>();
        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            JobBoardCallout.checkJobDataForMissingInfo(emptyList, 5);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'An AuraHandled Exception should have been thrown');
    }

    @isTest
    static void checkJobDataForMissingInfo_nullNumber (){

        List<Map<String, Object>> testList = new List<Map<String, Object>>();
        Map<String, Object> testMap = new Map<String, Object>();
        testMap.put('Test Key', 'Test Value');
        testList.add(testMap);

        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            JobBoardCallout.checkJobDataForMissingInfo(testList, null);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'An AuraHandled Exception should have been thrown');
    }

    @isTest
    static void checkJobDataForMissingInfo_zeroNumber (){

        List<Map<String, Object>> testList = new List<Map<String, Object>>();
        Map<String, Object> testMap = new Map<String, Object>();
        testMap.put('Test Key', 'Test Value');
        testList.add(testMap);

        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            JobBoardCallout.checkJobDataForMissingInfo(testList, 0);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'An AuraHandled Exception should have been thrown');
    }

    @isTest
    static void extractJobIdsFromJobs() {

        // Setup mock callout to work with
        Callout_Configuration__mdt joobleCallout = Callout_Configuration__mdt.getInstance('Jooble_Post');
        Integer jobsToGenerate = Integer.valueOf(joobleCallout.Record_Count_To_Get__c);
        String calloutResponseMock = TestDataFactory.generateTestJoobleCalloutString(jobsToGenerate);
        Map<String, Object> deserializedResponse = (Map<String, Object>)JSON.deserializeUntyped(calloutResponseMock);

        // Get the Id key value
        Integration_Field_Mapping__mdt ifm = [SELECT Key__c FROM Integration_Field_Mapping__mdt WHERE Id_Field__c = TRUE LIMIT 1];
        
        // Generate the expected Ids based on what the Test Data Factory produces
        Set<String> expectedJobIds = new Set<String>();
        for (Integer i = 0; i < jobsToGenerate; i++) {
            expectedJobIds.add(String.valueOf(i));
        }

        // Extract the job list and Ids
        Test.startTest();
        List<Map<String, Object>> jobList = JobBoardCallout.extractListOfJobsFromJson(deserializedResponse, 'jobs');
        Set<String> extractedJobIds = JobBoardCallout.extractJobIdsFromJobs(jobList, ifm);
        Test.stopTest();

        Assert.areEqual(expectedJobIds, extractedJobIds);
    }

    @isTest
    static void calculateMaxPagesOfJobs_totalJobCountGreaterThanMax() {

        Callout_Configuration__mdt cc = Callout_Configuration__mdt.getInstance('Jooble_Post');
        Integer maxJobsToDisplayInConfig = Integer.valueOf(cc.Record_Count_To_Get__c) * Integer.valueOf(cc.Max_Pages__c);
        Integer totalJobs = maxJobsToDisplayInConfig + 1;

        Test.startTest();
        Integer maxPagesOfJobs = JobBoardCallout.calculateMaxPagesOfJobs(cc, totalJobs);
        Test.stopTest();

        Assert.areEqual(cc.Max_Pages__c, maxPagesOfJobs, 'The max pages of jobs is not correct');
    }

    @isTest
    static void calculateMaxPagesOfJobs_totalJobCountLessThanMax() {

        Callout_Configuration__mdt cc = Callout_Configuration__mdt.getInstance('Jooble_Post');
        Integer maxJobsToDisplayInConfig = Integer.valueOf(cc.Record_Count_To_Get__c) * Integer.valueOf(cc.Max_Pages__c);
        Integer totalJobs = 200;

        Test.startTest();
        Integer maxPagesOfJobs = JobBoardCallout.calculateMaxPagesOfJobs(cc, totalJobs);
        Test.stopTest();

        Assert.areEqual(Math.ceil(totalJobs / Integer.valueOf(cc.Record_Count_To_Get__c)), maxPagesOfJobs, 'The max pages of jobs is not correct');
    }

    @isTest 
    static void calculateMaxJobsToDisplay() {

        Callout_Configuration__mdt cc = Callout_Configuration__mdt.getInstance('Jooble_Post');
        Integer maxPages = 10;

        Test.startTest();
        Integer maxJobs = JobBoardCallout.calculateMaxJobsToDisplay(cc, maxPages);
        Test.stopTest();

        Assert.areEqual(Integer.valueOf(cc.Record_Count_To_Get__c) * maxPages, maxJobs);
    }

    /* Since the processSelectedJobs method largely calls a serious of helper methods that are tested on their own, the 
    processSelectedJobs test methods test if the high-level outputs are correct. For example, success message received, 
    expected count of Accounts, Job Applications and Job Application Contacts for different scenarios */

    @isTest 
    static void processSelectedJobs_noAccountsOrContactsExist() {

        // Generate a sample of a response we can get from the selections in the LWC
        Integer selectedJobs = 200;
        List<Map<String, Object>> generateSelectedJobs = TestDataFactory.generateLwcJobSelectionResponse(selectedJobs);

        Test.startTest();
        String message = JobBoardCallout.processSelectedJobs(generateSelectedJobs);
        Test.stopTest();

        // Assert the process was successful
        Assert.areEqual('Success', message, 'The message Success was expected');

        // Check that we have 200 new Accounts and a Job Application for each
        List<Account> createdAccounts = [
            SELECT Id, 
                (SELECT Id, Company__c,
                    (SELECT Id FROM Job_Application_Contacts__r)
                FROM Job_Applications__r)
            FROM Account
        ];
        Assert.areEqual(selectedJobs, createdAccounts.size(), 'The expected count of Accounts was not created');
        for (Account acc : createdAccounts) {
            List<Job_Application__c> jobApps = acc.Job_Applications__r;
            Assert.areEqual(1, jobApps.size(), 'Each Account should have 1 Job Application');
            Job_Application__c jobApp = jobApps.get(0);
            List<Job_Application_Contact__c> jobAppContacts = jobApp.Job_Application_Contacts__r;
            Assert.isTrue(jobAppContacts.isEmpty(), 'There should be no Job Application Contacts for the Job App');
        }
    }

    @isTest 
    static void processSelectedJobs_accountsExistNoContact() {

        // Generate a sample of a response we can get from the selections in the LWC
        Integer selectedJobs = 200;
        List<Map<String, Object>> generateSelectedJobs = TestDataFactory.generateLwcJobSelectionResponse(selectedJobs);

        // Create Accounts for each Company Name so we can test Job Apps getting associated to existing Accounts
        List<Account> existingAccounts = new List<Account>();
        for (Map<String, Object> job : generateSelectedJobs) {
            String companyName = String.valueOf(job.get('company'));
            Account acc = new Account();
            acc.Name = companyName;
            existingAccounts.add(acc);
        }
        insert existingAccounts;
        Set<Id> accIds = new Set<Id>();
        for (Account acc : existingAccounts) {
            accIds.add(acc.Id);
        }

        Test.startTest();
        String message = JobBoardCallout.processSelectedJobs(generateSelectedJobs);
        Test.stopTest();

        // Assert the process was successful
        Assert.areEqual('Success', message, 'The message Success was expected');

        // Check that each existing Account has a Job Application but that doesn't have a Job App Contact
        List<Account> existingAccountsWithJobApps = [
            SELECT Id, 
                (SELECT Id, Company__c,
                    (SELECT Id FROM Job_Application_Contacts__r)
                FROM Job_Applications__r)
            FROM Account
            WHERE Id IN :accIds
        ];
        Assert.areEqual(selectedJobs, existingAccountsWithJobApps.size(), 'The expected count of existing Accounts was not returned');
        for (Account acc : existingAccountsWithJobApps) {
            List<Job_Application__c> jobApps = acc.Job_Applications__r;
            Assert.areEqual(1, jobApps.size(), 'Each Account should have 1 Job Application');
            Job_Application__c jobApp = jobApps.get(0);
            List<Job_Application_Contact__c> jobAppContacts = jobApp.Job_Application_Contacts__r;
            Assert.isTrue(jobAppContacts.isEmpty(), 'There should be no Job Application Contacts for the Job App');
        }
    }

    @isTest 
    static void processSelectedJobs_accountsExistWithContact() {

        // Generate a sample of a response we can get from the selections in the LWC
        Integer selectedJobs = 200;
        List<Map<String, Object>> generateSelectedJobs = TestDataFactory.generateLwcJobSelectionResponse(selectedJobs);

        // Create Accounts for each Company Name so we can test Job Apps getting associated to existing Accounts
        List<Account> existingAccounts = new List<Account>();
        for (Map<String, Object> job : generateSelectedJobs) {
            String companyName = String.valueOf(job.get('company'));
            Account acc = new Account();
            acc.Name = companyName;
            existingAccounts.add(acc);
        }
        insert existingAccounts;
        Set<Id> accIds = new Set<Id>();
        for (Account acc : existingAccounts) {
            accIds.add(acc.Id);
        }

        List<Contact> contactsOnAccount = TestDataFactory.generateContactsOnAccounts(true, existingAccounts);

        Test.startTest();
        String message = JobBoardCallout.processSelectedJobs(generateSelectedJobs);
        Test.stopTest();

        // Assert the process was successful
        Assert.areEqual('Success', message, 'The message Success was expected');

        // Assert Job Apps are related to the correct Accounts and Job App Contacts are related to the correct Job App / Contact
        List<Account> existingAccountsWithJobApps = [
            SELECT Id, 
                (SELECT Id, Company__c,
                    (SELECT Id, Contact__c FROM Job_Application_Contacts__r)
                FROM Job_Applications__r),
                (SELECT Id FROM Contacts)
            FROM Account
            WHERE Id IN :accIds
        ];
        Assert.areEqual(selectedJobs, existingAccountsWithJobApps.size(), 'The expected count of existing Accounts was not returned');
        for (Account acc : existingAccountsWithJobApps) {
            List<Job_Application__c> jobApps = acc.Job_Applications__r;
            Assert.areEqual(1, jobApps.size(), 'Each Account should have 1 Job Application');
            Job_Application__c jobApp = jobApps.get(0);
            List<Job_Application_Contact__c> jobAppContacts = jobApp.Job_Application_Contacts__r;
            Assert.areEqual(1, jobAppContacts.size(), 'Each Job App should have one Job App Contact');
            Id conId = acc.Contacts.get(0).Id;
            Assert.areEqual(conId, jobAppContacts.get(0).Contact__c, 'The Job App Contact should be related to the Contact on the Account');
        }
    }

    @isTest 
    static void processSelectedJobs_multipleJobsPerExistingAccount() {

        // Generate 100 jobs, clone them, give them a unique Id and add to the initial list of Jobs. This creates two jobs per company.
        Integer initialCountOfJobs = 100;
        List<Map<String, Object>> generateSelectedJobs = TestDataFactory.generateLwcJobSelectionResponse(initialCountOfJobs);
        List<Map<String, Object>> clonedJobs = generateSelectedJobs.clone();
        Integer startingCount = initialCountOfJobs;
        for (Map<String, Object> job : clonedJobs) {
            String jobId = String.valueOf(job.get('id'));
            jobId = String.valueOf(startingCount);
            job.put('id', jobId);
            generateSelectedJobs.add(job);
            startingCount++;
        }
        Integer selectedJobs = generateSelectedJobs.size();

        // Create Accounts for each Company Name so we can test Job Apps getting associated to existing Accounts
        Set<String> companyNamesAddedToList = new Set<String>();
        List<Account> existingAccounts = new List<Account>();
        for (Map<String, Object> job : generateSelectedJobs) {
            String companyName = String.valueOf(job.get('company'));
            if (!companyNamesAddedToList.contains(companyName)) {
                Account acc = new Account();
                acc.Name = companyName;
                existingAccounts.add(acc);
                companyNamesAddedToList.add(companyName);
            }
        }
        insert existingAccounts;
        Set<Id> accIds = new Set<Id>();
        for (Account acc : existingAccounts) {
            accIds.add(acc.Id);
        }

        List<Contact> contactsOnAccount = TestDataFactory.generateContactsOnAccounts(true, existingAccounts);

        Test.startTest();
        String message = JobBoardCallout.processSelectedJobs(generateSelectedJobs);
        Test.stopTest();

        // Assert the process was successful
        Assert.areEqual('Success', message, 'The message Success was expected');

        // Assert Job Apps are related to the correct Accounts and Job App Contacts are related to the correct Job App / Contact
        List<Account> existingAccountsWithJobApps = [
            SELECT Id, 
                (SELECT Id, Company__c,
                    (SELECT Id, Contact__c FROM Job_Application_Contacts__r)
                FROM Job_Applications__r),
                (SELECT Id FROM Contacts)
            FROM Account
            WHERE Id IN :accIds
        ];

        Assert.areEqual(initialCountOfJobs, existingAccountsWithJobApps.size(), 'The expected count of existing Accounts was not returned');
        for (Account acc : existingAccountsWithJobApps) {
            List<Job_Application__c> jobApps = acc.Job_Applications__r;
            Assert.areEqual(2, jobApps.size(), 'Each Account should have 2 Job Applications');
            for (Job_Application__c jobApp : jobApps) {
                List<Job_Application_Contact__c> jobAppContacts = jobApp.Job_Application_Contacts__r;
                Assert.areEqual(1, jobAppContacts.size(), 'Each Job App should have one Job App Contact');
                Id conId = acc.Contacts.get(0).Id;
                Assert.areEqual(conId, jobAppContacts.get(0).Contact__c, 'The Job App Contact should be related to the Contact on the Account');
            }
        }
    }

    @isTest 
    static void processSelectedJobs_someAccountsNewSomeExisting() {

        // Generate a sample of a response we can get from the selections in the LWC
        Integer selectedJobs = 200;
        List<Map<String, Object>> generateSelectedJobs = TestDataFactory.generateLwcJobSelectionResponse(selectedJobs);

        // Create Accounts for the first 100 Companies so we can test handling both new and existing Accounts
        List<Account> existingAccounts = new List<Account>();
        for (Map<String, Object> job : generateSelectedJobs) {
            String companyName = String.valueOf(job.get('company'));
            Account acc = new Account();
            acc.Name = companyName;
            existingAccounts.add(acc);
            if (existingAccounts.size() == 100) {
                break;
            }
        }
        insert existingAccounts;
        Set<Id> accIds = new Set<Id>();
        for (Account acc : existingAccounts) {
            accIds.add(acc.Id);
        }

        Test.startTest();
        String message = JobBoardCallout.processSelectedJobs(generateSelectedJobs);
        Test.stopTest();

        // Assert the process was successful
        Assert.areEqual('Success', message, 'The message Success was expected');

        // Check that we have 200 Accounts, each with one Job App and no Job App Contacts
        List<Account> accountsWithJobApps = [
            SELECT Id, 
                (SELECT Id, Company__c,
                    (SELECT Id FROM Job_Application_Contacts__r)
                FROM Job_Applications__r)
            FROM Account
        ];
        Assert.areEqual(selectedJobs, accountsWithJobApps.size(), 'The expected count of Accounts was not returned');
        for (Account acc : accountsWithJobApps) {
            List<Job_Application__c> jobApps = acc.Job_Applications__r;
            Assert.areEqual(1, jobApps.size(), 'Each Account should have 1 Job Application');
            Job_Application__c jobApp = jobApps.get(0);
            List<Job_Application_Contact__c> jobAppContacts = jobApp.Job_Application_Contacts__r;
            Assert.isTrue(jobAppContacts.isEmpty(), 'There should be no Job Application Contacts for the Job App');
        }
    }
}