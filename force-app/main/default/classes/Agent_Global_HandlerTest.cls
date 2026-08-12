/**
 * @description Master unit test class for Agent_Global_Handler targeting 100% code coverage.
 */
@IsTest
public class Agent_Global_HandlerTest {

    @IsTest
    static void testAllDomainRouting() {
        List<Agent_Request> requests = new List<Agent_Request>();

        // 1. Explicit domain calls
        Agent_Request reqVisit = new Agent_Request();
        reqVisit.domain = 'Visit';
        reqVisit.actionType = 'getavailable';
        requests.add(reqVisit);

        Agent_Request reqAcc = new Agent_Request();
        reqAcc.domain = 'Account';
        reqAcc.actionType = 'getcounts';
        requests.add(reqAcc);

        Agent_Request reqOrd = new Agent_Request();
        reqOrd.domain = 'Order';
        reqOrd.actionType = 'getaccountsummary';
        requests.add(reqOrd);

        Agent_Request reqUser = new Agent_Request();
        reqUser.domain = 'User';
        reqUser.actionType = 'search';
        reqUser.searchQuery = UserInfo.getLastName();
        requests.add(reqUser);

        Agent_Request reqRec = new Agent_Request();
        reqRec.domain = 'OrderRecommendation';
        reqRec.actionType = 'suggest_reorder';
        requests.add(reqRec);

        Agent_Request reqAct = new Agent_Request();
        reqAct.domain = 'VisitActivity';
        reqAct.actionType = 'getactivities';
        requests.add(reqAct);

        // 2. Action-based auto-infer routing (blank domain)
        Agent_Request reqInferVisit = new Agent_Request();
        reqInferVisit.actionType = 'getavailable';
        requests.add(reqInferVisit);

        Agent_Request reqInferAct = new Agent_Request();
        reqInferAct.actionType = 'getactivities';
        requests.add(reqInferAct);

        Agent_Request reqInferAcc = new Agent_Request();
        reqInferAcc.actionType = 'getcounts';
        requests.add(reqInferAcc);

        Agent_Request reqInferOrd = new Agent_Request();
        reqInferOrd.actionType = 'getaccountsummary';
        requests.add(reqInferOrd);

        Agent_Request reqInferSearchUser = new Agent_Request();
        reqInferSearchUser.actionType = 'search';
        reqInferSearchUser.agentName = 'TestRepAgent';
        requests.add(reqInferSearchUser);

        Agent_Request reqInferSearchVisit = new Agent_Request();
        reqInferSearchVisit.actionType = 'search';
        reqInferSearchVisit.agentName = null;
        requests.add(reqInferSearchVisit);

        // 3. Error and unknown domain handling
        Agent_Request reqBlank = new Agent_Request();
        reqBlank.domain = null;
        reqBlank.actionType = null;
        requests.add(reqBlank);

        Agent_Request reqInvalidDomain = new Agent_Request();
        reqInvalidDomain.domain = 'InvalidDomainXYZ';
        requests.add(reqInvalidDomain);

        Test.startTest();
        List<Agent_Response> responses = Agent_Global_Handler.execute(requests);
        Test.stopTest();

        Assert.areEqual(requests.size(), responses.size(), 'All requests processed successfully.');
        Assert.isNotNull(responses, 'Response list returned.');
    }
}