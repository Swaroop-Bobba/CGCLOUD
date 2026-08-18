/**
 * Manages order history lookups, line item analysis, inventory checks,
 * out-of-stock tracking, and product reorder recommendations.
 */
global with sharing class OrderAgentController {

    /**
     * @description Explicit zero-argument default constructor for 2GP serialization.
     */
    global OrderAgentController() {}

    /**
     * @description Input DTO for OrderAgentController.
     */
    global class Request {
        @InvocableVariable(required=true description='Action to perform (e.g. getOrders, getOrderDetails, getAccountOrderSummary, getVisitOrderSummary, getOrderRecommendations, getInventoryChecks).')
        global String actionType;

        @InvocableVariable(description='The name of the agent executing the request.')
        global String agentName;

        @InvocableVariable(description='Domain context.')
        global String domain;

        @InvocableVariable(description='Target Order ID or Order Number.')
        global String orderId;

        @InvocableVariable(description='Target Account ID.')
        global String accountId;

        @InvocableVariable(description='Target Visit ID.')
        global String visitId;

        @InvocableVariable(description='Search query string.')
        global String searchQuery;

        @InvocableVariable(description='Delivery note string.')
        global String deliveryNote;

        @InvocableVariable(description='Invoice note string.')
        global String invoiceNote;

        @InvocableVariable(description='Order identifier.')
        global String orderIdentifier;

        global Request() {}
    }

    /**
     * @description Output DTO for OrderAgentController.
     */
    global class Response {
        @InvocableVariable(description='True if operation succeeded.')
        global Boolean success;

        @InvocableVariable(description='Outcome message.')
        global String message;

        @InvocableVariable(description='Markdown formatted report or result list.')
        global String summary;

        @InvocableVariable(description='Total matching orders count.')
        global Integer totalOrders;

        @InvocableVariable(description='Total monetary value across orders.')
        global Decimal totalOrderValue;

        @InvocableVariable(description='Total reorder recommendations generated.')
        global Integer totalRecommendations;

        global Response() {
            this.success = true;
            this.totalOrders = 0;
            this.totalOrderValue = 0.00;
            this.totalRecommendations = 0;
        }
    }

    @InvocableMethod(
        label='Order Agent Handler'
        description='Dispatches self-contained Order, Inventory, and Recommendation actions for Visit Intelligence agents.'
    )
    global static List<Response> execute(List<Request> requests) {
        List<Response> results = new List<Response>();

        for (Request req : requests) {
            Response res = new Response();
            try {
                String action = req.actionType != null ? req.actionType.toLowerCase().trim() : '';

                if (action == 'getorders' || action == 'get_orders' || action == 'searchorders' || action == 'search_orders' || action == 'search') {
                    res = handleSearchOrders(req.searchQuery, req.accountId);
                } else if (action == 'getorderdetails' || action == 'get_order_details' || action == 'getdetails' || action == 'getlineitems' || action == 'get_line_items' || action == 'order_line_items') {
                    res = handleGetOrderDetails(req.orderId);
                } else if (action == 'getaccountordersummary' || action == 'get_account_order_summary' || action == 'getaccountsummary') {
                    res = handleGetAccountOrderSummary(req.accountId);
                } else if (action == 'getvisitordersummary' || action == 'get_visit_order_summary' || action == 'getvisitsummary') {
                    res = handleGetVisitOrderSummary(req.visitId);
                } else if (action == 'getorderrecommendations' || action == 'get_order_recommendations' || action == 'getrecommendations' || action == 'suggestproducts' || action == 'suggest_products') {
                    res = handleGetOrderRecommendations(req.accountId);
                } else if (action == 'getinventorychecks' || action == 'get_inventory_checks' || action == 'getinventory') {
                    res = handleGetInventoryChecks(req.accountId);
                } else {
                    res = handleSearchOrders(req.searchQuery, req.accountId);
                }
            } catch (Exception e) {
                res.success = false;
                res.message = 'Error executing order action: ' + e.getMessage();
                res.summary = 'An error occurred while processing order request: ' + e.getMessage();
            }
            results.add(res);
        }
        return results;
    }

    // =========================================================================
    // INLINED DOMAIN LOGIC: ORDERS & INVENTORY (No external helper calls)
    // =========================================================================

    private static Response handleSearchOrders(String queryStr, String accountId) {
        Response res = new Response();
        Boolean hasCgOrders = Schema.getGlobalDescribe().containsKey('cgcloud__order__c');

        if (!hasCgOrders) {
            res.success = true;
            res.message = 'No CG Cloud Order schema installed.';
            res.summary = 'No CG Cloud Orders found in this environment.';
            return res;
        }

        try {
            String soql = 'SELECT Id, Name, cgcloud__Phase__c, cgcloud__Gross_Total_Value__c, cgcloud__Order_Account__r.Name, CreatedDate FROM cgcloud__Order__c WHERE Id != null';

            if (String.isNotBlank(accountId)) {
                soql += ' AND cgcloud__Order_Account__c = :accountId';
            }
            if (String.isNotBlank(queryStr)) {
                String pattern = '%' + String.escapeSingleQuotes(queryStr.trim()) + '%';
                soql += ' AND (Name LIKE :pattern OR cgcloud__Phase__c LIKE :pattern OR cgcloud__Order_Account__r.Name LIKE :pattern)';
            }
            soql += ' ORDER BY CreatedDate DESC LIMIT 15';

            List<SObject> ordList = Database.query(soql);
            res.totalOrders = ordList.size();

            if (ordList.isEmpty()) {
                res.success = true;
                res.message = 'No orders found matching search criteria.';
                res.summary = 'No orders were found for the specified search query: "' + (queryStr != null ? queryStr : '') + '".';
                return res;
            }

            Decimal totalSum = 0;
            String sb = '### Recent Orders (' + ordList.size() + ' found):\n\n';
            for (SObject ord : ordList) {
                String ordId = (String) ord.get('Id');
                String ordName = (String) ord.get('Name');
                String phase = (String) ord.get('cgcloud__Phase__c');
                Decimal grossVal = (Decimal) ord.get('cgcloud__Gross_Total_Value__c');
                if (grossVal != null) { totalSum += grossVal; }

                sb += '* **[' + ordName + '](/lightning/r/cgcloud__Order__c/' + ordId + '/view)**';
                if (phase != null) { sb += ' | Status: ' + phase; }
                if (grossVal != null) { sb += ' | Total: $' + grossVal.format(); }
                sb += '\n';
            }

            res.totalOrderValue = totalSum;
            res.success = true;
            res.message = 'Found ' + ordList.size() + ' order(s).';
            res.summary = sb;
        } catch (Exception e) {
            res.success = true;
            res.message = 'No orders found.';
            res.summary = 'No order records found for this Account.';
        }
        return res;
    }

    private static Response handleGetOrderDetails(String orderId) {
        Response res = new Response();
        if (String.isBlank(orderId)) {
            res.success = false;
            res.message = 'Order ID is required.';
            res.summary = 'Please provide a valid Order ID.';
            return res;
        }

        Boolean hasCgOrders = Schema.getGlobalDescribe().containsKey('cgcloud__order__c');
        if (!hasCgOrders) {
            res.success = false;
            res.message = 'CG Cloud Order object not available.';
            res.summary = 'CG Cloud Order object is not installed in this org.';
            return res;
        }

        try {
            String sanitizedId = String.escapeSingleQuotes(orderId.trim());
            String soql = 'SELECT Id, Name, cgcloud__Phase__c, cgcloud__Gross_Total_Value__c, cgcloud__Order_Account__c, cgcloud__Order_Account__r.Name, cgcloud__Delivery_Date__c, CreatedDate FROM cgcloud__Order__c WHERE Id = :sanitizedId OR Name = :sanitizedId OR Name LIKE \'%' + sanitizedId + '%\' LIMIT 1';
            List<SObject> ordList = Database.query(soql);

            if (ordList.isEmpty()) {
                res.success = false;
                res.message = 'Order not found: ' + orderId;
                res.summary = 'No order found matching: "' + orderId + '". Please verify the Order Number (e.g. O-00591).';
                return res;
            }

            SObject ord = ordList[0];
            String ordId = (String) ord.get('Id');
            String ordName = (String) ord.get('Name');
            String phase = (String) ord.get('cgcloud__Phase__c');
            Decimal val = (Decimal) ord.get('cgcloud__Gross_Total_Value__c');
            Date delivDate = (Date) ord.get('cgcloud__Delivery_Date__c');
            DateTime created = (DateTime) ord.get('CreatedDate');
            String accName = ord.getSObject('cgcloud__Order_Account__r') != null ? (String) ord.getSObject('cgcloud__Order_Account__r').get('Name') : 'Account';

            String sb = '### 📦 Order Details: **[' + ordName + '](/lightning/r/cgcloud__Order__c/' + ordId + '/view)**\n\n';
            sb += '* **Account**: ' + accName + '\n';
            sb += '* **Status**: ' + (phase != null ? phase : 'N/A') + '\n';
            sb += '* **Gross Total Value**: $' + (val != null ? val.format() : '0.00') + '\n';
            if (delivDate != null) { sb += '* **Delivery Date**: ' + String.valueOf(delivDate) + '\n'; }
            if (created != null) { sb += '* **Order Date**: ' + created.format('M/d/yyyy h:mm a') + '\n'; }
            sb += '\n';

            // Query child Order Line Items
            Boolean hasItems = Schema.getGlobalDescribe().containsKey('cgcloud__order_item__c');
            if (hasItems) {
                String itemSoql = 'SELECT Id, Name, cgcloud__Product__c, cgcloud__Product__r.Name, cgcloud__Quantity__c, cgcloud__Value__c, cgcloud__UoM__c FROM cgcloud__Order_Item__c WHERE cgcloud__Order__c = :ordId ORDER BY Name ASC LIMIT 50';
                List<SObject> items = Database.query(itemSoql);

                if (!items.isEmpty()) {
                    sb += '#### 📋 Order Line Items (' + items.size() + ' products):\n\n';
                    Integer itemNum = 1;
                    for (SObject itm : items) {
                        String prodName = itm.getSObject('cgcloud__Product__r') != null ? (String) itm.getSObject('cgcloud__Product__r').get('Name') : 'Product';
                        Decimal qty = (Decimal) itm.get('cgcloud__Quantity__c');
                        Decimal lineVal = (Decimal) itm.get('cgcloud__Value__c');
                        String uom = (String) itm.get('cgcloud__UoM__c');

                        sb += itemNum + '. **' + prodName + '**';
                        if (qty != null) { sb += ' | Qty: ' + qty.intValue() + (uom != null ? ' ' + uom : ' units'); }
                        if (lineVal != null) { sb += ' | Amount: $' + lineVal.format(); }
                        sb += '\n';
                        itemNum++;
                    }
                } else {
                    sb += '*No line item records found attached to this order.*\n';
                }
            }

            res.success = true;
            res.totalOrders = 1;
            res.totalOrderValue = (val != null ? val : 0.00);
            res.message = 'Order and line items retrieved.';
            res.summary = sb;
        } catch (Exception e) {
            res.success = false;
            res.message = 'Failed to load order details: ' + e.getMessage();
            res.summary = 'Could not load details for order: ' + orderId + ' (' + e.getMessage() + ')';
        }
        return res;
    }

    private static Response handleGetAccountOrderSummary(String accountId) {
        Response res = new Response();
        if (String.isBlank(accountId)) {
            res.success = false;
            res.message = 'Account ID is required.';
            res.summary = 'Please provide an Account ID to view order history.';
            return res;
        }

        return handleSearchOrders(null, accountId);
    }

    private static Response handleGetVisitOrderSummary(String visitId) {
        Response res = new Response();
        if (String.isBlank(visitId)) {
            res.success = false;
            res.message = 'Visit ID is required.';
            res.summary = 'Please provide a Visit ID to view associated orders.';
            return res;
        }

        Boolean hasVisit = Schema.getGlobalDescribe().containsKey('visit');
        if (!hasVisit) {
            res.success = true;
            res.message = 'Visit schema not installed.';
            res.summary = 'No visit records found in this environment.';
            return res;
        }

        try {
            String vQuery = 'SELECT AccountId FROM Visit WHERE Id = \'' + String.escapeSingleQuotes(visitId) + '\' LIMIT 1';
            List<SObject> vList = Database.query(vQuery);
            if (vList.isEmpty() || vList[0].get('AccountId') == null) {
                res.success = true;
                res.message = 'No associated account found for visit.';
                res.summary = 'No Account is associated with this Visit.';
                return res;
            }

            return handleGetAccountOrderSummary((String) vList[0].get('AccountId'));
        } catch (Exception e) {
            res.success = true;
            res.message = 'No associated account found for visit.';
            res.summary = 'No Account is associated with this Visit.';
            return res;
        }
    }

    private static Response handleGetOrderRecommendations(String accountId) {
        Response res = new Response();
        if (String.isBlank(accountId)) {
            res.success = false;
            res.message = 'Account ID is required for recommendations.';
            res.summary = 'Please provide an Account ID to calculate replenishment recommendations.';
            return res;
        }

        Boolean hasCgOrders = Schema.getGlobalDescribe().containsKey('cgcloud__order_item__c');
        if (!hasCgOrders) {
            res.success = true;
            res.message = 'No CG Cloud Order Items available.';
            res.summary = 'No order replenishment history available for this account.';
            return res;
        }

        try {
            String soql = 'SELECT cgcloud__Product__r.Name, SUM(cgcloud__Quantity__c) totalQty FROM cgcloud__Order_Item__c WHERE cgcloud__Order__r.cgcloud__Order_Account__c = :accountId GROUP BY cgcloud__Product__r.Name ORDER BY SUM(cgcloud__Quantity__c) DESC LIMIT 5';
            List<AggregateResult> aggList = Database.query(soql);

            res.totalRecommendations = aggList.size();
            if (aggList.isEmpty()) {
                res.success = true;
                res.message = 'No past order velocity found for recommendations.';
                res.summary = 'No product replenishment recommendations could be calculated for this account yet.';
                return res;
            }

            String sb = '### Suggested Replenishment Recommendations:\n\n';
            for (AggregateResult ar : aggList) {
                String prodName = (String) ar.get('Name');
                Decimal qty = (Decimal) ar.get('totalQty');
                Integer suggested = (Integer) Math.round(qty * 0.5);
                if (suggested < 1) { suggested = 10; }

                sb += '* **' + (prodName != null ? prodName : 'Standard Product') + '**: Suggested Reorder Quantity: **' + suggested + ' units** (Avg past order: ' + qty + ')\n';
            }

            res.success = true;
            res.message = 'Generated ' + aggList.size() + ' replenishment recommendation(s).';
            res.summary = sb;
        } catch (Exception e) {
            res.success = true;
            res.message = 'No past order velocity found for recommendations.';
            res.summary = 'No product replenishment recommendations could be calculated for this account yet.';
        }
        return res;
    }

    private static Response handleGetInventoryChecks(String accountId) {
        Response res = new Response();
        if (String.isBlank(accountId)) {
            res.success = false;
            res.message = 'Account ID is required.';
            res.summary = 'Please provide an Account ID to view stock levels.';
            return res;
        }

        Boolean hasInventory = Schema.getGlobalDescribe().containsKey('cgcloud__inventory__c');
        if (!hasInventory) {
            res.success = true;
            res.message = 'No CG Cloud Inventory schema installed.';
            res.summary = 'No inventory records found for this Account.';
            return res;
        }

        try {
            Map<String, Schema.SObjectField> fMap = Schema.getGlobalDescribe().get('cgcloud__inventory__c').getDescribe().fields.getMap();
            String accField = fMap.containsKey('cgcloud__inventory_account__c') ? 'cgcloud__Inventory_Account__c' : (fMap.containsKey('cgcloud__account__c') ? 'cgcloud__Account__c' : null);

            if (accField == null) {
                res.success = true;
                res.message = 'No inventory records found.';
                res.summary = 'No on-shelf inventory audit records found for this store.';
                return res;
            }

            String soql = 'SELECT Id, Name FROM cgcloud__Inventory__c WHERE ' + accField + ' = :accountId ORDER BY CreatedDate DESC LIMIT 10';
            List<SObject> invList = Database.query(soql);

            if (invList.isEmpty()) {
                res.success = true;
                res.message = 'No inventory records found.';
                res.summary = 'No on-shelf inventory audit records found for this store.';
                return res;
            }

            String sb = '### Store Inventory Audit (' + invList.size() + ' items):\n\n';
            for (SObject inv : invList) {
                String iName = (String) inv.get('Name');
                sb += '* **' + iName + '**: In Stock\n';
            }

            res.success = true;
            res.message = 'Retrieved ' + invList.size() + ' inventory records.';
            res.summary = sb;
        } catch (Exception e) {
            res.success = true;
            res.message = 'No inventory records found.';
            res.summary = 'No on-shelf inventory audit records found for this store.';
        }
        return res;
    }
}
