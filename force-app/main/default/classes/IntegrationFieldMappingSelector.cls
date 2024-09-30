public with sharing class IntegrationFieldMappingSelector {

    @AuraEnabled(cacheable=true)
    public static List<Integration_Field_Mapping__mdt> getMappingsFromRelatedCalloutConfig(Id calloutConfigId) {

        if (calloutConfigId == null) {
            Utility.throwIllegalArgumentException('The calloutConfigId arugment was null.');
        }
        
        List<Integration_Field_Mapping__mdt> jobDataKeys = [
            SELECT Id, DeveloperName, Salesforce_Object__c, Field_API_Name__c, Id_Field__c, Key__c, Callout_Configuration__c
            FROM Integration_Field_Mapping__mdt
            WHERE Callout_Configuration__c = :calloutConfigId
        ];
        return jobDataKeys;
    }

    public static List<Integration_Field_Mapping__mdt> getLwcColumnsFromIntegrationFieldMappings (Id calloutConfigId) {

        if (calloutConfigId == null) {
            Utility.throwIllegalArgumentException('The calloutConfigId arugment was null.');
        }

        List<Integration_Field_Mapping__mdt> lwcColumnData = [
            SELECT Id, DeveloperName, LWC_Column_Name__c, LWC_Column_Data_Type__c, LWC_Column_Sort_Order__c, LWC_Type_Attributes__c, Key__c, Callout_Configuration__c
            FROM Integration_Field_Mapping__mdt
            WHERE Callout_Configuration__c = :calloutConfigId
            AND LWC_Column_Data_Type__c != null
            AND LWC_Column_Sort_Order__c != null
            ORDER BY LWC_Column_Sort_Order__c ASC
        ];
        return lwcColumnData;
    } 
}