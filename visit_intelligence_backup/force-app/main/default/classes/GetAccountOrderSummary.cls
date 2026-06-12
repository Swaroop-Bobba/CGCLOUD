/**
 * @deprecated This class is obsolete and has been replaced by the Apex Class: GetAccountOrderSummaryForAgent (apex://GetAccountOrderSummaryForAgent).
 * It is no longer referenced by the Visit Intelligence Agent.
 */
public with sharing class GetAccountOrderSummary {

    @InvocableMethod(
        label='Get Account Order Summary'
        description='Retrieve order history summary, buying insights, phase breakdown, and recent orders for a given Account.'
    )
    public static List<Result> execute(List<Request> requests) {
        List<Result> results = new List<Result>();

        for (Request req : requests) {
            Result res = new Result();
            res.totalOrders = 0;
            res.totalSpend = 0;
            res.buyingInsight = 'No historical order data available.';
            res.phaseBreakdown = 'No orders to analyze.';
            res.recentOrders = '[]';

            try {
                String accId = req.accountId;

                // Dynamic SOQL for managed package objects (cgcloud__Order__c)
                String orderQuery = 
                    'SELECT Id, Name, cgcloud__Order_Date__c, cgcloud__Delivery_Date__c, ' +
                    'cgcloud__Phase__c, cgcloud__Total_Value__c, cgcloud__Gross_Total_Value__c, ' +
                    'cgcloud__Delivery_Note__c, ' +
                    '(SELECT Id, cgcloud__Product__r.Name, cgcloud__Quantity__c, cgcloud__UOM__c ' +
                    ' FROM cgcloud__Order_Items__r) ' +
                    'FROM cgcloud__Order__c ' +
                    'WHERE cgcloud__Order_Account__c = :accId ' +
                    'ORDER BY CreatedDate DESC LIMIT 10';

                List<SObject> orders = Database.query(orderQuery, AccessLevel.USER_MODE);

                if (orders.isEmpty()) {
                    res.buyingInsight = 'No previous orders found for this account.';
                    results.add(res);
                    continue;
                }

                res.totalOrders = orders.size();

                // ---- Build recent orders summary, phase breakdown, and buying insights ----
                Decimal grandTotal = 0;
                Map<String, Decimal> phaseTotals = new Map<String, Decimal>();
                Map<String, ProductStat> productStats = new Map<String, ProductStat>();
                List<String> orderSummaries = new List<String>();

                for (SObject ord : orders) {
                    Decimal totalVal = (Decimal) ord.get('cgcloud__Total_Value__c');
                    if (totalVal == null) totalVal = 0;
                    grandTotal += totalVal;

                    String phase = (String) ord.get('cgcloud__Phase__c');
                    if (String.isBlank(phase)) phase = 'Draft';

                    if (!phaseTotals.containsKey(phase)) {
                        phaseTotals.put(phase, 0);
                    }
                    phaseTotals.put(phase, phaseTotals.get(phase) + totalVal);

                    // Build individual order summary line
                    String orderName = (String) ord.get('Name');
                    Object orderDateObj = ord.get('cgcloud__Order_Date__c');
                    String orderDate = orderDateObj != null ? String.valueOf(orderDateObj) : 'N/A';
                    Object deliveryDateObj = ord.get('cgcloud__Delivery_Date__c');
                    String deliveryDate = deliveryDateObj != null ? String.valueOf(deliveryDateObj) : 'N/A';
                    Decimal grossVal = (Decimal) ord.get('cgcloud__Gross_Total_Value__c');
                    if (grossVal == null) grossVal = 0;

                    // Process child order items for product stats
                    List<SObject> items = ord.getSObjects('cgcloud__Order_Items__r');
                    Integer itemCount = 0;
                    Set<String> uniqueProductsInOrder = new Set<String>();
                    List<String> itemDetails = new List<String>();

                    if (items != null) {
                        itemCount = items.size();
                        for (SObject item : items) {
                            SObject productRef = item.getSObject('cgcloud__Product__r');
                            String productName = (productRef != null) ? (String) productRef.get('Name') : 'Unknown Product';
                            Decimal qty = (Decimal) item.get('cgcloud__Quantity__c');
                            if (qty == null) qty = 0;
                            String uom = (String) item.get('cgcloud__UOM__c');
                            if (String.isBlank(uom)) uom = 'PCS';

                            // Track product stats for buying insights
                            if (!productStats.containsKey(productName)) {
                                productStats.put(productName, new ProductStat(uom));
                            }
                            productStats.get(productName).totalQuantity += qty;
                            uniqueProductsInOrder.add(productName);

                            itemDetails.add(productName + ' x ' + qty.setScale(0) + ' ' + uom);
                        }

                        // Increment order count for each unique product
                        for (String pName : uniqueProductsInOrder) {
                            productStats.get(pName).orderCount += 1;
                        }
                    }

                    String itemsText = itemDetails.isEmpty() ? 'No items' : String.join(itemDetails, '; ');
                    String phaseEmoji = '⚪ ';
                    if (phase.equalsIgnoreCase('released') || phase.equalsIgnoreCase('submitted')) phaseEmoji = '🟢 ';
                    else if (phase.equalsIgnoreCase('draft')) phaseEmoji = '🟡 ';
                    else if (phase.equalsIgnoreCase('canceled')) phaseEmoji = '🔴 ';

                    orderSummaries.add(
                        '📦 **Order #' + orderName + '**\n' +
                        '* **Date**: ' + orderDate + ' | **Delivery**: ' + deliveryDate + '\n' +
                        '* **Phase**: ' + phaseEmoji + phase + '\n' +
                        '* **Total Value**: **$' + totalVal.setScale(2) + '** (Gross: $' + grossVal.setScale(2) + ')\n' +
                        '* **Items (' + itemCount + ')**: _' + itemsText + '_\n'
                    );
                }

                res.totalSpend = grandTotal;
                res.recentOrders = String.join(orderSummaries, '\n');

                // ---- Generate Phase Breakdown ----
                List<String> phaseLines = new List<String>();
                for (String phase : phaseTotals.keySet()) {
                    Decimal val = phaseTotals.get(phase);
                    Decimal pct = (grandTotal > 0) ? (val / grandTotal * 100) : 0;
                    String phaseEmoji = '⚪ ';
                    if (phase.equalsIgnoreCase('released') || phase.equalsIgnoreCase('submitted')) phaseEmoji = '🟢 ';
                    else if (phase.equalsIgnoreCase('draft')) phaseEmoji = '🟡 ';
                    else if (phase.equalsIgnoreCase('canceled')) phaseEmoji = '🔴 ';
                    
                    phaseLines.add(phaseEmoji + '**' + phase + '**: $' + val.setScale(2) + ' (' + pct.setScale(0) + '%)');
                }
                res.phaseBreakdown = String.join(phaseLines, ' | ');

                // ---- Generate Buying Insights (mirrors LWC generateInsights() logic) ----
                if (productStats.isEmpty()) {
                    res.buyingInsight = 'This customer has placed ' + res.totalOrders + 
                        ' orders historically (total spend: $' + grandTotal.setScale(2) + 
                        '), but no individual product details were found.';
                } else {
                    // Sort by order frequency to find "usually orders"
                    List<ProductEntry> productList = new List<ProductEntry>();
                    for (String name : productStats.keySet()) {
                        ProductStat stat = productStats.get(name);
                        productList.add(new ProductEntry(name, stat.totalQuantity, stat.orderCount, stat.uom));
                    }

                    // Sort by frequency (orderCount DESC)
                    productList.sort();

                    // Top 2 by frequency
                    List<String> topFreqNames = new List<String>();
                    for (Integer i = 0; i < Math.min(2, productList.size()); i++) {
                        topFreqNames.add(productList[i].name);
                    }
                    String usuallyOrders = String.join(topFreqNames, ' and ');

                    // Find most saleable (highest total quantity)
                    ProductEntry mostSaleable = productList[0];
                    for (ProductEntry pe : productList) {
                        if (pe.totalQuantity > mostSaleable.totalQuantity) {
                            mostSaleable = pe;
                        }
                    }

                    res.buyingInsight = '📊 **Spend Overview**: Historical Orders: **' + res.totalOrders + 
                        '** | Total Spend: **$' + grandTotal.setScale(2) + '**\n\n' +
                        '🛍️ **Frequent Products**: Usually purchases **' + usuallyOrders + '**\n\n' +
                        '🏆 **Top-Selling Product**: **' + mostSaleable.name + '** (' + mostSaleable.totalQuantity.setScale(0) + ' ' + mostSaleable.uom + ')';
                }

            } catch (Exception e) {
                // Fallback for orgs without CG Cloud package
                res.buyingInsight = 'Order data is not available in this environment. The CG Cloud managed package may not be installed.';
                res.phaseBreakdown = 'N/A';
                res.recentOrders = '[]';
            }

            results.add(res);
        }

        return results;
    }

    // Helper class for product statistics
    private class ProductStat {
        public Decimal totalQuantity;
        public Integer orderCount;
        public String uom;

        public ProductStat(String uom) {
            this.totalQuantity = 0;
            this.orderCount = 0;
            this.uom = uom;
        }
    }

    // Sortable wrapper for product entries (sorted by orderCount DESC)
    private class ProductEntry implements Comparable {
        public String name;
        public Decimal totalQuantity;
        public Integer orderCount;
        public String uom;

        public ProductEntry(String name, Decimal totalQuantity, Integer orderCount, String uom) {
            this.name = name;
            this.totalQuantity = totalQuantity;
            this.orderCount = orderCount;
            this.uom = uom;
        }

        public Integer compareTo(Object other) {
            ProductEntry o = (ProductEntry) other;
            // Sort by orderCount descending
            return o.orderCount - this.orderCount;
        }
    }

    public class Request {
        @InvocableVariable(required=true description='The Account ID to retrieve order history for.')
        public String accountId;
    }

    public class Result {
        @InvocableVariable(description='Total number of historical orders.')
        public Integer totalOrders;

        @InvocableVariable(description='Total historical spend across all orders.')
        public Decimal totalSpend;

        @InvocableVariable(description='AI-generated buying insight summary: top products by frequency, most saleable product.')
        public String buyingInsight;

        @InvocableVariable(description='Order value breakdown by phase (e.g. Released: $5200 (60%), Draft: $3500 (40%)).')
        public String phaseBreakdown;

        @InvocableVariable(description='Formatted list of recent orders with details including order number, date, phase, total, items.')
        public String recentOrders;
    }
}
