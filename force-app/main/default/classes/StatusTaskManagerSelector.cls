public with sharing class StatusTaskManagerSelector {

    public static List<Status_Task_Manager__mdt> getActiveStatusConfigsForProcess(String process) {

        if (process == null) {
            Utility.throwIllegalArgumentException('The process argument was null');
        }

        List<Status_Task_Manager__mdt> processStatusConfigs = [
            SELECT 
                Id, 
                Active__c, 
                Default_Days_For_Task_Due_Date__c, 
                Default_Task_Priority__c,
                Default_Task_Status__c,
                Order__c,
                Process__c,
                Status__c,
                Task_Generation_Class__c,
                Valid_Next_Status__c
            FROM Status_Task_Manager__mdt
            WHERE Process__c = :process
            AND Active__c = TRUE
        ];
        return processStatusConfigs;
    }
}