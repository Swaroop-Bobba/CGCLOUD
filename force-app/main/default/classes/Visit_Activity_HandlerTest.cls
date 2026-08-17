@IsTest
private class Visit_Activity_HandlerTest {

    @TestSetup
    static void setupData() {
        cgcloud__Account_Template__c accTemplate = new cgcloud__Account_Template__c(
            Name = 'Default Customer Template',
            cgcloud__Sales_Org__c = '0001'
        );
        insert accTemplate;

        Account acc = new Account(
            Name = 'CGC Metro Market',
            BillingStreet = '123 Market St',
            BillingCity = 'San Francisco',
            BillingState = 'CA',
            cgcloud__Account_Template__c = accTemplate.Id
        );
        insert acc;

        cgcloud__Visit_Template__c template = new cgcloud__Visit_Template__c(
            Name = 'Default Store Visit',
            cgcloud__Sales_Org__c = '0001'
        );
        insert template;

        Schema.Location loc = new Schema.Location(Name = 'Test Activity Location');
        insert loc;

        Visit v = new Visit(
            AccountId = acc.Id,
            PlaceId = loc.Id,
            cgcloud__Visit_Template__c = template.Id,
            PlannedVisitStartTime = Datetime.now(),
            PlannedVisitEndTime = Datetime.now().addHours(2),
            Status = 'Planned'
        );
        insert v;

        cgcloud__Data_Type__c dt = new cgcloud__Data_Type__c(
            Name = 'DomBool',
            cgcloud__Data_Type__c = 'Toggle',
            cgcloud__Sales_Org__c = '0001'
        );
        insert dt;

        cgcloud__Job_Template__c jtQ = new cgcloud__Job_Template__c(
            Name = 'Question',
            cgcloud__Sales_Org__c = '0001'
        );
        insert jtQ;

        cgcloud__Job_Template__c jtS = new cgcloud__Job_Template__c(
            Name = 'Survey',
            cgcloud__Sales_Org__c = '0001'
        );
        insert jtS;

        cgcloud__Job_Definition_Template__c jdtQ1 = new cgcloud__Job_Definition_Template__c(
            Name = 'Display OK?',
            cgcloud__Description_Language_1__c = 'Check display condition',
            cgcloud__Job_Template__c = jtQ.Id,
            cgcloud__Data_Type__c = dt.Id,
            cgcloud__Sales_Org__c = '0001'
        );
        insert jdtQ1;

        cgcloud__Job_Definition_Template__c jdtQ2 = new cgcloud__Job_Definition_Template__c(
            Name = 'Second placement possible?',
            cgcloud__Description_Language_1__c = 'Check secondary placement',
            cgcloud__Job_Template__c = jtQ.Id,
            cgcloud__Data_Type__c = dt.Id,
            cgcloud__Sales_Org__c = '0001'
        );
        insert jdtQ2;

        cgcloud__Job_Definition_Template__c jdtS1 = new cgcloud__Job_Definition_Template__c(
            Name = 'Lemonade Spring Promo',
            cgcloud__Description_Language_1__c = 'Promo audit',
            cgcloud__Job_Template__c = jtS.Id,
            cgcloud__Data_Type__c = dt.Id,
            cgcloud__Sales_Org__c = '0001'
        );
        insert jdtS1;

        cgcloud__Field_Sales_Activity__c fsa = new cgcloud__Field_Sales_Activity__c(
            cgcloud__Description_Language_1__c = 'Audit Coke shelving and displays',
            cgcloud__Phase__c = 'Committed',
            cgcloud__Sales_Org__c = '0001'
        );
        insert fsa;

        cgcloud__Job_Definition_List_Template__c jdlTemplate = new cgcloud__Job_Definition_List_Template__c(
            Name = 'Standard Activity Template',
            cgcloud__Sales_Org__c = '0001'
        );
        insert jdlTemplate;

        cgcloud__Job_Definition_List__c jdl = new cgcloud__Job_Definition_List__c(
            Name = 'Coke Activities',
            cgcloud__Visit_Template__c = template.Id,
            cgcloud__Field_Sales_Activity__c = fsa.Id,
            cgcloud__Job_Definition_List_Template__c = jdlTemplate.Id,
            cgcloud__Sales_Org__c = '0001',
            cgcloud__Active__c = true
        );
        insert jdl;

        cgcloud__Job_DL_Job_Definition_Template__c link1 = new cgcloud__Job_DL_Job_Definition_Template__c(
            cgcloud__Job_Definition_List__c = jdl.Id,
            cgcloud__Job_Definition_Template__c = jdtQ1.Id,
            cgcloud__Sales_Org__c = '0001',
            cgcloud__Mandatory__c = false,
            cgcloud__Job_Action_Success__c = 'None'
        );
        insert link1;

        cgcloud__Job_DL_Job_Definition_Template__c link2 = new cgcloud__Job_DL_Job_Definition_Template__c(
            cgcloud__Job_Definition_List__c = jdl.Id,
            cgcloud__Job_Definition_Template__c = jdtQ2.Id,
            cgcloud__Sales_Org__c = '0001',
            cgcloud__Mandatory__c = true,
            cgcloud__Job_Action_Success__c = 'Validation'
        );
        insert link2;

        cgcloud__Job_DL_Job_Definition_Template__c link3 = new cgcloud__Job_DL_Job_Definition_Template__c(
            cgcloud__Job_Definition_List__c = jdl.Id,
            cgcloud__Job_Definition_Template__c = jdtS1.Id,
            cgcloud__Sales_Org__c = '0001',
            cgcloud__Mandatory__c = false,
            cgcloud__Job_Action_Success__c = 'None'
        );
        insert link3;

        cgcloud__Visit_Job__c vj1 = new cgcloud__Visit_Job__c(
            cgcloud__Visit__c = v.Id,
            cgcloud__Job_Definition_Template__c = jdtQ1.Id,
            cgcloud__Done__c = true,
            cgcloud__Value__c = 'Yes'
        );
        insert vj1;

        if (Schema.getGlobalDescribe().containsKey('cgcloud__delivery_task__c')) {
            try {
                SObject del = Schema.getGlobalDescribe().get('cgcloud__delivery_task__c').newSObject();
                del.put('cgcloud__Visit__c', v.Id);
                del.put('cgcloud__Status__c', 'Scheduled');
                del.put('cgcloud__Delivery_Note__c', 'Deliver cold drinks');
                Database.insert(del, AccessLevel.USER_MODE);
            } catch (Exception e) {}
        }
    }

