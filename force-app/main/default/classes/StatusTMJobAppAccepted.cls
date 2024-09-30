public with sharing class StatusTMJobAppAccepted implements StatusTaskManager {
    
    public List<Task> generateStatusTasks (List<Job_Application__c> jobAppsNeedingTasks, Status_Task_Manager__mdt statusConfig) {
        
        if (jobAppsNeedingTasks.isEmpty() || statusConfig == null) {
            Utility.throwIllegalArgumentException('Arguments passed to the method are null');
        }

        // Set default fields used for all Tasks in this Status
        Task taskWithDefaultFields = new Task();
        taskWithDefaultFields.ActivityDate = Date.today() + Integer.valueOf(statusConfig.Default_Days_For_Task_Due_Date__c);
        taskWithDefaultFields.Priority = statusConfig.Default_Task_Priority__c;
        taskWithDefaultFields.Status = statusConfig.Default_Task_Status__c;
        List<Task> newTasks = new List<Task>();
        for (Job_Application__c jobApp : jobAppsNeedingTasks) {

            taskWithDefaultFields.WhatId = jobApp.Id;

            Task planResignationTask = taskWithDefaultFields.clone();
            planResignationTask.Subject = 'Plan your resignation if applicable';
            newTasks.add(planResignationTask);

            Task relaxTask = taskWithDefaultFields.clone();
            relaxTask.Subject = 'Take some time to relax and recharge';
            newTasks.add(relaxTask);

            Task linkedInTask = taskWithDefaultFields.clone();
            linkedInTask.Subject = 'Announce your new job on LinkedIn';
            newTasks.add(linkedInTask);

            Task prepareForOnboardingTask = taskWithDefaultFields.clone();
            prepareForOnboardingTask.Subject = 'Prepare for your first day of onboarding';
            newTasks.add(prepareForOnboardingTask);
        }
    return newTasks;
    }
}