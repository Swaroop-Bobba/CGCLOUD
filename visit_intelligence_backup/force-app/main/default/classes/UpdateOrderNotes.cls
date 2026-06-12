public with sharing class UpdateOrderNotes {

    public class Request {
        @InvocableVariable(required=true description='The Salesforce Order ID or Order Name (e.g., O-01159) to update.')
        public String orderIdentifier;

        @InvocableVariable(description='The new delivery note text. If not provided, the delivery note will not be updated.')
        public String deliveryNote;

        @InvocableVariable(description='The new invoice note text. If not provided, the invoice note will not be updated.')
        public String invoiceNote;
    }

    public class Result {
        @InvocableVariable(description='Whether the update was successful.')
        public Boolean success;

        @InvocableVariable(description='Success or error message.')
        public String resultMessage;
    }

    @InvocableMethod(
        label='Update Order Notes'
        description='Update delivery note and/or invoice note on a specific CG Cloud Order by its ID or Name.'
    )
    public static List<Result> execute(List<Request> requests) {
        List<Result> results = new List<Result>();

        for (Request req : requests) {
            Result res = new Result();
            res.success = false;

            try {
                String ident = req.orderIdentifier;
                if (String.isBlank(ident)) {
                    res.resultMessage = 'Order identifier cannot be empty.';
                    results.add(res);
                    continue;
                }

                ident = ident.trim();

                // Find the order record
                List<cgcloud__Order__c> orders = new List<cgcloud__Order__c>();
                
                // If it looks like a Salesforce ID (15 or 18 chars), try to query by Id first
                if (ident.length() == 15 || ident.length() == 18) {
                    orders = [SELECT Id, cgcloud__Delivery_Note__c, cgcloud__Invoice_Note__c 
                              FROM cgcloud__Order__c 
                              WHERE Id = :ident 
                              WITH USER_MODE 
                              LIMIT 1];
                }
                
                // If not found or not a valid ID format, fallback to querying by Name (Order Name)
                if (orders.isEmpty()) {
                    orders = [SELECT Id, cgcloud__Delivery_Note__c, cgcloud__Invoice_Note__c 
                              FROM cgcloud__Order__c 
                              WHERE Name = :ident 
                              WITH USER_MODE 
                              LIMIT 1];
                }

                if (orders.isEmpty()) {
                    res.resultMessage = 'Order record not found with identifier: ' + ident;
                    results.add(res);
                    continue;
                }

                cgcloud__Order__c orderToUpdate = orders[0];
                Boolean changed = false;

                if (req.deliveryNote != null) {
                    orderToUpdate.cgcloud__Delivery_Note__c = req.deliveryNote;
                    changed = true;
                }

                if (req.invoiceNote != null) {
                    orderToUpdate.cgcloud__Invoice_Note__c = req.invoiceNote;
                    changed = true;
                }

                if (changed) {
                    Database.update(orderToUpdate, AccessLevel.USER_MODE);
                    res.success = true;
                    res.resultMessage = 'Order notes updated successfully.';
                } else {
                    res.success = true;
                    res.resultMessage = 'No updates provided.';
                }

            } catch (Exception e) {
                res.success = false;
                res.resultMessage = 'Error updating order: ' + e.getMessage();
            }

            results.add(res);
        }

        return results;
    }
}
