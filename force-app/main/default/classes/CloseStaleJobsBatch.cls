public with sharing class CloseStaleJobsBatch implements Database.Batchable<sObject>, Database.Stateful{

    private Set<String> jobAppOwnerEmails = new Set<String>();
    private Integer recordsProcessed = 0;
    @TestVisible private static final String STATUS_TO_SET = 'Auto Close - Stale';
    @TestVisible private static final Integer DAYS_AGO_SINCE_FOLLOW_UP_TO_BE_STALE = 30;
    
    public Database.QueryLocator start(Database.BatchableContext BC){
        Date staleDate = Date.today().addDays(-DAYS_AGO_SINCE_FOLLOW_UP_TO_BE_STALE);
        return Database.getQueryLocator(JobApplicationSelector.getStaleJobApplications(staleDate));
    }
    
    public void execute(Database.BatchableContext BC, List<Job_Application__c> scope){
        
        for (Job_Application__c jobApp : scope) {
            jobApp.Application_Status__c = STATUS_TO_SET;
            if (jobApp.Owner.isActive){
                jobAppOwnerEmails.add(jobApp.Owner.Email);
            }
        }
        try {
            update scope;
            recordsProcessed += scope.size();
        } catch (DmlException e) {
            Utility.throwDmlException(e);
        }
    }
    
    public void finish(Database.BatchableContext BC){

        if(recordsProcessed >= 1 && !jobAppOwnerEmails.isEmpty()) {
            try {
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setToAddresses(new List<String>(jobAppOwnerEmails));
                mail.setSubject('Stale Job Applications Closed');
                mail.setPlainTextBody('Stale Job Applications have been updated to the status: ' + STATUS_TO_SET);
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            } catch (Exception e) {
                Utility.throwHandledException('There was a problem sending an email');
            }
        }
    }
}