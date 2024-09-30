public with sharing class StatusTMJobAppNegotiating implements StatusTaskManager {
    
    public List<Task> generateStatusTasks (List<Job_Application__c> jobAppsNeedingTasks, Status_Task_Manager__mdt statusConfig) {
        
        if (jobAppsNeedingTasks.isEmpty() || statusConfig == null) {
            Utility.throwIllegalArgumentException('Arguments passed to the method are null');
        }
        
        // Set default fields used for all Tasks in this Status
        Task taskWithDefaultFields = new Task();
        taskWithDefaultFields.ActivityDate = Date.today() + Integer.valueOf(statusConfig.Default_Days_For_Task_Due_Date__c);
        taskWithDefaultFields.Priority  = statusConfig.Default_Task_Priority__c;
        taskWithDefaultFields.Status = statusConfig.Default_Task_Status__c;
        List<Task> newTasks = new List<Task>();
        for (Job_Application__c jobApp : jobAppsNeedingTasks) {

            taskWithDefaultFields.WhatId = jobApp.Id;

            Task researchMarketValueTask = taskWithDefaultFields.clone();
            researchMarketValueTask.Subject = 'Research your market value and know your numbers';
            newTasks.add(researchMarketValueTask);

            Task prepareNegotiationScriptsTask = taskWithDefaultFields.clone();
            prepareNegotiationScriptsTask.Subject = 'Prepare your negotiation scripts';
            newTasks.add(prepareNegotiationScriptsTask);

            Task evaluateYourOfferTask = taskWithDefaultFields.clone();
            evaluateYourOfferTask.Subject = 'Evaluate your offer and decline or accept';
            newTasks.add(evaluateYourOfferTask);
        }
    return newTasks;
    }
}