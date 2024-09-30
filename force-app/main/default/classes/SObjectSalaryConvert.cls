public interface SObjectSalaryConvert {

    void checkSalaryPatternAndConvert(
        List<sObject> sObjectsToCheckForPattern, 
        String fieldToCheckForPattern, 
        String fieldToPopulateWithConversion);
    List<sObject> getSObjectsNotMatchingPattern();
    // There isn't a use case to get the sObjects with a converted salary, but this could easily be added later
}