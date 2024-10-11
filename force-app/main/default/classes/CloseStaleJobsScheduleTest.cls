@isTest
public with sharing class CloseStaleJobsScheduleTest {

    @isTest
    static void closeStaleJobSchedule() {
        
        Test.startTest();
        CloseStaleJobsSchedule scheduleJob = new CloseStaleJobsSchedule();
        String year = String.valueOf(Date.today().year() + 1);
        // 0 seconds, 0 minutes, 0 hours, 1st of month, 1st month of year, day doesn't take precedence, year
        String cron = '0 0 0 1 1 ? ' + year;
        String jobId = System.schedule('CloseStaleJobsSchedule', cron, scheduleJob);
        scheduleJob.execute(null);
        Test.stopTest();

        Assert.isNotNull(jobId, 'The Job Id should not be null');
    }
}