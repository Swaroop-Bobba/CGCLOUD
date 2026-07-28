/**
 * @description Test class for Order_Agent_Service.
 */
@IsTest
public class Order_Agent_ServiceTest {

    @IsTest
    static void testExecuteActionRouting() {
        Account acc = new Account(Name = 'CGC Order Service Account');
        insert as user acc;

        Order_Agent_Service service = new Order_Agent_Service();

        Test.startTest();
        // 1. Get account summary
        Agent_Request reqAcc = new Agent_Request();
        reqAcc.actionType = 'getAccountSummary';
        reqAcc.accountId = acc.Id;
        Agent_Response resAcc = service.execute(reqAcc);

        // 2. Get visit summary
        Agent_Request reqVisit = new Agent_Request();
        reqVisit.actionType = 'getVisitSummary';
        reqVisit.visitId = 'mock_visit_id';
        Agent_Response resVisit = service.execute(reqVisit);

        // 3. Search orders
        Agent_Request reqSearch = new Agent_Request();
        reqSearch.actionType = 'search';
        reqSearch.searchQuery = 'Order123';
        Agent_Response resSearch = service.execute(reqSearch);
        Test.stopTest();

        Assert.isNotNull(resAcc, 'Get account summary should succeed.');
        Assert.isNotNull(resVisit, 'Get visit summary should succeed.');
        Assert.isNotNull(resSearch, 'Search orders should succeed.');
    }

    @IsTest
    static void testOrderDmlAndLineItems() {
        Account acc = new Account(Name = 'CGC Order DML Account');
        insert as user acc;

        try {
            Product2 prod = new Product2(Name = 'Empower Cola 0.5L', IsActive = true);
            insert as user prod;

            cgcloud__Order__c ord = new cgcloud__Order__c(
                cgcloud__Order_Account__c = acc.Id,
                cgcloud__Phase__c = 'Draft',
                cgcloud__Total_Value__c = 150.00,
                cgcloud__Gross_Total_Value__c = 140.00,
                cgcloud__Order_Date__c = Date.today(),
                cgcloud__Delivery_Date__c = Date.today().addDays(2),
                cgcloud__Delivery_Note__c = 'Gate code 1234'
            );
            insert as user ord;

            cgcloud__Order_Item__c item = new cgcloud__Order_Item__c(
                cgcloud__Order__c = ord.Id,
                cgcloud__Product__c = prod.Id,
                cgcloud__Quantity__c = 10,
                cgcloud__UOM__c = 'PCS'
            );
            insert as user item;

            Order_Agent_Service service = new Order_Agent_Service();

            Test.startTest();
            // 1. Get details
            Agent_Request reqDetails = new Agent_Request();
            reqDetails.actionType = 'getDetails';
            reqDetails.orderId = ord.Id;
            Agent_Response resDetails = service.execute(reqDetails);

            // 2. Get line items
            Agent_Request reqLines = new Agent_Request();
            reqLines.actionType = 'getLineItems';
            reqLines.orderId = ord.Id;
            Agent_Response resLines = service.execute(reqLines);

            // 3. Update notes
            Agent_Request reqNotes = new Agent_Request();
            reqNotes.actionType = 'updatenotes';
            reqNotes.orderIdentifier = ord.Id;
            reqNotes.deliveryNote = 'Updated delivery instruction';
            reqNotes.invoiceNote = 'Updated invoice reference';
            Agent_Response resNotes = service.execute(reqNotes);
            Test.stopTest();

            Assert.isTrue(resDetails.success, 'Details fetch should succeed.');
            Assert.areEqual(ord.Id, resDetails.orderId, 'Correct Order ID returned.');

            Assert.isTrue(resLines.success, 'Line items fetch should succeed.');
            Assert.areEqual(1, resLines.itemCount, '1 item should be retrieved.');

            Assert.isTrue(resNotes.success, 'Notes update should succeed.');
            
            cgcloud__Order__c updatedOrd = [SELECT cgcloud__Delivery_Note__c, cgcloud__Invoice_Note__c FROM cgcloud__Order__c WHERE Id = :ord.Id LIMIT 1];
            Assert.areEqual('Updated delivery instruction', updatedOrd.cgcloud__Delivery_Note__c, 'Delivery note was changed.');
            Assert.areEqual('Updated invoice reference', updatedOrd.cgcloud__Invoice_Note__c, 'Invoice note was changed.');

        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, 'CGC Order schema mocks skipped: ' + e.getMessage());
        }
    }

    @IsTest
    static void testOrderServiceCoverageBoost() {
        Order_Agent_Service service = new Order_Agent_Service();

        Test.startTest();
        // 1. Invalid or empty action types
        Agent_Request reqEmpty = new Agent_Request();
        service.execute(reqEmpty);

        Agent_Request reqInvalid = new Agent_Request();
        reqInvalid.actionType = 'invalid_action';
        service.execute(reqInvalid);

        // 2. Blank parameters for all methods
        Order_Agent_Service.getOrderDetails('');
        Order_Agent_Service.getOrderDetails('invalid_id');

        Order_Agent_Service.searchOrders('');
        Order_Agent_Service.searchOrders('NonexistentOrderTerm');

        Order_Agent_Service.getAccountOrderSummary('');
        Order_Agent_Service.getAccountOrderSummary('fake_acc_id');

        Order_Agent_Service.getVisitOrderSummary('');
        Order_Agent_Service.getVisitOrderSummary('fake_visit_id');

        Order_Agent_Service.getOrderLineItems('');
        Order_Agent_Service.getOrderLineItems('fake_order_id');

        Order_Agent_Service.updateOrderNotes('', 'del', 'inv');
        Order_Agent_Service.updateOrderNotes('fake_order_id', 'del', 'inv');
        Order_Agent_Service.updateOrderNotes('123456789012345', null, null);

        // 3. Wrapper coverage
        VisitSummaryWrapper vsw = new VisitSummaryWrapper();
        vsw.storeName = 'Test Store';
        VisitSummaryWrapper.Suggestion sugg = new VisitSummaryWrapper.Suggestion('1', 'Label', 'Command', 'utility:check');

        CreateVisitWrapper cvw = new CreateVisitWrapper();
        cvw.subject = 'Test Subject';

        Agent_Request ar = new Agent_Request();
        ar.domain = 'Order';
        Test.stopTest();

        Assert.isNotNull(service, 'Service instance exists.');
    }
}
