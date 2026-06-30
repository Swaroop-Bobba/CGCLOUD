List<Visit_Activity_Handler.ActivityInfo> res = Visit_Activity_Service.getVisitActivities('0Z5Bh0000001YndKAE', 'all');
System.debug('=== getVisitActivities Output ===');
System.debug('Number of Activities: ' + res.size());
for (Visit_Activity_Handler.ActivityInfo act : res) {
    System.debug('Activity: ' + act.activityName + ' | ID: ' + act.activityId);
    if (act.questions != null) {
        for (Visit_Activity_Handler.QuestionInfo q : act.questions) {
            System.debug('  - Question: ' + q.questionName + ' | Type: ' + q.jobType);
        }
    }
}
