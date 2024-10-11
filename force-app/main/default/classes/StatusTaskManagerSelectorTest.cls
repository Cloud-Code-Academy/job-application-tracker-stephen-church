@isTest
public with sharing class StatusTaskManagerSelectorTest {

    @isTest
    static void getActiveStatusConfigsForProcess() {

        Test.startTest();
        List<Status_Task_Manager__mdt> statusTaskManagers = 
            StatusTaskManagerSelector.getActiveStatusConfigsForProcess('Job Application');
        Test.stopTest();

        for (Status_Task_Manager__mdt stm : statusTaskManagers) {
            Assert.isTrue(stm.Active__c, 'The query should have only got Active Status Task Managers');
            Assert.areEqual('Job Application', stm.Process__c, 'The process hould be "Job Application');
        }
    }

    @isTest
    static void getActiveStatusConfigsForProcess_nullValue() {

        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            List<Status_Task_Manager__mdt> statusTaskManagers = StatusTaskManagerSelector.getActiveStatusConfigsForProcess(null);
        } catch (IllegalArgumentException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'An Illegal Argument Exception should have been thrown');
    }
}