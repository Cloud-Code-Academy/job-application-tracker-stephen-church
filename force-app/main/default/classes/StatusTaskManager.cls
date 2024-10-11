public interface StatusTaskManager {

    List<Task> generateStatusTasks(List<SObject> parentRecordsNeedingTasks, Status_Task_Manager__mdt statusConfig);
}