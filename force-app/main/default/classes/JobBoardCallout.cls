public with sharing class JobBoardCallout {

    // Didn't go cacheable = true because if a user refreshes the same search on the LWC, nothing happens and it is weird
    @AuraEnabled
    public static Map<String, Object> getJobs (String jobKeywords, String jobLocation, String pageNumber) {
        
        if (jobKeywords == null || jobLocation == null || pageNumber == null) {
            Utility.throwIllegalArgumentException('An argument was null.');
        }

        // Get details of the callout to be performed from Custom Metadata
        Callout_Configuration__mdt calloutDetails = Callout_Configuration__mdt.getInstance('Jooble_Post');
        
        // Call various methods that help process, check and prepare the data
        HttpResponse calloutResponse = performJoobleCallout(jobKeywords, jobLocation, pageNumber, calloutDetails);
        Map<String, Object> deserializedJson = deserializeJsonAndCheckForKeys(calloutResponse.getBody());
        List<Map<String, Object>> jobsDataByAttributes = extractListOfJobsFromJson(deserializedJson, 'jobs');
        Integer jobCountFromDeserializedJson = Integer.valueOf(deserializedJson.get('totalCount'));
        checkJobDataForMissingInfo(jobsDataByAttributes, jobCountFromDeserializedJson);
        List<Integration_Field_Mapping__mdt> jobDataKeys = 
            IntegrationFieldMappingSelector.getMappingsFromRelatedCalloutConfig(calloutDetails.Id);
        
        // Get mappings that will help map fields from the integration to SF Job Application records
        Integration_Field_Mapping__mdt idMapping = IntegrationFieldMappingHelper.getIdMapping(jobDataKeys);
        if (idMapping == null || jobDataKeys.isEmpty()) {
            Utility.throwAuraHandledException('The CMDT integration mappings are not setup correctly.');
        }

        // Call methods that help validate if the Job Applications already exist in SF and shouldn't be shown for selection
        Set<String> jobIds = extractJobIdsFromJobs(jobsDataByAttributes, idMapping);
        List<Job_Application__c> jobsAlreadySaved = JobApplicationSelector.getJobAppsWithExternalJobId(jobIds);
        if (jobIds.size() == jobsAlreadySaved.size()) {
            Utility.throwUiFriendlyException('You have already saved all of the jobs returned by the search!');
        }
        Set<String> alreadySavedJobIds = new Set<String>();
        if (!jobsAlreadySaved.isEmpty()) {
            alreadySavedJobIds = Utility.getSetOfStringsFromField(jobsAlreadySaved, 'Job_Posting_Id__c');
        }
        
        // Prepare the job data in a format that can be consumed by the client
        List<Map<String, String>> jobDataForClient = IntegrationFieldMappingHelper.prepareJobDataForUserSelection(
            jobDataKeys, idMapping.Key__c, jobsDataByAttributes, alreadySavedJobIds);

        /* When calling the Jooble API, it was saying it had a specified amount of Jobs, but when I was trying to navigate
        through pages to get them, it just cut off returning jobs at a certain point, way below the total jobs. So, this is just
        to set a max number of pages based on what I saw so this didn't happen in the UI. I have a video if you care for future
        cohorts - it was a time suck figuring out what was going on!*/
        Integer maxPagesToDisplay = calculateMaxPagesOfJobs(calloutDetails, jobCountFromDeserializedJson);
        Integer maxJobs = calculateMaxJobsToDisplay(calloutDetails, maxPagesToDisplay);

        // Bundle the job data with the job count and return that to the LWC
        Map<String, Object> jobDataAndVolumeForClient = new Map<String, Object>();
        jobDataAndVolumeForClient.put('jobs', jobDataForClient);
        jobDataAndVolumeForClient.put('jobCount', maxJobs);
        jobDataAndVolumeForClient.put('maxPages', maxPagesToDisplay);
        return jobDataAndVolumeForClient;
    }

    public static HttpResponse performJoobleCallout (
        String jobKeywords, String jobLocation, String pageNumber, Callout_Configuration__mdt calloutDetails) {
        
        if (jobKeywords == null || jobLocation == null || pageNumber == null || calloutDetails == null) {
            Utility.throwIllegalArgumentException('An argument was null.');
        }
        
        // Create the callout request from CMDT passed into the method
        Http callout = new Http();
        HttpRequest calloutRequest = new HttpRequest();
        String calloutString = calloutDetails.Body__c;
        calloutString = calloutString.replace('***jobKeywords***', jobKeywords);
        calloutString = calloutString.replace('***jobLocation***', jobLocation);
        calloutString = calloutString.replace('***recordCount***', calloutDetails.Record_Count_To_Get__c);
        calloutString = calloutString.replace('***pageNumber***', pageNumber);
        calloutRequest.setBody(calloutString);
        calloutRequest.setEndpoint(calloutDetails.Endpoint__c + calloutDetails.API_Key__c);
        calloutRequest.setMethod(calloutDetails.Method__c);
        calloutRequest.setHeader(calloutDetails.Header_Key__c, calloutDetails.Header_Value__c);
        
        // Send the callout and throw an exception back to the client if we have an issue.
        HttpResponse calloutResponse = callout.send(calloutRequest);
        if (!Utility.checkIfResponseCodeIsSuccess(calloutResponse.getStatusCode())){
            Utility.throwCalloutException(
                calloutResponse.getStatusCode(), 'An error occurred with a callout.');
        }
        // Return successful callout
        return calloutResponse;
    }

    public static Map<String, Object> deserializeJsonAndCheckForKeys (String calloutResponse) {
        // Deserialize the JSON and check the expected keys are present
        Map<String, Object> deserializedJson = Utility.deserializeJson(calloutResponse);
        if (!deserializedJson.containsKey('totalCount')) {
            Utility.throwAuraHandledException('The job data is missing the totalCount key.');
        }
        if (!deserializedJson.containsKey('jobs')) {
            Utility.throwAuraHandledException('The job data is missing the jobs key.');
        }
        return deserializedJson;
    }

    public static List<Map<String, Object>> extractListOfJobsFromJson(Map<String, Object> deserializedJson, String jobsKey) {
        if (deserializedJson.isEmpty() || jobsKey == null) {
            Utility.throwIllegalArgumentException('An argument was null.');
        }
        List<Object> jobsFromKey = (List<Object>)deserializedJson.get(jobsKey);
        List<Map<String, Object>> jobsDataByAttributes = new List<Map<String, Object>>();
        for (Object job : jobsFromKey) {
            Map<String, Object> jobByKey = (Map<String, Object>)job;
            jobsDataByAttributes.add(jobByKey);
        }
        return jobsDataByAttributes;
    }
    
    public static void checkJobDataForMissingInfo (List<Map<String, Object>> jobDataBeforeProcessing, Integer jobCount) {
        Map<String, Object> mapWithErrorInfo = new Map<String, Object>();
        if (jobDataBeforeProcessing.isEmpty() || jobCount == null || jobCount == 0) {
            Utility.throwUiFriendlyException('No jobs met your search criteria. Try again!');
        }
    }

    public static Set<String> extractJobIdsFromJobs(
        List<Map<String, Object>> jobsDataByAttributes, Integration_Field_Mapping__mdt idMapping) {
        Set<String> extractedJobIds = new Set<String>();
        for (Map<String, Object> job : jobsDataByAttributes) {
            if (String.valueOf(job.get(idMapping.Key__c)) != null) {
                extractedJobIds.add(String.valueOf(job.get(idMapping.Key__c)));
            }
        }
        return extractedJobIds;
    }

    public static Integer calculateMaxPagesOfJobs(Callout_Configuration__mdt config, Integer totalJobCount) {

        if (config == null || totalJobCount == null) {
            Utility.throwIllegalArgumentException('An argument was null.');
        }

        Integer maxPagesToAllowInClient = 0;
        Integer maxJobsToDisplay = Integer.valueOf(config.Record_Count_To_Get__c) * Integer.valueOf(config.Max_Pages__c);
        if (totalJobCount > maxJobsToDisplay) {
            maxPagesToAllowInClient = Integer.valueOf(config.Max_Pages__c);
        } else {
            Math.ceil(maxPagesToAllowInClient = (totalJobCount / Integer.valueOf(config.Record_Count_To_Get__c)));
        }
        return maxPagesToAllowInClient;
    }

    public static Integer calculateMaxJobsToDisplay(Callout_Configuration__mdt config, Integer maxPages) {

        if (config == null || maxPages == null) {
            Utility.throwIllegalArgumentException('An argument was null.');
        }

        Integer maxJobsToDisplay = Integer.valueOf(config.Record_Count_To_Get__c) * maxPages;
        return maxJobsToDisplay;
    }
    
    @AuraEnabled
    public static String processSelectedJobs(List<Map<String, Object>> selectedJobs) {

        // Get CMDT that will help with mapping values from selected Jobs to SF Job Applications
        Id joobleCalloutId = Callout_Configuration__mdt.getInstance('Jooble_Post').Id;
        List<Integration_Field_Mapping__mdt> jobMappings = IntegrationFieldMappingSelector.getMappingsFromRelatedCalloutConfig(joobleCalloutId);

        // Find the field mappings that reference the Account and Job_Posting_Id as they are potentially used for Account names. Throw an exception if either are null
        // Ideally, I wouldn't call this method twice and do it in one call, but this prevents a last minute bug I found that I didn't have time to fix in a better way
        Integration_Field_Mapping__mdt accountNameMapping = IntegrationFieldMappingHelper.getCalloutMappingForObjectAndField(jobMappings, 'Account', 'Name');
        Integration_Field_Mapping__mdt jobPostingIdMapping = IntegrationFieldMappingHelper.getCalloutMappingForObjectAndField(jobMappings, 'Job_Application__c', 'Job_Posting_Id__c');
        if (accountNameMapping == null || jobPostingIdMapping == null) {
            Utility.throwAuraHandledException('A mapping to help identify existing Account records and set new Account Names could not be found.');
        }

        // Build a Set of Company Names so we can see if Accounts already exist for them
        // If the Job doesn't have a Company Name, the Job Posting Id will be in the Set and used as the Account Name
        Set<String> companyNamesForSelectedJobs = 
            Utility.getSingleStringFromEachMapInList(accountNameMapping.Key__c, jobPostingIdMapping.Key__c, selectedJobs);

        // Get Accounts and the oldest Contact associated with them, since they will be the Job App Contact if one exists
        List<Account> existingAccountsForCompanies = AccountSelector.getAccountsAndOldestContact(companyNamesForSelectedJobs);

        // Loop the Account records and build Maps that will help with processing later in the method
        Map<String, Account> accountsByCompanyName = new Map<String, Account>();
        Map<Id, String> accountNameById = new Map<Id, String>();
        for (Account acc : existingAccountsForCompanies) {
            accountsByCompanyName.put(acc.Name, acc);
            accountNameById.put(acc.Id, acc.Name);
        }

        // Return a Map of Account sObjects by Company Name for the companies that need one and then insert the Accounts
        Map<String, Account> newAccountsByCompanyName = 
            AccountHelper.generateAccountsForNamesNotInSet(companyNamesForSelectedJobs, accountsByCompanyName);
        if (!newAccountsByCompanyName.values().isEmpty()) {
            List<Account> newAccounts = Utility.insertRecords(newAccountsByCompanyName.values());
            // Add the new Accounts to the existing Account maps that will help with processing
            for (Account newAccountForJob : newAccounts) {
                accountsByCompanyName.put(newAccountForJob.Name, newAccountForJob);
                accountNameById.put(newAccountForJob.Id, newAccountForJob.Name);
            }
        }

        // Loop the selected Jobs and insert the Job Application records
        List<Job_Application__c> selectedJobApplications = JobApplicationHelper.generateJobApplicationsFromSelectedJobs(
            selectedJobs, accountNameMapping.Key__c, accountsByCompanyName, jobMappings);
        selectedJobApplications = Utility.insertRecords(selectedJobApplications);

        // Create Job Application Contacts when the Account associated with the Job Application has an exisitng Contact
        List<Job_Application_Contact__c> newJobAppContacts = JobApplicationContactHelper.generateContactsForNewJobApplications(
            selectedJobApplications, accountNameById, accountsByCompanyName, 'Existing Contact');
        if (!newJobAppContacts.isEmpty()) {
            newJobAppContacts = Utility.insertRecords(newJobAppContacts);
        }
        String message = 'Success';
        return message;
    }
}