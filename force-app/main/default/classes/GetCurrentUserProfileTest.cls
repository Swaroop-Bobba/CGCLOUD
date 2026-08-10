/**
 * @description Master unit test class for GetCurrentUserProfile service targeting 100% code coverage.
 */
@IsTest
public class GetCurrentUserProfileTest {

    @IsTest
    static void testExecuteGetCurrentUserProfilePositive() {
        GetCurrentUserProfile service = new GetCurrentUserProfile();
        Agent_Request req = new Agent_Request();

        Test.startTest();
        Agent_Response res = service.execute(req);
        Test.stopTest();

        Assert.isTrue(res.success, 'GetCurrentUserProfile should execute successfully.');
        Assert.isNotNull(res.profileName, 'Profile name should be populated.');
    }

    @IsTest
    static void testExecuteGetCurrentUserProfileNullHandling() {
        GetCurrentUserProfile service = new GetCurrentUserProfile();

        Test.startTest();
        Agent_Response res = service.execute(null);
        Test.stopTest();

        Assert.isTrue(res.success, 'GetCurrentUserProfile should handle null request.');
        Assert.isNotNull(res.profileName, 'Profile name should be populated.');
    }

    @IsTest
    static void testExecuteGetCurrentUserProfileExceptionCatch() {
        GetCurrentUserProfile.forceException = true;
        GetCurrentUserProfile service = new GetCurrentUserProfile();

        Test.startTest();
        Agent_Response res = service.execute(new Agent_Request());
        Test.stopTest();

        Assert.isFalse(res.success, 'GetCurrentUserProfile should handle exception.');
        Assert.isNotNull(res.message, 'Error message should be populated.');
        GetCurrentUserProfile.forceException = false;
    }
}