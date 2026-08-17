@IsTest
private class Order_Agent_HandlerTest {

    @TestSetup
    static void setupData() {
        Account acc = new Account(
            Name = 'CGC Metro Market',
            BillingStreet = '123 Market St',
            BillingCity = 'San Francisco',
            BillingState = 'CA'
        );
        insert acc;

        String vId = null;
        if (Schema.getGlobalDescribe().containsKey('visit')) {
            SObject v = Schema.getGlobalDescribe().get('Visit').newSObject();
            v.put('AccountId', acc.Id);
            if (Schema.getGlobalDescribe().containsKey('location')) {
                Schema.Location loc = new Schema.Location(Name = 'Test Order Location');
                insert loc;
                v.put('PlaceId', loc.Id);
            }
            v.put('PlannedVisitStartTime', Datetime.now());
            v.put('Status', 'Planned');
            Database.insert(v, AccessLevel.USER_MODE);
            vId = (String) v.get('Id');

            SObject vNoAcc = Schema.getGlobalDescribe().get('Visit').newSObject();
            vNoAcc.put('PlannedVisitStartTime', Datetime.now());
            vNoAcc.put('Status', 'Planned');
            if (Schema.getGlobalDescribe().containsKey('location')) {
                List<SObject> locs = Database.query('SELECT Id FROM Location LIMIT 1');
                if (!locs.isEmpty()) { vNoAcc.put('PlaceId', (String) locs[0].get('Id')); }
            }
            try { Database.insert(vNoAcc, AccessLevel.USER_MODE); } catch (Exception e) {}
        }

        String ordId = null;
        if (Schema.getGlobalDescribe().containsKey('cgcloud__order__c')) {
            try {
                String templId = null;
                if (Schema.getGlobalDescribe().containsKey('cgcloud__order_template__c')) {
                    SObject ot = Schema.getGlobalDescribe().get('cgcloud__order_template__c').newSObject();
                    ot.put('Name', 'Test Order Template');
                    Database.insert(ot, AccessLevel.USER_MODE);
                    templId = (String) ot.get('Id');
                }

                SObject ord = Schema.getGlobalDescribe().get('cgcloud__order__c').newSObject();
                ord.put('cgcloud__Order_Account__c', acc.Id);
                ord.put('cgcloud__Phase__c', 'Ready');
                ord.put('cgcloud__Gross_Total_Value__c', 250.00);
                ord.put('cgcloud__Delivery_Date__c', Date.today().addDays(3));
                Map<String, Schema.SObjectField> ordFields = Schema.getGlobalDescribe().get('cgcloud__order__c').getDescribe().fields.getMap();
                if (templId != null && ordFields.containsKey('cgcloud__order_template__c')) {
                    ord.put('cgcloud__Order_Template__c', templId);
                }
                if (ordFields.containsKey('cgcloud__initiation_date__c')) {
                    ord.put('cgcloud__Initiation_Date__c', Date.today());
                }
                Database.insert(ord, AccessLevel.USER_MODE);
                ordId = (String) ord.get('Id');

                Product2 prod = new Product2(Name = 'Test Reorder Product', IsActive = true);
                insert prod;

                if (Schema.getGlobalDescribe().containsKey('cgcloud__order_item__c')) {
                    SObject itm = Schema.getGlobalDescribe().get('cgcloud__order_item__c').newSObject();
                    itm.put('cgcloud__Order__c', ordId);
                    itm.put('cgcloud__Product__c', prod.Id);
                    itm.put('cgcloud__Quantity__c', 25);
                    itm.put('cgcloud__Value__c', 125.00);
                    itm.put('cgcloud__UoM__c', 'SalesUnit');
                    Database.insert(itm, AccessLevel.USER_MODE);
                }
            } catch (Exception e) {
                System.debug(LoggingLevel.WARN, 'Order setup warning: ' + e.getMessage());
            }
        }

        if (Schema.getGlobalDescribe().containsKey('cgcloud__inventory__c')) {
            try {
                SObject inv = Schema.getGlobalDescribe().get('cgcloud__inventory__c').newSObject();
                inv.put('Name', 'Test Stock Audit');
                Map<String, Schema.SObjectField> invFields = Schema.getGlobalDescribe().get('cgcloud__inventory__c').getDescribe().fields.getMap();
                if (invFields.containsKey('cgcloud__inventory_account__c')) {
                    inv.put('cgcloud__Inventory_Account__c', acc.Id);
                } else if (invFields.containsKey('cgcloud__account__c')) {
                    inv.put('cgcloud__Account__c', acc.Id);
                }
                Database.insert(inv, AccessLevel.USER_MODE);
            } catch (Exception e) {}
        }
    }

