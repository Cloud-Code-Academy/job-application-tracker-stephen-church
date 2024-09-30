public with sharing class StatusTMJobAppSaved implements StatusTaskManager {
    
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

            Task jobDescriptionTask = taskWithDefaultFields.clone();
            jobDescriptionTask.Subject = 'Check job description aligns with interests and values';
            newTasks.add(jobDescriptionTask);

            Task roleFitTask = taskWithDefaultFields.clone();
            roleFitTask.Subject = 'Review highlighted skills to see if the role is a good fit';
            newTasks.add(roleFitTask);

            Task researchCompanyTask = taskWithDefaultFields.clone();
            researchCompanyTask.Subject = 'Research the company / role';
            newTasks.add(researchCompanyTask);

            Task excitementLevelTask = taskWithDefaultFields.clone();
            excitementLevelTask.Subject = 'Mark your excitement level and decide whether to proceed';
            newTasks.add(excitementLevelTask);
        }
    return newTasks;
    }
}