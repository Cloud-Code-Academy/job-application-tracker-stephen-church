public with sharing class JobApplicationContactTriggerHandler extends TriggerHandler {

    private List<Job_Application_Contact__c> triggerDotNew;
    private Map<Id, Job_Application_Contact__c> triggerDotNewMap;
    private Map<Id, Job_Application_Contact__c> triggerDotOldMap;

    // Constructor that sets Trigger.new and Trigger.newMap into variables
    public JobApplicationContactTriggerHandler() {
        this.triggerDotNew = (List<Job_Application_Contact__c>)Trigger.new;
        this.triggerDotNewMap = (Map<Id, Job_Application_Contact__c>)Trigger.newMap;
        this.triggerDotOldMap = (Map<Id, Job_Application_Contact__c>)Trigger.oldMap;
    }

    
    public override void beforeInsert() {
        JobApplicationContactHelper.enforceOneHiringManagerPerJobInsert(triggerDotNew);
        JobApplicationContactHelper.enforceOnePrimaryContactPerJobInsert(triggerDotNew);
        JobApplicationContactHelper.defaultJobApplicationContactToPrimaryOnInsert(triggerDotNew);
    }

    public override void beforeUpdate() {
        JobApplicationContactHelper.enforceOneHiringManagerPerJobUpdate(triggerDotNew, triggerDotOldMap);
        JobApplicationContactHelper.enforceOnePrimaryContactPerJobUpdate(triggerDotNew, triggerDotOldMap);
        JobApplicationContactHelper.handlePrimaryContactDeselect(triggerDotNew, triggerDotOldMap);
    }

    public override void afterInsert() {
        JobApplicationContactHelper.replacePrimaryContactsOnInsert(triggerDotNew);
    }
    
    public override void afterUpdate() {
        JobApplicationContactHelper.replacePrimaryContactsOnUpdate(triggerDotNew, triggerDotOldMap);
    }
}