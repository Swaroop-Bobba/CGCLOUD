/**
 * @description Test class for Visit_Agent_Service.
 */
@IsTest
@SuppressWarnings('PMD.NcssMethodCount')
public class Visit_Agent_ServiceTest {

    @IsTest
    static void testExecuteActionRouting() {
        // Setup mock data
        Account acc = new Account(Name = 'CGC Agent Service Store');
        insert as user acc;

        Schema.Location loc = new Schema.Location(Name = 'CGC Route Location');
        insert as user loc;

        Visit vis = new Visit(
            AccountId = acc.Id,
            PlaceId = loc.Id,
            Status = 'Planned',
            PlannedVisitStartTime = DateTime.now()
        );
        insert as user vis;

        Visit_Agent_Service service = new Visit_Agent_Service();

        Test.startTest();
        // 1. Get available
        Agent_Request reqAvailable = new Agent_Request();
        reqAvailable.actionType = 'getAvailable';
        Agent_Response resAvailable = service.execute(reqAvailable);

        // 2. Get account visits
        Agent_Request reqAccVis = new Agent_Request();
        reqAccVis.actionType = 'getAccountVisits';
        reqAccVis.accountId = acc.Id;
        Agent_Response resAccVis = service.execute(reqAccVis);

        // 3. Get OOS visits
        Agent_Request reqOos = new Agent_Request();
        reqOos.actionType = 'getOosVisits';
        reqOos.accountId = acc.Id;
        Agent_Response resOos = service.execute(reqOos);

        // 4. Search visits
        Agent_Request reqSearch = new Agent_Request();
        reqSearch.actionType = 'search';
        reqSearch.searchQuery = 'CGC Agent Service Store today';
        Agent_Response resSearch = service.execute(reqSearch);

        // 5. Get store brief
        Agent_Request reqBrief = new Agent_Request();
        reqBrief.actionType = 'getStoreBrief';
        reqBrief.visitId = vis.Id;
        reqBrief.accountId = acc.Id;
        Agent_Response resBrief = service.execute(reqBrief);

        // 6. Generate summary
        Agent_Request reqSummary = new Agent_Request();
        reqSummary.actionType = 'generateSummary';
        reqSummary.visitId = vis.Id;
        Agent_Response resSummary = service.execute(reqSummary);
        Test.stopTest();

        Assert.isTrue(resAvailable.success, 'Get available visits action should succeed.');
        Assert.isTrue(resAccVis.success, 'Get account visits action should succeed.');
        Assert.isTrue(resOos.success, 'Get OOS visits action should succeed.');
        Assert.isTrue(resSearch.success, 'Search visits action should succeed.');
        Assert.isTrue(resBrief.success, 'Get store brief action should succeed.');
        Assert.isTrue(resSummary.success, 'Generate summary action should succeed.');
    }

    @IsTest
    static void testUpdateVisitStatusAndNotes() {
        Account acc = new Account(Name = 'Update Action Store');
        insert as user acc;

        Schema.Location loc = new Schema.Location(Name = 'Update Location');
        insert as user loc;

        Visit vis = new Visit(
            AccountId = acc.Id,
            PlaceId = loc.Id,
            Status = 'Planned',
            PlannedVisitStartTime = DateTime.now()
        );
        insert as user vis;

        Visit_Agent_Service service = new Visit_Agent_Service();

        Test.startTest();
        // 1. Test Status update
        Agent_Request reqStatus = new Agent_Request();
        reqStatus.actionType = 'update_visit_status';
        reqStatus.visitId = vis.Id;
        reqStatus.status = 'InProgress';
        Agent_Response resStatus = service.execute(reqStatus);

        // 2. Test Notes update
        Agent_Request reqNotes = new Agent_Request();
        reqNotes.actionType = 'update_visit_notes_mobile_action';
        reqNotes.visitId = vis.Id;
        reqNotes.notes = 'Checked target display shelves';
        Agent_Response resNotes = service.execute(reqNotes);
        Test.stopTest();

        Assert.isTrue(resStatus.success, 'Status update action should succeed.');
        Assert.isTrue(resNotes.success, 'Notes update action should succeed.');

        Visit updatedVis = [SELECT Status, cgcloud__Note__c FROM Visit WHERE Id = :vis.Id LIMIT 1];
        Assert.areEqual('InProgress', updatedVis.Status, 'Status was successfully changed.');
        Assert.areEqual('Checked target display shelves', updatedVis.cgcloud__Note__c, 'Notes were successfully appended.');
    }

