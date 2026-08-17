@IsTest
private class Visit_Agent_HandlerTest {

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
        Visit_Agent_Handler.Request req = new Visit_Agent_Handler.Request();
        req.actionType = 'getAvailable';

        Test.startTest();
        List<Visit_Agent_Handler.Response> resList = Visit_Agent_Handler.execute(
            new List<Visit_Agent_Handler.Request>{ req }
        );
        Test.stopTest();

        Assert.areEqual(1, resList.size(), 'Expected 1 response');
        Assert.isTrue(resList[0].success, 'Expected getAvailable to succeed');
        Assert.isNotNull(resList[0].summary, 'Summary should not be null');
    }

    @IsTest
    static void testSearchVisits() {
        Visit_Agent_Handler.Request reqAll = new Visit_Agent_Handler.Request();
        reqAll.actionType = 'search';
        reqAll.searchQuery = 'all';
        reqAll.searchOffset = '0';

        Visit_Agent_Handler.Request reqNTO = new Visit_Agent_Handler.Request();
        reqNTO.actionType = 'search';
        reqNTO.searchQuery = '*NTO Store #201';
        reqNTO.searchOffset = '0';

        Visit_Agent_Handler.Request reqToday = new Visit_Agent_Handler.Request();
        reqToday.actionType = 'searchVisits';
        reqToday.searchQuery = 'today planned';

        Visit_Agent_Handler.Request reqThisWeek = new Visit_Agent_Handler.Request();
        reqThisWeek.actionType = 'searchVisits';
        reqThisWeek.searchQuery = 'this week in progress';

        Visit_Agent_Handler.Request reqTomorrow = new Visit_Agent_Handler.Request();
        reqTomorrow.actionType = 'searchVisits';
        reqTomorrow.searchQuery = 'tomorrow completed';

        Visit_Agent_Handler.Request reqNextWeek = new Visit_Agent_Handler.Request();
        reqNextWeek.actionType = 'searchVisits';
        reqNextWeek.searchQuery = 'next week';

        Visit_Agent_Handler.Request reqLastWeek = new Visit_Agent_Handler.Request();
        reqLastWeek.actionType = 'searchVisits';
        reqLastWeek.searchQuery = 'last week';

        Visit_Agent_Handler.Request reqThisMonth = new Visit_Agent_Handler.Request();
        reqThisMonth.actionType = 'searchVisits';
        reqThisMonth.searchQuery = 'this month';

        Test.startTest();
        List<Visit_Agent_Handler.Response> resList = Visit_Agent_Handler.execute(
            new List<Visit_Agent_Handler.Request>{ reqAll, reqNTO, reqToday, reqThisWeek, reqTomorrow, reqNextWeek, reqLastWeek, reqThisMonth }
        );
        Test.stopTest();

        Assert.areEqual(8, resList.size(), 'Expected 8 responses');
        for (Visit_Agent_Handler.Response r : resList) {
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

        Visit_Agent_Handler.Request reqDetails = new Visit_Agent_Handler.Request();
        reqDetails.actionType = 'getVisitDetails';
        reqDetails.visitId = vId;

        Visit_Agent_Handler.Request reqSummary = new Visit_Agent_Handler.Request();
        reqSummary.actionType = 'generateSummary';
        reqSummary.visitId = vId;

        Visit_Agent_Handler.Request reqStoreBrief = new Visit_Agent_Handler.Request();
        reqStoreBrief.actionType = 'getStoreBrief';
        reqStoreBrief.visitId = vId;
        reqStoreBrief.accountId = targetAccId;

        Test.startTest();
        List<Visit_Agent_Handler.Response> resList = Visit_Agent_Handler.execute(
            new List<Visit_Agent_Handler.Request>{ reqDetails, reqSummary, reqStoreBrief }
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

        Visit_Agent_Handler.Request reqStale = new Visit_Agent_Handler.Request();
        reqStale.actionType = 'get_stale_visits';
        reqStale.accountId = targetAccId;
        reqStale.searchOffset = '0';

        Visit_Agent_Handler.Request reqAlerts = new Visit_Agent_Handler.Request();
        reqAlerts.actionType = 'send_visit_alerts';
        reqAlerts.visitIds = new List<String>{ vId };

        Visit_Agent_Handler.Request reqNotes = new Visit_Agent_Handler.Request();
        reqNotes.actionType = 'update_visit_notes';
        reqNotes.visitId = vId;
        reqNotes.notes = 'Updated inspection notes';

        Test.startTest();
        List<Visit_Agent_Handler.Response> resList = Visit_Agent_Handler.execute(
            new List<Visit_Agent_Handler.Request>{ reqStale, reqAlerts, reqNotes }
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

        Visit_Agent_Handler.Request req = new Visit_Agent_Handler.Request();
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

        Visit_Agent_Handler.Request reqWrapper = new Visit_Agent_Handler.Request();
        reqWrapper.actionType = 'create_visit_record';
        reqWrapper.createVisitWrapper = wrapper;

        Test.startTest();
        List<Visit_Agent_Handler.Response> resList = Visit_Agent_Handler.execute(
            new List<Visit_Agent_Handler.Request>{ req, reqWrapper }
        );
        Test.stopTest();

        Assert.areEqual(2, resList.size(), 'Expected 2 responses');
    }

    @IsTest
    static void testErrorAndEdgeCases() {
        Visit_Agent_Handler.Request reqBlankId = new Visit_Agent_Handler.Request();
        reqBlankId.actionType = 'getVisitDetails';
        reqBlankId.visitId = '';

        Visit_Agent_Handler.Request reqSummaryBlank = new Visit_Agent_Handler.Request();
        reqSummaryBlank.actionType = 'getVisitSummary';
        reqSummaryBlank.visitId = '';

        Visit_Agent_Handler.Request reqUnknown = new Visit_Agent_Handler.Request();
        reqUnknown.actionType = 'nonExistentAction';

        Visit_Agent_Handler.Request reqDefaultSearch = new Visit_Agent_Handler.Request();
        reqDefaultSearch.actionType = 'nonExistentAction';
        reqDefaultSearch.searchQuery = 'Metro Market';

        Test.startTest();
        List<Visit_Agent_Handler.Response> resList = Visit_Agent_Handler.execute(
            new List<Visit_Agent_Handler.Request>{ reqBlankId, reqSummaryBlank, reqUnknown, reqDefaultSearch }
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

        Visit_Agent_Handler.Request req = new Visit_Agent_Handler.Request();
        req.actionType = 'getVisitSummary';
        req.visitId = (String) v.get('Id');

        Test.startTest();
        List<Visit_Agent_Handler.Response> resList = Visit_Agent_Handler.execute(
            new List<Visit_Agent_Handler.Request>{ req }
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

        List<Visit_Agent_Handler.Request> requests = new List<Visit_Agent_Handler.Request>();

        // Search date filters
        List<String> queryFilters = new List<String>{
            'yesterday', 'this month', 'next month', 'in progress', 'completed', 'cancelled'
        };
        for (String q : queryFilters) {
            Visit_Agent_Handler.Request r = new Visit_Agent_Handler.Request();
            r.actionType = 'search';
            r.searchQuery = q;
            requests.add(r);
        }

        // Summary by Name & AccountId
        if (String.isNotBlank(vName)) {
            Visit_Agent_Handler.Request rName = new Visit_Agent_Handler.Request();
            rName.actionType = 'generateSummary';
            rName.visitId = vName;
            requests.add(rName);
        }

        Visit_Agent_Handler.Request rAccOnly = new Visit_Agent_Handler.Request();
        rAccOnly.actionType = 'generateSummary';
        rAccOnly.accountId = acc.Id;
        requests.add(rAccOnly);

        // Search users
        Visit_Agent_Handler.Request rUsers = new Visit_Agent_Handler.Request();
        rUsers.actionType = 'search_users';
        rUsers.searchQuery = 'Standard';
        requests.add(rUsers);

        // Blank search query fallback
        Visit_Agent_Handler.Request rBlank = new Visit_Agent_Handler.Request();
        rBlank.actionType = 'search';
        rBlank.searchQuery = '';
        requests.add(rBlank);

        Test.startTest();
        List<Visit_Agent_Handler.Response> responses = Visit_Agent_Handler.execute(requests);
        Test.stopTest();

        Assert.isTrue(responses.size() > 0, 'Expected responses for all filters');
    }
}
