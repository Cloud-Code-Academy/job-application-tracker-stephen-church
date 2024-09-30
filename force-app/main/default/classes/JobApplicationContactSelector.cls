public with sharing class JobApplicationContactSelector {

    public static List<Job_Application_Contact__c> getJobApplicationContactsByRole (Set<Id> jobAppIds, String role) {

        if (jobAppIds.isEmpty()) {
            Utility.throwIllegalArgumentException('The jobAppIds arugment doesn not have any Ids');
        }

        List<Job_Application_Contact__c> jobAppContacts = [
            SELECT Id, Role__c, Primary_Contact__c, Job_Application__c
            FROM Job_Application_Contact__c
            WHERE Job_Application__c IN :jobAppIds
            AND Role__c = :role
        ];
        return jobAppContacts;
    }

    public static List<Job_Application_Contact__c> getPrimaryContactsForJobApps (Set<Id> jobAppIds) {

        if (jobAppIds.isEmpty()) {
            Utility.throwIllegalArgumentException('The jobAppIds argument is null');
        }

        List<Job_Application_Contact__c> primaryJobAppContacts = [
            SELECT Id, Primary_Contact__c, Job_Application__c
            FROM Job_Application_Contact__c
            WHERE Job_Application__c IN :jobAppIds
            AND Primary_Contact__c = TRUE
        ];
        return primaryJobAppContacts;
    }

    public static List<Job_Application_Contact__c> getPrimaryContactsForJobAppsExcludingCertainContacts (Set<Id> jobAppIds, Set<Id> jobAppContactIdsToNotGet) {

        if (jobAppIds.isEmpty() || jobAppContactIdsToNotGet.isEmpty()) {
            Utility.throwIllegalArgumentException('Arguments passed to the method were null');
        }

        List<Job_Application_Contact__c> primaryJobAppContacts = [
            SELECT Id, Primary_Contact__c, Job_Application__c
            FROM Job_Application_Contact__c
            WHERE Job_Application__c IN :jobAppIds
            AND Id NOT IN :jobAppContactIdsToNotGet
            AND Primary_Contact__c = TRUE
        ];
        return primaryJobAppContacts;

    }
}