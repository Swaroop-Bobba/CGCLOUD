public with sharing class GetAccountOrderSummaryForAgent {

    @InvocableMethod(
        label='Get Account Order Summary (Agent)'
        description='Retrieve order history summary with clean professional formatting for Agent display. No markdown bold/italic.'
    )
    public static List<Result> execute(List<Request> requests) {
        List<Result> results = new List<Result>();

        for (Request req : requests) {
            Result res = new Result();
            res.totalOrders = 0;
            res.totalSpend = 0;
            res.buyingInsight = 'No historical order data available.';
            res.phaseBreakdown = 'No orders to analyze.';
            res.recentOrders = '';

            try {
                String accId = req.accountId;

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

                Decimal grandTotal = 0;
                Map<String, Decimal> phaseTotals = new Map<String, Decimal>();
                Map<String, ProductStat> productStats = new Map<String, ProductStat>();
                List<String> orderCards = new List<String>();

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

                    String orderName = (String) ord.get('Name');
                    Object orderDateObj = ord.get('cgcloud__Order_Date__c');
                    String orderDate = orderDateObj != null ? formatDate(String.valueOf(orderDateObj)) : 'N/A';
                    Object deliveryDateObj = ord.get('cgcloud__Delivery_Date__c');
                    String deliveryDate = deliveryDateObj != null ? formatDate(String.valueOf(deliveryDateObj)) : 'N/A';
                    Decimal grossVal = (Decimal) ord.get('cgcloud__Gross_Total_Value__c');
                    if (grossVal == null) grossVal = 0;

                    List<SObject> items = ord.getSObjects('cgcloud__Order_Items__r');
                    Integer itemCount = 0;
                    Set<String> uniqueProductsInOrder = new Set<String>();
                    List<String> itemLines = new List<String>();

                    if (items != null) {
                        itemCount = items.size();
                        for (SObject item : items) {
                            SObject productRef = item.getSObject('cgcloud__Product__r');
                            String productName = (productRef != null) ? (String) productRef.get('Name') : 'Unknown Product';
                            Decimal qty = (Decimal) item.get('cgcloud__Quantity__c');
                            if (qty == null) qty = 0;
                            String uom = (String) item.get('cgcloud__UOM__c');
                            if (String.isBlank(uom)) uom = 'PCS';

                            if (!productStats.containsKey(productName)) {
                                productStats.put(productName, new ProductStat(uom));
                            }
                            productStats.get(productName).totalQuantity += qty;
                            uniqueProductsInOrder.add(productName);

                            itemLines.add('     \u2022 ' + productName + '  \u2014  ' + qty.setScale(0) + ' ' + uom);
                        }

                        for (String pName : uniqueProductsInOrder) {
                            productStats.get(pName).orderCount += 1;
                        }
                    }

                    // Build clean order card
                    String phaseIcon = getPhaseIcon(phase);
                    String card =
                        '\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\n' +
                        '\uD83D\uDCE6 Order ' + orderName + '\n' +
                        '\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\n' +
                        '  \uD83D\uDCC5 Order Date     :  ' + orderDate + '\n' +
                        '  \uD83D\uDE9A Delivery Date  :  ' + deliveryDate + '\n' +
                        '  ' + phaseIcon + ' Phase          :  ' + phase + '\n' +
                        '  \uD83D\uDCB0 Total Value    :  $' + totalVal.setScale(2) + '\n' +
                        '  \uD83D\uDCCA Gross Value    :  $' + grossVal.setScale(2) + '\n';

                    if (itemCount > 0) {
                        card += '  \uD83D\uDCCB Items (' + itemCount + '):\n' + String.join(itemLines, '\n') + '\n';
                    } else {
                        card += '  \uD83D\uDCCB Items: No items\n';
                    }

                    orderCards.add(card);
                }

                res.totalSpend = grandTotal;
                res.recentOrders = String.join(orderCards, '\n');

                // Phase Breakdown
                List<String> phaseLines = new List<String>();
                for (String phase : phaseTotals.keySet()) {
                    Decimal val = phaseTotals.get(phase);
                    Decimal pct = (grandTotal > 0) ? (val / grandTotal * 100) : 0;
                    String phaseIcon = getPhaseIcon(phase);
                    phaseLines.add('  ' + phaseIcon + ' ' + phase + '  \u2014  $' + val.setScale(2) + '  (' + pct.setScale(0) + '%)');
                }
                res.phaseBreakdown =
                    '\uD83D\uDCCA Phase Breakdown\n' +
                    '\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\n' +
                    String.join(phaseLines, '\n');

                // Buying Insights
                if (productStats.isEmpty()) {
                    res.buyingInsight =
                        '\uD83D\uDCCA Spend Overview\n' +
                        '\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\n' +
                        '  Historical Orders  :  ' + res.totalOrders + '\n' +
                        '  Total Spend        :  $' + grandTotal.setScale(2) + '\n' +
                        '  Product Details    :  Not available';
                } else {
                    List<ProductEntry> productList = new List<ProductEntry>();
                    for (String name : productStats.keySet()) {
                        ProductStat stat = productStats.get(name);
                        productList.add(new ProductEntry(name, stat.totalQuantity, stat.orderCount, stat.uom));
                    }
                    productList.sort();

                    List<String> topFreqNames = new List<String>();
                    for (Integer i = 0; i < Math.min(2, productList.size()); i++) {
                        topFreqNames.add(productList[i].name);
                    }
                    String usuallyOrders = String.join(topFreqNames, ' and ');

                    ProductEntry mostSaleable = productList[0];
                    for (ProductEntry pe : productList) {
                        if (pe.totalQuantity > mostSaleable.totalQuantity) {
                            mostSaleable = pe;
                        }
                    }

                    res.buyingInsight =
                        '\uD83D\uDCCA Spend Overview\n' +
                        '\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\n' +
                        '  Historical Orders  :  ' + res.totalOrders + '\n' +
                        '  Total Spend        :  $' + grandTotal.setScale(2) + '\n\n' +
                        '\uD83D\uDED2 Frequent Products\n' +
                        '\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\n' +
                        '  Usually purchases: ' + usuallyOrders + '\n\n' +
                        '\uD83C\uDFC6 Top-Selling Product\n' +
                        '\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\n' +
                        '  ' + mostSaleable.name + '  \u2014  ' + mostSaleable.totalQuantity.setScale(0) + ' ' + mostSaleable.uom;
                }

            } catch (Exception e) {
                res.buyingInsight = 'Order data is not available in this environment. The CG Cloud managed package may not be installed.';
                res.phaseBreakdown = 'N/A';
                res.recentOrders = '';
            }

            results.add(res);
        }

        return results;
    }

    private static String getPhaseIcon(String phase) {
        if (phase.equalsIgnoreCase('released') || phase.equalsIgnoreCase('submitted')) {
            return '\u2705';
        } else if (phase.equalsIgnoreCase('draft')) {
            return '\uD83D\uDFE1';
        } else if (phase.equalsIgnoreCase('canceled')) {
            return '\u274C';
        }
        return '\u26AA';
    }

    private static String formatDate(String rawDate) {
        if (String.isBlank(rawDate)) return 'N/A';
        // rawDate is typically "2026-05-29 00:00:00" or "2026-05-29"
        // Return just the date portion in a clean format
        if (rawDate.length() >= 10) {
            String datePart = rawDate.substring(0, 10);
            List<String> parts = datePart.split('-');
            if (parts.size() == 3) {
                String monthName = getMonthName(Integer.valueOf(parts[1]));
                return parts[2] + ' ' + monthName + ' ' + parts[0];
            }
        }
        return rawDate;
    }

    private static String getMonthName(Integer month) {
        List<String> months = new List<String>{
            'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
            'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
        };
        if (month >= 1 && month <= 12) {
            return months[month - 1];
        }
        return String.valueOf(month);
    }

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

        @InvocableVariable(description='Buying insight summary with spend overview, frequent products, and top-selling product.')
        public String buyingInsight;

        @InvocableVariable(description='Order value breakdown by phase.')
        public String phaseBreakdown;

        @InvocableVariable(description='Formatted list of recent orders with details.')
        public String recentOrders;
    }
}
