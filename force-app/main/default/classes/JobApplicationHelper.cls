public with sharing class JobApplicationHelper {

    @TestVisible public static final String OPEN_TASK_ERROR = 'You cannot change the status when there are open Tasks';
    @TestVisible public static final String INVALID_STATUS_CHANGE_START = 'The Application Status cannot be changed from ';
    
    public static List<Job_Application__c> generateJobApplicationsFromSelectedJobs (
        List<Map<String, Object>> selectedJobs, 
        String accountNameMapping, 
        Map<String, Account> accountsByCompanyName,
        List<Integration_Field_Mapping__mdt> jobFieldMappings) {

        if (selectedJobs.isEmpty() || accountNameMapping == null || accountsByCompanyName.isEmpty() || jobFieldMappings.isEmpty()) {
            Utility.throwIllegalArgumentException('An argument was null.');
        }

        List<Job_Application__c> selectedJobApplications = new List<Job_Application__c>();
        for (Map<String, Object> singleSelectedJob : selectedJobs) {
            Job_Application__c selectedJobApplication = new Job_Application__c();
            String companyName = String.valueOf(singleSelectedJob.get(accountNameMapping));
            if(accountsByCompanyName.get(companyName) == null) { 
                String jobIdAsCompanyName = String.valueOf(singleSelectedJob.get('id'));
                selectedJobApplication.Company__c = accountsByCompanyName.get(jobIdAsCompanyName).Id;
            } else {
                selectedJobApplication.Company__c = accountsByCompanyName.get(companyName).Id;
            }
            selectedJobApplication = (Job_Application__c)IntegrationFieldMappingHelper.mapValuesToSingleSObject(
                jobFieldMappings, 'Job_Application__c', selectedJobApplication, singleSelectedJob);
            selectedJobApplications.add(selectedJobApplication);
        }
        return selectedJobApplications;
    }

    public static void setStringSalaryToDecimalSalary(List<Job_Application__c> jobApplications) {

        if (jobApplications.isEmpty()) {
            Utility.throwIllegalArgumentException('The jobApplications argument was empty');
        }

        // Get Job Applications that have a string salary value and end the method if none exist
        List<Job_Application__c> jobApplicationsToConvertSalaryFor = new List<Job_Application__c>();
        for (Job_Application__c application : jobApplications) {
            if (application.Salary_From_Job_Board__c != null) {
                jobApplicationsToConvertSalaryFor.add(application);
            }
        }
        if (jobApplicationsToConvertSalaryFor.isEmpty()) {
            return;
        }

        // Get Custom Metadata that contains the classes with the logic to check string salaries and convert to decimals
        List<SObject_Salary_Conversion_Class__mdt> activeSalaryConversions = SObjectSalaryConversionClassSelector.getActiveSalaryConversions();
        if (activeSalaryConversions.isEmpty()) {
            Utility.throwQueryException('No active Salary Conversions were found in the Custom Metadata');
        }

        // Loop the classes stored in CMDT, instantiate them to perform the conversions and track sObjects still to have a salary converted
        for (SObject_Salary_Conversion_Class__mdt conversion : activeSalaryConversions) {
            // Break the loop once there are no more sObjects to convert a salary for
            if (jobApplicationsToConvertSalaryFor.isEmpty()) {
                break;
            }
            // Get the class name so it can be instantiated and check string pattern and assign decimal salaries for matches
            Type salaryConversionClassName = Type.forName(conversion.DeveloperName);
            SObjectSalaryConvert conversionCheck = (SObjectSalaryConvert)salaryConversionClassName.newInstance();
            conversionCheck.checkSalaryPatternAndConvert(jobApplicationsToConvertSalaryFor, 'Salary_From_Job_Board__c', 'Salary__c');
            // Call the instance method to get the sObjects that didn't meet the pattern to use in the next loop iteration
            jobApplicationsToConvertSalaryFor = conversionCheck.getSObjectsNotMatchingPattern();
        }
    }

    public static void calculateTaxesAndTakeHomeWhenSalaryChanged(List<Job_Application__c> updatedJobApps, Map<Id, Job_Application__c> oldJobAppsById) {

        if (updatedJobApps.isEmpty() || oldJobAppsById.isEmpty()) {
            Utility.throwIllegalArgumentException('Null arguments were passed to the method');
        }
        List<Job_Application__c> jobApplicationsToCalculateTaxesFor = new List<Job_Application__c>();
        for(Job_Application__c jobApp : updatedJobApps) {
            if (jobApp.Salary__c != oldJobAppsById.get(jobApp.Id).Salary__c) {
                jobApplicationsToCalculateTaxesFor.add(jobApp);
            }
        }
        if (!jobApplicationsToCalculateTaxesFor.isEmpty()) {
            calculateTaxesAndTakeHome(jobApplicationsToCalculateTaxesFor);
        }
    }

    public static List<Job_Application__c> calculateTaxesAndTakeHome (List<Job_Application__c> jobApplicationsToCalculateTaxesFor){

        if (jobApplicationsToCalculateTaxesFor.isEmpty()) {
            Utility.throwIllegalArgumentException('The jobApplicationsToCalculateTaxesFor argument was null');
        }

        // Get the tax filing of the User, the details of that status and the withholding rates for that status
        String userFederalTaxStatus = UserSelector.getFederalTaxStatusOfUser(UserInfo.getUserId());
        Federal_Tax_Filing_Status__mdt filingStatusInfo = Federal_Tax_Filing_Status__mdt.getInstance(userFederalTaxStatus);
        List<Federal_Withholding__mdt> withholdingForStatus = FederalWithholdingSelector.getFederalWithholdingsForStatus(filingStatusInfo.Id);
        // There were some limitations around SOQL and CMDT, so just using the getInstance method to add these to the List
        withholdingForStatus.add(Federal_Withholding__mdt.getInstance('Social_Security'));
        withholdingForStatus.add(Federal_Withholding__mdt.getInstance('Medicare'));
        if (filingStatusInfo == null || withholdingForStatus.isEmpty()) {
            Utility.throwQueryException('The filing status or withholding rates could not be found');
        }

        // Set the estimated taxes
        // I know nested for loops aren't typically suggested, but I don't feel like this is doing extra processing.
        for (Job_Application__c app : jobApplicationsToCalculateTaxesFor) {
            if (app.Salary__c == null || app.Salary__c == 0) {
                app.Estimated_Annual_Federal_Tax__c = 0;
                app.Estimated_Annual_Medicare_Tax__c = 0;
                app.Estimated_Annual_Social_Security_Tax__c = 0;
                app.Estimated_Annual_Take_Home_Pay__c = 0;
                app.Estimated_Monthly_Take_Home_Pay__c = 0;
                continue;
            }
            // Set the Estimated Annual Federal Tax to 0 so we can use += on it as we go through each tax brackets
            app.Estimated_Annual_Federal_Tax__c = 0;
            for (Federal_Withholding__mdt withholding : withholdingForStatus) {
                if (app.Salary__c < withholding.Bracket_Start__c) {
                    continue;
                }      
                Decimal taxableAmount = FederalWithholdingHelper.getAmountToTaxInTaxBracket(
                    app.Salary__c, 
                    withholding.Bracket_Start__c, 
                    withholding.Bracket_End__c);
                Decimal amountToTax = FederalWithholdingHelper.calculateTaxesDue(
                    taxableAmount, 
                    withholding.Tax_Rate__c);
                if (withholding.Type__c == 'Federal Income Tax') {
                    app.Estimated_Annual_Federal_Tax__c += amountToTax;
                } else if (withholding.Type__c == 'Social Security') {
                    app.Estimated_Annual_Social_Security_Tax__c = amountToTax;
                } else {
                    app.Estimated_Annual_Medicare_Tax__c = amountToTax;
                }
            }
            Decimal totalTax = app.Estimated_Annual_Federal_Tax__c + app.Estimated_Annual_Medicare_Tax__c + app.Estimated_Annual_Social_Security_Tax__c;
            app.Estimated_Annual_Take_Home_Pay__c = app.Salary__c - totalTax;
            app.Estimated_Monthly_Take_Home_Pay__c = app.Estimated_Annual_Take_Home_Pay__c / 12;
        }
        return jobApplicationsToCalculateTaxesFor;
    }

    public static void blockStatusChangeWhenOpenTasks(Map<Id, Job_Application__c> jobAppsById, Map<Id, Job_Application__c> oldJobAppsById){

        // First, check if the status changed
        Set<Id> jobAppIdsWithStatusChange = new Set<Id>();
        for (Job_Application__c jobApp : jobAppsById.values()) {
            if (jobApp.Application_Status__c != oldJobAppsById.get(jobApp.Id).Application_Status__c) {
                jobAppIdsWithStatusChange.add(jobApp.Id);
            }
        }

        // If status changed, query to see if they have open tasks
        if (!jobAppIdsWithStatusChange.isEmpty()) {
            List<Job_Application__c> jobAppsWithOpenChildTasks = JobApplicationSelector.getJobAppsWithOpenTasks(jobAppIdsWithStatusChange);
            for (Job_Application__c jobApp : jobAppsWithOpenChildTasks) {
                if (!jobApp.Tasks.isEmpty()) {
                    jobAppsById.get(jobApp.Id).addError(OPEN_TASK_ERROR);
                }
            }
        }
    }

    public static void blockUnauthorizedStatusChanges(
        Map<Id, Job_Application__c> jobAppsById, 
        Map<Id, Job_Application__c> oldJobAppsById,
        List<Status_Task_Manager__mdt> jobAppStatusConfigs){

        if (jobAppsById.isEmpty() || oldJobAppsById.isEmpty() || jobAppStatusConfigs.isEmpty()) {
            Utility.throwIllegalArgumentException('Null arguments were passed to the method');
        }
        
        // Build a Map of Status Task Managers with the Status as the Key and the CMDT record as the value.
        Map<String, Status_Task_Manager__mdt> statusTaskManagersByStatus = new Map<String, Status_Task_Manager__mdt>();
        for (Status_Task_Manager__mdt stm : jobAppStatusConfigs) {
            statusTaskManagersByStatus.put(stm.Status__c, stm);
        }

        // Throw an error on a Job Application if the status change isn't valid
        for (Job_Application__c jobApp : jobAppsById.values()) {
            Job_Application__c oldJobApp = oldJobAppsById.get(jobApp.Id);
            // If no status change, check next record
            if (jobApp.Application_Status__c == oldJobApp.Application_Status__c) {
                continue;
            }
            // All statuses should be in the CMDT but - if not - continue to the next iteration
            if (statusTaskManagersByStatus.get(oldJobApp.Application_Status__c) == null) {
                continue;
            }
            // Otherwise, get the status config for the prior status so we can check if the status change is valid
            Status_Task_Manager__mdt validStatusConfig = statusTaskManagersByStatus.get(oldJobApp.Application_Status__c);
            String allowedNextStatus = validStatusConfig.Valid_Next_Status__c;
            if (allowedNextStatus == null || !allowedNextStatus.contains(jobApp.Application_Status__c)) {
                jobApp.addError(
                    INVALID_STATUS_CHANGE_START + oldJobApp.Application_Status__c + ' to ' + jobApp.Application_Status__c + '.');
            }
        }
    }

    public static void setSubmissionDateWhenStatusIsApplied(List<Job_Application__c> jobApps, Map<Id, Job_Application__c> oldJobAppsById) {

        if (jobApps.isEmpty()) {
            Utility.throwIllegalArgumentException('The jobApps argument was null');
        }

        for (Job_Application__c jobApp : jobApps) {
            if (jobApp.Application_Status__c == 'Applied' && oldJobAppsById.get(jobApp.Id).Application_Status__c != 'Applied') {
                jobApp.Application_Submission_Date__c = Date.today();
            }
        }
    }

    public static void generateTasksForStatus(List<Job_Application__c> jobApps, List<Status_Task_Manager__mdt> statusConfigs) {

        if (jobApps.isEmpty() || statusConfigs.isEmpty()) {
            Utility.throwIllegalArgumentException('Null arguments were passed to the method');
        }

        // Tracks the job apps that need status Tasks and the classes that should be used to create those for that particular status
        Map<String, List<Job_Application__c>> jobAppsByStatusClassName = new Map<String, List<Job_Application__c>>();
        Map<String, Status_Task_Manager__mdt> statusTaskManagersByStatus = new Map<String, Status_Task_Manager__mdt>();
        Map<String, Status_Task_Manager__mdt> statusTaskManagersByClassName = new Map<String, Status_Task_Manager__mdt>();
        Set<String> statusesRequiringTasks = new Set<String>();
        // Loop the Status Task Managers and assign appropriately to the above variables
        for (Status_Task_Manager__mdt stm : statusConfigs) {
            statusTaskManagersByStatus.put(stm.Status__c, stm);
            statusTaskManagersByClassName.put(stm.Task_Generation_Class__c, stm);
            if (stm.Task_Generation_Class__c != null) {
                // Tracks Job Application Class Names that create Tasks and sets up an empty job list to track jobs needing to invoke that Class
                List<Job_Application__c> emptyJobAppsForMap = new List<Job_Application__c>();
                jobAppsByStatusClassName.put(stm.Task_Generation_Class__c, emptyJobAppsForMap);
                statusesRequiringTasks.add(stm.Status__c);
            }
        }

        // Loop the Job Applications and setup variables to help with processing
        for(Job_Application__c jobApp : jobApps) {
            String taskClassNameForNewStatus = null;
            Status_Task_Manager__mdt statusConfigNewStatus = new Status_Task_Manager__mdt();

            // If this Job Application doesn't have a status requiring a Task, exit the method as no further action is required
            if (!statusesRequiringTasks.contains((jobApp.Application_Status__c))) {
                return;
            } else {
                taskClassNameForNewStatus = statusTaskManagersByStatus.get(jobApp.Application_Status__c).Task_Generation_Class__c;
            }

            // Get the list in the Map tracking Job Apps needing Tasks by the responsible Class. Add the Job to it and put it back in the Map
            List<Job_Application__c> jobAppsForStatus = jobAppsByStatusClassName.get(taskClassNameForNewStatus);
            jobAppsForStatus.add(jobApp);
            jobAppsByStatusClassName.put(taskClassNameForNewStatus, jobAppsForStatus);
        }

        // Loop the Class Names that can create Tasks and remove those with an empty Job App List so we don't try to invoke them
        for (String stmStatus : jobAppsByStatusClassName.keySet()) {
            if (jobAppsByStatusClassName.get(stmStatus).isEmpty()) {
                jobAppsByStatusClassName.remove(stmStatus);
            }
        }

        // Loop the remaining Classes that we should create an instance of and pass in the Job Apps that need Tasks created by that instance
        List<Task> statusBasedTasks = new List<Task>();
        for (String statusClassName : jobAppsByStatusClassName.keySet()){
            Type taskClassNameAsApexType = Type.forName(statusClassName);
            StatusTaskManager taskGenerator = (StatusTaskManager)taskClassNameAsApexType.newInstance();
            statusBasedTasks.addAll(taskGenerator.generateStatusTasks(jobAppsByStatusClassName.get(statusClassName), statusTaskManagersByClassName.get(statusClassName)));
        }
        // Call Utility method to insert the Tasks in bulk
        Utility.insertRecords(statusBasedTasks);
    }
}