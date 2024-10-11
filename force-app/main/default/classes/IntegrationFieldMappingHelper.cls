public with sharing class IntegrationFieldMappingHelper {

    public static Integration_Field_Mapping__mdt getIdMapping (List<Integration_Field_Mapping__mdt> mappings) {
        
        if (mappings.isEmpty()){
            Utility.throwIllegalArgumentException('mappings arugment was null.');
        }
        
        Integration_Field_Mapping__mdt idMapping = new Integration_Field_Mapping__mdt();
        for (Integration_Field_Mapping__mdt mapping : mappings) {
            if (mapping.Id_Field__c) {
                idMapping = mapping;
                break;
            }
        }
        return idMapping;
    }

    public static Integration_Field_Mapping__mdt getCalloutMappingForObjectAndField (
        List<Integration_Field_Mapping__mdt> mappings,
        String objectMappedTo,
        String fieldApiNameMappedTo) {
        
        if (mappings.isEmpty() || objectMappedTo == null || fieldApiNameMappedTo == null){
            Utility.throwIllegalArgumentException('An argument was null.');
        }
        
        Integration_Field_Mapping__mdt mappingToReturn = new Integration_Field_Mapping__mdt();
        for (Integration_Field_Mapping__mdt mapping : mappings) {
            if (mapping.Salesforce_Object__c == objectMappedTo && mapping.Field_API_Name__c == fieldApiNameMappedTo) {
                mappingToReturn = mapping;
                break;
            }
        }
        return mappingToReturn;
    }

    public static List<Map<String, String>> prepareJobDataForUserSelection (
        List<Integration_Field_Mapping__mdt> jobDataMappings, 
        String jobIdMappingName, 
        List<Map<String, Object>> jobData, 
        Set<String> alreadySavedJobIds) {

        if (jobDataMappings.isEmpty() || jobData.isEmpty() || jobIdMappingName == null) {
            Utility.throwIllegalArgumentException('An argument was null.');
        }

        List<Map<String, String>> jobDataToReturn = new List<Map<String, String>>();
        for (Map<String, Object> job : jobData) {
            String jobId = String.valueOf(job.get(jobIdMappingName));
            // If the Job hasn't been saved in SF, prepare the data to be returned to the UI a User can select from
            if (!alreadySavedJobIds.contains(jobId)) {
                Map<String, String> jobToReturn = new Map<String, String>();
                for (Integration_Field_Mapping__mdt mapping : jobDataMappings) {
                    jobToReturn.put(mapping.Key__c, String.valueOf(job.get(mapping.Key__c)));
                }
                jobDataToReturn.add(jobToReturn);
            }
        }
        return jobDataToReturn;
    }

    public static sObject mapValuesToSingleSObject (
        List<Integration_Field_Mapping__mdt> mappings, 
        String targetSObject, 
        sObject record,
        Map<String, Object> dataToMap) {

        if (mappings.isEmpty() || targetSObject == null || dataToMap.isEmpty()) {
            Utility.throwIllegalArgumentException('An argument was null.');
        }
        
        for (Integration_Field_Mapping__mdt mapping: mappings) {
            if (mapping.Salesforce_Object__c == targetSObject && mapping.Field_API_Name__c != null) {
                record.put(mapping.Field_API_Name__c, String.valueOf(dataToMap.get(mapping.Key__c)));
            }
        }
        return record;
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getLwcColumnsFromIntegrationFieldMappings (String calloutConfigDevName) {

        if (calloutConfigDevName == null) {
            Utility.throwIllegalArgumentException('An argument was null.');
        }

        if (Callout_Configuration__mdt.getInstance(calloutConfigDevName) == null) {
            Utility.throwHandledException('There is no callout configuration in the Custom Metadata with the requested name.');
        }

        Id calloutConfigId = Callout_Configuration__mdt.getInstance(calloutConfigDevName).Id;
        List<Integration_Field_Mapping__mdt> dataForLwcColumnAttributes = 
            IntegrationFieldMappingSelector.getLwcColumnsFromIntegrationFieldMappings(calloutConfigId);

        if (dataForLwcColumnAttributes.isEmpty()) {
            Utility.throwHandledException('There are no column configurations in the Custom Metadata for this callout.');
        }

        List<Map<String, Object>> lwcColumnAttributes = new List<Map<String, Object>>();
        for (Integration_Field_Mapping__mdt columnData : dataForLwcColumnAttributes) {
            Map<String, Object> lwcColumn = new Map<String, Object>();
            lwcColumn.put('label', String.valueOf(columnData.LWC_Column_Name__c));
            lwcColumn.put('fieldName', String.valueOf(columnData.Key__c));
            lwcColumn.put('type', String.valueOf(columnData.LWC_Column_Data_Type__c));
            lwcColumn.put('sortable', 'true');
            if (columnData.LWC_Type_Attributes__c != null) {
                // Deserialize the JSON from Custom Metadata to customize the job URL
                Map<String, Object> deserializedTypeAttributes = Utility.deserializeJson(columnData.LWC_Type_Attributes__c);
                lwcColumn.put('typeAttributes', deserializedTypeAttributes);
            }
            lwcColumnAttributes.add(lwcColumn);
        }
        return lwcColumnAttributes;
    }
}