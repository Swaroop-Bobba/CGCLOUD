/**
 * @description Master unit test class for User_Agent_Service targeting 100% code coverage.
 */
@IsTest
public class User_Agent_ServiceTest {

    @IsTest
    static void testExecuteSearchPositive() {
        User_Agent_Service service = new User_Agent_Service();
        Agent_Request req = new Agent_Request();
        req.actionType = 'search';
        req.searchQuery = UserInfo.getLastName();

        Test.startTest();
        Agent_Response res = service.execute(req);
        Test.stopTest();

        Assert.isTrue(res.success, 'User search should execute successfully.');
        Assert.isNotNull(res.users, 'Users list should not be null.');
    }

    @IsTest
    static void testExecuteUnknownAction() {
        User_Agent_Service service = new User_Agent_Service();
        Agent_Request req = new Agent_Request();
        req.actionType = 'invalid';

        Test.startTest();
        Agent_Response res = service.execute(req);
        Agent_Response resNull = service.execute(null);
        Test.stopTest();

        Assert.isFalse(res.success, 'Unknown action should return success = false.');
        Assert.isFalse(resNull.success, 'Null request should return success = false.');
    }

    @IsTest
    static void testSearchUsersNullAndBlank() {
        Test.startTest();
        List<Agent_Response.UserOption> optNull = User_Agent_Service.searchUsers(null);
        List<Agent_Response.UserOption> optBlank = User_Agent_Service.searchUsers('');
        Test.stopTest();

        Assert.isTrue(optNull.isEmpty(), 'Null search returns empty list.');
        Assert.isTrue(optBlank.isEmpty(), 'Blank search returns empty list.');
    }

    @IsTest
    static void testExecuteExceptions() {
        User_Agent_Service.forceException = true;
        User_Agent_Service service = new User_Agent_Service();

        Test.startTest();
        Agent_Response res = service.execute(new Agent_Request());
        List<Agent_Response.UserOption> opts = User_Agent_Service.searchUsers('test');
        Test.stopTest();

        Assert.isFalse(res.success, 'Exception caught.');
        User_Agent_Service.forceException = false;
    }
}