    @IsTest
    static void testGetActivitiesAllAndFiltered() {
        Visit v = [SELECT Id FROM Visit LIMIT 1];

        Visit_Activity_Handler.Request reqAll = new Visit_Activity_Handler.Request();
        reqAll.actionType = 'getactivities';
        reqAll.visitId = v.Id;
        reqAll.questionOrSurveyFilter = 'all';

        Visit_Activity_Handler.Request reqQ = new Visit_Activity_Handler.Request();
        reqQ.actionType = 'get_activities';
        reqQ.visitId = v.Id;
        reqQ.questionOrSurveyFilter = 'question';

        Visit_Activity_Handler.Request reqS = new Visit_Activity_Handler.Request();
        reqS.actionType = 'getassessmenttasks';
        reqS.visitId = v.Id;
        reqS.questionOrSurveyFilter = 'survey';

        Test.startTest();
        List<Visit_Activity_Handler.Response> resList = Visit_Activity_Handler.execute(
            new List<Visit_Activity_Handler.Request>{ reqAll, reqQ, reqS }
        );
        Test.stopTest();

        Assert.isTrue(resList[0].success, 'Activities retrieval should succeed');
        Assert.isTrue(resList[0].summary.contains('Planned Activities'), 'Should return planned activities table');
        Assert.isTrue(resList[1].success, 'Question filtered activities should succeed');
        Assert.isTrue(resList[2].success, 'Survey filtered activities should succeed');
    }

    @IsTest
    static void testGetJobsStatusAllAndFiltered() {
        Visit v = [SELECT Id FROM Visit LIMIT 1];

        Visit_Activity_Handler.Request reqAll = new Visit_Activity_Handler.Request();
        reqAll.actionType = 'getjobsstatus';
        reqAll.visitId = v.Id;
        reqAll.statusFilter = 'all';
        reqAll.questionOrSurveyFilter = 'all';

        Visit_Activity_Handler.Request reqAns = new Visit_Activity_Handler.Request();
        reqAns.actionType = 'get_jobs_status';
        reqAns.visitId = v.Id;
        reqAns.statusFilter = 'answered';
        reqAns.questionOrSurveyFilter = 'question';

        Visit_Activity_Handler.Request reqPend = new Visit_Activity_Handler.Request();
        reqPend.actionType = 'get_jobs_status';
        reqPend.visitId = v.Id;
        reqPend.statusFilter = 'pending';
        reqPend.questionOrSurveyFilter = 'survey';

        Test.startTest();
        List<Visit_Activity_Handler.Response> resList = Visit_Activity_Handler.execute(
            new List<Visit_Activity_Handler.Request>{ reqAll, reqAns, reqPend }
        );
        Test.stopTest();

        Assert.isTrue(resList[0].success, 'Jobs status should succeed');
        Assert.isTrue(resList[0].summary.contains('Questions & Surveys Status'), 'Should return status table');
        Assert.isTrue(resList[0].totalTasks > 0, 'Total tasks should be > 0');
    }

    @IsTest
    static void testAccountTargetingJdl() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        cgcloud__Visit_Template__c template = [SELECT Id FROM cgcloud__Visit_Template__c LIMIT 1];

