@isTest(SeeAllData=true)
public class GetAvailableVisitsTest {
    @isTest
    static void testGetAvailableVisits() {
        GetAvailableVisits.Request req = new GetAvailableVisits.Request();
        List<GetAvailableVisits.Request> reqs = new List<GetAvailableVisits.Request>{req};
        
        Test.startTest();
        List<GetAvailableVisits.Result> results = GetAvailableVisits.execute(reqs);
        Test.stopTest();
        
        System.assertEquals(1, results.size(), 'Should return exactly 1 result');
        System.assertNotEquals(null, results[0].visits, 'Visits list should not be null');
    }
}