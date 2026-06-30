String visitId = '0Z5Bh0000001YndKAE';
String typeFilter = 'all';

Visit v = [SELECT Id, cgcloud__Visit_Template__c, AccountId FROM Visit WHERE Id = :visitId LIMIT 1];
Id visitTemplateId = v.cgcloud__Visit_Template__c;
Id visitAccountId = v.AccountId;

Set<Id> includedDirectJdlIds = new Set<Id>();
Set<Id> excludedDirectJdlIds = new Set<Id>();
Set<Id> includedSetJdlIds = new Set<Id>();

if (visitAccountId != null) {
    List<cgcloud__Job_Definition_List_Account__c> jdlAccounts = [
        SELECT cgcloud__Job_Definition_List__c, cgcloud__Excluded__c
        FROM cgcloud__Job_Definition_List_Account__c
        WHERE cgcloud__Account__c = :visitAccountId
    ];
    for (cgcloud__Job_Definition_List_Account__c jda : jdlAccounts) {
        if (jda.cgcloud__Excluded__c == true) {
            excludedDirectJdlIds.add(jda.cgcloud__Job_Definition_List__c);
        } else {
            includedDirectJdlIds.add(jda.cgcloud__Job_Definition_List__c);
        }
    }

    List<cgcloud__Account_Set_Account__c> customerSets = [
        SELECT cgcloud__Account_Set__c
        FROM cgcloud__Account_Set_Account__c
        WHERE cgcloud__Account_Set_Account__c = :visitAccountId
    ];
    Set<Id> accountSetIds = new Set<Id>();
    for (cgcloud__Account_Set_Account__c csa : customerSets) {
        if (csa.cgcloud__Account_Set__c != null) {
            accountSetIds.add(csa.cgcloud__Account_Set__c);
        }
    }

    if (!accountSetIds.isEmpty()) {
        List<cgcloud__Job_Definition_List_Account_Set__c> jdlSets = [
            SELECT cgcloud__Job_Definition_List__c
            FROM cgcloud__Job_Definition_List_Account_Set__c
            WHERE cgcloud__Account_Set__c IN :accountSetIds
        ];
        for (cgcloud__Job_Definition_List_Account_Set__c jds : jdlSets) {
            includedSetJdlIds.add(jds.cgcloud__Job_Definition_List__c);
        }
    }
}

// Links Query WITHOUT instantiatedJdtIds filter
String linksQuery = 'SELECT cgcloud__Job_Definition_List__c FROM cgcloud__Job_DL_Job_Definition_Template__c WHERE cgcloud__Job_Definition_List__r.cgcloud__Visit_Template__c = :visitTemplateId AND cgcloud__Job_Definition_List__r.cgcloud__Active__c = true';
List<cgcloud__Job_DL_Job_Definition_Template__c> links = Database.query(linksQuery);
Set<Id> candidateJdlIds = new Set<Id>();
for (cgcloud__Job_DL_Job_Definition_Template__c link : links) {
    candidateJdlIds.add(link.cgcloud__Job_Definition_List__c);
}

Set<Id> activeJdlIds = new Set<Id>();
if (!candidateJdlIds.isEmpty()) {
    List<cgcloud__Job_Definition_List__c> filteredJdls = [
        SELECT Id, Name, cgcloud__Consider_Account__c
        FROM cgcloud__Job_Definition_List__c
        WHERE Id IN :candidateJdlIds
    ];
    for (cgcloud__Job_Definition_List__c jdl : filteredJdls) {
        if (jdl.cgcloud__Consider_Account__c == false) {
            activeJdlIds.add(jdl.Id);
        } else {
            if (excludedDirectJdlIds.contains(jdl.Id)) {
                continue;
            }
            if (includedDirectJdlIds.contains(jdl.Id) || includedSetJdlIds.contains(jdl.Id)) {
                activeJdlIds.add(jdl.Id);
            }
        }
    }
}

System.debug('=== Active JDLs Found ===');
for (Id idVal : activeJdlIds) {
    cgcloud__Job_Definition_List__c j = [SELECT Name FROM cgcloud__Job_Definition_List__c WHERE Id = :idVal];
    System.debug('JDL Name: ' + j.Name + ' | ID: ' + idVal);
}