        cgcloud__Job_Definition_List_Template__c jdlTemplateTarget = new cgcloud__Job_Definition_List_Template__c(
            Name = 'Targeted Activity Template',
            cgcloud__Sales_Org__c = '0001',
            cgcloud__Consider_Account__c = true
        );
        insert jdlTemplateTarget;

        cgcloud__Job_Definition_List__c jdlAcc = new cgcloud__Job_Definition_List__c(
            Name = 'Targeted Customer JDL',
            cgcloud__Visit_Template__c = template.Id,
            cgcloud__Job_Definition_List_Template__c = jdlTemplateTarget.Id,
            cgcloud__Sales_Org__c = '0001',
            cgcloud__Active__c = true
        );
        insert jdlAcc;

        cgcloud__Job_Definition_List_Account__c jdlAccLink = new cgcloud__Job_Definition_List_Account__c(
            cgcloud__Job_Definition_List__c = jdlAcc.Id,
            cgcloud__Account__c = acc.Id,
            cgcloud__Sales_Org__c = '0001',
            cgcloud__Excluded__c = false
        );
        insert jdlAccLink;

        cgcloud__Job_Template__c jt = [SELECT Id FROM cgcloud__Job_Template__c WHERE Name = 'Question' LIMIT 1];
        cgcloud__Data_Type__c dt = [SELECT Id FROM cgcloud__Data_Type__c LIMIT 1];
        cgcloud__Job_Definition_Template__c jdt = new cgcloud__Job_Definition_Template__c(
            Name = 'Customer Specific Question',
            cgcloud__Job_Template__c = jt.Id,
            cgcloud__Data_Type__c = dt.Id,
            cgcloud__Sales_Org__c = '0001'
        );
        insert jdt;

        cgcloud__Job_DL_Job_Definition_Template__c link = new cgcloud__Job_DL_Job_Definition_Template__c(
            cgcloud__Job_Definition_List__c = jdlAcc.Id,
            cgcloud__Job_Definition_Template__c = jdt.Id,
            cgcloud__Sales_Org__c = '0001',
            cgcloud__Mandatory__c = false,
            cgcloud__Job_Action_Success__c = 'None'
        );
        insert link;

        Visit v = [SELECT Id FROM Visit LIMIT 1];

        Visit_Activity_Handler.Request req = new Visit_Activity_Handler.Request();
        req.actionType = 'getactivities';
        req.visitId = v.Id;

        Test.startTest();
        List<Visit_Activity_Handler.Response> resList = Visit_Activity_Handler.execute(
            new List<Visit_Activity_Handler.Request>{ req }
        );
        Test.stopTest();

