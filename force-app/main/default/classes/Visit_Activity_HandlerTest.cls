@IsTest
private class Visit_Activity_HandlerTest {

    @TestSetup
    static void setupData() {
        Account acc = new Account(
            Name = 'CGC Metro Market',
            BillingStreet = '123 Market St',
            BillingCity = 'San Francisco',
            BillingState = 'CA'
        );
        insert acc;

        String vId = 'fakeVisitId';
        if (Schema.getGlobalDescribe().containsKey('visit')) {
            SObject v = Schema.getGlobalDescribe().get('Visit').newSObject();
            v.put('AccountId', acc.Id);
            if (Schema.getGlobalDescribe().containsKey('location')) {
                Schema.Location loc = new Schema.Location(Name = 'Test Activity Location');
                insert loc;
                v.put('PlaceId', loc.Id);
            }
            v.put('PlannedVisitStartTime', Datetime.now());
            v.put('Status', 'Planned');
            Database.insert(v, AccessLevel.USER_MODE);
            vId = (String) v.get('Id');

            // Attempt creating AssessmentTask if object is present
            if (Schema.getGlobalDescribe().containsKey('assessmenttask')) {
                try {
                    SObject task1 = Schema.getGlobalDescribe().get('assessmenttask').newSObject();
                    task1.put('Name', 'Inventory Check Task');
                    task1.put('ParentId', vId);
                    task1.put('TaskType', 'InventoryCheck');
                    task1.put('Status', 'Completed');
                    task1.put('Description', 'Completed task check');
                    Database.insert(task1, AccessLevel.USER_MODE);

                    SObject task2 = Schema.getGlobalDescribe().get('assessmenttask').newSObject();
                    task2.put('Name', 'Planogram Check Task');
                    task2.put('ParentId', vId);
                    task2.put('TaskType', 'PlanogramCheck');
                    task2.put('Status', 'In Progress');
                    task2.put('Description', 'Pending task check');
                    Database.insert(task2, AccessLevel.USER_MODE);
                } catch (Exception e) {
                    // Ignore if specific required fields differ
                }
            }

            if (Schema.getGlobalDescribe().containsKey('cgcloud__delivery_task__c')) {
                try {
                    SObject del = Schema.getGlobalDescribe().get('cgcloud__delivery_task__c').newSObject();
                    del.put('cgcloud__Visit__c', vId);
                    del.put('cgcloud__Status__c', 'Scheduled');
                    del.put('cgcloud__Delivery_Note__c', 'Deliver cold drinks');
                    Database.insert(del, AccessLevel.USER_MODE);
                } catch (Exception e) {}
            }
        }
    }

    @IsTest
    static void testGetAssessmentTasks() {
        String vId = 'fakeVisitId';
        if (Schema.getGlobalDescribe().containsKey('visit')) {
            List<SObject> vList = Database.query('SELECT Id FROM Visit LIMIT 1');
            if (!vList.isEmpty()) { vId = (String) vList[0].get('Id'); }
        }

        Visit_Activity_Handler.Request reqAll = new Visit_Activity_Handler.Request();
        reqAll.actionType = 'getAssessmentTasks';
        reqAll.visitId = vId;

        Visit_Activity_Handler.Request reqFilter = new Visit_Activity_Handler.Request();
        reqFilter.actionType = 'get_activities';
        reqFilter.visitId = vId;
        reqFilter.statusFilter = 'Completed';

        Visit_Activity_Handler.Request reqBlank = new Visit_Activity_Handler.Request();
        reqBlank.actionType = 'get_assessment_tasks';
        reqBlank.visitId = '';

        Visit_Activity_Handler.Request reqActivities = new Visit_Activity_Handler.Request();
        reqActivities.actionType = 'getactivities';
        reqActivities.visitId = vId;

        Test.startTest();
        List<Visit_Activity_Handler.Response> resList = Visit_Activity_Handler.execute(
            new List<Visit_Activity_Handler.Request>{ reqAll, reqFilter, reqBlank, reqActivities }
        );
        Test.stopTest();

        Assert.isTrue(resList[0].success, 'All assessment tasks should succeed');
        Assert.isTrue(resList[1].success, 'Filtered assessment tasks should succeed');
        Assert.isFalse(resList[2].success, 'Blank ID should fail');
        Assert.isTrue(resList[3].success, 'getactivities should succeed');
    }

