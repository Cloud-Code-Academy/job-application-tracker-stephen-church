public with sharing class JobApplicationSelector {

    public static List<Job_Application__c> getJobAppsWithExternalJobId(Set<String> externalJobIds) {

        if (externalJobIds.isEmpty()) {
            Utility.throwIllegalArgumentException('The externalJobIds argument was null.');
        }
        
        List<Job_Application__c> jobApps = new List<Job_Application__c>();
        if (!externalJobIds.isEmpty()) {
            jobApps = [
                SELECT Id, Job_Posting_Id__c
                FROM Job_Application__c
                WHERE Job_Posting_Id__c IN :externalJobIds
            ];
        }
        return jobApps;
    }

    public static List<Job_Application__c> getJobAppsWithOpenTasks(Set<Id> jobAppIdsToGet) {

        if (jobAppIdsToGet.isEmpty()) {
            Utility.throwIllegalArgumentException('The jobAppIdsToGet variable is null');
        }

        List<Job_Application__c> jobAppsWithOpenTasks = [
            SELECT Id,
                (SELECT Id, IsClosed FROM Tasks WHERE WhatId IN :jobAppIdsToGet AND IsClosed = FALSE)
            FROM Job_Application__c
            WHERE Id IN :jobAppIdsToGet
        ];
        return jobAppsWithOpenTasks;
    }

    public static String getStaleJobApplications(Date staleDate) {

        String queryString = 'SELECT Id, Application_Status__c, Follow_Up_Date__c, Owner.Email, Owner.isActive ' +
        'FROM Job_Application__c ' +
        'WHERE Follow_Up_Date__c <= :staleDate ' + 
        'AND Application_Status__c NOT IN (\'Offer Declined\', \'Offer Accepted\', \'Not Interested\', \'No Offer\', \'Auto Close - Stale\')';
        return queryString;
    }
}