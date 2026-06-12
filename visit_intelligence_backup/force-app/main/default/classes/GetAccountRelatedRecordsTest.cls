@isTest(SeeAllData=true)
public class GetAccountRelatedRecordsTest {
    @isTest
    static void testGetAccountRelatedRecords() {
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

        // Run execute for different types
        List<GetAccountRelatedRecords.Request> reqs = new List<GetAccountRelatedRecords.Request>();
        
        GetAccountRelatedRecords.Request r1 = new GetAccountRelatedRecords.Request();
        r1.accountId = accId;
        r1.recordType = 'contacts';
        reqs.add(r1);

        GetAccountRelatedRecords.Request r2 = new GetAccountRelatedRecords.Request();
        r2.accountId = accId;
        r2.recordType = 'opportunities';
        reqs.add(r2);

        GetAccountRelatedRecords.Request r3 = new GetAccountRelatedRecords.Request();
        r3.accountId = accId;
        r3.recordType = 'cases';
        reqs.add(r3);

        GetAccountRelatedRecords.Request r4 = new GetAccountRelatedRecords.Request();
        r4.accountId = accId;
        r4.recordType = 'visits';
        reqs.add(r4);

        GetAccountRelatedRecords.Request r5 = new GetAccountRelatedRecords.Request();
        r5.accountId = accId;
        r5.recordType = 'promotions';
        reqs.add(r5);

        GetAccountRelatedRecords.Request r6 = new GetAccountRelatedRecords.Request();
        r6.accountId = accId;
        r6.recordType = 'surveys';
        reqs.add(r6);

        GetAccountRelatedRecords.Request r7 = new GetAccountRelatedRecords.Request();
        r7.accountId = accId;
        r7.recordType = 'inventory';
        reqs.add(r7);

        GetAccountRelatedRecords.Request r8 = new GetAccountRelatedRecords.Request();
        r8.accountId = accId;
        r8.recordType = 'outofstock';
        reqs.add(r8);

        GetAccountRelatedRecords.Request r9 = new GetAccountRelatedRecords.Request();
        r9.accountId = accId;
        r9.recordType = 'retailstores';
        reqs.add(r9);

        GetAccountRelatedRecords.Request r10 = new GetAccountRelatedRecords.Request();
        r10.accountId = accId;
        r10.recordType = 'assortments';
        reqs.add(r10);

        GetAccountRelatedRecords.Request r11 = new GetAccountRelatedRecords.Request();
        r11.accountId = accId;
        r11.recordType = 'storeproducts';
        reqs.add(r11);

        GetAccountRelatedRecords.Request r12 = new GetAccountRelatedRecords.Request();
        r12.accountId = accId;
        r12.recordType = 'tactics';
        reqs.add(r12);

        GetAccountRelatedRecords.Request r13 = new GetAccountRelatedRecords.Request();
        r13.accountId = accId;
        r13.recordType = 'assortmentproducts';
        reqs.add(r13);

        Test.startTest();
        List<GetAccountRelatedRecords.Result> results = GetAccountRelatedRecords.execute(reqs);
        Test.stopTest();

        System.assertEquals(13, results.size(), 'Should return results for all 13 requests');
        for (GetAccountRelatedRecords.Result res : results) {
            System.assertNotEquals(null, res.records, 'Records list should not be null');
            System.assert(res.records.size() > 0, 'Records list should contain elements');
        }
    }
}
