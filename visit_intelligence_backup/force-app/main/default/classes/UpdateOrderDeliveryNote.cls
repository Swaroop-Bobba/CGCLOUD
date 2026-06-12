/**
 * @deprecated This class is obsolete and has been replaced by the Apex Class: UpdateOrderNotes (apex://UpdateOrderNotes).
 * It is no longer referenced by the Visit Intelligence Agent.
 */
public with sharing class UpdateOrderDeliveryNote {

    @InvocableMethod(
        label='Update Order Delivery Note'
        description='Update the delivery note/instructions on a specific CG Cloud Order record.'
    )
    public static List<Result> execute(List<Request> requests) {
        List<Result> results = new List<Result>();

        for (Request req : requests) {
            Result res = new Result();
            res.success = false;
            res.resultMessage = '';

            try {
                String ordId = req.orderId;
                String note = req.deliveryNote;

                // Use dynamic SObject construction for managed package safety
                SObject orderRecord = Schema.getGlobalDescribe().get('cgcloud__Order__c').newSObject();
                orderRecord.put('Id', ordId);
                orderRecord.put('cgcloud__Delivery_Note__c', note);

                update orderRecord;

                res.success = true;
                res.resultMessage = 'Delivery note updated successfully.';

            } catch (Exception e) {
                res.success = false;
                res.resultMessage = 'Error updating delivery note: ' + e.getMessage();
            }

            results.add(res);
        }

        return results;
    }

    public class Request {
        @InvocableVariable(required=true description='The CG Cloud Order ID to update.')
        public String orderId;

        @InvocableVariable(required=true description='The new delivery note text.')
        public String deliveryNote;
    }

    public class Result {
        @InvocableVariable(description='Whether the update was successful.')
        public Boolean success;

        @InvocableVariable(description='Success or error message.')
        public String resultMessage;
    }
}
