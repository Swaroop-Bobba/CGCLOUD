@IsTest
private class GetNextStepsOptionsTest {
    @IsTest
    static void testExecute() {
        GetNextStepsOptions.Request req1 = new GetNextStepsOptions.Request();
        req1.excludeOption = null;
        
        GetNextStepsOptions.Request req2 = new GetNextStepsOptions.Request();
        req2.excludeOption = 'View today\'s activities or surveys';
        
        List<GetNextStepsOptions.Request> requests = new List<GetNextStepsOptions.Request>{req1, req2};
        
        Test.startTest();
        List<GetNextStepsOptions.Result> results = GetNextStepsOptions.execute(requests);
        Test.stopTest();
        
        System.assertEquals(2, results.size(), 'Expected two results.');
        
        // Check result 1 (no exclusion)
        System.assertEquals(4, results[0].itemDetails.size(), 'Expected 4 next step options.');
        System.assertEquals('View today\'s activities or surveys', results[0].itemDetails[0].itemName, 'Mismatch in first option label.');
        
        // Check result 2 (with exclusion)
        System.assertEquals(3, results[1].itemDetails.size(), 'Expected 3 next step options after exclusion.');
        for (GetNextStepsOptions.ItemDetail opt : results[1].itemDetails) {
            System.assertNotEquals('View today\'s activities or surveys', opt.itemName, 'Excluded option was found in list.');
        }
    }
}
