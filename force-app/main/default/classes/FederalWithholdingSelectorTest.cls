@isTest
public with sharing class FederalWithholdingSelectorTest {

    @isTest
    static void getFederalWithholdingsForStatus_expectedResults() {

        Id taxStatusId = Federal_Tax_Filing_Status__mdt.getInstance('Married_Filing_Jointly').Id;

        Test.startTest();
        List<Federal_Withholding__mdt> withholdings = FederalWithholdingSelector.getFederalWithholdingsForStatus(taxStatusId);
        Test.stopTest();

        Decimal lastOrderByValue = null;
        for (Federal_Withholding__mdt withholding : withholdings) {
            Assert.isTrue(withholding.Federal_Tax_Filing_Status__c == taxStatusId, 
                'The Federal Tax Filing Status should be ' + taxStatusId + '. It is ' + withholding.Federal_Tax_Filing_Status__c);
            Assert.isTrue(withholding.Type__c == 'Federal Income Tax', 
                'The withholding Type should be Federal Income Tax. It is ' + withholding.Type__c);
            Assert.isTrue(withholding.Order__c > lastOrderByValue || (withholding.Order__c != null & lastOrderByValue == null), 
                'The Order value should be greater than ' + lastOrderByValue + '. It is ' + withholding.Order__c);
            lastOrderByValue = withholding.Order__c;
        }
    }

    @isTest
    static void getFederalWithholdingsForStatus_illegalArgument(){

        Id taxStatusId = null;
        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            List<Federal_Withholding__mdt> withholdings = FederalWithholdingSelector.getFederalWithholdingsForStatus(taxStatusId);
        } catch (IllegalArgumentException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'An Illegal Argument Exception should have been thrown,');
    }
}