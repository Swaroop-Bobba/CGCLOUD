public class TriggerAccountExtensionAction {
    public class Request {
        @InvocableVariable(label='Account ID' required=true)
        public String accountId;
    }
    
    public class Result {
        @InvocableVariable(label='Extension ID')
        public String extensionId;
        @InvocableVariable(label='Success')
        public Boolean success;
        @InvocableVariable(label='Error Message')
        public String errorMessage;
    }
    
    @InvocableMethod(label='Trigger Account Extension' description='Triggers the Account Extension logic for an Account')
    public static List<Result> triggerExtension(List<Request> requests) {
        List<Result> results = new List<Result>();
        
        Set<Id> accountIds = new Set<Id>();
        for (Request req : requests) {
            if (req.accountId != null) {
                accountIds.add(req.accountId);
            }
        }
        
        Map<Id, Account> accountMap = new Map<Id, Account>([
            SELECT Id, Name, CreatedDate, cgcloud__Number_Of_Extensions__c
            FROM Account
            WHERE Id IN :accountIds
        ]);
        
        for (Request req : requests) {
            Result res = new Result();
            try {
                Account acc = accountMap.get(req.accountId);
                if (acc == null) {
                    throw new AuraHandledException('Account not found.');
                }
                
                Integer extCount = acc.cgcloud__Number_Of_Extensions__c == null 
                    ? 0 
                    : Integer.valueOf(acc.cgcloud__Number_Of_Extensions__c);
                
                if (extCount != 0) {
                    res.success = true;
                    res.errorMessage = 'Extension already exists.';
                    results.add(res);
                    continue;
                }
                
                Date fromDate = acc.CreatedDate != null ? acc.CreatedDate.date() : Date.today();
                Date thruDate = fromDate.addMonths(1);
                
                cgcloud__Account_Extension__c ext = new cgcloud__Account_Extension__c(
                    cgcloud__account__c = acc.Id,
                    cgcloud__customer_id__c = acc.Name,
                    cgcloud__priority__c = 'High',
                    cgcloud__Phase__c = 'Priority ERP',
                    cgcloud__Sales_Relevant__c = true,
                    cgcloud__pricing_type__c = 'Standard',
                    cgcloud__Promotion_Valid_From__c = fromDate,
                    cgcloud__Promotion_Valid_Thru__c = thruDate,
                    cgcloud__Customer_Role_Price_Type__c = 'Consumer',
                    cgcloud__customer_role_valid_from__c = fromDate,
                    cgcloud__customer_role_valid_thru__c = thruDate,
                    cgcloud__bill_to_role_valid_from__c = fromDate,
                    cgcloud__bill_to_role_valid_thru__c = thruDate,
                    cgcloud__delivery_role_valid_from__c = fromDate,
                    cgcloud__delivery_role_valid_thru__c = thruDate,
                    cgcloud__Store_Role_Valid_From__c = fromDate,
                    cgcloud__Store_Role_Valid_Thru__c = thruDate,
                    cgcloud__Order_Role_Valid_From__c = fromDate,
                    cgcloud__Order_Role_Valid_Thru__c = thruDate,
                    cgcloud__Payer_Role_Valid_From__c = fromDate,
                    cgcloud__Payer_Role_Valid_Thru__c = thruDate,
                    cgcloud__Broker_Role_Valid_From__c = fromDate,
                    cgcloud__Broker_Role_Valid_Thru__c = thruDate,
                    cgcloud__Payer_Role_Credit_Rating__c = 'A',
                    cgcloud__Invoice_Document_Transaction_Type__c = 'InvoiceCashInvoice',
                    cgcloud__Payment_Mode__c = 'Cash',
                    cgcloud__Date_Closure__c = thruDate
                );
                insert ext;
                
                res.extensionId = ext.Id;
                res.success = true;
                res.errorMessage = '';
            } catch (Exception e) {
                res.success = false;
                res.errorMessage = e.getMessage();
            }
            results.add(res);
        }
        return results;
    }
}
