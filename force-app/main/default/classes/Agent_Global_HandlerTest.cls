/**
 * @description Test class for Agent_Global_Handler.
 */
@IsTest
public class Agent_Global_HandlerTest {

    @IsTest
    static void testGlobalHandlerRouting() {
        Test.startTest();
        // 1. Valid request to GetCurrentUserProfile
        Agent_Request reqUser = new Agent_Request();
        reqUser.domain = 'User';
        reqUser.actionType = 'search';
        reqUser.searchQuery = 'test';
        
        List<Agent_Response> responsesUser = Agent_Global_Handler.execute(new List<Agent_Request>{ reqUser });
        
        // 2. Request with blank domain that should auto-resolve to Visit domain
        Agent_Request reqAutoVisit = new Agent_Request();
        reqAutoVisit.actionType = 'getavailable';
        
        List<Agent_Response> responsesAutoVisit = Agent_Global_Handler.execute(new List<Agent_Request>{ reqAutoVisit });

        // 3. Request with unknown domain to test exception handling
        Agent_Request reqUnknown = new Agent_Request();
        reqUnknown.domain = 'InvalidDomainTest';
        reqUnknown.actionType = 'someAction';
        
        List<Agent_Response> responsesUnknown = Agent_Global_Handler.execute(new List<Agent_Request>{ reqUnknown });
        
        // 4. Request with empty domain and action to test failure
        Agent_Request reqEmpty = new Agent_Request();
        List<Agent_Response> responsesEmpty = Agent_Global_Handler.execute(new List<Agent_Request>{ reqEmpty });
        Test.stopTest();

        Assert.isNotNull(responsesUser, 'User domain responses should not be null.');
        Assert.isTrue(responsesUser[0].success, 'User profile action should succeed.');
        Assert.isNotNull(responsesUser[0].users, 'Users list should be returned.');

        Assert.isNotNull(responsesAutoVisit, 'Auto-resolved domain responses should not be null.');
        Assert.isTrue(responsesAutoVisit[0].success, 'Auto-resolved action should succeed.');

        Assert.isNotNull(responsesUnknown, 'Unknown domain responses should not be null.');
        Assert.isFalse(responsesUnknown[0].success, 'Unknown domain routing should fail.');
        Assert.isTrue(responsesUnknown[0].message.contains('Unknown domain service'), 'Message matches domain resolution failure.');

        Assert.isNotNull(responsesEmpty, 'Empty request responses should not be null.');
        Assert.isFalse(responsesEmpty[0].success, 'Empty request should fail.');
        Assert.areEqual('Domain parameter is required.', responsesEmpty[0].message, 'ErrorMessage matches parameter requirements.');
    }
}