    @IsTest
    static void testGetJobsStatusAndDelivery() {
        String vId = 'fakeVisitId';
        if (Schema.getGlobalDescribe().containsKey('visit')) {
            List<SObject> vList = Database.query('SELECT Id FROM Visit LIMIT 1');
            if (!vList.isEmpty()) { vId = (String) vList[0].get('Id'); }
        }

        Visit_Activity_Handler.Request reqJobs = new Visit_Activity_Handler.Request();
        reqJobs.actionType = 'getJobsStatus';
        reqJobs.visitId = vId;
        reqJobs.statusFilter = 'Pending';

        Visit_Activity_Handler.Request reqJobs2 = new Visit_Activity_Handler.Request();
        reqJobs2.actionType = 'get_jobs_status';
        reqJobs2.visitId = vId;

        Visit_Activity_Handler.Request reqDel = new Visit_Activity_Handler.Request();
        reqDel.actionType = 'getDeliveryActivities';
        reqDel.visitId = vId;

        Visit_Activity_Handler.Request reqDelAlias = new Visit_Activity_Handler.Request();
        reqDelAlias.actionType = 'getdeliveries';
        reqDelAlias.visitId = vId;

        Visit_Activity_Handler.Request reqDelBlank = new Visit_Activity_Handler.Request();
        reqDelBlank.actionType = 'get_delivery_activities';
        reqDelBlank.visitId = '';

        Test.startTest();
        List<Visit_Activity_Handler.Response> resList = Visit_Activity_Handler.execute(
            new List<Visit_Activity_Handler.Request>{ reqJobs, reqJobs2, reqDel, reqDelAlias, reqDelBlank }
        );
        Test.stopTest();

        Assert.isTrue(resList[0].success, 'Jobs status should succeed');
        Assert.isTrue(resList[1].success, 'Jobs status alias should succeed');
        Assert.isTrue(resList[2].success, 'Delivery activities should succeed');
        Assert.isTrue(resList[3].success, 'Delivery alias should succeed');
        Assert.isFalse(resList[4].success, 'Blank delivery ID should fail');
    }

    @IsTest
    static void testGetNextSteps() {
        String vId = 'fakeVisitId';
        if (Schema.getGlobalDescribe().containsKey('visit')) {
            List<SObject> vList = Database.query('SELECT Id FROM Visit LIMIT 1');
            if (!vList.isEmpty()) { vId = (String) vList[0].get('Id'); }
        }

        Visit_Activity_Handler.Request req = new Visit_Activity_Handler.Request();
        req.actionType = 'getNextSteps';
        req.visitId = vId;

        Visit_Activity_Handler.Request req2 = new Visit_Activity_Handler.Request();
        req2.actionType = 'get_next_steps';
        req2.visitId = vId;

        Test.startTest();
        List<Visit_Activity_Handler.Response> resList = Visit_Activity_Handler.execute(
            new List<Visit_Activity_Handler.Request>{ req, req2 }
        );
        Test.stopTest();

        Assert.isTrue(resList[0].success, 'Next steps should succeed');
        Assert.isTrue(resList[0].summary.contains('Recommended Next Actions'), 'Should return next steps summary');
        Assert.isTrue(resList[1].success, 'Alternate next steps should succeed');
    }

    @IsTest
    static void testUnknownActionAndConstructors() {
        Visit_Activity_Handler handler = new Visit_Activity_Handler();
        Assert.isNotNull(handler, 'Constructor should succeed');

        Visit_Activity_Handler.Request req = new Visit_Activity_Handler.Request();
        req.actionType = 'unsupportedActionType';
        req.agentName = 'VisitIntelligence';
        req.domain = 'Activity';
        req.accountId = '001000000000000AAA';
        req.questionOrSurveyFilter = 'Safety';
        req.excludeOption = 'None';

        Test.startTest();
        List<Visit_Activity_Handler.Response> resList = Visit_Activity_Handler.execute(
            new List<Visit_Activity_Handler.Request>{ req }
        );
        Test.stopTest();

        Assert.isFalse(resList[0].success, 'Unknown action should return failure response');
    }
}
