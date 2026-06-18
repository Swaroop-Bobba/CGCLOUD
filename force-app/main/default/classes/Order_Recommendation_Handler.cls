public with sharing class Order_Recommendation_Handler {

    public class Request {
        @InvocableVariable(required=true description='The name of the agent executing the request.')
        public String agentName;

        @InvocableVariable(required=true description='The type of action to perform.')
        public String actionType; // 'getContext', 'suggestProducts'

        @InvocableVariable(description='The Order ID.')
        public String orderId;

        @InvocableVariable(description='The Account ID.')
        public String accountId;

        @InvocableVariable(description='The search query.')
        public String searchQuery;
    }

    public class Result {
        @InvocableVariable(description='The Order ID.')
        public String orderId;

        @InvocableVariable(description='The associated Account ID.')
        public String accountId;

        @InvocableVariable(description='The associated Account Name.')
        public String accountName;

        @InvocableVariable(description='The Order Name/Number.')
        public String orderName;

        @InvocableVariable(description='The Order Status.')
        public String orderStatus;

        @InvocableVariable(description='Formatted product recommendations.')
        public String recommendations;

        @InvocableVariable(description='Formatted recent orders text.')
        public String recentOrdersText;
    }

    @InvocableMethod(
        label='Order Recommendation Handler'
        description='Handles order and product recommendation operations'
    )
    public static List<Result> execute(List<Request> requests) {
        List<Result> results = new List<Result>();
        for (Request req : requests) {
            Result res = new Result();
            String action = req.actionType != null ? req.actionType.toLowerCase().trim() : '';

            if (action == 'getcontext') {
                res = Order_Recommendation_Service.getOrderContext(req.orderId);
            } else if (action == 'suggestproducts') {
                res = Order_Recommendation_Service.suggestProducts(req.accountId, req.orderId);
            } else if (action == 'getaccountcontext') {
                res = Order_Recommendation_Service.getAccountContext(req.accountId);
            } else if (action == 'getfullorderlist') {
                res = Order_Recommendation_Service.getFullOrderList(req.accountId);
            } else if (action == 'getordersummary') {
                res = Order_Recommendation_Service.getOrderSummary(req.accountId);
            } else if (action == 'searchaccounts') {
                res = Order_Recommendation_Service.searchAccounts(req.searchQuery);
            }
            results.add(res);
        }
        return results;
    }
}