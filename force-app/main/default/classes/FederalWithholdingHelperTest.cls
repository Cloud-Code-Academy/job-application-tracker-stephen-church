@isTest
public with sharing class FederalWithholdingHelperTest {

    @isTest
    static void getAmountToTaxInTaxBracket_noTax() {
        Decimal salary = 100000;
        Decimal taxBracketStart = 105000;
        Decimal taxBracketEnd = 110000;

        Test.startTest();
        Decimal amountToTax = FederalWithholdingHelper.getAmountToTaxInTaxBracket(salary, taxBracketStart, taxBracketEnd);
        Test.stopTest();

        Assert.isTrue(amountToTax == 0, 'The amountToTax variable should be 0. It is ' + amountToTax);
    }

    @isTest
    static void getAmountToTaxInTaxBracket_partialTaxFromBracket() {
        Decimal salary = 100000;
        Decimal taxBracketStart = 90000;
        Decimal taxBracketEnd = 110000;

        Test.startTest();
        Decimal amountToTax = FederalWithholdingHelper.getAmountToTaxInTaxBracket(salary, taxBracketStart, taxBracketEnd);
        Test.stopTest();

        Assert.isTrue(amountToTax == 10000, 'The amountToTax variable should be 10000. It is ' + amountToTax);
    }

    @isTest
    static void getAmountToTaxInTaxBracket_noEndToTaxBracket() {
        Decimal salary = 100000;
        Decimal taxBracketStart = 90000;
        Decimal taxBracketEnd = null;

        Test.startTest();
        Decimal amountToTax = FederalWithholdingHelper.getAmountToTaxInTaxBracket(salary, taxBracketStart, taxBracketEnd);
        Test.stopTest();

        Assert.isTrue(amountToTax == 10000, 'The amountToTax variable should be 10000. It is ' + amountToTax);
    }

    @isTest
    static void getAmountToTaxInTaxBracket_overTaxBracketEnd() {
        Decimal salary = 100000;
        Decimal taxBracketStart = 80000;
        Decimal taxBracketEnd = 90000;

        Test.startTest();
        Decimal amountToTax = FederalWithholdingHelper.getAmountToTaxInTaxBracket(salary, taxBracketStart, taxBracketEnd);
        Test.stopTest();

        Assert.isTrue(amountToTax == 10000, 'The amountToTax variable should be 10000. It is ' + amountToTax);
    }

    @isTest
    static void getAmountToTaxInBracket_missingTaxBracketStart(){

        Decimal salary = 100000;
        Decimal taxBracketStart = null;
        Decimal taxBracketEnd = 90000;
        Boolean exceptionThrown = false;

        // Call the method and try to catch the expected exception
        Test.startTest();
        try{
            Decimal amountToTax = FederalWithholdingHelper.getAmountToTaxInTaxBracket(salary, taxBracketStart, taxBracketEnd);
        } catch (IllegalArgumentException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        // Assert the exception was thrown
        Assert.isTrue(exceptionThrown, 'An Illegal Argument Exception should have been thrown');
    }

    @isTest
    static void getAmountToTaxInBracket_missingSalary(){

        Decimal salary = null;
        Decimal taxBracketStart = 80000;
        Decimal taxBracketEnd = 90000;
        Boolean exceptionThrown = false;

        // Call the method and try to catch the expected exception
        Test.startTest();
        try{
            Decimal amountToTax = FederalWithholdingHelper.getAmountToTaxInTaxBracket(salary, taxBracketStart, taxBracketEnd);
        } catch (IllegalArgumentException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        // Assert the exception was thrown
        Assert.isTrue(exceptionThrown, 'An Illegal Argument Exception should have been thrown');
    }

    @isTest
    static void calculateTaxesDue_zeroes(){

        Decimal amountToTax = 0;
        Decimal rateToTax = 0;

        Test.startTest();
        Decimal taxesDue = FederalWithholdingHelper.calculateTaxesDue(amountToTax, rateToTax);
        Test.stopTest();

        Assert.isTrue(taxesDue == 0, 'The taxesDue variable should be 0. It is ' + taxesDue);
    }

    @isTest
    static void calculateTaxesDue_zeroRate(){

        Decimal amountToTax = 100000;
        Decimal rateToTax = 0;

        Test.startTest();
        Decimal taxesDue = FederalWithholdingHelper.calculateTaxesDue(amountToTax, rateToTax);
        Test.stopTest();

        Assert.isTrue(taxesDue == 0, 'The taxesDue variable should be 0. It is ' + taxesDue);
    }

    @isTest
    static void calculateTaxesDue_zeroAmount(){

        Decimal amountToTax = 0;
        Decimal rateToTax = 100;

        Test.startTest();
        Decimal taxesDue = FederalWithholdingHelper.calculateTaxesDue(amountToTax, rateToTax);
        Test.stopTest();

        Assert.isTrue(taxesDue == 0, 'The taxesDue variable should be 0. It is ' + taxesDue);
    }

    @isTest
    static void calculateTaxesDue_bothRounded(){

        Decimal amountToTax = 100000;
        Decimal rateToTax = 1;

        Test.startTest();
        Decimal taxesDue = FederalWithholdingHelper.calculateTaxesDue(amountToTax, rateToTax);
        Test.stopTest();

        Assert.isTrue(taxesDue == 1000, 'The taxesDue variable should be 1000. It is ' + taxesDue);
    }

    
    @isTest
    static void calculateTaxesDue_decimalRate(){

        Decimal amountToTax = 100000;
        Decimal rateToTax = 1.50;

        Test.startTest();
        Decimal taxesDue = FederalWithholdingHelper.calculateTaxesDue(amountToTax, rateToTax);
        Test.stopTest();

        Assert.isTrue(taxesDue == 1500, 'The taxesDue variable should be 1500. It is ' + taxesDue);
    }

    @isTest
    static void calculateTaxesDue_decimalAmount(){

        Decimal amountToTax = 100000.50;
        Decimal rateToTax = 1;

        Test.startTest();
        Decimal taxesDue = FederalWithholdingHelper.calculateTaxesDue(amountToTax, rateToTax);
        Test.stopTest();

        Assert.isTrue(taxesDue == 1000.005, 'The taxesDue variable should be 1000.005. It is ' + taxesDue);
    }

    @isTest
    static void calculateTaxesDue_bothDecimal(){

        Decimal amountToTax = 100000.50;
        Decimal rateToTax = 1.50;

        Test.startTest();
        Decimal taxesDue = FederalWithholdingHelper.calculateTaxesDue(amountToTax, rateToTax);
        Test.stopTest();

        Assert.isTrue(taxesDue == 1500.0075, 'The taxesDue variable should be 1500.0075. It is ' + taxesDue);
    }

    @isTest
    static void getAmountToTaxInBracket_missingAmountToTax(){

        Decimal amountToTax = null;
        Decimal rateToTax = 1.50;
        Boolean exceptionThrown = false;

        Test.startTest();
        try{
            Decimal taxesDue = FederalWithholdingHelper.calculateTaxesDue(amountToTax, rateToTax);
        } catch (IllegalArgumentException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'An Illegal Argument Exception should have been thrown');
    }

    @isTest
    static void getAmountToTaxInBracket_missingRateToTax(){

        Decimal amountToTax = 100000;
        Decimal rateToTax = null;
        Boolean exceptionThrown = false;

        Test.startTest();
        try{
            Decimal taxesDue = FederalWithholdingHelper.calculateTaxesDue(amountToTax, rateToTax);
        } catch (IllegalArgumentException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'An Illegal Argument Exception should have been thrown');
    }
}