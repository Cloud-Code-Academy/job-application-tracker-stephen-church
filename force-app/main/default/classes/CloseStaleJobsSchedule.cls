public with sharing class CloseStaleJobsSchedule implements Schedulable {

    public void execute (SchedulableContext SC) {
        CloseStaleJobsBatch batch = new CloseStaleJobsBatch(); 
        Database.executeBatch(batch);
    }
}