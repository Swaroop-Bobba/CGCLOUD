public with sharing class AccountExtensionService {

    @AuraEnabled
    public static void createExtension(Id accountId) {

        if (accountId == null) {
            throw new AuraHandledException('Account Id is missing. Please open this from an Account record.');
        }

        List<Account> accList = [
            SELECT Id, Name, CreatedDate, cgcloud__Number_Of_Extensions__c
            FROM Account
            WHERE Id = :accountId
        ];

        if (accList.isEmpty()) {
            throw new AuraHandledException('No access to this Account or record does not exist.');
        }

        Account acc = accList[0];

        Integer extCount = acc.cgcloud__Number_Of_Extensions__c == null 
            ? 0 
            : Integer.valueOf(acc.cgcloud__Number_Of_Extensions__c);

        if (extCount != 0) {
            throw new AuraHandledException('Extension already exists for this Account.');
        }

        Date fromDate = acc.CreatedDate.date();
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
    }
}