public with sharing class GetOrderDetails_CGC_Intelligence {
    public class Request {
        @InvocableVariable(required=true description='The Order ID.')
        public String orderId;
    }
    public class Result {
        @InvocableVariable(description='The Order ID.')
        public String orderId;
        @InvocableVariable(description='The parent Account ID.')
        public String accountId;
        @InvocableVariable(description='The parent Account Name.')
        public String accountName;
        @InvocableVariable(description='The Order Name.')
        public String orderName;
        @InvocableVariable(description='The Order Status/Phase.')
        public String orderStatus;
    }
    @InvocableMethod(
        label='Get Order Details (CGC_Intelligence)'
        description='Retrieve Order details and its parent Account.'
    )
    public static List<Result> execute(List<Request> requests) {
        List<Result> results = new List<Result>();
        Set<Id> orderIds = new Set<Id>();
        for (Request req : requests) {
            if (String.isNotBlank(req.orderId)) {
                try {
                    orderIds.add((Id) req.orderId.trim());
                } catch (Exception e) {}
            }
        }
        Map<Id, cgcloud__Order__c> ordersMap = new Map<Id, cgcloud__Order__c>([
            SELECT Id, Name, cgcloud__Phase__c, cgcloud__Order_Account__c, cgcloud__Order_Account__r.Name 
            FROM cgcloud__Order__c 
            WHERE Id IN :orderIds WITH USER_MODE
        ]);
        for (Request req : requests) {
            Result res = new Result();
            if (String.isNotBlank(req.orderId)) {
                String trimmedId = req.orderId.trim();
                res.orderId = trimmedId;
                if (ordersMap.containsKey(trimmedId)) {
                    cgcloud__Order__c ord = ordersMap.get(trimmedId);
                    res.accountId = ord.cgcloud__Order_Account__c;
                    res.accountName = ord.cgcloud__Order_Account__r != null ? ord.cgcloud__Order_Account__r.Name : '';
                    res.orderName = ord.Name;
                    res.orderStatus = ord.cgcloud__Phase__c;
                }
            }
            results.add(res);
        }
        return results;
    }
}