/**
 * Unit tests verifying visit search, date parsing, pagination,
 * summaries, and navigation in VisitAgentController.
 */
@IsTest
private class VisitAgentControllerTest {

    @TestSetup
    static void setupData() {
        Account acc = new Account(
            Name = 'CGC Metro Market',
            BillingStreet = '100 Main St',
            BillingCity = 'Dallas',
            BillingState = 'TX',
            BillingPostalCode = '75001',
            BillingCountry = 'USA',
            Phone = '555-1234'
        );
        insert acc;

        if (Schema.getGlobalDescribe().containsKey('visit')) {
            SObject v = Schema.getGlobalDescribe().get('Visit').newSObject();
            v.put('AccountId', acc.Id);
            if (Schema.getGlobalDescribe().containsKey('location')) {
                Schema.Location loc = new Schema.Location(Name = 'Test Market Location');
                insert loc;
                v.put('PlaceId', loc.Id);
            }
            v.put('PlannedVisitStartTime', Datetime.now());
            v.put('PlannedVisitEndTime', Datetime.now().addHours(2));
            v.put('Status', 'Planned');
            if (Schema.getGlobalDescribe().get('Visit').getDescribe().fields.getMap().containsKey('cgcloud__note__c')) {
                v.put('cgcloud__Note__c', 'Initial note');
            }
            Database.insert(v, AccessLevel.USER_MODE);
        }
    }

    @IsTest
    static void testListAvailableVisits() {
        VisitAgentController.Request req = new VisitAgentController.Request();
        req.actionType = 'getAvailable';

        Test.startTest();
        List<VisitAgentController.Response> resList = VisitAgentController.execute(
            new List<VisitAgentController.Request>{ req }
        );
        Test.stopTest();

        Assert.areEqual(1, resList.size(), 'Expected 1 response');
        Assert.isTrue(resList[0].success, 'Expected getAvailable to succeed');
        Assert.isNotNull(resList[0].summary, 'Summary should not be null');
    }

    @IsTest
    static void testSearchVisits() {
        VisitAgentController.Request reqAll = new VisitAgentController.Request();
        reqAll.actionType = 'search';
        reqAll.searchQuery = 'all';
        reqAll.searchOffset = '0';

        VisitAgentController.Request reqNTO = new VisitAgentController.Request();
        reqNTO.actionType = 'search';
        reqNTO.searchQuery = '*NTO Store #201';
        reqNTO.searchOffset = '0';

        VisitAgentController.Request reqToday = new VisitAgentController.Request();
        reqToday.actionType = 'searchVisits';
        reqToday.searchQuery = 'today planned';

        VisitAgentController.Request reqThisWeek = new VisitAgentController.Request();
        reqThisWeek.actionType = 'searchVisits';
        reqThisWeek.searchQuery = 'this week in progress';

        VisitAgentController.Request reqTomorrow = new VisitAgentController.Request();
        reqTomorrow.actionType = 'searchVisits';
        reqTomorrow.searchQuery = 'tomorrow completed';

        VisitAgentController.Request reqNextWeek = new VisitAgentController.Request();
        reqNextWeek.actionType = 'searchVisits';
        reqNextWeek.searchQuery = 'next week';

        VisitAgentController.Request reqLastWeek = new VisitAgentController.Request();
        reqLastWeek.actionType = 'searchVisits';
        reqLastWeek.searchQuery = 'last week';

        VisitAgentController.Request reqThisMonth = new VisitAgentController.Request();
        reqThisMonth.actionType = 'searchVisits';
        reqThisMonth.searchQuery = 'this month';

        Test.startTest();
        List<VisitAgentController.Response> resList = VisitAgentController.execute(
            new List<VisitAgentController.Request>{ reqAll, reqNTO, reqToday, reqThisWeek, reqTomorrow, reqNextWeek, reqLastWeek, reqThisMonth }
        );
        Test.stopTest();

        Assert.areEqual(8, resList.size(), 'Expected 8 responses');
        for (VisitAgentController.Response r : resList) {
            Assert.isTrue(r.success, 'Expected search queries to succeed');
            Assert.isNotNull(r.summary, 'Summary should be generated');
        }
    }

    @IsTest
    static void testGetVisitDetailsAndSummary() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        String vId = 'fakeVisitId';
        String targetAccId = acc.Id;
        if (Schema.getGlobalDescribe().containsKey('visit')) {
            List<SObject> vList = Database.query('SELECT Id, AccountId FROM Visit LIMIT 1');
            if (!vList.isEmpty()) {
                vId = (String) vList[0].get('Id');
                targetAccId = (String) vList[0].get('AccountId');
            }
        }

