/**
 * Runs dynamic SOQL queries in user mode to calculate aggregate totals,
 * visit metrics, and custom filtering requested during agent conversations.
 */
global with sharing class RecordCalculationController {
    global class QueryRequest {
        @InvocableVariable(required=true label='SOQL Query' description='The SOQL query to execute.')
        global String query;
    }

    global class QueryResponse {
        @InvocableVariable(label='Success' description='True if the query completed successfully.')
        global Boolean success;

        @InvocableVariable(label='Records JSON' description='JSON string of the query result records.')
        global String recordsJson;

        @InvocableVariable(label='Error Message' description='Error message if the query failed.')
        global String errorMessage;
    }

    @InvocableMethod(label='Execute SOQL Query' description='Executes a dynamic SOQL query and returns the results as a JSON string. Runs in User Mode to respect object/field permissions.')
    global static List<QueryResponse> execute(List<QueryRequest> requests) {
        List<QueryResponse> responses = new List<QueryResponse>();
        for (QueryRequest req : requests) {
            QueryResponse resp = new QueryResponse();
            try {
                if (String.isBlank(req.query)) {
                    resp.success = false;
                    resp.errorMessage = 'Query string cannot be empty.';
                    responses.add(resp);
                    continue;
                }
                
                // Execute dynamic SOQL query in User Mode to respect Salesforce security models.
                List<SObject> results = Database.query(req.query, AccessLevel.USER_MODE);
                resp.success = true;
                resp.recordsJson = JSON.serialize(results);
            } catch (Exception e) {
                resp.success = false;
                resp.errorMessage = e.getMessage();
                System.debug('Error executing dynamic SOQL query: ' + e.getMessage() + '\n' + e.getStackTraceString());
            }
            responses.add(resp);
        }
        return responses;
    }
}