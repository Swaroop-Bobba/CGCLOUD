/**
 * Unit tests verifying user profile and context retrieval in UserContextController.
 */
@IsTest
private class UserContextControllerTest {

    @IsTest
    static void testGetCurrentUserProfile() {
        UserContextController.Request req = new UserContextController.Request();
        req.domain = 'User';
        req.actionType = 'getProfile';

        Test.startTest();
        List<UserContextController.Response> resList = UserContextController.execute(
            new List<UserContextController.Request>{ req }
        );
        Test.stopTest();

        Assert.isNotNull(resList, 'Response list should not be null');
        Assert.areEqual(1, resList.size(), 'Expected 1 response');
        Assert.isNotNull(resList[0].profileName, 'Profile name should not be null');
    }

    @IsTest
    static void testConstructors() {
        UserContextController instance = new UserContextController();
        UserContextController.Request req = new UserContextController.Request();
        UserContextController.Response res = new UserContextController.Response();

        Assert.isNotNull(instance, 'Instance should not be null');
        Assert.isNotNull(req, 'Request should not be null');
        Assert.isNotNull(res, 'Response should not be null');
    }
}