public with sharing class SObjectSalaryConvertHelper {

    public static String removeDollarSignFromSalaryString (String salaryString) {
        
        if (salaryString == null) {
            Utility.throwIllegalArgumentException('The salaryString argument is null');
        }
        
        salaryString = salaryString.remove('$');
        return salaryString;
    }

    public static String removeKFromSalaryString (String salaryString) {
        
        if (salaryString == null) {
            Utility.throwIllegalArgumentException('The salaryString argument is null');
        }
        
        salaryString = salaryString.remove('k');
        return salaryString;
    }

    public static String removePerHourFromSalaryString (String salaryString) {
        
        if (salaryString == null) {
            Utility.throwIllegalArgumentException('The salaryString argument is null');
        }
        
        salaryString = salaryString.remove('perhour');
        return salaryString;
    }

    public static String appendZeroesOnAbbreviatedSalaryString (String abbreviatedSalary, Integer zeroesToAppend) {

        if (abbreviatedSalary == null || zeroesToAppend == null) {
            Utility.throwIllegalArgumentException('There were missing arguments');
        }

        for (Integer i = 0; i < zeroesToAppend; i++) {
            abbreviatedSalary = abbreviatedSalary + '0';
        }
        return abbreviatedSalary;
    } 

    public static Decimal getMidPointDecimalFromTwoNumericStrings (String numericString1, String numericString2) {
        
        if (numericString1 == null || numericString2 == null ) {
            Utility.throwIllegalArgumentException('An argument was null');
        }

        Decimal midPointValue = null;
        try {
            midPointValue = (Decimal.valueOf(numericString1) + Decimal.valueOf(numericString2)) / 2;
        } catch (TypeException e) {
            Utility.throwTypeException('The Strings could not be converted to a Decimal');
        }
        return midPointValue;
    }

    public static Decimal getSalaryFromHourlyRateAndHoursPerYear (Decimal hourlyRate) {

        if (hourlyRate == null) {
            Utility.throwIllegalArgumentException('The hourlyRate argument was null');
        }
        Integer workingHoursPerYear = Integer.valueOf(System.Label.Working_Hours_Per_Year);
        Decimal salaryValueToSet = (hourlyRate * workingHoursPerYear);
        return salaryValueToSet;
    }
}