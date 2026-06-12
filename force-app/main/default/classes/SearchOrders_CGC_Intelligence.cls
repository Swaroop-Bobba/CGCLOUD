public with sharing class SearchOrders_CGC_Intelligence {
    public class Request {
        @InvocableVariable(required=true description='The search query.')
        public String searchQuery;
    }
    public class Result {
        @InvocableVariable(description='List of matching orders.')
        public List<OrderOption> orders;
    }
    public class OrderOption {
        @InvocableVariable(description='The Order ID.')
        public String orderId;
        @InvocableVariable(description='The Order Name/Number.')
        public String orderName;
        @InvocableVariable(description='The parent Account ID.')
        public String accountId;
        @InvocableVariable(description='The parent Account Name.')
        public String accountName;
        @InvocableVariable(description='Formatted label with order info.')
        public String label;

        public OrderOption() {}
        public OrderOption(String id, String name, String accId, String accName, String lbl) {
            this.orderId = id;
            this.orderName = name;
            this.accountId = accId;
            this.accountName = accName;
            this.label = lbl;
        }
    }

    @InvocableMethod(
        label='Search Orders (CGC_Intelligence)'
        description='Search for Order records by name or account name.'
    )
    public static List<Result> execute(List<Request> requests) {
        List<Result> results = new List<Result>();
        for (Request req : requests) {
            Result res = new Result();
            res.orders = new List<OrderOption>();
            String q = req.searchQuery;
            if (String.isNotBlank(q)) {
                String pattern = '%' + q.trim().replaceAll('\\s+', '%') + '%';
                List<cgcloud__Order__c> ords = [
                    SELECT Id, Name, cgcloud__Phase__c, cgcloud__Order_Account__c, cgcloud__Order_Account__r.Name 
                    FROM cgcloud__Order__c 
                    WHERE Name LIKE :pattern OR cgcloud__Order_Account__r.Name LIKE :pattern
                    WITH USER_MODE 
                    LIMIT 15
                ];
                for (cgcloud__Order__c o : ords) {
                    String accName = o.cgcloud__Order_Account__r != null ? o.cgcloud__Order_Account__r.Name : 'Unknown';
                    String lbl = 'Order ' + o.Name + ' \u2014 ' + accName + ' (Status: ' + o.cgcloud__Phase__c + ')';
                    res.orders.add(new OrderOption(o.Id, o.Name, o.cgcloud__Order_Account__c, accName, lbl));
                }
            }
            results.add(res);
        }
        return results;
    }
}