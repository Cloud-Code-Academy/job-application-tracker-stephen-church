public with sharing class StatusTMJobAppApplying implements StatusTaskManager {
    
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

            Task researchPeopleTask = taskWithDefaultFields.clone();
            researchPeopleTask.Subject = 'Find and research someone who works at the company and add them as a Contact';
            newTasks.add(researchPeopleTask);

            Task informationalInterviewTask = taskWithDefaultFields.clone();
            informationalInterviewTask.Subject = 'Setup up an informational interview to learn more about the role / company';
            newTasks.add(informationalInterviewTask);

            Task referralsTask = taskWithDefaultFields.clone();
            referralsTask.Subject = 'Identify potential referrals to help get your application on the top of the pile';
            newTasks.add(referralsTask);

            Task workAchievementsTask = taskWithDefaultFields.clone();
            workAchievementsTask.Subject = 'Customize your work achievements using the job description keywords';
            newTasks.add(workAchievementsTask);

            Task submitApplicationTask = taskWithDefaultFields.clone();
            submitApplicationTask.Subject = 'Submit your application on the company website if possible';
            newTasks.add(submitApplicationTask);
        }
    return newTasks;
    }
}