public with sharing class StatusTMJobAppApplied implements StatusTaskManager {
    
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

            Task reachOutTask = taskWithDefaultFields.clone();
            reachOutTask.Subject = 'Reach out to the hiring manager or recruiter';
            newTasks.add(reachOutTask);

            Task weeklyFollowUpTask = taskWithDefaultFields.clone();
            weeklyFollowUpTask.Subject = 'Follow up on your application via email weekly';
            newTasks.add(weeklyFollowUpTask);

            Task similarOppsTask = taskWithDefaultFields.clone();
            similarOppsTask.Subject = 'Continue identifying and saving similar job opportunities';
            newTasks.add(similarOppsTask);

            Task weeklyNetworkingCallsTask = taskWithDefaultFields.clone();
            weeklyNetworkingCallsTask.Subject = 'Set up weekly networking calls to explore similar companies/roles';
            newTasks.add(weeklyNetworkingCallsTask);
        }
    return newTasks;
    }
}