@isTest(SeeAllData=true)
public class GetAccountRelatedCountsTest {
    @isTest
    static void testGetAccountRelatedCounts() {
        // Query an existing Visit with an Account
        List<Visit> visits = [SELECT Id, AccountId FROM Visit WHERE AccountId != null LIMIT 1];
        Id accId;
        if (!visits.isEmpty()) {
            accId = visits[0].AccountId;
        } else {
            // Fallback: create Account
            Account acc = new Account(Name = 'Test Account');
            insert acc;
            accId = acc.Id;
        }

        List<GetAccountRelatedCounts.Request> reqs = new List<GetAccountRelatedCounts.Request>();
        GetAccountRelatedCounts.Request req = new GetAccountRelatedCounts.Request();
        req.accountId = accId;
        reqs.add(req);

        Test.startTest();
        List<GetAccountRelatedCounts.Result> results = GetAccountRelatedCounts.execute(reqs);
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return results for the request');
        GetAccountRelatedCounts.Result res = results[0];
        System.assertNotEquals(null, res.totalContacts, 'totalContacts should be populated');
        System.assertNotEquals(null, res.totalRetailStores, 'totalRetailStores should be populated');
        System.assertNotEquals(null, res.totalTactics, 'totalTactics should be populated');
        System.assertNotEquals(null, res.totalAssortmentProducts, 'totalAssortmentProducts should be populated');
    }
}