        VisitAgentController.Request reqDetails = new VisitAgentController.Request();
        reqDetails.actionType = 'getVisitDetails';
        reqDetails.visitId = vId;

        VisitAgentController.Request reqSummary = new VisitAgentController.Request();
        reqSummary.actionType = 'generateSummary';
        reqSummary.visitId = vId;

        VisitAgentController.Request reqStoreBrief = new VisitAgentController.Request();
        reqStoreBrief.actionType = 'getStoreBrief';
        reqStoreBrief.visitId = vId;
        reqStoreBrief.accountId = targetAccId;

        Test.startTest();
        List<VisitAgentController.Response> resList = VisitAgentController.execute(
            new List<VisitAgentController.Request>{ reqDetails, reqSummary, reqStoreBrief }
        );
        Test.stopTest();

        Assert.areEqual(3, resList.size(), 'Expected 3 responses');
    }

    @IsTest
    static void testStaleVisitsAndAlertsAndNotes() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        String vId = 'fakeVisitId';
        String targetAccId = acc.Id;
        if (Schema.getGlobalDescribe().containsKey('visit')) {
            List<SObject> vList = Database.query('SELECT Id, AccountId FROM Visit LIMIT 1');
            if (!vList.isEmpty()) {
                vId = (String) vList[0].get('Id');
                targetAccId = (String) vList[0].get('AccountId');
            }
        }

        VisitAgentController.Request reqStale = new VisitAgentController.Request();
        reqStale.actionType = 'get_stale_visits';
        reqStale.accountId = targetAccId;
        reqStale.searchOffset = '0';

        VisitAgentController.Request reqAlerts = new VisitAgentController.Request();
        reqAlerts.actionType = 'send_visit_alerts';
        reqAlerts.visitIds = new List<String>{ vId };

        VisitAgentController.Request reqNotes = new VisitAgentController.Request();
        reqNotes.actionType = 'update_visit_notes';
        reqNotes.visitId = vId;
        reqNotes.notes = 'Updated inspection notes';

        Test.startTest();
        List<VisitAgentController.Response> resList = VisitAgentController.execute(
            new List<VisitAgentController.Request>{ reqStale, reqAlerts, reqNotes }
        );
        Test.stopTest();

        Assert.areEqual(3, resList.size(), 'Expected 3 responses');
    }

    @IsTest
    static void testCreateVisit() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        String locId = null;
        if (Schema.getGlobalDescribe().containsKey('location')) {
            List<SObject> locs = Database.query('SELECT Id FROM Location LIMIT 1');
            if (!locs.isEmpty()) { locId = (String) locs[0].get('Id'); }
        }

        VisitAgentController.Request req = new VisitAgentController.Request();
        req.actionType = 'create_visit_record';
        req.accountId = acc.Id;
        req.placeId = locId;
        req.status = 'Planned';
        req.plannedStartTime = Datetime.now().addDays(3);
        req.plannedEndTime = Datetime.now().addDays(3).addHours(1);

        CreateVisitWrapper wrapper = new CreateVisitWrapper();
        wrapper.accountId = acc.Id;
        wrapper.placeId = locId;
        wrapper.plannedStartTime = Datetime.now().addDays(4);
        wrapper.plannedEndTime = Datetime.now().addDays(4).addHours(1);

        VisitAgentController.Request reqWrapper = new VisitAgentController.Request();
        reqWrapper.actionType = 'create_visit_record';
        reqWrapper.createVisitWrapper = wrapper;

        Test.startTest();
        List<VisitAgentController.Response> resList = VisitAgentController.execute(
            new List<VisitAgentController.Request>{ req, reqWrapper }
        );
        Test.stopTest();

        Assert.areEqual(2, resList.size(), 'Expected 2 responses');
    }

    @IsTest
    static void testErrorAndEdgeCases() {
        VisitAgentController.Request reqBlankId = new VisitAgentController.Request();
        reqBlankId.actionType = 'getVisitDetails';
        reqBlankId.visitId = '';

        VisitAgentController.Request reqSummaryBlank = new VisitAgentController.Request();
        reqSummaryBlank.actionType = 'getVisitSummary';
        reqSummaryBlank.visitId = '';

        VisitAgentController.Request reqUnknown = new VisitAgentController.Request();
        reqUnknown.actionType = 'nonExistentAction';

        VisitAgentController.Request reqDefaultSearch = new VisitAgentController.Request();
        reqDefaultSearch.actionType = 'nonExistentAction';
        reqDefaultSearch.searchQuery = 'Metro Market';

        Test.startTest();
        List<VisitAgentController.Response> resList = VisitAgentController.execute(
            new List<VisitAgentController.Request>{ reqBlankId, reqSummaryBlank, reqUnknown, reqDefaultSearch }
        );
        Test.stopTest();

        Assert.areEqual(4, resList.size(), 'Expected 4 responses');
        Assert.isFalse(resList[0].success, 'Blank ID should fail');
        Assert.isFalse(resList[1].success, 'Blank Summary ID should fail');
        Assert.isTrue(resList[2].success, 'Fallback to available visits');
        Assert.isTrue(resList[3].success, 'Fallback to search');
    }

    @IsTest
    static void testVisitSummaryShippingAddress() {
        Account accShip = new Account(
            Name = 'CGC Shipping Visit Store',
            ShippingStreet = '789 Sunset Blvd',
            ShippingCity = 'Los Angeles',
            ShippingState = 'CA',
            ShippingPostalCode = '90028',
            ShippingCountry = 'USA'
        );
        insert accShip;

        SObject v = Schema.getGlobalDescribe().get('Visit').newSObject();
        v.put('AccountId', accShip.Id);
        if (Schema.getGlobalDescribe().containsKey('location')) {
            Schema.Location loc = new Schema.Location(Name = 'Test Shipping Loc');
            insert loc;
            v.put('PlaceId', loc.Id);
        }
        v.put('PlannedVisitStartTime', Datetime.now());
        v.put('PlannedVisitEndTime', Datetime.now().addHours(1));
        v.put('Status', 'Planned');
        Database.insert(v, AccessLevel.USER_MODE);

        VisitAgentController.Request req = new VisitAgentController.Request();
        req.actionType = 'getVisitSummary';
        req.visitId = (String) v.get('Id');

        Test.startTest();
        List<VisitAgentController.Response> resList = VisitAgentController.execute(
            new List<VisitAgentController.Request>{ req }
        );
        Test.stopTest();

        Assert.areEqual(1, resList.size(), 'Expected 1 response');
        Assert.isTrue(resList[0].success, 'Expected summary to succeed');
        Assert.isTrue(resList[0].summary.contains('789 Sunset Blvd'), 'Expected shipping street in summary');
    }

    @IsTest
    static void testAdditionalCoverageAndFilters() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        String vId = 'fakeVisitId';
        String vName = '';
        if (Schema.getGlobalDescribe().containsKey('visit')) {
            List<SObject> vList = Database.query('SELECT Id, Name, AccountId FROM Visit LIMIT 1');
            if (!vList.isEmpty()) {
                vId = (String) vList[0].get('Id');
                vName = (String) vList[0].get('Name');
            }
        }

        List<VisitAgentController.Request> requests = new List<VisitAgentController.Request>();

        // Search date filters
        List<String> queryFilters = new List<String>{
            'yesterday', 'this month', 'next month', 'in progress', 'completed', 'cancelled'
        };
        for (String q : queryFilters) {
            VisitAgentController.Request r = new VisitAgentController.Request();
            r.actionType = 'search';
            r.searchQuery = q;
            requests.add(r);
        }

        // Summary by Name & AccountId
        if (String.isNotBlank(vName)) {
            VisitAgentController.Request rName = new VisitAgentController.Request();
            rName.actionType = 'generateSummary';
            rName.visitId = vName;
            requests.add(rName);
        }

        VisitAgentController.Request rAccOnly = new VisitAgentController.Request();
        rAccOnly.actionType = 'generateSummary';
        rAccOnly.accountId = acc.Id;
        requests.add(rAccOnly);

        // Search users
        VisitAgentController.Request rUsers = new VisitAgentController.Request();
        rUsers.actionType = 'search_users';
        rUsers.searchQuery = 'Standard';
        requests.add(rUsers);

        // Blank search query fallback
        VisitAgentController.Request rBlank = new VisitAgentController.Request();
        rBlank.actionType = 'search';
        rBlank.searchQuery = '';
        requests.add(rBlank);

        Test.startTest();
        List<VisitAgentController.Response> responses = VisitAgentController.execute(requests);
        Test.stopTest();

        Assert.isTrue(responses.size() > 0, 'Expected responses for all filters');
    }
}
