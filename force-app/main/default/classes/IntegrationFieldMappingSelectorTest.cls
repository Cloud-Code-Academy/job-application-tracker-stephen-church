@isTest
public with sharing class IntegrationFieldMappingSelectorTest {

    @isTest
    static void getMappingsFromRelatedCalloutConfig() {

        Id joobleCalloutConfigId = Callout_Configuration__mdt.getInstance('Jooble_Post').Id;

        Test.startTest();
        List<Integration_Field_Mapping__mdt> mappings = IntegrationFieldMappingSelector.getMappingsFromRelatedCalloutConfig(joobleCalloutConfigId);
        Test.stopTest();

        for (Integration_Field_Mapping__mdt mapping : mappings) {
            Assert.areEqual(joobleCalloutConfigId, mapping.Callout_Configuration__c, 'The callout configuration on the returned mappings is not as expected');
        }
    }

    @isTest
    static void getMappingsFromRelatedCalloutConfig_illegalArgument() {

        Id nullId = null;
        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            List<Integration_Field_Mapping__mdt> mappings = IntegrationFieldMappingSelector.getMappingsFromRelatedCalloutConfig(nullId);
        } catch (IllegalArgumentException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'An Illegal Argument Exception should have been thrown');
    }

    @isTest
    static void getLwcColumnsFromIntegrationFieldMappings() {

        Id joobleCalloutConfigId = Callout_Configuration__mdt.getInstance('Jooble_Post').Id;

        Test.startTest();
        List<Integration_Field_Mapping__mdt> mappings = IntegrationFieldMappingSelector.getLwcColumnsFromIntegrationFieldMappings(joobleCalloutConfigId);
        Test.stopTest();

        Integer lastSortOrderValueLooped = null;
        for (Integration_Field_Mapping__mdt mapping : mappings) {
            if (lastSortOrderValueLooped == null) {
                lastSortOrderValueLooped = (Integer)mapping.LWC_Column_Sort_Order__c;
            } else {
                Assert.isTrue(mapping.LWC_Column_Sort_Order__c > lastSortOrderValueLooped, 'The LWC Column Sort Order of ' + mapping.LWC_Column_Sort_Order__c + ' should be greater than the last value looped of ' + lastSortOrderValueLooped);
                lastSortOrderValueLooped += 1;
            }
            Assert.areEqual(joobleCalloutConfigId, mapping.Callout_Configuration__c, 'The callout configuration on the returned mappings is not as expected');
            Assert.isNotNull(mapping.LWC_Column_Sort_Order__c, 'The LWC Column Sort Order field should not be null');
            Assert.isNotNull(mapping.LWC_Column_Data_Type__c, 'The LWC Column Data Type field should not be null');
        }
    }

    @isTest
    static void getLwcColumnsFromIntegrationFieldMappings_illegalArgument() {

        Id nullId = null;
        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            List<Integration_Field_Mapping__mdt> mappings = IntegrationFieldMappingSelector.getLwcColumnsFromIntegrationFieldMappings(nullId);
        } catch (IllegalArgumentException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'An Illegal Argument Exception should have been thrown');
    }
}