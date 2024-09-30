@isTest
public with sharing class UtilityTest {

    @isTest
    static void throwUiFriendlyException() {

        Boolean exceptionThrown = false;
        // Looks like AuraHandled exceptions just default to the below, even if I pass a message.
        String expectedPartOfExceptionMessage = 'Script-thrown exception';
        String fullExceptionMessageReceived = null;

        Test.startTest();
        try{
            Utility.throwUiFriendlyException('Test');
        } catch (AuraHandledException e) {
            fullExceptionMessageReceived = e.getMessage();
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'An exception of the expected type was not thrown');
        Assert.isTrue(fullExceptionMessageReceived.contains(expectedPartOfExceptionMessage),
            'The exception message does not contain the expected String');
    }

    @isTest
    static void throwHandledException() {

        Boolean exceptionThrown = false;
        String customPartOfExceptionMessage = 'Test';
        String expectedPartOfExceptionMessage = 
            Utility.GENERIC_ERROR_MESSAGE_START + 
            Utility.HANDLED_EXCEPTION_START + 
            customPartOfExceptionMessage + 
            Utility.SEPARATOR_FOR_STACK_TRACE;
        String fullExceptionMessageReceived = null;

        Test.startTest();
        try{
            Utility.throwHandledException(customPartOfExceptionMessage);
        } catch (HandledException e) {
            fullExceptionMessageReceived = e.getMessage();
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'An exception of the expected type was not thrown');
        Assert.isTrue(fullExceptionMessageReceived.contains(expectedPartOfExceptionMessage),
            'The exception message does not contain the expected String');
    }

    @isTest
    static void throwIllegalArgumentException() {

        Boolean exceptionThrown = false;
        String customPartOfExceptionMessage = 'Test';
        String expectedPartOfExceptionMessage = 
            Utility.GENERIC_ERROR_MESSAGE_START + 
            Utility.ILLEGAL_ARGUMENT_EXCEPTION_START + 
            customPartOfExceptionMessage + 
            Utility.SEPARATOR_FOR_STACK_TRACE;
        String fullExceptionMessageReceived = null;

        Test.startTest();
        try{
            Utility.throwIllegalArgumentException(customPartOfExceptionMessage);
        } catch (IllegalArgumentException e) {
            fullExceptionMessageReceived = e.getMessage();
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'An exception of the expected type was not thrown');
        Assert.isTrue(fullExceptionMessageReceived.contains(expectedPartOfExceptionMessage),
            'The exception message does not contain the expected String');
    }

    @isTest
    static void throwTypeException() {

        Boolean exceptionThrown = false;
        String customPartOfExceptionMessage = 'Test';
        String expectedPartOfExceptionMessage = 
            Utility.GENERIC_ERROR_MESSAGE_START + 
            Utility.TYPE_EXCEPTION_START + 
            customPartOfExceptionMessage + 
            Utility.SEPARATOR_FOR_STACK_TRACE;
        String fullExceptionMessageReceived = null;

        Test.startTest();
        try{
            Utility.throwTypeException(customPartOfExceptionMessage);
        } catch (TypeException e) {
            fullExceptionMessageReceived = e.getMessage();
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'An exception of the expected type was not thrown');
        Assert.isTrue(fullExceptionMessageReceived.contains(expectedPartOfExceptionMessage),
            'The exception message does not contain the expected String');
    }

    @isTest
    static void throwCalloutException() {

        Integer statusCode = 500;

        Boolean exceptionThrown = false;
        String customPartOfExceptionMessage = 'Test';
        String expectedPartOfExceptionMessage = 
            Utility.GENERIC_ERROR_MESSAGE_START + 
            Utility.CALLOUT_EXCEPTION_START;
        String fullExceptionMessageReceived = null;

        Test.startTest();
        try{
            Utility.throwCalloutException(statusCode, customPartOfExceptionMessage);
        } catch (CalloutException e) {
            fullExceptionMessageReceived = e.getMessage();
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'An exception of the expected type was not thrown');
        Assert.isTrue(fullExceptionMessageReceived.contains(expectedPartOfExceptionMessage),
            'The exception message does not contain the expected String');
    }

    @isTest
    static void throwDmlException() {

        Boolean exceptionThrown = false;
        String customPartOfExceptionMessage = 'Test';
        String expectedPartOfExceptionMessage = 
            Utility.GENERIC_ERROR_MESSAGE_START + 
            Utility.DML_EXCEPTION_START + 
            customPartOfExceptionMessage + 
            Utility.SEPARATOR_FOR_STACK_TRACE;
        String fullExceptionMessageReceived = null;

        Test.startTest();
        try{
            DmlException testDmlException = new DmlException(customPartOfExceptionMessage);
            Utility.throwDmlException(testDmlException);
        } catch (DmlException e) {
            fullExceptionMessageReceived = e.getMessage();
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'An exception of the expected type was not thrown');
        Assert.isTrue(fullExceptionMessageReceived.contains(expectedPartOfExceptionMessage),
            'The exception message does not contain the expected String');
    }

    @isTest
    static void throwQueryException() {

        Boolean exceptionThrown = false;
        String customPartOfExceptionMessage = 'Test';
        String expectedPartOfExceptionMessage = 
            Utility.GENERIC_ERROR_MESSAGE_START + 
            Utility.QUERY_EXCEPTION_START + 
            customPartOfExceptionMessage + 
            Utility.SEPARATOR_FOR_STACK_TRACE;
        String fullExceptionMessageReceived = null;

        Test.startTest();
        try{
            Utility.throwQueryException(customPartOfExceptionMessage);
        } catch (QueryException e) {
            fullExceptionMessageReceived = e.getMessage();
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'An exception of the expected type was not thrown');
        Assert.isTrue(fullExceptionMessageReceived.contains(expectedPartOfExceptionMessage),
            'The exception message does not contain the expected String');
    }

    @isTest
    static void checkIfResponseCodeIsSuccess_true() {

        Test.startTest();
        Boolean result = Utility.checkIfResponseCodeIsSuccess(200);
        Test.stopTest();

        Assert.isTrue(result, 'The response code should have been a success');
    }

    @isTest
    static void checkIfResponseCodeIsSuccess_false() {

        Test.startTest();
        Boolean result = Utility.checkIfResponseCodeIsSuccess(100);
        Test.stopTest();

        Assert.isFalse(result, 'The response code should not have been a success');
    }

    @isTest
    static void checkIfResponseCodeIsSuccess_nullCode() {

        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            Boolean result = Utility.checkIfResponseCodeIsSuccess(null);
        } catch (IllegalArgumentException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'An Illegal Argument exception should have been thrown');
    }

    @isTest 
    static void deserializeJson() {

        Map<String, String> testMap = new Map<String, String>();
        testMap.put('String A', 'String 1');
        testMap.put('String B', 'String 2');

        String serializedJson = JSON.serialize(testMap);

        Test.startTest();
        Map<String, Object> deserializedJson = Utility.deserializeJson(serializedJson);
        Test.stopTest();

        Assert.areEqual(testMap.keySet(), deserializedJson.keySet()); 
        for (String key : testMap.keySet()) {
            String testMapValue = testMap.get(key);
            String deserializedJsonValue = String.valueOf(deserializedJson.get(key));
            Assert.areEqual(testMapValue, deserializedJsonValue, 'The values do not match');
        }
    }

    @isTest
    static void deserializeJson_null() {

        Boolean exceptionThrown = true;
        Test.startTest();
        try {
            Map<String, Object> deserializedJson = Utility.deserializeJson(null);
        } catch (IllegalArgumentException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'An Illegal Arugment exception should have been thrown');
    }

    @isTest
    static void getSingleStringFromEachMapInList() {

        List<Map<String, Object>> listOfMaps = TestDataFactory.generateListOfMapsForUtilityTests('Target Key', 'Other Key');

        Test.startTest();
        Set<String> extractedStrings = Utility.getSingleStringFromEachMapInList('Target Key', 'Other Key', listOfMaps);
        Test.stopTest();

        Assert.areEqual(2, extractedStrings.size(), 'Two keys should have been extracted from the list of Maps');
        Assert.isTrue(extractedStrings.contains('Target Value 1'), 'Target Value 1 should have been extracted from the list of Maps');
        Assert.isTrue(extractedStrings.contains('Target Value 2'), 'Target Value 2 should have been extracted from the list of Maps');
    }

    @isTest
    static void getSingleStringFromEachMapInList_invalidKey() {

        List<Map<String, Object>> listOfMaps = TestDataFactory.generateListOfMapsForUtilityTests('Target Key', 'Other Key');

        Test.startTest();
        Set<String> extractedStrings = Utility.getSingleStringFromEachMapInList('Invalid Key', 'Invalid Key 2', listOfMaps);
        Test.stopTest();

        Assert.isTrue(extractedStrings.isEmpty(), 'extractedStrings should be null');
    }

    @isTest
    static void getSingleStringFromEachMapInList_missingString() {
        
        List<Map<String, Object>> listOfMaps = TestDataFactory.generateListOfMapsForUtilityTests('Target Key', 'Other Key');
        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            Set<String> extractedStrings = Utility.getSingleStringFromEachMapInList(null, null, listOfMaps);
        } catch (IllegalArgumentException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'An Illegal Argument Exception should have been thrown');
    }

    @isTest
    static void getSingleStringFromEachMapInList_missingList() {
        
        List<Map<String, Object>> listOfMaps = new List<Map<String, Object>>();
        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            Set<String> extractedStrings = Utility.getSingleStringFromEachMapInList('Test Key', 'Test Key 2', listOfMaps);
        } catch (IllegalArgumentException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'An Illegal Argument Exception should have been thrown');
    }

    @isTest
    static void getSetOfStringsFromField() {

        List<Job_Application__c> jobApps = new List<Job_Application__c>();
        Set<String> expectedValues = new Set<String>();
        for (Integer i = 0; i < 5; i++) {
            Job_Application__c jobApp = new Job_Application__c();
            jobApp.Job_Title__c = String.valueOf(i);
            jobApps.add(jobApp);
            expectedValues.add(String.valueOf(i));
        }

        Test.startTest();
        Set<String> returnedStrings = Utility.getSetOfStringsFromField(jobApps, 'Job_Title__c');
        Test.stopTest();

        Assert.areEqual(expectedValues, returnedStrings, 'The expected strings were not returned');
    }

    @isTest
    static void getSetOfStringsFromField_nullField() {

        List<Job_Application__c> jobApps = new List<Job_Application__c>();
        Set<String> expectedValues = new Set<String>();
        for (Integer i = 0; i < 5; i++) {
            Job_Application__c jobApp = new Job_Application__c();
            jobApp.Job_Title__c = String.valueOf(i);
            jobApps.add(jobApp);
            expectedValues.add(String.valueOf(i));
        }

        Test.startTest();
        Set<String> returnedStrings = Utility.getSetOfStringsFromField(jobApps, 'Rating__c');
        Test.stopTest();

        Assert.isTrue(returnedStrings.isEmpty(), 'There should have been no strings returned');
    }

    @isTest
    static void getSetOfStringsFromField_missingList() {

        List<Job_Application__c> jobApps = new List<Job_Application__c>();
        Boolean exceptionThrown = false;

        Test.startTest();
        try{
            Set<String> returnedStrings = Utility.getSetOfStringsFromField(jobApps, 'Rating__c');
        } catch (IllegalArgumentException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'An Illegal Argument Exception should have been thrown');
    }

    @isTest
    static void getSetOfStringsFromField_missingField() {

        List<Job_Application__c> jobApps = new List<Job_Application__c>();
        Set<String> expectedValues = new Set<String>();
        for (Integer i = 0; i < 5; i++) {
            Job_Application__c jobApp = new Job_Application__c();
            jobApp.Job_Title__c = String.valueOf(i);
            jobApps.add(jobApp);
            expectedValues.add(String.valueOf(i));
        }
        Boolean exceptionThrown = false;

        Test.startTest();
        try{
            Set<String> returnedStrings = Utility.getSetOfStringsFromField(jobApps, null);
        } catch (IllegalArgumentException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'An Illegal Argument Exception should have been thrown');
    }

    @isTest
    static void insertRecords() {

        Map<String, Account> testAccountsById = TestDataFactory.generateAccountsByName(false, 200);

        Test.startTest();
        List<Account> insertedAccounts = Utility.insertRecords(testAccountsById.values());
        Test.stopTest();

        Set<Id> accountIds = new Set<Id>();
        for (Account acc : insertedAccounts) {
            accountIds.add(acc.Id);
        }

        Assert.isTrue(accountIds.size() == 200, '200 Account Ids should have been generated');
    }

    @isTest
    static void insertRecords_missingReqField() {

        List<Account> testAccounts = new List<Account>();
        for (Integer i = 0; i < 200; i++) {
            Account newAccount = new Account();
            testAccounts.add(newAccount);
        }
        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            testAccounts = Utility.insertRecords(testAccounts);
        } catch (DmlException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'A DML Exception should have been thrown');
    }

    @isTest
    static void insertRecords_missingList() {

        Boolean exceptionThrown = false;
        List<Account> emptyList = new List<Account>();

        Test.startTest();
        try {
            List<Account> testAccounts = Utility.insertRecords(emptyList);
        } catch (IllegalArgumentException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'An Illegal Argument Exception should have been thrown');
    }

    @isTest
    static void updateRecords() {

        Map<String, Account> testAccountsById = TestDataFactory.generateAccountsByName(true, 200);
        Map<Id, String> expectedNamesById = new Map<Id, String>();
        Integer i = 0;
        for (Account acc : testAccountsById.values()) {
            String updatedName = 'Updated Name ' + i;
            acc.Name = updatedName;
            expectedNamesById.put(acc.Id, updatedName);
        }

        Test.startTest();
        List<Account> updatedAccounts = Utility.updateRecords(testAccountsById.values());
        Test.stopTest();

        for (Account acc : updatedAccounts) {
            String expectedName = expectedNamesById.get(acc.Id);
            Assert.areEqual(expectedName, acc.Name, 'The Account does not have the expected updated name');
        }
    }

    @isTest
    static void updateRecords_missingReqField() {

        Map<String, Account> testAccountsById = TestDataFactory.generateAccountsByName(true, 200);
        for (Account acc : testAccountsById.values()) {
            acc.Name = null;
        }

        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            List<Account> updatedAccounts = Utility.updateRecords(testAccountsById.values());
        } catch (DmlException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'A DML Exception should have been thrown');
    }

    @isTest
    static void updateRecords_missingList() {

        Boolean exceptionThrown = false;
        List<Account> emptyList = new List<Account>();

        Test.startTest();
        try {
            List<Account> testAccounts = Utility.updateRecords(emptyList);
        } catch (IllegalArgumentException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'An Illegal Argument Exception should have been thrown');
    }

    @isTest 
    static void getSObjectFieldValueLoweredNoWhiteSpace_normalCasingSpacing() {

        Job_Application__c testJobApp = new Job_Application__c();
        testJobApp.Job_Title__c = 'Test Job Title';
        String expectedReturnValue = 'testjobtitle';

        Test.startTest();
        String returnedValue = Utility.getSObjectFieldValueLoweredNoWhiteSpace(testJobApp, 'Job_Title__c');
        Test.stopTest();

        Assert.areEqual(expectedReturnValue, returnedValue);
    }

    @isTest 
    static void getSObjectFieldValueLoweredNoWhiteSpace_allCapsWhitespace() {

        Job_Application__c testJobApp = new Job_Application__c();
        testJobApp.Job_Title__c = 'TEST JOB TITLE';
        String expectedReturnValue = 'testjobtitle';

        Test.startTest();
        String returnedValue = Utility.getSObjectFieldValueLoweredNoWhiteSpace(testJobApp, 'Job_Title__c');
        Test.stopTest();

        Assert.areEqual(expectedReturnValue, returnedValue);
    }

    @isTest 
    static void getSObjectFieldValueLoweredNoWhiteSpace_normalCasingTrailingWhitespace() {

        Job_Application__c testJobApp = new Job_Application__c();
        testJobApp.Job_Title__c = ' Test Job Title ';
        String expectedReturnValue = 'testjobtitle';

        Test.startTest();
        String returnedValue = Utility.getSObjectFieldValueLoweredNoWhiteSpace(testJobApp, 'Job_Title__c');
        Test.stopTest();

        Assert.areEqual(expectedReturnValue, returnedValue);
    }

    @isTest 
    static void getSObjectFieldValueLoweredNoWhiteSpace_nullSObject() {

        Job_Application__c testJobApp = new Job_Application__c();
        Boolean exceptionThrown = true;

        Test.startTest();
        try {
            String returnedValue = Utility.getSObjectFieldValueLoweredNoWhiteSpace(testJobApp, 'Job_Title__c');
        } catch (IllegalArgumentException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'An Illegal Argument Exception should have been thrown');
    }

    @isTest 
    static void getSObjectFieldValueLoweredNoWhiteSpace_nullField() {

        Job_Application__c testJobApp = new Job_Application__c();
        testJobApp.Job_Title__c = ' Test Job Title ';
        Boolean exceptionThrown = true;

        Test.startTest();
        try {
            String returnedValue = Utility.getSObjectFieldValueLoweredNoWhiteSpace(testJobApp, null);
        } catch (IllegalArgumentException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'An Illegal Argument Exception should have been thrown');
    }

    @isTest 
    static void checkStringMatchesPattern_true() {

        String pattern = '\\$\\d{1,3}k';
        String stringToCheck = '$100k';

        Test.startTest();
        Boolean result = Utility.checkStringMatchesPattern(stringToCheck, pattern);
        Test.stopTest();

        Assert.isTrue(result, 'The string should match the pattern');
    }

    @isTest 
    static void checkStringMatchesPattern_false() {

        String pattern = '\\$\\d{1,3}k';
        String stringToCheck = '100k';

        Test.startTest();
        Boolean result = Utility.checkStringMatchesPattern(stringToCheck, pattern);
        Test.stopTest();

        Assert.isFalse(result, 'The string should match the pattern');
    }

    @isTest 
    static void checkStringMatchesPattern_nullPattern() {

        String pattern = null;
        String stringToCheck = '100k';
        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            Utility.checkStringMatchesPattern(stringToCheck, pattern);
        } catch (IllegalArgumentException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'An Illegal Argument Exception should have been thrown');
    }

    @isTest 
    static void checkStringMatchesPattern_nullSting() {

        String pattern = '\\$\\d{1,3}k';
        String stringToCheck = null;
        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            Utility.checkStringMatchesPattern(stringToCheck, pattern);
        } catch (IllegalArgumentException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'An Illegal Argument Exception should have been thrown');
    }
}