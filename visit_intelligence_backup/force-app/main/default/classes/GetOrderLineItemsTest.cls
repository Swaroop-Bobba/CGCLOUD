@IsTest
private class GetOrderLineItemsTest {

    @IsTest
    static void testExecuteWithFakeOrderId() {
        // Test with a non-existent order ID — should hit try/catch
        GetOrderLineItems.Request req = new GetOrderLineItems.Request();
        req.orderId = 'a0B000000000000AAA'; // Fake ID

        List<GetOrderLineItems.Result> results = 
            GetOrderLineItems.execute(new List<GetOrderLineItems.Request>{ req });

        System.assertEquals(1, results.size(), 'Should return exactly one result');
        System.assertNotEquals(null, results[0].itemsSummary, 'Items summary should not be null');
        System.assertNotEquals(null, results[0].itemCount, 'Item count should not be null');
    }

    @IsTest
    static void testMultipleRequests() {
        GetOrderLineItems.Request req1 = new GetOrderLineItems.Request();
        req1.orderId = 'a0B000000000001AAA';

        GetOrderLineItems.Request req2 = new GetOrderLineItems.Request();
        req2.orderId = 'a0B000000000002AAA';

        List<GetOrderLineItems.Result> results = 
            GetOrderLineItems.execute(new List<GetOrderLineItems.Request>{ req1, req2 });

        System.assertEquals(2, results.size(), 'Should return two results');
    }

    @IsTest
    static void testOrderItemWrapper() {
        // Verify the OrderItem wrapper class is constructable
        GetOrderLineItems.OrderItem item = new GetOrderLineItems.OrderItem();
        item.productName = 'Test Product';
        item.quantity = 10;
        item.uom = 'PCS';

        System.assertEquals('Test Product', item.productName);
        System.assertEquals(10, item.quantity);
        System.assertEquals('PCS', item.uom);
    }
}
