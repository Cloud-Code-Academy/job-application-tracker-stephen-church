@isTest
public with sharing class SObjectSalaryConvertHelperTest {

    @isTest
    static void removeDollarSignFromSalaryString_removeValueOnce() {

        String startingValue = '$100';
        String expectedValue = '100';
        
        Test.startTest();
        String actualValue = SObjectSalaryConvertHelper.removeDollarSignFromSalaryString(startingValue);
        Test.stopTest();

        Assert.areEqual(expectedValue, actualValue, 'The value returned is not as expected');
    }

    @isTest
    static void removeDollarSignFromSalaryString_removeValueTwice() {

        String startingValue = '$$100';
        String expectedValue = '100';
        
        Test.startTest();
        String actualValue = SObjectSalaryConvertHelper.removeDollarSignFromSalaryString(startingValue);
        Test.stopTest();

        Assert.areEqual(expectedValue, actualValue, 'The value returned is not as expected');
    }

    @isTest
    static void removeDollarSignFromSalaryString_noValueToRemove() {

        String startingValue = '100';
        String expectedValue = '100';
        
        Test.startTest();
        String actualValue = SObjectSalaryConvertHelper.removeDollarSignFromSalaryString(startingValue);
        Test.stopTest();

        Assert.areEqual(expectedValue, actualValue, 'The value returned is not as expected');
    }

    @isTest
    static void removeDollarSignFromSalaryString_nullValue() {

        String startingValue = null;
        Boolean exceptionThrown = false;
        
        Test.startTest();
        try {
            String actualValue = SObjectSalaryConvertHelper.removeDollarSignFromSalaryString(startingValue);
        } catch (IllegalArgumentException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'An Illegal Argument Exception should have been thrown');
    }

    @isTest
    static void removeKFromSalaryString_removeValueOnce() {

        String startingValue = '100k';
        String expectedValue = '100';
        
        Test.startTest();
        String actualValue = SObjectSalaryConvertHelper.removeKFromSalaryString(startingValue);
        Test.stopTest();

        Assert.areEqual(expectedValue, actualValue, 'The value returned is not as expected');
    }

    @isTest
    static void removeKFromSalaryString_removeValueTwice() {

        String startingValue = '100kk';
        String expectedValue = '100';
        
        Test.startTest();
        String actualValue = SObjectSalaryConvertHelper.removeKFromSalaryString(startingValue);
        Test.stopTest();

        Assert.areEqual(expectedValue, actualValue, 'The value returned is not as expected');
    }

    @isTest
    static void removeKFromSalaryString_noValueToRemove() {

        String startingValue = '100';
        String expectedValue = '100';
        
        Test.startTest();
        String actualValue = SObjectSalaryConvertHelper.removeKFromSalaryString(startingValue);
        Test.stopTest();

        Assert.areEqual(expectedValue, actualValue, 'The value returned is not as expected');
    }

    @isTest
    static void removeKFromSalaryString_nullValue() {

        String startingValue = null;
        Boolean exceptionThrown = false;
        
        Test.startTest();
        try {
            String actualValue = SObjectSalaryConvertHelper.removeKFromSalaryString(startingValue);
        } catch (IllegalArgumentException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'An Illegal Argument Exception should have been thrown');
    }

    @isTest
    static void removePerHourFromSalaryString_removeValueOnce() {

        String startingValue = '100perhour';
        String expectedValue = '100';
        
        Test.startTest();
        String actualValue = SObjectSalaryConvertHelper.removePerHourFromSalaryString(startingValue);
        Test.stopTest();

        Assert.areEqual(expectedValue, actualValue, 'The value returned is not as expected');
    }

    @isTest
    static void removePerHourFromSalaryString_removeValueTwice() {

        String startingValue = '100perhourperhour';
        String expectedValue = '100';
        
        Test.startTest();
        String actualValue = SObjectSalaryConvertHelper.removePerHourFromSalaryString(startingValue);
        Test.stopTest();

        Assert.areEqual(expectedValue, actualValue, 'The value returned is not as expected');
    }

    @isTest
    static void removePerHourFromSalaryString_noValueToRemove() {

        String startingValue = '100';
        String expectedValue = '100';
        
        Test.startTest();
        String actualValue = SObjectSalaryConvertHelper.removePerHourFromSalaryString(startingValue);
        Test.stopTest();

        Assert.areEqual(expectedValue, actualValue, 'The value returned is not as expected');
    }

    @isTest
    static void removePerHourFromSalaryString_nullValue() {

        String startingValue = null;
        Boolean exceptionThrown = false;
        
        Test.startTest();
        try {
            String actualValue = SObjectSalaryConvertHelper.removePerHourFromSalaryString(startingValue);
        } catch (IllegalArgumentException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'An Illegal Argument Exception should have been thrown');
    }

    @isTest 
    static void appendZeroesOnAbberviatedSalaryString_appendZeroes() {

        String startingValue = '100';
        Integer zeroesToAppend = 3;
        String expectedValue = '100000';

        Test.startTest();
        String actualValue = 
            SObjectSalaryConvertHelper.appendZeroesOnAbbreviatedSalaryString(startingValue, zeroesToAppend);
        Test.stopTest();

        Assert.areEqual(expectedValue, actualValue, 'The value returned is not as expected');
    }

    @isTest 
    static void appendZeroesOnAbberviatedSalaryString_dontAppend() {

        String startingValue = '100';
        Integer zeroesToAppend = 0;
        String expectedValue = '100';

        Test.startTest();
        String actualValue = 
            SObjectSalaryConvertHelper.appendZeroesOnAbbreviatedSalaryString(startingValue, zeroesToAppend);
        Test.stopTest();

        Assert.areEqual(expectedValue, actualValue, 'The value returned is not as expected');
    }

    @isTest
    static void appendZeroesOnAbberviatedSalaryString_nullString() {

        String startingValue = null;
        Integer zeroesToAppend = 3;
        Boolean exceptionThrown = false;
        
        Test.startTest();
        try {
            String actualValue = 
                SObjectSalaryConvertHelper.appendZeroesOnAbbreviatedSalaryString(startingValue, zeroesToAppend);
        } catch (IllegalArgumentException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'An Illegal Argument Exception should have been thrown');
    }

    @isTest
    static void appendZeroesOnAbberviatedSalaryString_nullInteger() {

        String startingValue = '100';
        Integer zeroesToAppend = null;
        Boolean exceptionThrown = false;
        
        Test.startTest();
        try {
            String actualValue = 
                SObjectSalaryConvertHelper.appendZeroesOnAbbreviatedSalaryString(startingValue, zeroesToAppend);
        } catch (IllegalArgumentException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'An Illegal Argument Exception should have been thrown');
    }

    @isTest
    static void getMidPointDecimalFromTwoNumericStrings_twoNonDecimalStrings() {

        String stringNumber1 = '100';
        String stringNumber2 = '50';
        Decimal expectedValue = 75.00;

        Test.startTest();
        Decimal actualValue = sObjectSalaryConvertHelper.getMidPointDecimalFromTwoNumericStrings(stringNumber1, stringNumber2);
        Test.stopTest();

        Assert.areEqual(expectedValue, actualValue, 'The value returned is not as expected');
    }

    @isTest
    static void getMidPointDecimalFromTwoNumericStrings_oneDecimalStringOneNon() {

        String stringNumber1 = '100.50';
        String stringNumber2 = '50';
        Decimal expectedValue = 75.25;

        Test.startTest();
        Decimal actualValue = sObjectSalaryConvertHelper.getMidPointDecimalFromTwoNumericStrings(stringNumber1, stringNumber2);
        Test.stopTest();

        Assert.areEqual(expectedValue, actualValue, 'The value returned is not as expected');
    }

    @isTest
    static void getMidPointDecimalFromTwoNumericStrings_twoDecimalStrings() {

        String stringNumber1 = '100.50';
        String stringNumber2 = '100.75';
        Decimal expectedValue = 100.625;

        Test.startTest();
        Decimal actualValue = sObjectSalaryConvertHelper.getMidPointDecimalFromTwoNumericStrings(stringNumber1, stringNumber2);
        Test.stopTest();

        Assert.areEqual(expectedValue, actualValue, 'The value returned is not as expected');
    }

    @isTest
    static void getMidPointDecimalFromTwoNumericStrings_nonNumericString() {

        String stringNumber = '100';
        String stringNonNumber = 'Test';
        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            Decimal actualValue = sObjectSalaryConvertHelper.getMidPointDecimalFromTwoNumericStrings(stringNumber, stringNonNumber);
        } catch (TypeException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'A TypeException should have been thrown');
    }

    @isTest
    static void getMidPointDecimalFromTwoNumericStrings_nullString1() {

        String stringNumber1 = '100.50';
        String stringNumber2 = null;
        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            Decimal actualValue = sObjectSalaryConvertHelper.getMidPointDecimalFromTwoNumericStrings(stringNumber1, stringNumber2);
        } catch (IllegalArgumentException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'An Illegal Argument Exception should have been thrown');
    }

    @isTest
    static void getMidPointDecimalFromTwoNumericStrings_nullString2() {

        String stringNumber1 = null;
        String stringNumber2 = '100';
        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            Decimal actualValue = sObjectSalaryConvertHelper.getMidPointDecimalFromTwoNumericStrings(stringNumber1, stringNumber2);
        } catch (IllegalArgumentException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'An Illegal Argument Exception should have been thrown');
    }

    @isTest 
    static void getSalaryFromHourlyRateAndHoursPerYear_decimalHourlyRate() {

        Decimal hourlyRate = 100.00;
        Integer workingHoursPerYear = Integer.valueOf(System.Label.Working_Hours_Per_Year);

        Test.startTest();
        Decimal salary = SObjectSalaryConvertHelper.getSalaryFromHourlyRateAndHoursPerYear(hourlyRate);
        Test.stopTest();

        Assert.isTrue(salary / workingHoursPerYear == hourlyRate, 'The salary did not calculate correctly');
    }

    @isTest 
    static void getSalaryFromHourlyRateAndHoursPerYear_nonDecimalHourlyRate() {

        Decimal hourlyRate = 100;
        Integer workingHoursPerYear = Integer.valueOf(System.Label.Working_Hours_Per_Year);

        Test.startTest();
        Decimal salary = SObjectSalaryConvertHelper.getSalaryFromHourlyRateAndHoursPerYear(hourlyRate);
        Test.stopTest();

        Assert.isTrue(salary / workingHoursPerYear == hourlyRate, 'The salary did not calculate correctly');
    }

    @isTest 
    static void getSalaryFromHourlyRateAndHoursPerYear_nullHourlyRate() {

        Decimal hourlyRate = null;
        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            Decimal salary = SObjectSalaryConvertHelper.getSalaryFromHourlyRateAndHoursPerYear(hourlyRate);
        } catch (IllegalArgumentException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'An Illegal Argument Exception should have been thrown');
    }
}