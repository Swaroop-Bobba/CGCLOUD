@isTest
public class SearchVisitsForAgentTest {

    @isTest
    static void testExecuteWithNoData() {
        SearchVisitsForAgent.Request req = new SearchVisitsForAgent.Request();
        req.searchQuery = 'Test Non-Existent Store 123';
        List<SearchVisitsForAgent.Request> reqs = new List<SearchVisitsForAgent.Request>{req};
        
        Test.startTest();
        List<SearchVisitsForAgent.Result> results = SearchVisitsForAgent.execute(reqs);
        Test.stopTest();
        
        System.assertEquals(1, results.size());
        System.assertNotEquals(null, results[0].visits);
    }

    @isTest
    static void testExecuteWithEmptyQuery() {
        SearchVisitsForAgent.Request req = new SearchVisitsForAgent.Request();
        req.searchQuery = '';
        List<SearchVisitsForAgent.Request> reqs = new List<SearchVisitsForAgent.Request>{req};
        
        Test.startTest();
        List<SearchVisitsForAgent.Result> results = SearchVisitsForAgent.execute(reqs);
        Test.stopTest();
        
        System.assertEquals(1, results.size());
        System.assertEquals(0, results[0].visits.size());
    }

    @isTest
    static void testSearchByRetailStore() {
        // Create test Account
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        // Create test Retail Store
        RetailStore store = new RetailStore(
            Name = 'Reliance Fresh Bandra',
            AccountId = acc.Id
        );
        insert store;
        
        // Create test Visit linked to the Retail Store
        Visit v = new Visit(
            PlaceId = store.Id,
            AccountId = acc.Id,
            Status = 'Planned',
            PlannedVisitStartTime = Datetime.now()
        );
        insert v;

        SearchVisitsForAgent.Request req = new SearchVisitsForAgent.Request();
        req.searchQuery = 'Reliance Fresh Bandra';
        List<SearchVisitsForAgent.Request> reqs = new List<SearchVisitsForAgent.Request>{req};
        
        Test.startTest();
        List<SearchVisitsForAgent.Result> results = SearchVisitsForAgent.execute(reqs);
        Test.stopTest();
        
        System.assertEquals(1, results.size());
        System.assertNotEquals(0, results[0].visits.size());
    }

    @isTest
    static void testSearchByLocation() {
        // Create test Account
        Account acc = new Account(Name = 'Test Account 2');
        insert acc;
        
        // Create test Location
        Schema.Location loc = new Schema.Location(
            Name = 'Bandra Central Warehouse',
            LocationType = 'Warehouse'
        );
        insert loc;
        
        // Create test Visit linked to the Location
        Visit v = new Visit(
            PlaceId = loc.Id,
            AccountId = acc.Id,
            Status = 'Planned',
            PlannedVisitStartTime = Datetime.now()
        );
        insert v;

        SearchVisitsForAgent.Request req = new SearchVisitsForAgent.Request();
        req.searchQuery = 'Bandra Central';
        List<SearchVisitsForAgent.Request> reqs = new List<SearchVisitsForAgent.Request>{req};
        
        Test.startTest();
        List<SearchVisitsForAgent.Result> results = SearchVisitsForAgent.execute(reqs);
        Test.stopTest();
        
        System.assertEquals(1, results.size());
        System.assertNotEquals(0, results[0].visits.size());
    }
}