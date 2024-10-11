public with sharing class JobApplicationContactHelper {

    @TestVisible public static final String MORE_THAN_1_PRIMARY_IN_BATCH_ERROR = 
        'More than 1 Job Application Contact had Primary Contact selected. A Job Application can only have 1 Primary Contact.';
    public static final String MORE_THAN_1_HIRING_MGR_ERROR = 
        'More than 1 Job Application Contact had Hiring Manager selected. A Job Application can only have 1 Hiring Manager.';
    @TestVisible public static final String SELECT_NEW_PRIMARY_ERROR = 
            'A Job Application must have at least one Primary Contact. Select a new Primary Contact and this will replace the existing one automatically.';
    
    /*** GENERATES JOB APPLICATION CONTACTS FROM JOB APPS CREATED FROM JOOBLE */

    public static List<Job_Application_Contact__c> generateContactsForNewJobApplications (
        List<Job_Application__c> newJobApps,
        Map<Id, String> accountNameById,
        Map<String, Account> accountsByCompanyName,
        String contactRole) {

        if (newJobApps.isEmpty() || accountNameById.isEmpty() || accountsByCompanyName.isEmpty() || contactRole == null) {
            Utility.throwIllegalArgumentException('An argument was null.');
        }

        List<Job_Application_Contact__c> jobApplicationContacts = new List<Job_Application_Contact__c>();
        for (Job_Application__c jobApp : newJobApps){
            String companyName = accountNameById.get(jobApp.Company__c);
            if (!accountsByCompanyName.get(companyName).Contacts.isEmpty()) {
                Id oldestContactId = accountsByCompanyName.get(companyName).Contacts.get(0).Id;
                Job_Application_Contact__c jobContact = new Job_Application_Contact__c (
                    Job_Application__c = jobApp.Id,
                    Contact__c = oldestContactId,
                    Role__c = contactRole
                );
                jobApplicationContacts.add(jobContact);
            }
        }
        return jobApplicationContacts;
    }

    /*** METHODS FOR ENFORCING 1 HIRING MANAGER PER JOB APPLICATION ***/

    // Identifies Job Application Contacts updated to Hiring Manager so we can check for existing Hiring Managers on the same Job App
    public static void enforceOneHiringManagerPerJobUpdate (List<Job_Application_Contact__c> jobAppContacts, Map<Id, Job_Application_Contact__c> oldJobAppContactsById) {

        if (jobAppContacts.isEmpty() || oldJobAppContactsById.isEmpty()) {
            Utility.throwIllegalArgumentException('The jobAppContacts argument is null');
        }

        // Adds all of the Job Application Contacts updated to Hiring Manager to a list.
        List<Job_Application_Contact__c> jobAppContactsUpdatedToHiringManager = new List<Job_Application_Contact__c>();
        for (Job_Application_Contact__c contact : jobAppContacts) {
            if (contact.Role__c == 'Hiring Manager' && contact.Role__c != oldJobAppContactsById.get(contact.Id).Role__c) {
                jobAppContactsUpdatedToHiringManager.add(contact);
            }
        }
        // Calls the method to ensure Job Apps only have 1 Hiring Manager
        if (!jobAppContactsUpdatedToHiringManager.isEmpty()) {
            enforceOneHiringManagerPerJob(jobAppContactsUpdatedToHiringManager);
        }
    }

    // Identifies Job Application Contacts inserted as Hiring Manager so we can check for existing Hiring Managers on the same Job App
    public static void enforceOneHiringManagerPerJobInsert (List<Job_Application_Contact__c> jobAppContacts) {

        if (jobAppContacts.isEmpty()) {
            Utility.throwIllegalArgumentException('The jobAppContacts argument is null');
        }

        // Adds all of the Job Application Contacts created as Hiring Manager to a list.
        List<Job_Application_Contact__c> hiringManagerJobAppContacts = new List<Job_Application_Contact__c>();
        for (Job_Application_Contact__c contact : jobAppContacts) {
            if (contact.Role__c == 'Hiring Manager') {
                hiringManagerJobAppContacts.add(contact);
            }
        }
        // Calls the method to ensure Job Apps only have 1 Hiring Manager
        if (!hiringManagerJobAppContacts.isEmpty()) {
            enforceOneHiringManagerPerJob(hiringManagerJobAppContacts);
        }
    }

    // Checks for duplicate hiring managers in the trigger batch and those that already exist outside of the trigger
    public static void enforceOneHiringManagerPerJob (List<Job_Application_Contact__c> jobAppContacts) {

        if (jobAppContacts.isEmpty()) {
            Utility.throwIllegalArgumentException('The jobAppContacts argument is null');
        }
        
        // Throw an error if more than 1 record in the batch has set the Hiring Manager
        Map<Id, Job_Application_Contact__c> newHiringManagersByJobAppId = new Map<Id, Job_Application_Contact__c>();
        for (Job_Application_Contact__c contact : jobAppContacts) {
            if (newHiringManagersByJobAppId.containsKey(contact.Job_Application__c)) {
                Job_Application_Contact__c otherHiringManager = newHiringManagersByJobAppId.get(contact.Job_Application__c);
                otherHiringManager.addError(MORE_THAN_1_HIRING_MGR_ERROR);
                contact.addError(MORE_THAN_1_HIRING_MGR_ERROR);
            } else {
                newHiringManagersByJobAppId.put(contact.Job_Application__c, contact);
            }
        }

        // Now we have checked for duplicate Hiring Managers in the trigger, query for existing ones and put their Job App Ids in a Set
        List<Job_Application_Contact__c> existingHiringManagers = 
            JobApplicationContactSelector.getJobApplicationContactsByRole(newHiringManagersByJobAppId.keySet(), 'Hiring Manager');
        Set<Id> jobAppIdsWithHiringManager = new Set<Id>();
        for (Job_Application_Contact__c hiringManager : existingHiringManagers) {
            jobAppIdsWithHiringManager.add(hiringManager.Job_Application__c);
        }

        // For the new hiring manager records without a dupe in the trigger, throw an error if a hiring manager already exists outside of the trigger.
        for (Job_Application_Contact__c contact : newHiringManagersByJobAppId.values()) {
            if (jobAppIdsWithHiringManager.contains(contact.Job_Application__c)) {
                contact.addError(MORE_THAN_1_HIRING_MGR_ERROR);
            }
        }
    }

    /*** WHEN A JOB APPLICATION CONTACT IS INSERTED OR UPDATED, ENSURE ONLY ONE IN THE BATCH FOR EACH JOB APP HAS THE PRIMARY CONTACT FIELD SET ***/
    /* Note, if the trigger ran across two batches and a Primary Contact was set in each Batch, it is understood the one in the latter batch would be the Primary.
    This is because I built functionality where selecting a Primary Contact automatically replaces the prior one as I wanted to ensure one Primary at all times.
    So, this edge case of two primaries across different batches was considered, but I decided to keep the implementation this way and just guard against two Primary Contacts in the same batch*/

    public static void enforceOnePrimaryContactPerJobUpdate (List<Job_Application_Contact__c> jobAppContacts, Map<Id, Job_Application_Contact__c> oldJobAppContactsById) {

        if (jobAppContacts.isEmpty() || oldJobAppContactsById.isEmpty()) {
            Utility.throwIllegalArgumentException('The jobAppContacts argument is null');
        }

        // Adds all of the Job Application Contacts updated to Primary Contact to a list
        List<Job_Application_Contact__c> jobAppContactsUpdatedToPrimaryContact = new List<Job_Application_Contact__c>();
        for (Job_Application_Contact__c contact : jobAppContacts) {
            if (contact.Primary_Contact__c && contact.Primary_Contact__c != oldJobAppContactsById.get(contact.Id).Primary_Contact__c) {
                jobAppContactsUpdatedToPrimaryContact.add(contact);
            }
        }
        // Calls the method to ensure Job Apps only have 1 Primary Contact
        if (!jobAppContactsUpdatedToPrimaryContact.isEmpty()) {
            enforceOnePrimaryContact(jobAppContactsUpdatedToPrimaryContact);
        }
    }

    public static void enforceOnePrimaryContactPerJobInsert (List<Job_Application_Contact__c> jobAppContacts) {

        if (jobAppContacts.isEmpty()) {
            Utility.throwIllegalArgumentException('The jobAppContacts argument is null');
        }

        // Adds all of the Job Application Contacts created as Primary Contact to a list
        List<Job_Application_Contact__c> primaryContactJobAppContacts = new List<Job_Application_Contact__c>();
        for (Job_Application_Contact__c contact : jobAppContacts) {
            if (contact.Primary_Contact__c) {
                primaryContactJobAppContacts.add(contact);
            }
        }
        // Calls the method to ensure Job Apps only have 1 Primary Contact
        if (!primaryContactJobAppContacts.isEmpty()) {
            enforceOnePrimaryContact(primaryContactJobAppContacts);
        }
    }

    public static void enforceOnePrimaryContact (List<Job_Application_Contact__c> jobAppContacts) {

        if (jobAppContacts.isEmpty()) {
            Utility.throwIllegalArgumentException('The jobAppContacts arugment is null');
        }

        Map<Id, Job_Application_Contact__c> primaryContactByJobAppIdFromBatch = new Map<Id, Job_Application_Contact__c>();
        Set<Id> jobAppIdsWithDupePrimaryContacts = new Set<Id>();

        for (Job_Application_Contact__c contact : jobAppContacts) {
            // If a record has Primary Contact selected, track it as the Primary Contact for that Job App in the trigger
            if (contact.Primary_Contact__c && !primaryContactByJobAppIdFromBatch.containsKey(contact.Job_Application__c)) {
                primaryContactByJobAppIdFromBatch.put(contact.Job_Application__c, contact);
            
            // If a second record from the trigger has Primary Contact selected for the same Job App, throw an error
            } else if (contact.Primary_Contact__c && primaryContactByJobAppIdFromBatch.containsKey(contact.Job_Application__c)) {
                contact.addError(MORE_THAN_1_PRIMARY_IN_BATCH_ERROR);
                if (!jobAppIdsWithDupePrimaryContacts.contains(contact.Job_Application__c)) {
                    jobAppIdsWithDupePrimaryContacts.add(contact.Job_Application__c);
                    Job_Application_Contact__c otherPrimaryContact = primaryContactByJobAppIdFromBatch.remove(contact.Job_Application__c);
                    otherPrimaryContact.addError(MORE_THAN_1_PRIMARY_IN_BATCH_ERROR);
                }
            }     
        }
    }

    /*** WHEN JOB APPLICATION CONTACTS ARE INSERTED WITH NO PRIMARY CONTACT, SET ONE OF THEM PER JOB APP TO THE PRIMARY CONTACT */

    public static void defaultJobApplicationContactToPrimaryOnInsert (List<Job_Application_Contact__c> jobAppContacts) {

        if (jobAppContacts.isEmpty()) {
            Utility.throwIllegalArgumentException('The jobAppContacts arugment is null');
        }

        Map<Id, Job_Application_Contact__c> defaultPrimaryContactByJobAppId = new Map<Id, Job_Application_Contact__c>();
        Map<Id, Job_Application_Contact__c> primaryContactByJobAppIdFromBatch = new Map<Id, Job_Application_Contact__c>();

        for (Job_Application_Contact__c contact : jobAppContacts) {
            
            // If a new record has Primary Contact selected, track it as the Primary Contact for that Job App in the trigger and remove any default Primary Contacts flagged that didn't have Primary selected
            if (contact.Primary_Contact__c && !primaryContactByJobAppIdFromBatch.containsKey(contact.Job_Application__c)) {
                primaryContactByJobAppIdFromBatch.put(contact.Job_Application__c, contact);
                if (defaultPrimaryContactByJobAppId.containsKey(contact.Job_Application__c)) {
                    defaultPrimaryContactByJobAppId.remove(contact.Job_Application__c);
                }
            
            // If Primary Contact isn't selected and no other records in the trigger for that Job App have it selected so far or have been flagged as the default Primary Contact, flag it as the default Primary Contact
            } else if (
                !contact.Primary_Contact__c && 
                !defaultPrimaryContactByJobAppId.containsKey(contact.Job_Application__c) &&
                !primaryContactByJobAppIdFromBatch.containsKey(contact.Job_Application__c)){
                    defaultPrimaryContactByJobAppId.put(contact.Job_Application__c, contact);
            }
        }

        // If there are no Job App Contacts flagged as needing to be the default Primary Contact, end the method
        if (defaultPrimaryContactByJobAppId.isEmpty()) {
            return;
        }
        // Otherwise, check if the potential default Primary Contacts already have a Primary Contact on the Job Application.
        List<Job_Application_Contact__c> existingPrimaryContacts = JobApplicationContactSelector.getPrimaryContactsForJobApps(defaultPrimaryContactByJobAppId.keySet());
        Map<Id, Job_Application_Contact__c> existingPrimaryContactsByJobAppId = new Map<Id, Job_Application_Contact__c>();
        for (Job_Application_Contact__c existingContact : existingPrimaryContacts) {
            existingPrimaryContactsByJobAppId.put(existingContact.Job_Application__c, existingContact);
        }

        // If there isn't an existing Primary Contact for a Job App associated with a new Job App Contact, set the ones identified as the default Primary Contact to the true primary contact
        for(Job_Application_Contact__c potentialDefaultcontact : defaultPrimaryContactByJobAppId.values()) {
            if (!existingPrimaryContactsByJobAppId.containsKey(potentialDefaultcontact.Job_Application__c)) {
                potentialDefaultcontact.Primary_Contact__c = true;
            }
        }
    }

    /*** WHEN A JOB APPLICATION CONTACT IS INSERTED AS THE PRIMARY OR UPDATED AS THE PRIMARY, EXISTING PRIMARY CONTACTS SHOULD HAVE THAT BOX DE-SELECTED ***/

    // This identifies new Job App Contacts in the Trigger that have the Primary Contact box selected and passes them to methods to replace the existing Primary Contact and prevent duplicate Primary Contacts
    public static void replacePrimaryContactsOnInsert (List<Job_Application_Contact__c> jobAppContacts) {

        if (jobAppContacts.isEmpty()) {
            Utility.throwIllegalArgumentException('The jobAppContacts argument is null');
        }

        Map<Id, Job_Application_Contact__c> primaryContactByJobAppId = new Map<Id, Job_Application_Contact__c>();
        for (Job_Application_Contact__c contact : jobAppContacts) {
            if (contact.Primary_Contact__c) {
                primaryContactByJobAppId.put(contact.Job_Application__c, contact);
            }
        }
        
        if (!primaryContactByJobAppId.isEmpty()) {
            replaceExistingPrimaryContact(primaryContactByJobAppId);
        }
    }

    // This identifies existing Job App Contacts in the Trigger that have the Primary Contact box selected and passes them to methods to replace the existing Primary Contact and prevent duplicate Primary Contacts
    public static void replacePrimaryContactsOnUpdate (List<Job_Application_Contact__c> jobAppContacts, Map<Id, Job_Application_Contact__c> oldJobAppContacts) {

        if (jobAppContacts.isEmpty() || oldJobAppContacts.isEmpty()) {
            Utility.throwIllegalArgumentException('The method received null arguments.');
        }

        Map<Id, Job_Application_Contact__c> primaryContactByJobAppId = new Map<Id, Job_Application_Contact__c>();
        for (Job_Application_Contact__c contact : jobAppContacts) {
            if (contact.Primary_Contact__c && !oldJobAppContacts.get(contact.Id).Primary_Contact__c) {
                primaryContactByJobAppId.put(contact.Job_Application__c, contact);
            }
        }

        if (!primaryContactByJobAppId.isEmpty()) {
            replaceExistingPrimaryContact(primaryContactByJobAppId);
        }
    }

    // Helper method for removing the checkbox for the existing Primary Contact so that the new one is the sole Primary Contact
    public static void replaceExistingPrimaryContact(Map<Id, Job_Application_Contact__c> desiredPrimaryByJobAppId) {

        if (desiredPrimaryByJobAppId.isEmpty()) {
            Utility.throwIllegalArgumentException('The newPrimaryByJobAppId argument was null');
        }

        List<Job_Application_Contact__c> existingPrimaryContacts = 
            JobApplicationContactSelector.getPrimaryContactsForJobApps(desiredPrimaryByJobAppId.keySet());
        List<Job_Application_Contact__c> primaryContactsToRemove = new List<Job_Application_Contact__c>();
        for (Job_Application_Contact__c contact : existingPrimaryContacts) {
            if (desiredPrimaryByJobAppId.get(contact.Job_Application__c) == null) {
                continue;
            }
            Id desiredPrimaryForJobApp = desiredPrimaryByJobAppId.get(contact.Job_Application__c).Id;
            if (desiredPrimaryForJobApp != contact.Id) {
                contact.Primary_Contact__c = false;
                primaryContactsToRemove.add(contact);         
            }
        }
        if (!primaryContactsToRemove.isEmpty()) {
            Utility.updateRecords(primaryContactsToRemove);
        }
    }

    // When the only Primary Contact on a Job App is de-selected, throw an error if no other record on the Job App has it selected
    public static void handlePrimaryContactDeselect (List<Job_Application_Contact__c> jobAppContacts, Map<Id, Job_Application_Contact__c> oldJobAppContacts) {

        if (jobAppContacts.isEmpty() || oldJobAppContacts.isEmpty()) {
            Utility.throwIllegalArgumentException('Arguments passed to the method were null');
        }

        // Loop Job Application Contacts in the Trigger to track those that had the Primary box de-selected or selected
        Map<Id, Job_Application_Contact__c> deselectedPrimaryContactsById = new Map<Id, Job_Application_Contact__c>();
        Map<Id, Job_Application_Contact__c> selectedPrimaryContactByJobAppId = new Map<Id, Job_Application_Contact__c>();
        Set<Id> jobApplicationIds = new Set<Id>();
        for (Job_Application_Contact__c contact : jobAppContacts) {
            jobApplicationIds.add(contact.Job_Application__c);
            if (!contact.Primary_Contact__c && oldJobAppContacts.get(contact.Id).Primary_Contact__c) {
                deselectedPrimaryContactsById.put(contact.Id, contact);
            } else if (contact.Primary_Contact__c && !oldJobAppContacts.get(contact.Id).Primary_Contact__c) {
                selectedPrimaryContactByJobAppId.put(contact.Job_Application__c, contact);
            }
        }

        // If no Job Application Contacts had the Primary Box de-selected, end the method as there is nothing to handle
        if (deselectedPrimaryContactsById.isEmpty()) {
            return;
        }

        // Query other Job Application Contacts outside of the trigger that have the Primary Box selected for the same Job App
        // This could happen if a new one is inserted as the Primary, which will deselect the box on the existing Primary per other methods
        // In this case, we wouldn't want to throw an error on the de-select, as we have a new Primary
        List<Job_Application_Contact__c> otherPrimaryContacts = JobApplicationContactSelector.getPrimaryContactsForJobAppsExcludingCertainContacts(jobApplicationIds, oldJobAppContacts.keySet());
        Map<Id, Job_Application_Contact__c> otherPrimaryContactsByJobAppId = new Map<Id, Job_Application_Contact__c>();
        for (Job_Application_Contact__c otherPrimary : otherPrimaryContacts) {
            otherPrimaryContactsByJobAppId.put(otherPrimary.Job_Application__c, otherPrimary);
        }

        // Loop Job Application Contacts that had the Primary Contact de-selected and ensure we have a new Primary Contact in the trigger or database
        for (Job_Application_Contact__c deselectedPrimary : deselectedPrimaryContactsById.values()) {
            // Check if another record in the trigger for the same Job App had the Primary Box selected - if so, no error needed
            if (selectedPrimaryContactByJobAppId.get(deselectedPrimary.Job_Application__c) != null) {
                continue;
            // Check if no other Primary Contacts for the Job App have the box selected. If so, error needed.
            } else if (otherPrimaryContactsByJobAppId.get(deselectedPrimary.Job_Application__c) == null) {
                deselectedPrimary.addError(SELECT_NEW_PRIMARY_ERROR);
            }
        }
    }
}