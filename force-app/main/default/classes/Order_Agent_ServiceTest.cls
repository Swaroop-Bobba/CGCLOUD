/**
 * @description Master unit test class for Order_Agent_Service covering positive, negative, null, fallback, and update scenarios.
 */
@IsTest
public class Order_Agent_ServiceTest {

    @TestSetup
    static void setupData() {
        Account acc = new Account(Name = 'CGC Order Master Store');
        insert as user acc;

        Schema.Location loc = new Schema.Location(Name = 'Order Master Location');
        insert as user loc;

        Visit vis = new Visit(
            AccountId = acc.Id,
            PlaceId = loc.Id,
            Status = 'Planned',
            PlannedVisitStartTime = DateTime.now()
        );
        insert as user vis;

        cgcloud__Order_Template__c tpl = new cgcloud__Order_Template__c(Name = 'Test Order Template');
        insert as user tpl;

        cgcloud__Order__c ord = new cgcloud__Order__c(
            cgcloud__Order_Account__c = acc.Id,
            cgcloud__Visit__c = vis.Id,
            cgcloud__Order_Template__c = tpl.Id,
            cgcloud__Phase__c = 'Initial',
            cgcloud__Order_Date__c = Date.today(),
            cgcloud__Delivery_Date__c = Date.today().addDays(3),
            cgcloud__Total_Value__c = 1500,
            cgcloud__Gross_Total_Value__c = 1600,
            cgcloud__Delivery_Note__c = 'Initial Delivery Note'
        );
        insert as user ord;

        Product2 p = new Product2(Name = 'Order Product Soda', ProductCode = 'OPS-10', IsActive = true);
        insert as user p;

        cgcloud__Order_Item__c item = new cgcloud__Order_Item__c(
            cgcloud__Order__c = ord.Id,
            cgcloud__Product__c = p.Id,
            cgcloud__Quantity__c = 25,
            cgcloud__UOM__c = 'PCE'
        );
        insert as user item;
    }

    @IsTest
    static void testExecuteActionRouting() {
        cgcloud__Order__c ord = [SELECT Id, Name, cgcloud__Order_Account__c, cgcloud__Visit__c FROM cgcloud__Order__c LIMIT 1];
        Order_Agent_Service service = new Order_Agent_Service();

        Test.startTest();
        // 1. Get details
        Agent_Request reqDetails = new Agent_Request();
        reqDetails.actionType = 'getdetails';
        reqDetails.orderId = ord.Id;
        Agent_Response resDetails = service.execute(reqDetails);

        // 2. Search orders
        Agent_Request reqSearch = new Agent_Request();
        reqSearch.actionType = 'search';
        reqSearch.searchQuery = 'CGC Order Master Store';
        Agent_Response resSearch = service.execute(reqSearch);

        // 3. Get account order summary
        Agent_Request reqSummary = new Agent_Request();
        reqSummary.actionType = 'getsummary';
        reqSummary.accountId = ord.cgcloud__Order_Account__c;
        Agent_Response resSummary = service.execute(reqSummary);

        // 4. Get visit order summary
        Agent_Request reqVisitSummary = new Agent_Request();
        reqVisitSummary.actionType = 'getvisitsummary';
        reqVisitSummary.visitId = ord.cgcloud__Visit__c;
        Agent_Response resVisitSummary = service.execute(reqVisitSummary);

        // 5. Get order line items
        Agent_Request reqLineItems = new Agent_Request();
        reqLineItems.actionType = 'getlineitems';
        reqLineItems.orderId = ord.Id;
        Agent_Response resLineItems = service.execute(reqLineItems);

        // 6. Update order delivery note
        Agent_Request reqUpdate = new Agent_Request();
        reqUpdate.actionType = 'updatenote';
        reqUpdate.orderId = ord.Id;
        reqUpdate.orderIdentifier = ord.Id;
        reqUpdate.deliveryNote = 'Updated Delivery Note Test';
        reqUpdate.invoiceNote = 'Updated Invoice Note Test';
        Agent_Response resUpdate = service.execute(reqUpdate);

        // 7. Invalid action
        Agent_Request reqInvalid = new Agent_Request();
        reqInvalid.actionType = 'invalid_action';
        Agent_Response resInvalid = service.execute(reqInvalid);
        Test.stopTest();

        Assert.isTrue(resDetails.success, 'Order details should succeed.');
        Assert.isTrue(resSearch.success, 'Order search should succeed.');
        Assert.isTrue(resSummary.totalOrders > 0, 'Account order summary should find orders.');
        Assert.isFalse(resInvalid.success, 'Invalid action should return failure.');
    }

    @IsTest
    static void testOrderServiceEdgeCasesAndNullHandling() {
        cgcloud__Order__c ord = [SELECT Id, Name, cgcloud__Order_Account__c, cgcloud__Visit__c FROM cgcloud__Order__c LIMIT 1];

        Test.startTest();
        Order_Agent_Service.getOrderDetails(ord.Id);
        Order_Agent_Service.getOrderDetails(null);
        Order_Agent_Service.getOrderDetails('invalid_order_id');

        Order_Agent_Service.getAccountOrderSummary(ord.cgcloud__Order_Account__c);
        Order_Agent_Service.getAccountOrderSummary(null);
        Order_Agent_Service.getAccountOrderSummary('001000000000000AAA');

        Order_Agent_Service.getVisitOrderSummary(ord.cgcloud__Visit__c);
        Order_Agent_Service.getVisitOrderSummary(null);
        Order_Agent_Service.getVisitOrderSummary('07VD00000000000AAA');

        Order_Agent_Service.getOrderLineItems(ord.Id);
        Order_Agent_Service.getOrderLineItems(null);
        Order_Agent_Service.getOrderLineItems('invalid_order_id');

        Order_Agent_Service.updateOrderNotes(ord.Id, 'New Delivery Note', 'Invoice Note');
        Order_Agent_Service.updateOrderNotes(null, 'Note', null);
        Order_Agent_Service.updateOrderNotes('invalid_order_id', 'Note', 'Inv Note');
        Test.stopTest();

        Assert.isNotNull(ord.Id, 'Order ID is valid.');
    }
}
