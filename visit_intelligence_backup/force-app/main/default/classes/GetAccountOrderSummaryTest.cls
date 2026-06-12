@IsTest
private class GetAccountOrderSummaryTest {

    @IsTest
    static void testExecuteWithNoAccount() {
        // Test with a non-existent account ID — should fall into try/catch
        GetAccountOrderSummary.Request req = new GetAccountOrderSummary.Request();
        req.accountId = '001000000000000AAA'; // Fake ID

        List<GetAccountOrderSummary.Result> results = 
            GetAccountOrderSummary.execute(new List<GetAccountOrderSummary.Request>{ req });

        System.assertEquals(1, results.size(), 'Should return exactly one result');
        // The result should either have 0 orders (if cgcloud package exists) 
        // or fallback message (if package not installed)
        System.assertNotEquals(null, results[0].buyingInsight, 'Buying insight should not be null');
    }

    @IsTest
    static void testExecuteWithRealAccount() {
        // Create a real Account to test the flow
        Account acc = new Account(Name = 'Test Order Account');
        insert acc;

        GetAccountOrderSummary.Request req = new GetAccountOrderSummary.Request();
        req.accountId = acc.Id;

        List<GetAccountOrderSummary.Result> results = 
            GetAccountOrderSummary.execute(new List<GetAccountOrderSummary.Request>{ req });

        System.assertEquals(1, results.size(), 'Should return exactly one result');
        System.assertNotEquals(null, results[0].totalOrders, 'Total orders should not be null');
        System.assertNotEquals(null, results[0].totalSpend, 'Total spend should not be null');
        System.assertNotEquals(null, results[0].buyingInsight, 'Buying insight should not be null');
        System.assertNotEquals(null, results[0].phaseBreakdown, 'Phase breakdown should not be null');
        System.assertNotEquals(null, results[0].recentOrders, 'Recent orders should not be null');
    }

    @IsTest
    static void testMultipleRequests() {
        Account acc1 = new Account(Name = 'Test Account A');
        Account acc2 = new Account(Name = 'Test Account B');
        insert new List<Account>{ acc1, acc2 };

        GetAccountOrderSummary.Request req1 = new GetAccountOrderSummary.Request();
        req1.accountId = acc1.Id;

        GetAccountOrderSummary.Request req2 = new GetAccountOrderSummary.Request();
        req2.accountId = acc2.Id;

        List<GetAccountOrderSummary.Result> results = 
            GetAccountOrderSummary.execute(new List<GetAccountOrderSummary.Request>{ req1, req2 });

        System.assertEquals(2, results.size(), 'Should return two results for two requests');
    }
}
