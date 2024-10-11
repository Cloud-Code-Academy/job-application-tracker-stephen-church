public with sharing class FederalWithholdingSelector {

    public static List<Federal_Withholding__mdt> getFederalWithholdingsForStatus(Id federalTaxStatusCmdtId) {

        if (federalTaxStatusCmdtId == null) {
            Utility.throwIllegalArgumentException('The federalTaxStatus argument was null.');
        }

        List<Federal_Withholding__mdt> withholdings = [
            SELECT Id, Bracket_Start__c, Bracket_End__c, DeveloperName, Order__c, Tax_Rate__c, Type__c, Federal_Tax_Filing_Status__c
            FROM Federal_Withholding__mdt
            WHERE Type__c = 'Federal Income Tax' 
            AND Federal_Tax_Filing_Status__c = :federalTaxStatusCmdtId
            ORDER BY Order__c
        ];
        if (withholdings.isEmpty()) {
            Utility.throwQueryException('The Federal Tax Filing Status has no withholding data in the CMDT');
        }
        return withholdings;
    }
}