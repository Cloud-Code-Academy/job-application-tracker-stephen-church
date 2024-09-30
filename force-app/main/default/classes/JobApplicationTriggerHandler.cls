public with sharing class JobApplicationTriggerHandler extends TriggerHandler {

    private List<Job_Application__c> triggerDotNew;
    private Map<Id, Job_Application__c> triggerDotNewMap;
    private Map<Id, Job_Application__c> triggerDotOldMap;
    private List<Status_Task_Manager__mdt> jobAppStatusConfigs;

    public JobApplicationTriggerHandler() {
        this.triggerDotNew = (List<Job_Application__c>)Trigger.new;
        this.triggerDotNewMap = (Map<Id, Job_Application__c>)Trigger.newMap;
        this.triggerDotOldMap = (Map<Id, Job_Application__c>)Trigger.oldMap;
        this.jobAppStatusConfigs = StatusTaskManagerSelector.getActiveStatusConfigsForProcess('Job Application');
    }
    
    public override void beforeInsert() {
        JobApplicationHelper.setStringSalaryToDecimalSalary(triggerDotNew);
        JobApplicationHelper.calculateTaxesAndTakeHome(triggerDotNew);
    }

    public override void afterInsert() {
        JobApplicationHelper.generateTasksForStatus(triggerDotNew, jobAppStatusConfigs);
    }

    public override void beforeUpdate() {
        JobApplicationHelper.blockStatusChangeWhenOpenTasks(triggerDotNewMap, triggerDotOldMap);
        JobApplicationHelper.blockUnauthorizedStatusChanges(triggerDotNewMap, triggerDotOldMap, jobAppStatusConfigs);
        JobApplicationHelper.setSubmissionDateWhenStatusIsApplied(triggerDotNew, triggerDotOldMap);
        JobApplicationHelper.calculateTaxesAndTakeHomeWhenSalaryChanged(triggerDotNew, triggerDotOldMap);
    }

    public override void afterUpdate() {
        JobApplicationHelper.generateTasksForStatus(triggerDotNew, jobAppStatusConfigs);
    }
}