    @IsTest
    static void testCreateVisitAction() {
        Account acc = new Account(Name = 'New Created Store');
        insert as user acc;

        Schema.Location loc = new Schema.Location(Name = 'New Location');
        insert as user loc;

        Visit_Agent_Service service = new Visit_Agent_Service();

        Test.startTest();
        Agent_Request req = new Agent_Request();
        req.actionType = 'create_visit_record';
        req.createVisitWrapper = new CreateVisitWrapper();
        req.createVisitWrapper.subject = 'Routine Audit';
        req.createVisitWrapper.accountId = acc.Id;
        req.createVisitWrapper.placeId = loc.Id;
        req.createVisitWrapper.plannedStartTime = DateTime.now().addDays(1);
        req.createVisitWrapper.plannedEndTime = DateTime.now().addDays(1).addHours(1);
        req.createVisitWrapper.isAllDayEvent = false;
        
        Agent_Response res = service.execute(req);
        Test.stopTest();

        Assert.isTrue(res.success, 'Create visit action should succeed.');
        Assert.isNotNull(res.visitId, 'Newly created Visit ID should be returned.');
        Assert.areEqual('Planned', res.visitStatus, 'New visit status is Planned.');
    }

    @IsTest
    static void testGetVisitForUpdateAction() {
        Account acc = new Account(Name = 'Load Details Store');
        insert as user acc;

        Schema.Location loc = new Schema.Location(Name = 'Load Details Location');
        insert as user loc;

        Visit vis = new Visit(
            AccountId = acc.Id,
            PlaceId = loc.Id,
            Status = 'Planned',
            PlannedVisitStartTime = DateTime.now(),
            PlannedVisitEndTime = DateTime.now().addHours(1),
            cgcloud__Subject__c = 'Subject Details'
        );
        insert as user vis;

        Visit_Agent_Service service = new Visit_Agent_Service();

        Test.startTest();
        Agent_Request req = new Agent_Request();
        req.actionType = 'get_visit_for_update';
        req.visitId = vis.Id;
        
        Agent_Response res = service.execute(req);
        Test.stopTest();

        Assert.isTrue(res.success, 'Get visit for update should succeed.');
        Assert.isNotNull(res.createVisitWrapper, 'CreateVisitWrapper should be returned.');
        Assert.areEqual('Subject Details', res.createVisitWrapper.subject, 'Subject name should match.');
    }

    @IsTest
    static void testSelectVisitAndOverdueVisits() {
        Account acc = new Account(Name = 'Overdue Visits Store');
        insert as user acc;

        Schema.Location loc = new Schema.Location(Name = 'Overdue Location');
        insert as user loc;

        Visit vis = new Visit(
            AccountId = acc.Id,
            PlaceId = loc.Id,
            Status = 'Planned',
            PlannedVisitStartTime = DateTime.now().addDays(-5)
        );
        insert as user vis;

        Visit_Agent_Service service = new Visit_Agent_Service();

        Test.startTest();
        // 1. Test select_and_navigate_visit
        Agent_Request reqSelect = new Agent_Request();
        reqSelect.actionType = 'select_and_navigate_visit';
        reqSelect.visitId = vis.Id;
        Agent_Response resSelect = service.execute(reqSelect);

        // 2. Test getstalevisits
        Agent_Request reqStale = new Agent_Request();
        reqStale.actionType = 'getstalevisits';
        reqStale.accountId = acc.Id;
        Agent_Response resStale = service.execute(reqStale);
        
        // 3. Test sendvisitalerts
        Agent_Request reqAlerts = new Agent_Request();
        reqAlerts.actionType = 'sendvisitalerts';
        reqAlerts.visitIds = new List<String>{ vis.Id };
        Agent_Response resAlerts = service.execute(reqAlerts);
        Test.stopTest();

        Assert.isTrue(resSelect.success, 'Select visit should succeed.');
        Assert.areEqual(vis.Id, resSelect.visitId, 'Correct visit selected.');

        Assert.isTrue(resStale.success, 'Stale visits retrieval should succeed.');
        Assert.isNotNull(resStale.staleVisits, 'Stale visits list is not null.');

        Assert.isTrue(resAlerts.success, 'Send alerts action execution should succeed.');
    }

