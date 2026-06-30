Visit v = [SELECT Id, AccountId, Account.Name, cgcloud__Visit_Template__c, cgcloud__Visit_Template__r.Name FROM Visit WHERE Id = '0Z5Bh0000001YndKAE' LIMIT 1];
System.debug('=== Visit Info ===');
System.debug('Visit ID: ' + v.Id + ' | Account ID: ' + v.AccountId + ' | Account Name: ' + v.Account.Name);
System.debug('Visit Template: ' + v.cgcloud__Visit_Template__c + ' | Template Name: ' + v.cgcloud__Visit_Template__r.Name);

if (v.AccountId != null) {
    List<cgcloud__Job_Definition_List_Account__c> jdlAccounts = [
        SELECT Id, cgcloud__Job_Definition_List__c, cgcloud__Job_Definition_List__r.Name, cgcloud__Excluded__c
        FROM cgcloud__Job_Definition_List_Account__c
        WHERE cgcloud__Account__c = :v.AccountId
    ];
    System.debug('=== JDL Accounts for Account ===');
    for (cgcloud__Job_Definition_List_Account__c jda : jdlAccounts) {
        System.debug('JDA ID: ' + jda.Id + ' | JDL: ' + jda.cgcloud__Job_Definition_List__r.Name + ' | Excluded: ' + jda.cgcloud__Excluded__c);
    }

    List<cgcloud__Account_Set_Account__c> customerSets = [
        SELECT Id, cgcloud__Account_Set__c, cgcloud__Account_Set__r.Name, cgcloud__Account_Set_Account__c
        FROM cgcloud__Account_Set_Account__c
        WHERE cgcloud__Account_Set_Account__c = :v.AccountId
    ];
    System.debug('=== Account Set Accounts for Account ===');
    for (cgcloud__Account_Set_Account__c csa : customerSets) {
        System.debug('CSA ID: ' + csa.Id + ' | Account Set: ' + csa.cgcloud__Account_Set__r.Name + ' | Customer: ' + csa.cgcloud__Account_Set_Account__c);
    }
}
