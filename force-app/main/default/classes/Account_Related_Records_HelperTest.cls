/**
 * @description Unit test class for Account_Related_Records_Helper covering record retrieval for all child record types across real, fake, and null account IDs.
 */
@IsTest(SeeAllData=true)
public class Account_Related_Records_HelperTest {

    /**
     * @description Tests getRelatedRecords for all supported record types with real and fake accounts.
     */
    @IsTest
    static void testGetRelatedRecordsAllTypes() {
        List<Account> realAccs = [SELECT Id FROM Account LIMIT 1];
        Id accId = !realAccs.isEmpty() ? realAccs[0].Id : null;
        String fakeAccId = '001000000000001AAA';

        List<String> recordTypes = new List<String>{
            'contacts',
            'opportunities',
            'cases',
            'visits',
            'promotions',
            'surveys',
            'inventory',
            'outofstock',
            'retailstores',
            'assortments',
            'storeproducts',
            'assortmentproducts',
            'assortment_products',
            'tactics',
            'invalid_type'
        };

        Test.startTest();
        for (String rType : recordTypes) {
            // Real account query
            List<Agent_Response.RecordInfo> realRecs = Account_Related_Records_Helper.getRelatedRecords(accId, rType);
            Assert.isNotNull(realRecs, 'Real account record retrieval should return a non-null list for type: ' + rType);

            // Fake account query (triggers mock/fallback lists)
            List<Agent_Response.RecordInfo> fakeRecs = Account_Related_Records_Helper.getRelatedRecords(fakeAccId, rType);
            Assert.isNotNull(fakeRecs, 'Fake account record retrieval should return a non-null list for type: ' + rType);
        }

        // Null and blank parameter tests
        List<Agent_Response.RecordInfo> nullRecs = Account_Related_Records_Helper.getRelatedRecords(null, 'contacts');
        Assert.areEqual(0, nullRecs.size(), 'Null account ID should return an empty list.');

        List<Agent_Response.RecordInfo> blankRecs = Account_Related_Records_Helper.getRelatedRecords('', 'contacts');
        Assert.areEqual(0, blankRecs.size(), 'Blank account ID should return an empty list.');

        List<Agent_Response.RecordInfo> nullTypeRecs = Account_Related_Records_Helper.getRelatedRecords(fakeAccId, null);
        Assert.isNotNull(nullTypeRecs, 'Null record type should execute cleanly.');
        Test.stopTest();
    }

    /**
     * @description Tests getRelatedRecords with programmatically seeded records graph to cover custom queries and loop iterations.
     */
    @IsTest
    static void testGetRelatedRecordsWithSeededData() {
        Account acc = new Account(
            Name = 'Seeded Helper Test Account',
            Industry = 'Retail',
            Phone = '555-4321',
            cgcloud__Account_Email__c = 'helper@example.com',
            ShippingStreet = '456 Market St',
            ShippingCity = 'San Francisco',
            ShippingState = 'CA',
            ShippingPostalCode = '94105',
            ShippingCountry = 'USA'
        );
        insert acc;

        Contact con = new Contact(FirstName = 'Jane', LastName = 'Smith', AccountId = acc.Id, Phone = '555-5678', Email = 'jane@example.com');
        insert con;

        Opportunity opp = new Opportunity(Name = 'Helper Opp', AccountId = acc.Id, StageName = 'Prospecting', CloseDate = System.today().addDays(15));
        insert opp;

        Case cs = new Case(Subject = 'Helper Case', AccountId = acc.Id, Status = 'New');
        insert cs;

        Schema.Location loc = new Schema.Location(Name = 'Helper Location');
        insert loc;

        Visit vis = new Visit(AccountId = acc.Id, PlaceId = loc.Id, Status = 'Planned', PlannedVisitStartTime = System.now(), cgcloud__OOS_Issues__c = true);
        insert vis;

        RetailStore rs = new RetailStore(Name = 'Helper Store', AccountId = acc.Id);
        insert rs;

        Assortment ass = new Assortment(Name = 'Helper Assortment');
        insert ass;

        StoreAssortment sa = new StoreAssortment(AccountId = acc.Id, AssortmentId = ass.Id, StartDate = System.today());
        insert sa;

        List<String> recordTypes = new List<String>{
            'contacts', 'opportunities', 'cases', 'visits', 'promotions',
            'surveys', 'inventory', 'outofstock', 'retailstores', 'assortments',
            'storeproducts', 'assortmentproducts', 'assortment_products', 'tactics'
        };

        Test.startTest();
        for (String rType : recordTypes) {
            List<Agent_Response.RecordInfo> recs = Account_Related_Records_Helper.getRelatedRecords(acc.Id, rType);
            Assert.isNotNull(recs, 'Seeded record query should return non-null list for type: ' + rType);
        }
        Test.stopTest();
    }
}