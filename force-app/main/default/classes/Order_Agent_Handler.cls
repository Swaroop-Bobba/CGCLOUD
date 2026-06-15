public with sharing class Order_Agent_Handler {

    public class Request {
        @InvocableVariable(required=true description='The name of the agent executing the request (e.g. CGC_Intelligence or Visit_Intelligence).')
        public String agentName;

        @InvocableVariable(required=true description='The type of action to perform.')
        public String actionType; // 'getDetails', 'search', 'getAccountSummary', 'getVisitSummary', 'getLineItems', 'updateNotes'

        @InvocableVariable(description='The Account ID.')
        public String accountId;

        @InvocableVariable(description='The Visit ID.')
        public String visitId;

        @InvocableVariable(description='The Order ID.')
        public String orderId;

        @InvocableVariable(description='The search query.')
        public String searchQuery;

        @InvocableVariable(description='The Order ID or Name for notes updates.')
        public String orderIdentifier;

        @InvocableVariable(description='New delivery note text.')
        public String deliveryNote;

        @InvocableVariable(description='New invoice note text.')
        public String invoiceNote;
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

        @InvocableVariable(description='List of matching orders.')
        public List<OrderOption> orders;

        // Spend summaries
        @InvocableVariable(description='Total orders.')
        public Integer totalOrders;

        @InvocableVariable(description='Total spend.')
        public Decimal totalSpend;

        @InvocableVariable(description='AI buying insight.')
        public String buyingInsight;

        @InvocableVariable(description='Phase breakdown.')
        public String phaseBreakdown;

        @InvocableVariable(description='Recent orders list.')
        public String recentOrders;

        // Line items
        @InvocableVariable(description='Line items.')
        public List<OrderItem> items;

        @InvocableVariable(description='Total number of line items.')
        public Integer itemCount;

        @InvocableVariable(description='Formatted text summary of line items.')
        public String itemsSummary;

        // Action outcome
        @InvocableVariable(description='Success.')
        public Boolean success;

        @InvocableVariable(description='Message.')
        public String resultMessage;
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

    public class OrderItem {
        @InvocableVariable(description='Product name.')
        public String productName;

        @InvocableVariable(description='Quantity ordered.')
        public Decimal quantity;

        @InvocableVariable(description='Unit of measure.')
        public String uom;
    }

    @InvocableMethod(
        label='Order Agent Handler'
        description='Handles all Order operations for Agents'
    )
    public static List<Result> execute(List<Request> requests) {
        List<Result> results = new List<Result>();
        for (Request req : requests) {
            Result res = new Result();
            String action = req.actionType != null ? req.actionType.toLowerCase().trim() : '';

            if (action == 'getdetails') {
                res = Order_Agent_Service.getOrderDetails(req.orderId);
            } else if (action == 'search') {
                res.orders = Order_Agent_Service.searchOrders(req.searchQuery);
            } else if (action == 'getaccountsummary') {
                res = Order_Agent_Service.getAccountOrderSummary(req.accountId);
            } else if (action == 'getvisitsummary') {
                res = Order_Agent_Service.getVisitOrderSummary(req.visitId);
            } else if (action == 'getlineitems') {
                res = Order_Agent_Service.getOrderLineItems(req.orderId);
            } else if (action == 'updatenotes') {
                res = Order_Agent_Service.updateOrderNotes(req.orderIdentifier, req.deliveryNote, req.invoiceNote);
            }
            results.add(res);
        }
        return results;
    }
}
