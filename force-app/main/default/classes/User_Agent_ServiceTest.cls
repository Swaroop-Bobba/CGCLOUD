/**
 * @description Test class for User_Agent_Service.
 */
@IsTest
public class User_Agent_ServiceTest {

    @IsTest
    static void testExecuteActionRouting() {
        User_Agent_Service service = new User_Agent_Service();

        Test.startTest();
        // 1. Valid user search
        Agent_Request req = new Agent_Request();
        req.actionType = 'search';
        req.searchQuery = UserInfo.getName().substring(0, Math.min(5, UserInfo.getName().length()));
        Agent_Response res = service.execute(req);

        // 2. Empty search
        List<Agent_Response.UserOption> optionsEmpty = User_Agent_Service.searchUsers('');

        // 3. Invalid action
        Agent_Request reqInvalid = new Agent_Request();
        reqInvalid.actionType = 'invalid_action';
        Agent_Response resInvalid = service.execute(reqInvalid);
        Test.stopTest();

        Assert.isTrue(res.success, 'Search action routing should succeed.');
        Assert.isNotNull(res.users, 'Users list should be returned.');
        Assert.isFalse(res.users.isEmpty(), 'CurrentUser should be retrieved by search.');

        Assert.isTrue(optionsEmpty.isEmpty(), 'Empty search returns empty list.');

        Assert.isFalse(resInvalid.success, 'Invalid action should fail.');
        Assert.isTrue(resInvalid.message.contains('Unknown actionType'), 'Correct error message.');
    }
}
