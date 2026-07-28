/**
 * @description Test class for ExecuteSOQLQuery.
 */
@IsTest
public class ExecuteSOQLQueryTest {

    @IsTest
    static void testExecuteValidQuery() {
        // Create standard account mock data
        Account acc = new Account(Name = 'Test Execute SOQL Query Account');
        insert as user acc;

        Test.startTest();
        ExecuteSOQLQuery.QueryRequest req = new ExecuteSOQLQuery.QueryRequest();
        req.query = 'SELECT Id, Name FROM Account WHERE Name = \'Test Execute SOQL Query Account\'';
        List<ExecuteSOQLQuery.QueryResponse> responses = ExecuteSOQLQuery.execute(new List<ExecuteSOQLQuery.QueryRequest>{ req });
        Test.stopTest();

        Assert.isNotNull(responses, 'Response list should not be null.');
        Assert.areEqual(1, responses.size(), 'Response list size should be 1.');
        Assert.isTrue(responses[0].success, 'Success flag should be true.');
        Assert.isNotNull(responses[0].recordsJson, 'Serialized records JSON should not be null.');
        Assert.isNull(responses[0].errorMessage, 'Error message should be null.');
    }

    @IsTest
    static void testExecuteEmptyQuery() {
        Test.startTest();
        ExecuteSOQLQuery.QueryRequest req = new ExecuteSOQLQuery.QueryRequest();
        req.query = '';
        List<ExecuteSOQLQuery.QueryResponse> responses = ExecuteSOQLQuery.execute(new List<ExecuteSOQLQuery.QueryRequest>{ req });
        Test.stopTest();

        Assert.isNotNull(responses, 'Response list should not be null.');
        Assert.areEqual(1, responses.size(), 'Response list size should be 1.');
        Assert.isFalse(responses[0].success, 'Success flag should be false.');
        Assert.areEqual('Query string cannot be empty.', responses[0].errorMessage, 'Error message matches empty query validation.');
    }

    @IsTest
    static void testExecuteInvalidQuery() {
        Test.startTest();
        ExecuteSOQLQuery.QueryRequest req = new ExecuteSOQLQuery.QueryRequest();
        req.query = 'SELECT InvalidField__c FROM Account';
        List<ExecuteSOQLQuery.QueryResponse> responses = ExecuteSOQLQuery.execute(new List<ExecuteSOQLQuery.QueryRequest>{ req });
        Test.stopTest();

        Assert.isNotNull(responses, 'Response list should not be null.');
        Assert.areEqual(1, responses.size(), 'Response list size should be 1.');
        Assert.isFalse(responses[0].success, 'Success flag should be false.');
        Assert.isNotNull(responses[0].errorMessage, 'Error message should be populated.');
    }
}
