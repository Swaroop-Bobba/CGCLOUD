@IsTest
private class UpdateOrderNotesTest {

    @IsTest
    static void testUpdateNotesById() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        cgcloud__Order_Template__c template = new cgcloud__Order_Template__c(
            Name = 'Test Template'
        );
        insert template;

        cgcloud__Order__c ord = new cgcloud__Order__c(
            cgcloud__Order_Account__c = acc.Id,
            cgcloud__Order_Date__c = Date.today(),
            cgcloud__Phase__c = 'Initial',
            cgcloud__Order_Template__c = template.Id,
            cgcloud__Delivery_Note__c = 'Old delivery note',
            cgcloud__Invoice_Note__c = 'Old invoice note'
        );
        insert ord;

        UpdateOrderNotes.Request req = new UpdateOrderNotes.Request();
        req.orderIdentifier = ord.Id;
        req.deliveryNote = 'Updated Delivery Note';
        req.invoiceNote = 'Updated Invoice Note';

        Test.startTest();
        List<UpdateOrderNotes.Result> results = UpdateOrderNotes.execute(new List<UpdateOrderNotes.Request>{ req });
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertEquals(true, results[0].success);

        cgcloud__Order__c updatedOrd = [SELECT cgcloud__Delivery_Note__c, cgcloud__Invoice_Note__c FROM cgcloud__Order__c WHERE Id = :ord.Id];
        System.assertEquals('Updated Delivery Note', updatedOrd.cgcloud__Delivery_Note__c);
        System.assertEquals('Updated Invoice Note', updatedOrd.cgcloud__Invoice_Note__c);
    }

    @IsTest
    static void testUpdateNotesByName() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        cgcloud__Order_Template__c template = new cgcloud__Order_Template__c(
            Name = 'Test Template'
        );
        insert template;

        cgcloud__Order__c ord = new cgcloud__Order__c(
            cgcloud__Order_Account__c = acc.Id,
            cgcloud__Order_Date__c = Date.today(),
            cgcloud__Phase__c = 'Initial',
            cgcloud__Order_Template__c = template.Id,
            cgcloud__Delivery_Note__c = 'Old delivery note',
            cgcloud__Invoice_Note__c = 'Old invoice note'
        );
        insert ord;

        // Query the auto-generated Name
        ord = [SELECT Id, Name FROM cgcloud__Order__c WHERE Id = :ord.Id];

        UpdateOrderNotes.Request req = new UpdateOrderNotes.Request();
        req.orderIdentifier = ord.Name; // Use the display Name (e.g. O-0001)
        req.deliveryNote = 'Updated Delivery Note By Name';
        req.invoiceNote = 'Updated Invoice Note By Name';

        Test.startTest();
        List<UpdateOrderNotes.Result> results = UpdateOrderNotes.execute(new List<UpdateOrderNotes.Request>{ req });
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertEquals(true, results[0].success);

        cgcloud__Order__c updatedOrd = [SELECT cgcloud__Delivery_Note__c, cgcloud__Invoice_Note__c FROM cgcloud__Order__c WHERE Id = :ord.Id];
        System.assertEquals('Updated Delivery Note By Name', updatedOrd.cgcloud__Delivery_Note__c);
        System.assertEquals('Updated Invoice Note By Name', updatedOrd.cgcloud__Invoice_Note__c);
    }

    @IsTest
    static void testUpdateSingleNote() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        cgcloud__Order_Template__c template = new cgcloud__Order_Template__c(
            Name = 'Test Template'
        );
        insert template;

        cgcloud__Order__c ord = new cgcloud__Order__c(
            cgcloud__Order_Account__c = acc.Id,
            cgcloud__Order_Date__c = Date.today(),
            cgcloud__Phase__c = 'Initial',
            cgcloud__Order_Template__c = template.Id,
            cgcloud__Delivery_Note__c = 'Old delivery note',
            cgcloud__Invoice_Note__c = 'Old invoice note'
        );
        insert ord;

        UpdateOrderNotes.Request req = new UpdateOrderNotes.Request();
        req.orderIdentifier = ord.Id;
        req.deliveryNote = 'Only Update Delivery';
        // req.invoiceNote is left null

        Test.startTest();
        List<UpdateOrderNotes.Result> results = UpdateOrderNotes.execute(new List<UpdateOrderNotes.Request>{ req });
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertEquals(true, results[0].success);

        cgcloud__Order__c updatedOrd = [SELECT cgcloud__Delivery_Note__c, cgcloud__Invoice_Note__c FROM cgcloud__Order__c WHERE Id = :ord.Id];
        System.assertEquals('Only Update Delivery', updatedOrd.cgcloud__Delivery_Note__c);
        System.assertEquals('Old invoice note', updatedOrd.cgcloud__Invoice_Note__c); // Should remain unchanged
    }

    @IsTest
    static void testUpdateWithInvalidIdentifier() {
        UpdateOrderNotes.Request req = new UpdateOrderNotes.Request();
        req.orderIdentifier = 'InvalidIdOrName';
        req.deliveryNote = 'Some Note';

        Test.startTest();
        List<UpdateOrderNotes.Result> results = UpdateOrderNotes.execute(new List<UpdateOrderNotes.Request>{ req });
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertEquals(false, results[0].success);
        System.assert(results[0].resultMessage.contains('Order record not found'));
    }

    @IsTest
    static void testUpdateWithEmptyIdentifier() {
        UpdateOrderNotes.Request req = new UpdateOrderNotes.Request();
        req.orderIdentifier = '   ';
        req.deliveryNote = 'Some Note';

        Test.startTest();
        List<UpdateOrderNotes.Result> results = UpdateOrderNotes.execute(new List<UpdateOrderNotes.Request>{ req });
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertEquals(false, results[0].success);
        System.assert(results[0].resultMessage.contains('Order identifier cannot be empty'));
    }
}
