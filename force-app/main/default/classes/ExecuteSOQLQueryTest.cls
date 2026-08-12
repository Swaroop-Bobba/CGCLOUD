/**
 * @description Unit test class for ExecuteSOQLQuery invocable action.
 */
@IsTest
public class ExecuteSOQLQueryTest {

    @IsTest
    static void testExecuteValidQuery() {
        Account acc = new Account(Name = 'SOQL Test Account');
        insert as user acc;

        ExecuteSOQLQuery.QueryRequest req = new ExecuteSOQLQuery.QueryRequest();
        req.query = 'SELECT Id, Name FROM Account WHERE Id = \'' + acc.Id + '\'';

        Test.startTest();
        List<ExecuteSOQLQuery.QueryResponse> resps = ExecuteSOQLQuery.execute(new List<ExecuteSOQLQuery.QueryRequest>{ req });
        Test.stopTest();

        Assert.areEqual(1, resps.size(), 'One response expected.');
        Assert.isTrue(resps[0].success, 'Query should be successful.');
        Assert.isNotNull(resps[0].recordsJson, 'Records JSON should be present.');
    }

    @IsTest
    static void testExecuteEmptyQuery() {
        ExecuteSOQLQuery.QueryRequest req = new ExecuteSOQLQuery.QueryRequest();
        req.query = '';

        Test.startTest();
        List<ExecuteSOQLQuery.QueryResponse> resps = ExecuteSOQLQuery.execute(new List<ExecuteSOQLQuery.QueryRequest>{ req });
        Test.stopTest();

        Assert.areEqual(1, resps.size(), 'One response expected.');
        Assert.isFalse(resps[0].success, 'Empty query should fail.');
        Assert.areEqual('Query string cannot be empty.', resps[0].errorMessage, 'Error message should match.');
    }

    @IsTest
    static void testExecuteInvalidQuery() {
        ExecuteSOQLQuery.QueryRequest req = new ExecuteSOQLQuery.QueryRequest();
        req.query = 'SELECT InvalidField FROM NonExistentObject';

        Test.startTest();
        List<ExecuteSOQLQuery.QueryResponse> resps = ExecuteSOQLQuery.execute(new List<ExecuteSOQLQuery.QueryRequest>{ req });
        Test.stopTest();

        Assert.areEqual(1, resps.size(), 'One response expected.');
        Assert.isFalse(resps[0].success, 'Invalid query should fail.');
        Assert.isNotNull(resps[0].errorMessage, 'Error message should be present.');
    }
}