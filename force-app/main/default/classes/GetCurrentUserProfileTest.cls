@IsTest
public class GetCurrentUserProfileTest {
    @IsTest
    static void testGetProfileName() {
        User contextUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(contextUser) {
            Test.startTest();
            GetCurrentUserProfile service = new GetCurrentUserProfile();
            Agent_Request req = new Agent_Request();
            Agent_Response res = service.execute(req);
            Test.stopTest();
    
            Assert.isNotNull(res, 'Response should not be null.');
            Assert.isTrue(res.success, 'Success should be true.');
            Assert.areNotEqual('Unknown', res.profileName, 'Profile name should be retrieved.');
            Assert.isNotNull(res.profileName, 'Profile name should not be null.');
        }
    }
}
