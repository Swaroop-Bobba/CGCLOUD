@IsTest
private class GetCurrentUserProfileTest {

    @IsTest
    static void testGetCurrentUserProfile() {
        GetCurrentUserProfile.Request req = new GetCurrentUserProfile.Request();
        req.domain = 'User';
        req.actionType = 'getProfile';

        Test.startTest();
        List<GetCurrentUserProfile.Response> resList = GetCurrentUserProfile.execute(
            new List<GetCurrentUserProfile.Request>{ req }
        );
        Test.stopTest();

        Assert.isNotNull(resList, 'Response list should not be null');
        Assert.areEqual(1, resList.size(), 'Expected 1 response');
        Assert.isNotNull(resList[0].profileName, 'Profile name should not be null');
    }

    @IsTest
    static void testConstructors() {
        GetCurrentUserProfile instance = new GetCurrentUserProfile();
        GetCurrentUserProfile.Request req = new GetCurrentUserProfile.Request();
        GetCurrentUserProfile.Response res = new GetCurrentUserProfile.Response();

        Assert.isNotNull(instance, 'Instance should not be null');
        Assert.isNotNull(req, 'Request should not be null');
        Assert.isNotNull(res, 'Response should not be null');
    }
}