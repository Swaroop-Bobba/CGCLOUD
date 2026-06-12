@isTest(SeeAllData=true)
public class SearchVisitsTest {
    @isTest
    static void testSearchVisits() {
        SearchVisits.Request req = new SearchVisits.Request();
        req.searchQuery = 'ABC';
        List<SearchVisits.Request> reqs = new List<SearchVisits.Request>{req};
        
        Test.startTest();
        List<SearchVisits.Result> results = SearchVisits.execute(reqs);
        
        // Test empty query case
        SearchVisits.Request reqEmpty = new SearchVisits.Request();
        reqEmpty.searchQuery = '';
        List<SearchVisits.Result> resultsEmpty = SearchVisits.execute(new List<SearchVisits.Request>{reqEmpty});
        Test.stopTest();
        
        System.assertEquals(1, results.size(), 'Should return exactly 1 result');
        System.assertNotEquals(null, results[0].visits, 'Visits list should not be null');
        System.assertEquals(1, resultsEmpty.size(), 'Should handle empty search queries gracefully');
    }
}
