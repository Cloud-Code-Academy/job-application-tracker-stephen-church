@isTest
public with sharing class SObjectSalaryConvert_DollarPerHRangeTest {

    static final Set<String> VALUES_MEETING_PATTERN = new Set<String>{
        '$5 per hour - $500 per hour', '$5 per hour - $50 per hour', '$50 per hour - $100 per hour', 
        '$5 - $500 per hour', '$5 - $50 per hour','$50 - $100 per hour', 
        '$50.50 per hour - $100.50 per hour', '$50.50 - $100.50 per hour'
    };
    static final Set<String> VALUES_NOT_MEETING_PATTERN = new Set<String>{
        '100k', '50k', '5k', '$5', '$10', '$100', '50k - 100k', '$100k', '$50k', '$5k','5k - 100k', 
        '5k - 10k', '$50 - $100', '$50k - $100k', '$5k - $100k', '$5k - $10k', '50 per hour', '$5 per hour - $500', 
        '$5 per hour - $50', '$50 per hour - $100', '$5 per hour', '$50 per hour', '$100 per hour', '$5.50 per hour',
        '$50.5 per hour', '$100.50 per hour'
    };

    @isTest
    static void checkSalaryPatternAndConvert_patternMatchesAndNotMatches(){

        Set<String> allValues = new Set<String>();
        allValues.addAll(VALUES_MEETING_PATTERN);
        allValues.addAll(VALUES_NOT_MEETING_PATTERN);

        List<Job_Application__c> jobAppsToCheck = new List<Job_Application__c>();
        for (String value : allValues) {
            Job_Application__c jobAppToCheck = new Job_Application__c();
            jobAppToCheck.Salary_From_Job_Board__c = value;
            jobAppsToCheck.add(jobAppToCheck);
        }

        Test.startTest();
        SObjectSalaryConvert_DollarPerHourRange salaryCheck = new SObjectSalaryConvert_DollarPerHourRange();
        salaryCheck.checkSalaryPatternAndConvert(jobAppsToCheck, 'Salary_From_Job_Board__c', 'Salary__c');
        List<Job_Application__c> jobsNotMeetingPattern = salaryCheck.getSObjectsNotMatchingPattern();
        Test.stopTest();

        Assert.areEqual(VALUES_NOT_MEETING_PATTERN.size(), jobsNotMeetingPattern.size(), 
            'The amount of jobs not meeting the pattern is not correct');
        for (Job_Application__c job : jobsNotMeetingPattern) {
            Assert.isTrue(VALUES_NOT_MEETING_PATTERN.contains(job.Salary_From_Job_Board__c), 
                'The Salary should be in the Set of values not meeting the pattern');
            Assert.isFalse(VALUES_MEETING_PATTERN.contains(job.Salary_From_Job_Board__c),
                'The Salary should not be in the Set of values meeting the pattern');
            Assert.isNull(job.Salary__c, 
                'The Salary fied should be null since the pattern was not met.');
        }
    }

    @isTest
    static void checkSalaryPatternAndConvert_checkWrongField(){

        Set<String> allValues = new Set<String>();
        allValues.addAll(VALUES_MEETING_PATTERN);
        allValues.addAll(VALUES_NOT_MEETING_PATTERN);

        List<Job_Application__c> jobAppsToCheck = new List<Job_Application__c>();
        for (String value : allValues) {
            Job_Application__c jobAppToCheck = new Job_Application__c();
            jobAppToCheck.Salary_From_Job_Board__c = value;
            jobAppToCheck.Job_Title__c = 'Test Title';
            jobAppsToCheck.add(jobAppToCheck);
        }

        Test.startTest();
        SObjectSalaryConvert_DollarPerHourRange salaryCheck = new SObjectSalaryConvert_DollarPerHourRange();
        salaryCheck.checkSalaryPatternAndConvert(jobAppsToCheck, 'Job_Title__c', 'Salary__c');
        List<Job_Application__c> jobsNotMeetingPattern = salaryCheck.getSObjectsNotMatchingPattern();
        Test.stopTest();

        Assert.areEqual(allValues.size(), jobsNotMeetingPattern.size(), 
            'The amount of jobs not meeting the pattern is not correct');
    }

    @isTest
    static void checkSalaryPatternAndConvert_checkNullValue(){

        Set<String> allValues = new Set<String>();
        allValues.addAll(VALUES_MEETING_PATTERN);
        allValues.addAll(VALUES_NOT_MEETING_PATTERN);

        List<Job_Application__c> jobAppsToCheck = new List<Job_Application__c>();
        for (String value : allValues) {
            Job_Application__c jobAppToCheck = new Job_Application__c();
            jobAppsToCheck.add(jobAppToCheck);
        }

        Test.startTest();
        SObjectSalaryConvert_DollarPerHourRange salaryCheck = new SObjectSalaryConvert_DollarPerHourRange();
        salaryCheck.checkSalaryPatternAndConvert(jobAppsToCheck, 'Salary_From_Job_Board__c', 'Salary__c');
        List<Job_Application__c> jobsNotMeetingPattern = salaryCheck.getSObjectsNotMatchingPattern();
        Test.stopTest();

        Assert.areEqual(allValues.size(), jobsNotMeetingPattern.size(), 
            'The amount of jobs not meeting the pattern is not correct');
    }

    @isTest
    static void checkSalaryPatternAndConvert_emptyJobsToCheck(){

        Set<String> allValues = new Set<String>();
        allValues.addAll(VALUES_MEETING_PATTERN);
        allValues.addAll(VALUES_NOT_MEETING_PATTERN);

        List<Job_Application__c> jobAppsToCheck = new List<Job_Application__c>();
        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            SObjectSalaryConvert_DollarPerHourRange salaryCheck = new SObjectSalaryConvert_DollarPerHourRange();
            salaryCheck.checkSalaryPatternAndConvert(jobAppsToCheck, 'Salary_From_Job_Board__c', 'Salary__c');
            List<Job_Application__c> jobsNotMeetingPattern = salaryCheck.getSObjectsNotMatchingPattern();
        } catch (IllegalArgumentException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'An Illegal Argument Exception should have been thrown');
    }

    @isTest
    static void checkSalaryPatternAndConvert_nullFieldToCheck(){

        Set<String> allValues = new Set<String>();
        allValues.addAll(VALUES_MEETING_PATTERN);
        allValues.addAll(VALUES_NOT_MEETING_PATTERN);

        List<Job_Application__c> jobAppsToCheck = new List<Job_Application__c>();
        for (String value : allValues) {
            Job_Application__c jobAppToCheck = new Job_Application__c();
            jobAppToCheck.Salary_From_Job_Board__c = value;
            jobAppsToCheck.add(jobAppToCheck);
        }
        String nullFieldToCheck = null;
        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            SObjectSalaryConvert_DollarPerHourRange salaryCheck = new SObjectSalaryConvert_DollarPerHourRange();
            salaryCheck.checkSalaryPatternAndConvert(jobAppsToCheck, nullFieldToCheck, 'Salary__c');
            List<Job_Application__c> jobsNotMeetingPattern = salaryCheck.getSObjectsNotMatchingPattern();
        } catch (IllegalArgumentException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'An Illegal Argument Exception should have been thrown');
    }

    @isTest
    static void checkSalaryPatternAndConvert_nullFieldToSet(){

        Set<String> allValues = new Set<String>();
        allValues.addAll(VALUES_MEETING_PATTERN);
        allValues.addAll(VALUES_NOT_MEETING_PATTERN);

        List<Job_Application__c> jobAppsToCheck = new List<Job_Application__c>();
        for (String value : allValues) {
            Job_Application__c jobAppToCheck = new Job_Application__c();
            jobAppToCheck.Salary_From_Job_Board__c = value;
            jobAppsToCheck.add(jobAppToCheck);
        }
        String nullFieldToSet = null;
        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            SObjectSalaryConvert_DollarPerHourRange salaryCheck = new SObjectSalaryConvert_DollarPerHourRange();
            salaryCheck.checkSalaryPatternAndConvert(jobAppsToCheck, 'Salary_From_Job_Board__c', nullFieldToSet);
            List<Job_Application__c> jobsNotMeetingPattern = salaryCheck.getSObjectsNotMatchingPattern();
        } catch (IllegalArgumentException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'An Illegal Argument Exception should have been thrown');
    }
}