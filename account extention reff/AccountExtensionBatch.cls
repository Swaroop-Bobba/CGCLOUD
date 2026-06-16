global class AccountExtensionBatch implements Database.Batchable<SObject> {

    global Database.QueryLocator start(Database.BatchableContext bc) {

        return Database.getQueryLocator([
            SELECT Id,
                   Name,
                   CreatedDate,
                   cgcloud__Number_Of_Extensions__c
            FROM Account
            WHERE cgcloud__Number_Of_Extensions__c = 0
            AND CreatedDate = TODAY
        ]);
    }

    global void execute(Database.BatchableContext bc, List<Account> scope) {

        List<cgcloud__Account_Extension__c> extensionsToInsert =
            new List<cgcloud__Account_Extension__c>();

        for (Account acc : scope) {

            Date fromDate = acc.CreatedDate.date();
            Date thruDate = fromDate.addMonths(1);

            cgcloud__Account_Extension__c ext =
                new cgcloud__Account_Extension__c(

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

            extensionsToInsert.add(ext);
        }

        if (!extensionsToInsert.isEmpty()) {

            Database.SaveResult[] results =
                Database.insert(extensionsToInsert, false);

            List<String> errorLogs = new List<String>();

            for (Integer i = 0; i < results.size(); i++) {

                if (!results[i].isSuccess()) {

                    for (Database.Error err : results[i].getErrors()) {

                        errorLogs.add(
                            'AccountId: ' +
                            extensionsToInsert[i].cgcloud__account__c +
                            ' | Error: ' +
                            err.getMessage()
                        );
                    }
                }
            }

            if (!errorLogs.isEmpty()) {

                System.debug(
                    'Batch Errors: ' +
                    String.join(errorLogs, ' || ')
                );
            }
        }
    }

    global void finish(Database.BatchableContext bc) {

        System.debug('Account Extension Batch Completed');
    }
}