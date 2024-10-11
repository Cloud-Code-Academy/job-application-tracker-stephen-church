public with sharing class SObjectSalaryConvert_DollarPerHourRange implements SObjectSalaryConvert {

    // REGEX pattern this class checks for after text is lowered and all whitespace is removed
    // String with a $, 1-3 numbers. First \\ to escape $ and then the \ itself. 
    // \\ to represent any digit and escape the first \.
    // \\ to represent and escape a . and also match any two digits. Parentheses and ? make decimal optional.
    // Pattern repeated either side of - and literal perhour string at end, optional after first number.
    static final String PATTERN_TO_LOOK_FOR = '\\$\\d{1,3}(\\.\\d{1,2})?(perhour)?-\\$\\d{1,3}(\\.\\d{1,2})?perhour';

    // Variable with the sObjects that didn't meet the pattern and a method for accessing them
    private List<sObject> sObjectsNotMatchingPattern = new List<sObject>();
    public List<sObject> getSObjectsNotMatchingPattern() {
        return this.sObjectsNotMatchingPattern;
    }

    // Method to check if the pattern matches and assign the sObjects with converted values, if needed
    public void checkSalaryPatternAndConvert(List<sObject> sObjectsToCheckForPattern, String fieldToCheckForPattern, String fieldToPopulateWithConversion) {
        
        if (sObjectsToCheckForPattern.isEmpty() || fieldToCheckForPattern == null || fieldToPopulateWithConversion == null) {
            Utility.throwIllegalArgumentException('An argument passed to the method was null');
        }
        
        for (SObject record : sObjectsToCheckForPattern) {
            String fieldValueToCheck = Utility.getSObjectFieldValueLoweredNoWhiteSpace(record, fieldToCheckForPattern);
            if (fieldValueToCheck != null && Utility.checkStringMatchesPattern(fieldValueToCheck, PATTERN_TO_LOOK_FOR)) {
                fieldValueToCheck = SObjectSalaryConvertHelper.removeDollarSignFromSalaryString(fieldValueToCheck);
                fieldValueToCheck = SObjectSalaryConvertHelper.removePerHourFromSalaryString(fieldValueToCheck);
                List<String> hourlyRateValues = fieldValueToCheck.split('-');
                String firstHourlyString = hourlyRateValues.get(0);
                String secondHourlyString = hourlyRateValues.get(1);
                Decimal midPointRate = SObjectSalaryConvertHelper.getMidPointDecimalFromTwoNumericStrings(firstHourlyString, secondHourlyString);
                Decimal salaryValueToSet = SObjectSalaryConvertHelper.getSalaryFromHourlyRateAndHoursPerYear(midPointRate);
                record.put(fieldToPopulateWithConversion, salaryValueToSet);
            } else {
                this.sObjectsNotMatchingPattern.add(record);
            }
        }
    }
}