trigger JobApplicationContactTrigger on Job_Application_Contact__c (before insert, before update, after insert, after update) {
    JobApplicationContactTriggerHandler jobApplicationContactHandler = new JobApplicationContactTriggerHandler();
    jobApplicationContactHandler.run();
}