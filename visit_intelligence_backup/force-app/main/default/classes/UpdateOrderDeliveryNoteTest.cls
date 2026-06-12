@IsTest
private class UpdateOrderDeliveryNoteTest {

    @IsTest
    static void testExecuteWithFakeOrderId() {
        // Test with a non-existent order ID — should hit the exception handler
        UpdateOrderDeliveryNote.Request req = new UpdateOrderDeliveryNote.Request();
        req.orderId = 'a0B000000000000AAA'; // Fake ID
        req.deliveryNote = 'Deliver before 10 AM';

        List<UpdateOrderDeliveryNote.Result> results = 
            UpdateOrderDeliveryNote.execute(new List<UpdateOrderDeliveryNote.Request>{ req });

        System.assertEquals(1, results.size(), 'Should return exactly one result');
        // Will fail because the ID doesn't exist, but should not throw unhandled exception
        System.assertNotEquals(null, results[0].resultMessage, 'Result message should not be null');
    }

    @IsTest
    static void testMultipleRequests() {
        UpdateOrderDeliveryNote.Request req1 = new UpdateOrderDeliveryNote.Request();
        req1.orderId = 'a0B000000000001AAA';
        req1.deliveryNote = 'Note 1';

        UpdateOrderDeliveryNote.Request req2 = new UpdateOrderDeliveryNote.Request();
        req2.orderId = 'a0B000000000002AAA';
        req2.deliveryNote = 'Note 2';

        List<UpdateOrderDeliveryNote.Result> results = 
            UpdateOrderDeliveryNote.execute(new List<UpdateOrderDeliveryNote.Request>{ req1, req2 });

        System.assertEquals(2, results.size(), 'Should return two results');
    }

    @IsTest
    static void testResultWrapper() {
        UpdateOrderDeliveryNote.Result res = new UpdateOrderDeliveryNote.Result();
        res.success = true;
        res.resultMessage = 'Test message';

        System.assertEquals(true, res.success);
        System.assertEquals('Test message', res.resultMessage);
    }
}