        Assert.isTrue(resList[0].success, 'Activities with targeted account should succeed');
    }

    @IsTest
    static void testDeliveriesAndNextSteps() {
        Visit v = [SELECT Id FROM Visit LIMIT 1];

        Visit_Activity_Handler.Request reqDel = new Visit_Activity_Handler.Request();
        reqDel.actionType = 'getDeliveryActivities';
        reqDel.visitId = v.Id;

        Visit_Activity_Handler.Request reqDelAlias = new Visit_Activity_Handler.Request();
        reqDelAlias.actionType = 'getdeliveries';
        reqDelAlias.visitId = v.Id;

        Visit_Activity_Handler.Request reqSteps = new Visit_Activity_Handler.Request();
        reqSteps.actionType = 'getNextSteps';
        reqSteps.visitId = v.Id;

        Visit_Activity_Handler.Request reqSteps2 = new Visit_Activity_Handler.Request();
        reqSteps2.actionType = 'get_next_steps';
        reqSteps2.visitId = v.Id;

        Test.startTest();
        List<Visit_Activity_Handler.Response> resList = Visit_Activity_Handler.execute(
            new List<Visit_Activity_Handler.Request>{ reqDel, reqDelAlias, reqSteps, reqSteps2 }
        );
        Test.stopTest();

        Assert.isTrue(resList[0].success, 'Delivery activities should succeed');
        Assert.isTrue(resList[1].success, 'Delivery alias should succeed');
        Assert.isTrue(resList[2].success, 'Next steps should succeed');
        Assert.isTrue(resList[3].success, 'Next steps alias should succeed');
    }

    @IsTest
    static void testFallbacksAndErrors() {
        Visit_Activity_Handler handler = new Visit_Activity_Handler();
        Assert.isNotNull(handler, 'Constructor should succeed');

        Visit_Activity_Handler.Request reqBlank = new Visit_Activity_Handler.Request();
        reqBlank.actionType = 'getactivities';
        reqBlank.visitId = '';

        Visit_Activity_Handler.Request reqJobsBlank = new Visit_Activity_Handler.Request();
        reqJobsBlank.actionType = 'getjobsstatus';
        reqJobsBlank.visitId = '';

        Visit_Activity_Handler.Request reqDelBlank = new Visit_Activity_Handler.Request();
        reqDelBlank.actionType = 'getdeliveryactivities';
        reqDelBlank.visitId = '';

        Visit_Activity_Handler.Request reqUnknown = new Visit_Activity_Handler.Request();
        reqUnknown.actionType = 'unknownActionType';
        reqUnknown.visitId = '0Z5000000000000AAA';

        Test.startTest();
        List<Visit_Activity_Handler.Response> resList = Visit_Activity_Handler.execute(
            new List<Visit_Activity_Handler.Request>{ reqBlank, reqJobsBlank, reqDelBlank, reqUnknown }
        );
        Test.stopTest();

        Assert.isFalse(resList[0].success, 'Blank ID should fail');
        Assert.isFalse(resList[1].success, 'Blank ID for jobs status should fail');
        Assert.isFalse(resList[2].success, 'Blank ID for delivery should fail');
        Assert.isFalse(resList[3].success, 'Unknown action should fail');
    }

    @IsTest
    static void testFallbackBranches() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Schema.Location loc = [SELECT Id FROM Location LIMIT 1];

        Visit vNoTemplate = new Visit(
            AccountId = acc.Id,
            PlaceId = loc.Id,
            PlannedVisitStartTime = Datetime.now(),
            PlannedVisitEndTime = Datetime.now().addHours(1),
            Status = 'Planned'
        );
        insert vNoTemplate;

        // VisitJob direct fallback
        cgcloud__Job_Definition_Template__c jdt = [SELECT Id FROM cgcloud__Job_Definition_Template__c LIMIT 1];
        cgcloud__Visit_Job__c vj = new cgcloud__Visit_Job__c(
            cgcloud__Visit__c = vNoTemplate.Id,
            cgcloud__Job_Definition_Template__c = jdt.Id,
            cgcloud__Done__c = false,
            cgcloud__Value__c = null
        );
        insert vj;

        Visit_Activity_Handler.Request req1 = new Visit_Activity_Handler.Request();
        req1.actionType = 'getactivities';
        req1.visitId = vNoTemplate.Id;

        Visit_Activity_Handler.Request req2 = new Visit_Activity_Handler.Request();
        req2.actionType = 'getjobsstatus';
        req2.visitId = vNoTemplate.Id;

        Test.startTest();
        List<Visit_Activity_Handler.Response> resList = Visit_Activity_Handler.execute(
            new List<Visit_Activity_Handler.Request>{ req1, req2 }
        );
        Test.stopTest();

        Assert.isTrue(resList[0].success, 'Visit Job fallback should succeed');
        Assert.isTrue(resList[1].success, 'Visit Job status should succeed');
    }

    @IsTest
    static void testAssessmentTaskFallback() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Schema.Location loc = [SELECT Id FROM Location LIMIT 1];

        Visit vEmpty = new Visit(
            AccountId = acc.Id,
            PlaceId = loc.Id,
            PlannedVisitStartTime = Datetime.now(),
            PlannedVisitEndTime = Datetime.now().addHours(1),
            Status = 'Planned'
        );
        insert vEmpty;

        if (Schema.getGlobalDescribe().containsKey('assessmenttask')) {
            try {
                SObject task1 = Schema.getGlobalDescribe().get('assessmenttask').newSObject();
                task1.put('Name', 'Task 1');
                task1.put('ParentId', vEmpty.Id);
                task1.put('TaskType', 'Audit');
                task1.put('Status', 'Completed');
                Database.insert(task1, AccessLevel.USER_MODE);

                SObject task2 = Schema.getGlobalDescribe().get('assessmenttask').newSObject();
                task2.put('Name', 'Task 2');
                task2.put('ParentId', vEmpty.Id);
                task2.put('TaskType', 'Inventory');
                task2.put('Status', 'Pending');
                Database.insert(task2, AccessLevel.USER_MODE);
            } catch (Exception e) {}
        }

        Visit_Activity_Handler.Request req1 = new Visit_Activity_Handler.Request();
        req1.actionType = 'getactivities';
        req1.visitId = vEmpty.Id;

        Visit_Activity_Handler.Request req2 = new Visit_Activity_Handler.Request();
        req2.actionType = 'getjobsstatus';
        req2.visitId = vEmpty.Id;
        req2.statusFilter = 'Completed';

        Test.startTest();
        List<Visit_Activity_Handler.Response> resList = Visit_Activity_Handler.execute(
            new List<Visit_Activity_Handler.Request>{ req1, req2 }
        );
        Test.stopTest();

        Assert.isTrue(resList[0].success, 'Fallback should succeed');
        Assert.isTrue(resList[1].success, 'Filtered fallback should succeed');
    }
}
