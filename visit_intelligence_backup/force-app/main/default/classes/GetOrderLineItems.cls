/**
 * @deprecated This class is obsolete and has been replaced by the Salesforce Flow: Get_Order_Line_Items (flow://Get_Order_Line_Items).
 * It is no longer referenced by the Visit Intelligence Agent.
 */
public with sharing class GetOrderLineItems {

    @InvocableMethod(
        label='Get Order Line Items'
        description='Retrieve product line items (product name, quantity, UOM) for a specific CG Cloud Order.'
    )
    public static List<Result> execute(List<Request> requests) {
        List<Result> results = new List<Result>();

        for (Request req : requests) {
            Result res = new Result();
            res.items = new List<OrderItem>();
            res.itemCount = 0;
            res.itemsSummary = 'No items found.';

            try {
                String ordId = req.orderId;

                String itemQuery = 
                    'SELECT Id, cgcloud__Product__r.Name, cgcloud__Quantity__c, cgcloud__UOM__c ' +
                    'FROM cgcloud__Order_Item__c ' +
                    'WHERE cgcloud__Order__c = :ordId ' +
                    'ORDER BY cgcloud__Product__r.Name ASC';

                List<SObject> sItems = Database.query(itemQuery, AccessLevel.USER_MODE);

                if (sItems.isEmpty()) {
                    results.add(res);
                    continue;
                }

                List<String> summaryLines = new List<String>();
                summaryLines.add('\uD83D\uDCCB Order Line Items (' + sItems.size() + ' total)');

                for (SObject si : sItems) {
                    OrderItem oi = new OrderItem();

                    SObject productRef = si.getSObject('cgcloud__Product__r');
                    oi.productName = (productRef != null) ? (String) productRef.get('Name') : 'Unknown Product';

                    Decimal qty = (Decimal) si.get('cgcloud__Quantity__c');
                    oi.quantity = (qty != null) ? qty : 0;

                    oi.uom = (String) si.get('cgcloud__UOM__c');
                    if (String.isBlank(oi.uom)) oi.uom = 'PCS';

                    res.items.add(oi);
                    summaryLines.add('     \u2022 ' + oi.productName + '  \u2014  ' + oi.quantity.setScale(0) + ' ' + oi.uom);
                }

                res.itemCount = res.items.size();
                res.itemsSummary = String.join(summaryLines, '\n');

            } catch (Exception e) {
                res.itemsSummary = 'Unable to retrieve order items. The CG Cloud managed package may not be installed.';
            }

            results.add(res);
        }

        return results;
    }

    public class Request {
        @InvocableVariable(required=true description='The CG Cloud Order ID to retrieve line items for.')
        public String orderId;
    }

    public class OrderItem {
        @InvocableVariable(description='Product name.')
        public String productName;

        @InvocableVariable(description='Quantity ordered.')
        public Decimal quantity;

        @InvocableVariable(description='Unit of measure.')
        public String uom;
    }

    public class Result {
        @InvocableVariable(description='List of order line items with product details.')
        public List<OrderItem> items;

        @InvocableVariable(description='Total number of line items.')
        public Integer itemCount;

        @InvocableVariable(description='Formatted text summary of all line items.')
        public String itemsSummary;
    }
}
