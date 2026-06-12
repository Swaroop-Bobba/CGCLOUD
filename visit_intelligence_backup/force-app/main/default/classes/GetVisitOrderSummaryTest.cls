@IsTest
private class GetVisitOrderSummaryTest {

    @IsTest
    static void testExecuteWithFakeVisitId() {
        // Test with a non-existent visit ID — should hit catch block or return fallback
        GetVisitOrderSummary.Request req = new GetVisitOrderSummary.Request();
        req.visitId = '001000000000000AAA'; // Fake ID

        List<GetVisitOrderSummary.Result> results = 
            GetVisitOrderSummary.execute(new List<GetVisitOrderSummary.Request>{ req });

        System.assertEquals(1, results.size(), 'Should return exactly one result');
        System.assertNotEquals(null, results[0].buyingInsight, 'Buying insight should not be null');
    }

    @IsTest
    static void testExecuteWithRealVisit() {
        // Create an Account, a RetailStore, and a Visit to test
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        RetailStore store = new RetailStore(Name = 'Test Store', AccountId = acc.Id);
        insert store;

        Visit vst = new Visit(
            AccountId = acc.Id,
            PlaceId = store.Id,
            Status = 'Planned',
            PlannedVisitStartTime = DateTime.now()
        );
        insert vst;

        GetVisitOrderSummary.Request req = new GetVisitOrderSummary.Request();
        req.visitId = vst.Id;

        List<GetVisitOrderSummary.Result> results = 
            GetVisitOrderSummary.execute(new List<GetVisitOrderSummary.Request>{ req });

        System.assertEquals(1, results.size(), 'Should return exactly one result');
        System.assertNotEquals(null, results[0].totalOrders, 'Total orders should not be null');
        System.assertNotEquals(null, results[0].totalSpend, 'Total spend should not be null');
        System.assertNotEquals(null, results[0].buyingInsight, 'Buying insight should not be null');
        System.assertNotEquals(null, results[0].phaseBreakdown, 'Phase breakdown should not be null');
        System.assertNotEquals(null, results[0].recentOrders, 'Recent orders should not be null');
    }

    @IsTest
    static void testMultipleRequests() {
        Account acc = new Account(Name = 'Test Account Bulk');
        insert acc;

        RetailStore store = new RetailStore(Name = 'Test Store Bulk', AccountId = acc.Id);
        insert store;

        Visit vst1 = new Visit(AccountId = acc.Id, PlaceId = store.Id, Status = 'Planned', PlannedVisitStartTime = DateTime.now());
        Visit vst2 = new Visit(AccountId = acc.Id, PlaceId = store.Id, Status = 'Planned', PlannedVisitStartTime = DateTime.now().addDays(1));
        insert new List<Visit>{ vst1, vst2 };

        GetVisitOrderSummary.Request req1 = new GetVisitOrderSummary.Request();
        req1.visitId = vst1.Id;

        GetVisitOrderSummary.Request req2 = new GetVisitOrderSummary.Request();
        req2.visitId = vst2.Id;

        List<GetVisitOrderSummary.Result> results = 
            GetVisitOrderSummary.execute(new List<GetVisitOrderSummary.Request>{ req1, req2 });

        System.assertEquals(2, results.size(), 'Should return two results');
    }
}