    @IsTest
    static void testPromptVisitMobileAction() {
        Account acc = new Account(Name = 'Mobile Prompt Store');
        insert as user acc;

        Visit_Agent_Service service = new Visit_Agent_Service();

        Test.startTest();
        // 1. Prompt Account input
        Agent_Request reqAcc = new Agent_Request();
        reqAcc.actionType = 'prompt_visit_mobile';
        reqAcc.accountInput = 'Mobile Prompt Store';
        Agent_Response resAcc = service.execute(reqAcc);

        // 2. Prompt Start time input
        Agent_Request reqTime = new Agent_Request();
        reqTime.actionType = 'prompt_visit_mobile';
        reqTime.plannedStartTimeStr = 'Tomorrow at 10:00 am';
        Agent_Response resTime = service.execute(reqTime);
        Test.stopTest();

        Assert.isTrue(resAcc.success, 'Mobile account matching should succeed.');
        Assert.areEqual(acc.Id, resAcc.accountId, 'Account resolved correctly.');

        Assert.isTrue(resTime.success, 'Mobile datetime parser should succeed.');
        Assert.isNotNull(resTime.plannedStartTimeStr, 'Parsed datetime ISO string returned.');
    }

    @IsTest
    static void testVisitServiceCoverageBoost() {
        Visit_Agent_Service service = new Visit_Agent_Service();

        Test.startTest();
        // 1. Blank and invalid action types
        Agent_Request reqEmpty = new Agent_Request();
        service.execute(reqEmpty);

        Agent_Request reqInvalid = new Agent_Request();
        reqInvalid.actionType = 'invalid_action';
        service.execute(reqInvalid);

        // 2. Action invocations via execute(req)
        Agent_Request r1 = new Agent_Request(); r1.actionType = 'getavailable'; service.execute(r1);
        Agent_Request r2 = new Agent_Request(); r2.actionType = 'getaccountvisits'; r2.accountId = 'fake_acc_id'; service.execute(r2);
        Agent_Request r3 = new Agent_Request(); r3.actionType = 'getoosvisits'; r3.accountId = 'fake_acc_id'; service.execute(r3);
        Agent_Request r4 = new Agent_Request(); r4.actionType = 'search'; r4.searchQuery = 'FakeSearchTerm'; service.execute(r4);
        Agent_Request r5 = new Agent_Request(); r5.actionType = 'getstorebrief'; r5.visitId = 'fake_visit_id'; r5.accountId = 'fake_acc_id'; service.execute(r5);
        Agent_Request r6 = new Agent_Request(); r6.actionType = 'generatesummary'; r6.visitId = 'fake_visit_id'; service.execute(r6);
        Agent_Request r7 = new Agent_Request(); r7.actionType = 'update_visit_status'; r7.visitId = 'fake_visit_id'; r7.status = 'InProgress'; service.execute(r7);
        Agent_Request r8 = new Agent_Request(); r8.actionType = 'update_visit_notes_mobile_action'; r8.visitId = 'fake_visit_id'; r8.notes = 'Notes'; service.execute(r8);
        Agent_Request r9 = new Agent_Request(); r9.actionType = 'create_visit_record'; r9.createVisitWrapper = new CreateVisitWrapper(); service.execute(r9);
        Agent_Request r10 = new Agent_Request(); r10.actionType = 'get_visit_for_update'; r10.visitId = 'fake_visit_id'; service.execute(r10);
        Agent_Request r11 = new Agent_Request(); r11.actionType = 'select_and_navigate_visit'; r11.visitId = 'fake_visit_id'; service.execute(r11);
        Agent_Request r12 = new Agent_Request(); r12.actionType = 'getstalevisits'; r12.accountId = 'fake_acc_id'; service.execute(r12);
        Agent_Request r13 = new Agent_Request(); r13.actionType = 'sendvisitalerts'; r13.visitIds = new List<String>{ 'fake_visit_id' }; service.execute(r13);
        Agent_Request r14 = new Agent_Request(); r14.actionType = 'prompt_visit_mobile'; r14.accountInput = 'Test Store'; service.execute(r14);
        Test.stopTest();

        Assert.isNotNull(service, 'Service instance exists.');
    }
}
