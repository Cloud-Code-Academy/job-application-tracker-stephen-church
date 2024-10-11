@isTest
public with sharing class IntegrationFieldMappingHelperTest {

    @IsTest
    static void getIdMapping_positive() {

        // Get an Integration Field Mapping that represents an Id field
        Integration_Field_Mapping__mdt idMapping = [
            SELECT Id, Callout_Configuration__c
            FROM Integration_Field_Mapping__mdt
            WHERE Id_Field__c = true
            LIMIT 1
        ];

        // Get all of the Integration Field Mappings for the same callout configuration
        List<Integration_Field_Mapping__mdt> mappingsForCalloutConfig = [
            SELECT Id, Id_Field__c, Callout_Configuration__c
            FROM Integration_Field_Mapping__mdt
            WHERE Callout_Configuration__c = :idMapping.Callout_Configuration__c
        ];

        Test.startTest();
        Integration_Field_Mapping__mdt returnedIdMapping = IntegrationFieldMappingHelper.getIdMapping(mappingsForCalloutConfig);
        Test.stopTest();

        // Assert the returned Id mapping is the expected Id Mapping
        Assert.isTrue(returnedIdMapping.Id == idMapping.Id, 'The Integration Field Mapping is not the expected Id mapping');
    }

    @isTest
    static void getIdMapping_noneReturned() {

        // Get all Integration Field Mappings where the Id field is not selected
        List<Integration_Field_Mapping__mdt> nonIdIntegrationMappings = [
            SELECT Id, Id_Field__c
            FROM Integration_Field_Mapping__mdt
            WHERE Id_Field__c = FALSE
        ];

        Test.startTest();
        Integration_Field_Mapping__mdt returnedIdMapping = IntegrationFieldMappingHelper.getIdMapping(nonIdIntegrationMappings);
        Test.stopTest();

        // Assert that the Id Mapping returned is null, since no Id Mappings were obtained via the query. Assert didn't work directly on the sObject since it isn't technically null.
        Assert.isNull(returnedIdMapping.Id, 'No Integration Field Mappings should be returned since the query filtered out Id Field mappings');
    }

    @isTest
    static void getIdMapping_illegalArgument() {

        List<Integration_Field_Mapping__mdt> emptyList = new List<Integration_Field_Mapping__mdt>();
        Boolean exceptionThrown = false;

        Test.startTest();
        try{
            Integration_Field_Mapping__mdt returnedIdMapping = IntegrationFieldMappingHelper.getIdMapping(emptyList);
        } catch (IllegalArgumentException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'An Illegal Argument exception should have been thrown');
    }

    @isTest
    static void getCalloutMappingForObjectAndField_positive() {

        // Get an Integration Field Mapping that has an Object and Field mapping
        Integration_Field_Mapping__mdt objectFieldMapping = [
            SELECT Id, Salesforce_Object__c, Field_API_Name__c, Callout_Configuration__c
            FROM Integration_Field_Mapping__mdt
            WHERE Salesforce_Object__c != null
            AND Field_API_Name__c != null
            LIMIT 1
        ];

        // Get the other Integration Field Mappings for that Callout Config and add the above to the list
        List<Integration_Field_Mapping__mdt> otherFieldMappings = [
            SELECT Id, Salesforce_Object__c, Field_API_Name__c, Callout_Configuration__c
            FROM Integration_Field_Mapping__mdt
            WHERE Callout_Configuration__c = :objectFieldMapping.Callout_Configuration__c
            AND Id != :objectFieldMapping.Id
        ];
        List<Integration_Field_Mapping__mdt> allFieldMappings = new List<Integration_Field_Mapping__mdt>();
        allFieldMappings.addAll(otherFieldMappings);
        allFieldMappings.add(objectFieldMapping);

        // Validate that the returned mapping is the one for the specific Object / Field mapping obtained up front
        Test.startTest();
        Integration_Field_Mapping__mdt returnedMapping = 
            IntegrationFieldMappingHelper.getCalloutMappingForObjectAndField(allFieldMappings, objectFieldMapping.Salesforce_Object__c, objectFieldMapping.Field_API_Name__c);
        Test.stopTest();

        Assert.areEqual(objectFieldMapping.Id, returnedMapping.Id, 'The returned mapping should be Id: ' + objectFieldMapping.Id + '. It was ' + returnedMapping.Id);
    }

    @isTest
    static void getCalloutMappingForObjectAndField_noneReturned() {

        // Get an Integration Field Mapping that has an Object and Field mapping
        Integration_Field_Mapping__mdt objectFieldMapping = [
            SELECT Id, Salesforce_Object__c, Field_API_Name__c, Callout_Configuration__c
            FROM Integration_Field_Mapping__mdt
            WHERE Salesforce_Object__c != null
            AND Field_API_Name__c != null
            LIMIT 1
        ];

        // Get the other Integration Field Mappings for that Callout Config
        List<Integration_Field_Mapping__mdt> otherFieldMappings = [
            SELECT Id, Salesforce_Object__c, Field_API_Name__c, Callout_Configuration__c
            FROM Integration_Field_Mapping__mdt
            WHERE Callout_Configuration__c = :objectFieldMapping.Callout_Configuration__c
            AND Id != :objectFieldMapping.Id
        ];

        // Validate no mapping returned since the one obtained up front that was requested was not in the List passed to the method
        Test.startTest();
        Integration_Field_Mapping__mdt returnedMapping = 
            IntegrationFieldMappingHelper.getCalloutMappingForObjectAndField(otherFieldMappings, objectFieldMapping.Salesforce_Object__c, objectFieldMapping.Field_API_Name__c);
        Test.stopTest();

        Assert.isNull(returnedMapping.Id, 'No mapping should have been returned. The following was returned: ' + returnedMapping);
    }

    @isTest
    static void getCalloutMappingForObjectAndField_emptyList() {

        // Get an Integration Field Mapping that has an Object and Field mapping and create an empty list to pass to the other
        Integration_Field_Mapping__mdt objectFieldMapping = [
            SELECT Id, Salesforce_Object__c, Field_API_Name__c, Callout_Configuration__c
            FROM Integration_Field_Mapping__mdt
            WHERE Salesforce_Object__c != null
            AND Field_API_Name__c != null
            LIMIT 1
        ];
        List<Integration_Field_Mapping__mdt> emptyList = new List<Integration_Field_Mapping__mdt>();
        Boolean exceptionThrown = false;

        // Validate an illegal argument exception is received since an empty list was passed to the method
        Test.startTest();
        try {
            Integration_Field_Mapping__mdt returnedMapping = 
                IntegrationFieldMappingHelper.getCalloutMappingForObjectAndField(emptyList, objectFieldMapping.Salesforce_Object__c, objectFieldMapping.Field_API_Name__c);
        } catch (IllegalArgumentException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'An illegal argument exception should have been thrown');
    }

    @isTest
    static void getCalloutMappingForObjectAndField_missingObject() {

        // Get an Integration Field Mapping that has an Object and Field mapping
        List<Integration_Field_Mapping__mdt> objectFieldMapping = [
            SELECT Id, Salesforce_Object__c, Field_API_Name__c, Callout_Configuration__c
            FROM Integration_Field_Mapping__mdt
            WHERE Salesforce_Object__c != null
            AND Field_API_Name__c != null
            LIMIT 1
        ];
        Boolean exceptionThrown = false;
        String nullString = null;

        // Validate an illegal argument exception is received since an empty list was passed to the method
        Test.startTest();
        try {
            Integration_Field_Mapping__mdt returnedMapping = 
                IntegrationFieldMappingHelper.getCalloutMappingForObjectAndField(objectFieldMapping, nullString, objectFieldMapping.get(0).Field_API_Name__c);
        } catch (IllegalArgumentException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'An illegal argument exception should have been thrown');
    }

    @isTest
    static void getCalloutMappingForObjectAndField_missingField() {

        // Get an Integration Field Mapping that has an Object and Field mapping
        List<Integration_Field_Mapping__mdt> objectFieldMapping = [
            SELECT Id, Salesforce_Object__c, Field_API_Name__c, Callout_Configuration__c
            FROM Integration_Field_Mapping__mdt
            WHERE Salesforce_Object__c != null
            AND Field_API_Name__c != null
            LIMIT 1
        ];
        Boolean exceptionThrown = false;
        String nullString = null;

        // Validate an illegal argument exception is received since an empty list was passed to the method
        Test.startTest();
        try {
            Integration_Field_Mapping__mdt returnedMapping = 
                IntegrationFieldMappingHelper.getCalloutMappingForObjectAndField(objectFieldMapping, objectFieldMapping.get(0).Salesforce_Object__c, nullString);
        } catch (IllegalArgumentException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'An illegal argument exception should have been thrown');
    }

    @isTest
    static void prepareJobDataForUserSelection_happyPath() {

        // Get Integration Field Mappings for Jooble Post
        Callout_Configuration__mdt joobleCallout = Callout_Configuration__mdt.getInstance('Jooble_Post');
        List<Integration_Field_Mapping__mdt> joobleMappings = [
            SELECT Id, Key__c, Salesforce_Object__c, Id_Field__c
            FROM Integration_Field_Mapping__mdt
            WHERE Callout_Configuration__c = :joobleCallout.Id
        ];

        // Loop the mappings to extract the one that represents the Id mapping
        String idMappingKey = null;
        for (Integration_Field_Mapping__mdt checkIdMapping : joobleMappings) {
            if (checkIdMapping.Id_Field__c) {
                idMappingKey = checkIdMapping.Key__c;
            }
        }

        // Setup two fake jobs and put their Id values in the Set to mimick the Job already existing in SF and - as a result - not being returned by the method
        Set<String> externalJobIdSet = new Set<String>();
        List<Map<String, Object>> jobsToNotReturn = new List<Map<String, Object>>();
        for (Integer i = 0; i < 2; i++) {
            Map<String, Object> jobToNotReturn = new Map<String, Object>();
            for (Integration_Field_Mapping__mdt mapping : joobleMappings) {
                String testValueForJobToNotReturn = 'Job To Not Return ' + i + ' - ' + mapping.Key__c;
                jobToNotReturn.put(mapping.Key__c, testValueForJobToNotReturn);
                if (mapping.Key__c == idMappingKey) {
                    externalJobIdSet.add(testValueForJobToNotReturn);
                }
                jobsToNotReturn.add(jobToNotReturn);
            }
        }

        // Setup two fake jobs and don't put their Id values in the Set to mimick the Jobs not existing in SF and - as a result - being returned by the method
        List<Map<String, Object>> jobsToReturn = new List<Map<String, Object>>();
        for (Integer i = 0; i < 2; i++) {
            Map<String, Object> jobToReturn = new Map<String, Object>();
            for (Integration_Field_Mapping__mdt mapping : joobleMappings) {
                String testValueForJobToReturn = 'Job To Return ' + i + ' - ' + mapping.Key__c;
                jobToReturn.put(mapping.Key__c, testValueForJobToReturn);
            }
            jobsToReturn.add(jobtoReturn);
        }

        // Add all Jobs to a List to be passed to the method
        List<Map<String, Object>> allJobs = new List<Map<String, Object>>();
        allJobs.addAll(jobsToNotReturn);
        allJobs.addAll(jobsToReturn);

        Test.startTest();
        List<Map<String, String>> jobsToDisplay = IntegrationFieldMappingHelper.prepareJobDataForUserSelection(
            joobleMappings, idMappingKey, allJobs, externalJobIdSet);
        Test.stopTest();

        // Assert the expected size of jobs was returned, as well as each individual job expected to be returned
        Assert.isTrue(jobsToDisplay.size() == 2, 'The returned list should have 2 jobs. It has ' + jobsToDisplay.size());
        Map<String, Object> firstExpectedJob = jobsToReturn.get(0);
        Map<String, Object> secondExpectedJob = jobsToReturn.get(1);
        Map<String, String> firstActualJob = jobsToDisplay.get(0);
        Map<String, String> secondActualJob = jobsToDisplay.get(1);
        Boolean firstExpectedJobReturned = false;
        Boolean secondExpectedJobReturned = false;
        if (firstExpectedJob == firstActualJob || firstExpectedJob == secondActualJob) {
            firstExpectedJobReturned = true;
        }
        if (secondExpectedJob == firstActualJob || secondExpectedJob == secondActualJob) {
            secondExpectedJobReturned = true;
        }
        Assert.isTrue(firstExpectedJobReturned, 'The first expected job was not returned: ' + firstExpectedJob);
        Assert.isTrue(secondExpectedJobReturned, 'The second expected job was not returned: ' + secondExpectedJob);
    }

    @isTest
    static void prepareJobDataForUserSelection_emptyMappings() {

        // Get Integration Field Mappings for Jooble Post
        Callout_Configuration__mdt joobleCallout = Callout_Configuration__mdt.getInstance('Jooble_Post');
        List<Integration_Field_Mapping__mdt> joobleMappings = [
            SELECT Id, Key__c, Salesforce_Object__c, Id_Field__c
            FROM Integration_Field_Mapping__mdt
            WHERE Callout_Configuration__c = :joobleCallout.Id
        ];

        // Loop the mappings to extract the one that represents the Id mapping
        String idMappingKey = null;
        for (Integration_Field_Mapping__mdt checkIdMapping : joobleMappings) {
            if (checkIdMapping.Id_Field__c) {
                idMappingKey = checkIdMapping.Key__c;
            }
        }

        // Create an empty list of Integration Field Mapping so we can see how the code handles receiving that
        List<Integration_Field_Mapping__mdt> emptyMappingList = new List<Integration_Field_Mapping__mdt>();

        // Setup two fake jobs and put their Id values in the Set
        Set<String> externalJobIdSet = new Set<String>();
        List<Map<String, Object>> jobsToNotReturn = new List<Map<String, Object>>();
        for (Integer i = 0; i < 2; i++) {
            Map<String, Object> jobToNotReturn = new Map<String, Object>();
            for (Integration_Field_Mapping__mdt mapping : joobleMappings) {
                String testValueForJobToNotReturn = 'Job To Not Return ' + i + ' - ' + mapping.Key__c;
                jobToNotReturn.put(mapping.Key__c, testValueForJobToNotReturn);
                if (mapping.Key__c == idMappingKey) {
                    externalJobIdSet.add(testValueForJobToNotReturn);
                }
                jobsToNotReturn.add(jobToNotReturn);
            }
        }

        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            List<Map<String, String>> jobsToDisplay = IntegrationFieldMappingHelper.prepareJobDataForUserSelection(
                emptyMappingList, idMappingKey, jobsToNotReturn, externalJobIdSet);
        } catch (IllegalArgumentException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        // Assert an illegal argument exception was thrown since the mappings were an empty list
        Assert.isTrue(exceptionThrown, 'An illegal argument exception should have been thrown');
    }

    @isTest
    static void prepareJobDataForUserSelection_emptyIdMapping() {

        // Get Integration Field Mappings for Jooble Post
        Callout_Configuration__mdt joobleCallout = Callout_Configuration__mdt.getInstance('Jooble_Post');
        List<Integration_Field_Mapping__mdt> joobleMappings = [
            SELECT Id, Key__c, Salesforce_Object__c, Id_Field__c
            FROM Integration_Field_Mapping__mdt
            WHERE Callout_Configuration__c = :joobleCallout.Id
        ];

        // Loop the mappings to extract the one that represents the Id mapping
        String idMappingKey = null;
        for (Integration_Field_Mapping__mdt checkIdMapping : joobleMappings) {
            if (checkIdMapping.Id_Field__c) {
                idMappingKey = checkIdMapping.Key__c;
            }
        }

        // Create a null Id mapping key as null so we can test that an exception is thrown
        String nullIdMappingKey = null;

        // Setup two fake jobs and put their Id values in the Set
        Set<String> externalJobIdSet = new Set<String>();
        List<Map<String, Object>> jobsToNotReturn = new List<Map<String, Object>>();
        for (Integer i = 0; i < 2; i++) {
            Map<String, Object> jobToNotReturn = new Map<String, Object>();
            for (Integration_Field_Mapping__mdt mapping : joobleMappings) {
                String testValueForJobToNotReturn = 'Job To Not Return ' + i + ' - ' + mapping.Key__c;
                jobToNotReturn.put(mapping.Key__c, testValueForJobToNotReturn);
                if (mapping.Key__c == idMappingKey) {
                    externalJobIdSet.add(testValueForJobToNotReturn);
                }
                jobsToNotReturn.add(jobToNotReturn);
            }
        }

        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            List<Map<String, String>> jobsToDisplay = IntegrationFieldMappingHelper.prepareJobDataForUserSelection(
                joobleMappings, nullIdMappingKey, jobsToNotReturn, externalJobIdSet);
        } catch (IllegalArgumentException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        // Assert an illegal argument exception was thrown since the mappings were an empty list
        Assert.isTrue(exceptionThrown, 'An illegal argument exception should have been thrown');
    }

    @isTest
    static void prepareJobDataForUserSelection_emptyJobData() {

        // Get Integration Field Mappings for Jooble Post
        Callout_Configuration__mdt joobleCallout = Callout_Configuration__mdt.getInstance('Jooble_Post');
        List<Integration_Field_Mapping__mdt> joobleMappings = [
            SELECT Id, Key__c, Salesforce_Object__c, Id_Field__c
            FROM Integration_Field_Mapping__mdt
            WHERE Callout_Configuration__c = :joobleCallout.Id
        ];

        // Loop the mappings to extract the one that represents the Id mapping
        String idMappingKey = null;
        for (Integration_Field_Mapping__mdt checkIdMapping : joobleMappings) {
            if (checkIdMapping.Id_Field__c) {
                idMappingKey = checkIdMapping.Key__c;
            }
        }

        // Create a variable of empty job data to see how the code handles that
        Set<String> externalJobIdSet = new Set<String>();
        List<Map<String, Object>> jobsToNotReturn = new List<Map<String, Object>>();

        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            List<Map<String, String>> jobsToDisplay = IntegrationFieldMappingHelper.prepareJobDataForUserSelection(
                joobleMappings, idMappingKey, jobsToNotReturn, externalJobIdSet);
        } catch (IllegalArgumentException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        // Assert an illegal argument exception was thrown since the mappings were an empty list
        Assert.isTrue(exceptionThrown, 'An illegal argument exception should have been thrown');
    }

    @isTest
    static void mapValuesToSingleSObject_happyPath() {

        // Get field mappings for the Jooble callout
        Id joobleCalloutId = Callout_Configuration__mdt.getInstance('Jooble_Post').Id;
        List<Integration_Field_Mapping__mdt> joobleFieldMappings = [
            SELECT Id, Salesforce_Object__c, Field_API_Name__c, Key__c
            FROM Integration_Field_Mapping__mdt
            WHERE Callout_Configuration__c = :joobleCalloutId
        ];

        // Loop the mappings and populate the data to pass to the method and populate a variable of expected field values returned
        Map<String, Object> jobDataToPassToMethod = new Map<String, Object>();
        Map<String, String> expectedFieldValuesReturned = new Map<String, String>();
        Integer i = 0;
        for (Integration_Field_Mapping__mdt mapping : joobleFieldMappings) {
            String testFieldValue = 'Test ' + i;
            jobDataToPassToMethod.put(mapping.Key__c, testFieldValue);
            if (mapping.Field_API_Name__c != null && mapping.Salesforce_Object__c == 'Job_Application__c') {
                expectedFieldValuesReturned.put(mapping.Field_API_Name__c, testFieldValue);
            }
            i += 1;
        }
        Job_Application__c emptyJobAppToPopulate = new Job_Application__c();

        Test.startTest();
        emptyJobAppToPopulate = (Job_Application__c)IntegrationFieldMappingHelper.mapValuesToSingleSObject(
            joobleFieldMappings, 'Job_Application__c', emptyJobAppToPopulate, jobDataToPassToMethod);
        Test.stopTest();

        // Assert that the expected field values are populated on the returned sObject
        Set<String> expectedFieldsToPopulate = expectedFieldValuesReturned.keySet();
        for (String field : expectedFieldsToPopulate) {
            String returnedFieldValue = String.valueOf(emptyJobAppToPopulate.get(field));
            Assert.areEqual(expectedFieldValuesReturned.get(field), returnedFieldValue,
                'The field values to do not match');
        }
    }

    @isTest
    static void mapValuesToSingleSObject_emptyMappings() {

        // Get field mappings for the Jooble callout
        Id joobleCalloutId = Callout_Configuration__mdt.getInstance('Jooble_Post').Id;
        List<Integration_Field_Mapping__mdt> joobleFieldMappings = [
            SELECT Id, Salesforce_Object__c, Field_API_Name__c, Key__c
            FROM Integration_Field_Mapping__mdt
            WHERE Callout_Configuration__c = :joobleCalloutId
        ];

        // Loop the mappings and populate the data to pass to the method and populate a variable of expected field values returned
        Map<String, Object> jobDataToPassToMethod = new Map<String, Object>();
        Integer i = 0;
        for (Integration_Field_Mapping__mdt mapping : joobleFieldMappings) {
            String testFieldValue = 'Test ' + i;
            jobDataToPassToMethod.put(mapping.Key__c, testFieldValue);
            i += 1;
        }
        Job_Application__c emptyJobAppToPopulate = new Job_Application__c();
    
        // Create an empty mappings list to pass to the method
        List<Integration_Field_Mapping__mdt> emptyMappingList = new List<Integration_Field_Mapping__mdt>();
        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            emptyJobAppToPopulate = (Job_Application__c)IntegrationFieldMappingHelper.mapValuesToSingleSObject(
                emptyMappingList, 'Job_Application__c', emptyJobAppToPopulate, jobDataToPassToMethod);
        } catch (IllegalArgumentException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        // Assert that an exception was thrown
        Assert.isTrue(exceptionThrown, 'An illegal argument exception should have been thrown');
    }

    @isTest
    static void mapValuesToSingleSObject_nullTargetSObject() {

        // Get field mappings for the Jooble callout
        Id joobleCalloutId = Callout_Configuration__mdt.getInstance('Jooble_Post').Id;
        List<Integration_Field_Mapping__mdt> joobleFieldMappings = [
            SELECT Id, Salesforce_Object__c, Field_API_Name__c, Key__c
            FROM Integration_Field_Mapping__mdt
            WHERE Callout_Configuration__c = :joobleCalloutId
        ];

        // Loop the mappings and populate the data to pass to the method
        Map<String, Object> jobDataToPassToMethod = new Map<String, Object>();
        Integer i = 0;
        for (Integration_Field_Mapping__mdt mapping : joobleFieldMappings) {
            String testFieldValue = 'Test ' + i;
            jobDataToPassToMethod.put(mapping.Key__c, testFieldValue);
            i += 1;
        }
        Job_Application__c emptyJobAppToPopulate = new Job_Application__c();
    
        // Create an empty mappings list to pass to the method
        String nullSObjectString = null;
        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            emptyJobAppToPopulate = (Job_Application__c)IntegrationFieldMappingHelper.mapValuesToSingleSObject(
                joobleFieldMappings, nullSObjectString, emptyJobAppToPopulate, jobDataToPassToMethod);
        } catch (IllegalArgumentException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        // Assert that an exception was thrown
        Assert.isTrue(exceptionThrown, 'An illegal argument exception should have been thrown');
    }

    @isTest
    static void mapValuesToSingleSObject_wrongTargetSObject() {

        // Get field mappings for the Jooble callout
        Id joobleCalloutId = Callout_Configuration__mdt.getInstance('Jooble_Post').Id;
        List<Integration_Field_Mapping__mdt> joobleFieldMappings = [
            SELECT Id, Salesforce_Object__c, Field_API_Name__c, Key__c
            FROM Integration_Field_Mapping__mdt
            WHERE Callout_Configuration__c = :joobleCalloutId
        ];

        // Loop the mappings and populate the data to pass to the method
        Map<String, Object> jobDataToPassToMethod = new Map<String, Object>();
        Integer i = 0;
        for (Integration_Field_Mapping__mdt mapping : joobleFieldMappings) {
            String testFieldValue = 'Test ' + i;
            jobDataToPassToMethod.put(mapping.Key__c, testFieldValue);
            i += 1;
        }
        Job_Application__c emptyJobAppToPopulate = new Job_Application__c();

        Test.startTest();
            Job_Application__c returnedSObject = (Job_Application__c)IntegrationFieldMappingHelper.mapValuesToSingleSObject(
                joobleFieldMappings, 'Not_a_real_sObject__c', emptyJobAppToPopulate, jobDataToPassToMethod);
        Test.stopTest();

        // Assert that the returned sObject is the same as the empty one passed to the method
        Assert.areEqual(emptyJobAppToPopulate, returnedSObject, 'An empty sObject should have been returned');
    }

    @isTest
    static void mapValuesToSingleSObject_emptyDataToMap() {

        // Get field mappings for the Jooble callout
        Id joobleCalloutId = Callout_Configuration__mdt.getInstance('Jooble_Post').Id;
        List<Integration_Field_Mapping__mdt> joobleFieldMappings = [
            SELECT Id, Salesforce_Object__c, Field_API_Name__c, Key__c
            FROM Integration_Field_Mapping__mdt
            WHERE Callout_Configuration__c = :joobleCalloutId
        ];

        // Create an empty Map to pass to the method to test getting an exception
        Map<String, Object> jobDataToPassToMethod = new Map<String, Object>();
        Job_Application__c emptyJobAppToPopulate = new Job_Application__c();
        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            emptyJobAppToPopulate = (Job_Application__c)IntegrationFieldMappingHelper.mapValuesToSingleSObject(
                joobleFieldMappings, 'Job_Application__c', emptyJobAppToPopulate, jobDataToPassToMethod);
        } catch (IllegalArgumentException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        // Assert that an exception was thrown
        Assert.isTrue(exceptionThrown, 'An illegal argument exception should have been thrown');
    }

    @isTest
    static void getLwcColumnsFromIntegrationFieldMappings() {

        // Get LWC column data for Jooble Post and build a Map of what is expected to be returned by the method call
        Id joobleCalloutId = Callout_Configuration__mdt.getInstance('Jooble_Post').Id;
        List<Integration_Field_Mapping__mdt> lwcColumnData = [
            SELECT Id, Key__c, LWC_Column_Data_Type__c, LWC_Column_Name__c, LWC_Type_Attributes__c
            FROM Integration_Field_Mapping__mdt
            WHERE Callout_Configuration__c = :joobleCalloutId
            AND LWC_Column_Data_Type__c != null
        ];
        Map<String, Map<String, Object>> expectedColumnsByColumnKey = new Map<String, Map<String, Object>>();
        for (Integration_Field_Mapping__mdt mapping : lwcColumnData) {
            Map<String, Object> column = new Map<String, Object>();
            column.put('label', String.valueOf(mapping.LWC_Column_Name__c));
            column.put('fieldName', String.valueOf(mapping.Key__c));
            column.put('type', String.valueOf(mapping.LWC_Column_Data_Type__c));
            column.put('sortable', 'true');
            if (mapping.LWC_Type_Attributes__c != null) {
                // Deserialize the JSON from Custom Metadata to customize the job URL
                Map<String, Object> deserializedTypeAttributes = Utility.deserializeJson(mapping.LWC_Type_Attributes__c);
                column.put('typeAttributes', deserializedTypeAttributes);
            }
            expectedColumnsByColumnKey.put(mapping.Key__c, column);
        }

        Test.startTest();
        List<Map<String, Object>> returnedColumns = IntegrationFieldMappingHelper.getLwcColumnsFromIntegrationFieldMappings('Jooble_Post');
        Test.stopTest();

        for(Map<String, Object> returnedColumn : returnedColumns) {
            String columnKey = String.valueOf(returnedColumn.get('fieldName'));
            Map<String, Object> expectedColumn = expectedColumnsByColumnKey.get(columnKey);
            Assert.areEqual(expectedColumn, returnedColumn, 'The expected column and returned column do not match');
        }
    }

    @isTest
    static void getLwcColumnsFromIntegrationFieldMappings_nullCalloutConfig() {

        String nullString = null;
        Boolean exceptionThrown = false;
        
        Test.startTest();
        try {
            List<Map<String, Object>> returnedColumns = IntegrationFieldMappingHelper.getLwcColumnsFromIntegrationFieldMappings(nullString);
        } catch (IllegalArgumentException e){
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'An illegal argument exception should have been thrown.');
    }

    @isTest
    static void getLwcColumnsFromIntegrationFieldMappings_invalidCalloutConfig() {

        String invalidCalloutString = 'adsadsw2133as';
        Boolean exceptionThrown = false;
        
        Test.startTest();
        try {
            List<Map<String, Object>> returnedColumns = IntegrationFieldMappingHelper.getLwcColumnsFromIntegrationFieldMappings(invalidCalloutString);
        } catch (HandledException e){
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'A handled exception should have been thrown.');
    }
}