    @IsTest
    static void testSearchOrders() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'CGC Metro Market' LIMIT 1];

        // 1. Search with account and matching phase
        Order_Agent_Handler.Request req1 = new Order_Agent_Handler.Request();
        req1.actionType = 'search';
        req1.accountId = acc.Id;
        req1.searchQuery = 'Ready';

        // 2. Search with account and non-existent query (empty branch)
        Order_Agent_Handler.Request req2 = new Order_Agent_Handler.Request();
        req2.actionType = 'search_orders';
        req2.accountId = acc.Id;
        req2.searchQuery = 'NonExistentOrderXYZ';

        // 3. Search with no query (get orders by account)
        Order_Agent_Handler.Request req3 = new Order_Agent_Handler.Request();
        req3.actionType = 'getorders';
        req3.accountId = acc.Id;

        // 4. Search with no account and no query (all orders)
        Order_Agent_Handler.Request req4 = new Order_Agent_Handler.Request();
        req4.actionType = 'get_orders';

        // 5. Search with no account but matching query
        Order_Agent_Handler.Request req5 = new Order_Agent_Handler.Request();
        req5.actionType = 'searchorders';
        req5.searchQuery = 'Ready';

        Test.startTest();
        List<Order_Agent_Handler.Response> resList = Order_Agent_Handler.execute(
            new List<Order_Agent_Handler.Request>{ req1, req2, req3, req4, req5 }
        );
        Test.stopTest();

        Assert.areEqual(5, resList.size(), 'Expected 5 responses');
        Assert.isTrue(resList[0].success, 'Expected search to succeed');
        Assert.isTrue(resList[1].success, 'Expected empty search to succeed');
    }

    @IsTest
    static void testGetOrderDetails() {
        String existingOrdId = null;
        String existingOrdName = null;
        if (Schema.getGlobalDescribe().containsKey('cgcloud__order__c')) {
            List<SObject> ordList = Database.query('SELECT Id, Name FROM cgcloud__Order__c LIMIT 1');
            if (!ordList.isEmpty()) {
                existingOrdId = (String) ordList[0].get('Id');
                existingOrdName = (String) ordList[0].get('Name');
            }
        }

        Order_Agent_Handler.Request reqBlank = new Order_Agent_Handler.Request();
        reqBlank.actionType = 'getOrderDetails';
        reqBlank.orderId = '';

        Order_Agent_Handler.Request reqNotFound = new Order_Agent_Handler.Request();
        reqNotFound.actionType = 'get_order_details';
        reqNotFound.orderId = '001000000000000AAA';

        List<Order_Agent_Handler.Request> reqList = new List<Order_Agent_Handler.Request>{ reqBlank, reqNotFound };

        if (existingOrdId != null) {
            Order_Agent_Handler.Request reqExisting = new Order_Agent_Handler.Request();
            reqExisting.actionType = 'getlineitems';
            reqExisting.orderId = existingOrdId;
            reqList.add(reqExisting);

            Order_Agent_Handler.Request reqByName = new Order_Agent_Handler.Request();
            reqByName.actionType = 'getdetails';
            reqByName.orderId = existingOrdName;
            reqList.add(reqByName);

            Order_Agent_Handler.Request reqOrderItems = new Order_Agent_Handler.Request();
            reqOrderItems.actionType = 'order_line_items';
            reqOrderItems.orderId = existingOrdId;
            reqList.add(reqOrderItems);

            Order_Agent_Handler.Request reqLineItemsAlias = new Order_Agent_Handler.Request();
            reqLineItemsAlias.actionType = 'get_line_items';
            reqLineItemsAlias.orderId = existingOrdId;
            reqList.add(reqLineItemsAlias);
        }

        Test.startTest();
        List<Order_Agent_Handler.Response> resList = Order_Agent_Handler.execute(reqList);
        Test.stopTest();

        Assert.isFalse(resList[0].success, 'Blank Order ID should fail');
        Assert.isFalse(resList[1].success, 'Non-existent Order ID should fail');
        if (existingOrdId != null) {
            Assert.isTrue(resList[2].success, 'Existing Order should load successfully');
            Assert.isTrue(resList[3].success, 'Order by Name should load successfully');
        }
    }

    @IsTest
    static void testGetAccountAndVisitOrderSummary() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'CGC Metro Market' LIMIT 1];
        String vId = 'fakeVisitId';
        String vNoAccId = 'fakeNoAcc';
        if (Schema.getGlobalDescribe().containsKey('visit')) {
            List<SObject> vList = Database.query('SELECT Id, AccountId FROM Visit WHERE AccountId != null LIMIT 1');
            if (!vList.isEmpty()) { vId = (String) vList[0].get('Id'); }
            List<SObject> vNoList = Database.query('SELECT Id FROM Visit WHERE AccountId = null LIMIT 1');
            if (!vNoList.isEmpty()) { vNoAccId = (String) vNoList[0].get('Id'); }
        }

        Order_Agent_Handler.Request reqAcc = new Order_Agent_Handler.Request();
        reqAcc.actionType = 'getAccountOrderSummary';
        reqAcc.accountId = acc.Id;

        Order_Agent_Handler.Request reqAccAlias = new Order_Agent_Handler.Request();
        reqAccAlias.actionType = 'getaccountsummary';
        reqAccAlias.accountId = acc.Id;

        Order_Agent_Handler.Request reqAccBlank = new Order_Agent_Handler.Request();
        reqAccBlank.actionType = 'get_account_order_summary';
        reqAccBlank.accountId = '';

        Order_Agent_Handler.Request reqVisit = new Order_Agent_Handler.Request();
        reqVisit.actionType = 'getVisitOrderSummary';
        reqVisit.visitId = vId;

        Order_Agent_Handler.Request reqVisitAlias = new Order_Agent_Handler.Request();
        reqVisitAlias.actionType = 'getvisitsummary';
        reqVisitAlias.visitId = vId;

        Order_Agent_Handler.Request reqVisitBlank = new Order_Agent_Handler.Request();
        reqVisitBlank.actionType = 'get_visit_order_summary';
        reqVisitBlank.visitId = '';

        Order_Agent_Handler.Request reqVisitNoAcc = new Order_Agent_Handler.Request();
        reqVisitNoAcc.actionType = 'get_visit_summary';
        reqVisitNoAcc.visitId = vNoAccId;

        Order_Agent_Handler.Request reqVisitInvalid = new Order_Agent_Handler.Request();
        reqVisitInvalid.actionType = 'getvisitordersummary';
        reqVisitInvalid.visitId = 'fakeInvalidVisitId123';

        Test.startTest();
        List<Order_Agent_Handler.Response> resList = Order_Agent_Handler.execute(
            new List<Order_Agent_Handler.Request>{ reqAcc, reqAccAlias, reqAccBlank, reqVisit, reqVisitAlias, reqVisitBlank, reqVisitNoAcc, reqVisitInvalid }
        );
        Test.stopTest();

        Assert.isTrue(resList[0].success, 'Account order summary should succeed');
        Assert.isFalse(resList[2].success, 'Blank account order summary should fail');
        Assert.isFalse(resList[5].success, 'Blank visit order summary should fail');
    }

    @IsTest
    static void testGetRecommendationsAndInventory() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'CGC Metro Market' LIMIT 1];
        Account emptyAcc = new Account(Name = 'Empty Test Account');
        insert emptyAcc;

        Order_Agent_Handler.Request reqRec = new Order_Agent_Handler.Request();
        reqRec.actionType = 'suggestProducts';
        reqRec.accountId = acc.Id;

        Order_Agent_Handler.Request reqRecAlias = new Order_Agent_Handler.Request();
        reqRecAlias.actionType = 'getorderrecommendations';
        reqRecAlias.accountId = acc.Id;

        Order_Agent_Handler.Request reqRecAlias2 = new Order_Agent_Handler.Request();
        reqRecAlias2.actionType = 'getrecommendations';
        reqRecAlias2.accountId = acc.Id;

        Order_Agent_Handler.Request reqRecAlias3 = new Order_Agent_Handler.Request();
        reqRecAlias3.actionType = 'suggest_products';
        reqRecAlias3.accountId = acc.Id;

        Order_Agent_Handler.Request reqRecEmpty = new Order_Agent_Handler.Request();
        reqRecEmpty.actionType = 'get_order_recommendations';
        reqRecEmpty.accountId = emptyAcc.Id;

        Order_Agent_Handler.Request reqRecBlank = new Order_Agent_Handler.Request();
        reqRecBlank.actionType = 'get_order_recommendations';
        reqRecBlank.accountId = '';

        Order_Agent_Handler.Request reqInv = new Order_Agent_Handler.Request();
        reqInv.actionType = 'getInventoryChecks';
        reqInv.accountId = acc.Id;

        Order_Agent_Handler.Request reqInvAlias = new Order_Agent_Handler.Request();
        reqInvAlias.actionType = 'getinventory';
        reqInvAlias.accountId = acc.Id;

        Order_Agent_Handler.Request reqInvAlias2 = new Order_Agent_Handler.Request();
        reqInvAlias2.actionType = 'get_inventory_checks';
        reqInvAlias2.accountId = acc.Id;

        Order_Agent_Handler.Request reqInvBlank = new Order_Agent_Handler.Request();
        reqInvBlank.actionType = 'get_inventory_checks';
        reqInvBlank.accountId = '';

        Test.startTest();
        List<Order_Agent_Handler.Response> resList = Order_Agent_Handler.execute(
            new List<Order_Agent_Handler.Request>{ reqRec, reqRecAlias, reqRecAlias2, reqRecAlias3, reqRecEmpty, reqRecBlank, reqInv, reqInvAlias, reqInvAlias2, reqInvBlank }
        );
        Test.stopTest();

        Assert.isTrue(resList[0].success, 'Recommendations should succeed');
        Assert.isTrue(resList[4].success, 'Empty recommendations account should succeed with empty result');
        Assert.isFalse(resList[5].success, 'Blank recommendations account should fail');
        Assert.isTrue(resList[6].success, 'Inventory checks should succeed');
        Assert.isFalse(resList[9].success, 'Blank inventory account should fail');
    }

    @IsTest
    static void testUnknownActionAndConstructors() {
        Order_Agent_Handler handler = new Order_Agent_Handler();
        Assert.isNotNull(handler, 'Constructor should succeed');

        Order_Agent_Handler.Request req = new Order_Agent_Handler.Request();
        req.actionType = 'unsupportedActionType';
        req.searchQuery = 'DefaultFallback';
        req.agentName = 'VisitIntelligence';
        req.domain = 'Order';
        req.deliveryNote = 'Test note';
        req.invoiceNote = 'Invoice note';
        req.orderIdentifier = 'ORD-001';

        Test.startTest();
        List<Order_Agent_Handler.Response> resList = Order_Agent_Handler.execute(
            new List<Order_Agent_Handler.Request>{ req }
        );
        Test.stopTest();

        Assert.areEqual(1, resList.size(), 'Expected 1 response');
        Assert.isTrue(resList[0].success, 'Fallback action should succeed');
    }
}
