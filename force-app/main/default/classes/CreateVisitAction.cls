global with sharing class CreateVisitAction {
    global class Request {
        @InvocableVariable(required=true description='The visit form data.')
        global CreateVisitWrapper visitData;
    }

    global class Result {
        @InvocableVariable(description='True if the visit was successfully created.')
        global Boolean success;
        
        @InvocableVariable(description='Result status message or error message.')
        global String message;

        @InvocableVariable(description='The created Visit ID.')
        global String visitId;

        @InvocableVariable(description='The associated Account ID.')
        global String accountId;

        @InvocableVariable(description='The Visit Status.')
        global String visitStatus;

        @InvocableVariable(description='The Visit Date.')
        global String visitDate;

        @InvocableVariable(description='The Assigned User.')
        global String assignedUser;
    }

    @InvocableMethod(label='Create Visit' description='Validates and creates a new Visit record.')
    global static List<Result> execute(List<Request> requests) {
        List<Result> results = new List<Result>();
        for (Request req : requests) {
            Result res = new Result();
            res.success = false;
            
            if (req.visitData == null) {
                res.message = 'Visit data is missing.';
                results.add(res);
                continue;
            }

            // Perform validation
            List<String> missingFields = new List<String>();
            if (String.isBlank(req.visitData.subject)) {
                missingFields.add('Subject');
            }
            if (String.isBlank(req.visitData.accountId)) {
                missingFields.add('Account');
            }
            if (req.visitData.plannedStartTime == null) {
                missingFields.add('Planned Visit Start');
            }
            if (String.isBlank(req.visitData.placeId)) {
                missingFields.add('Place');
            }

            if (!missingFields.isEmpty()) {
                res.message = 'Validation failed. Please populate the required fields: ' + String.join(missingFields, ', ') + '.';
                results.add(res);
                continue;
            }

            try {
                Visit newVisit = new Visit();
                newVisit.cgcloud__Subject__c = req.visitData.subject;
                newVisit.AccountId = req.visitData.accountId;
                newVisit.PlannedVisitStartTime = req.visitData.plannedStartTime;
                newVisit.PlaceId = req.visitData.placeId;
                
                if (String.isNotBlank(req.visitData.visitTemplateId)) {
                    newVisit.cgcloud__Visit_Template__c = req.visitData.visitTemplateId;
                }
                if (req.visitData.plannedEndTime != null) {
                    newVisit.PlannedVisitEndTime = req.visitData.plannedEndTime;
                }
                newVisit.cgcloud__IsAllDayEvent__c = req.visitData.isAllDayEvent != null ? req.visitData.isAllDayEvent : false;
                if (String.isNotBlank(req.visitData.accountableId)) {
                    newVisit.cgcloud__Accountable__c = req.visitData.accountableId;
                }
                
                // Responsible is currently logged-in user
                newVisit.cgcloud__Responsible__c = UserInfo.getUserId();
                
                // Record Type Id
                newVisit.RecordTypeId = '012f6000001JRXgAAO';

                insert as user newVisit;

                // Query details for return parameters
                Visit inserted = [
                    SELECT Id, Name, AccountId, Account.Name, Status, PlannedVisitStartTime, Owner.Name
                    FROM Visit
                    WHERE Id = :newVisit.Id
                    WITH USER_MODE
                    LIMIT 1
                ];

                res.success = true;
                res.message = 'Visit created successfully.';
                res.visitId = inserted.Id;
                res.accountId = inserted.AccountId;
                res.visitStatus = inserted.Status;
                res.visitDate = inserted.PlannedVisitStartTime != null ? inserted.PlannedVisitStartTime.format('dd/MM/yyyy, h:mm a') : '';
                res.assignedUser = inserted.Owner != null ? inserted.Owner.Name : '';

            } catch (DmlException e) {
                res.message = e.getDmlMessage(0);
            } catch (Exception e) {
                res.message = e.getMessage();
            }
            results.add(res);
        }
        return results;
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getAccountOptions() {
        List<Map<String, String>> options = new List<Map<String, String>>();
        try {
            for (Account acc : [SELECT Id, Name FROM Account WITH USER_MODE ORDER BY Name LIMIT 100]) {
                options.add(new Map<String, String>{'label' => acc.Name, 'value' => acc.Id});
            }
        } catch (Exception e) {
            System.debug('Error getting Accounts: ' + e.getMessage());
        }
        return options;
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> searchAccounts(String searchTerm) {
        List<Map<String, String>> options = new List<Map<String, String>>();
        try {
            List<Account> accounts;
            if (String.isBlank(searchTerm)) {
                accounts = [SELECT Id, Name FROM Account WITH USER_MODE ORDER BY Name LIMIT 50];
            } else {
                String searchPattern = '%' + searchTerm + '%';
                accounts = [SELECT Id, Name FROM Account WHERE Name LIKE :searchPattern WITH USER_MODE ORDER BY Name LIMIT 50];
            }
            for (Account acc : accounts) {
                options.add(new Map<String, String>{'label' => acc.Name, 'value' => acc.Id});
            }
        } catch (Exception e) {
            System.debug('Error searching Accounts: ' + e.getMessage());
        }
        return options;
    }

    @AuraEnabled(cacheable=true)
    public static String getAccountName(Id accountId) {
        try {
            Account acc = [SELECT Name FROM Account WHERE Id = :accountId WITH USER_MODE LIMIT 1];
            return acc.Name;
        } catch (Exception e) {
            return '';
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getPlaceOptions() {
        List<Map<String, String>> options = new List<Map<String, String>>();
        try {
            for (RetailStore store : [SELECT Id, Name FROM RetailStore WITH USER_MODE ORDER BY Name LIMIT 100]) {
                options.add(new Map<String, String>{'label' => store.Name + ' (Retail Store)', 'value' => store.Id});
            }
            for (Schema.Location loc : [SELECT Id, Name FROM Location WITH USER_MODE ORDER BY Name LIMIT 100]) {
                options.add(new Map<String, String>{'label' => loc.Name + ' (Location)', 'value' => loc.Id});
            }
        } catch (Exception e) {
            System.debug('Error getting Places: ' + e.getMessage());
        }
        return options;
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getTemplateOptions() {
        List<Map<String, String>> options = new List<Map<String, String>>();
        try {
            for (cgcloud__Visit_Template__c temp : [SELECT Id, Name FROM cgcloud__Visit_Template__c WITH USER_MODE ORDER BY Name LIMIT 100]) {
                options.add(new Map<String, String>{'label' => temp.Name, 'value' => temp.Id});
            }
        } catch (Exception e) {
            System.debug('Error getting Visit Templates: ' + e.getMessage());
        }
        return options;
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getUserOptions() {
        List<Map<String, String>> options = new List<Map<String, String>>();
        try {
            for (User u : [SELECT Id, Name FROM User WHERE IsActive = true WITH USER_MODE ORDER BY Name LIMIT 100]) {
                options.add(new Map<String, String>{'label' => u.Name, 'value' => u.Id});
            }
        } catch (Exception e) {
            System.debug('Error getting Users: ' + e.getMessage());
        }
        return options;
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, String> getCurrentUserInfo() {
        try {
            User u = [SELECT Id, Name FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            return new Map<String, String>{'Id' => u.Id, 'Name' => u.Name};
        } catch (Exception e) {
            return new Map<String, String>{'Id' => UserInfo.getUserId(), 'Name' => UserInfo.getName()};
        }
    }
}
