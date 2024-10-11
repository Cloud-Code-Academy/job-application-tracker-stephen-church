public with sharing class StatusTMJobAppInterviewing implements StatusTaskManager {
    
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

            Task prepareResponseTask = taskWithDefaultFields.clone();
            prepareResponseTask.Subject = 'Prepare your blurb or “tell me about yourself” response';
            newTasks.add(prepareResponseTask);

            Task practiceAnsweringTask = taskWithDefaultFields.clone();
            practiceAnsweringTask.Subject = 'Practice answering behavioral interview questions';
            newTasks.add(practiceAnsweringTask);

            Task researchCompanyInterviewersTask = taskWithDefaultFields.clone();
            researchCompanyInterviewersTask.Subject = 'Research the company and your interviewers';
            newTasks.add(researchCompanyInterviewersTask);

            Task setupVirtualIntTestTechTask = taskWithDefaultFields.clone();
            setupVirtualIntTestTechTask.Subject = 'Set up your virtual interview space and test your tech';
            newTasks.add(setupVirtualIntTestTechTask);

            Task sendRemindersTask = taskWithDefaultFields.clone();
            sendRemindersTask.Subject = 'Send thank you emails within 24 hours';
            newTasks.add(sendRemindersTask);
        }
    return newTasks;
    }
}