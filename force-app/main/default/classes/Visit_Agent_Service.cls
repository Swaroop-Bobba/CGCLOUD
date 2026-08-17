/**
 * @description UI Controller Service for Visit Intelligence Lightning Web Components (createVisitEditor).
 *              Provides AuraEnabled lookups, metadata queries, and context resolvers.
 */
global with sharing class Visit_Agent_Service {

    global Visit_Agent_Service() {}

    /**
     * @description Returns available Visit status picklist options.
     */
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getStatusOptions() {
        List<Map<String, String>> options = new List<Map<String, String>>();
        try {
            if (Schema.getGlobalDescribe().containsKey('visit')) {
                Schema.DescribeFieldResult fieldResult = Schema.getGlobalDescribe().get('Visit').getDescribe().fields.getMap().get('Status').getDescribe();
                for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
                    options.add(new Map<String, String>{
                        'label' => entry.getLabel(),
                        'value' => entry.getValue()
                    });
                }
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error in getStatusOptions: ' + e.getMessage());
        }
        return options;
    }

    /**
     * @description Returns active users in the system.
     */
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getActiveUsers() {
        return searchUsers('');
    }

    /**
     * @description Searches active users matching search term.
     */
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> searchUsers(String searchTerm) {
        List<Map<String, String>> options = new List<Map<String, String>>();
        try {
            List<User> users;
            if (String.isBlank(searchTerm)) {
                users = [SELECT Id, Name FROM User WHERE IsActive = TRUE WITH USER_MODE ORDER BY Name LIMIT 50];
            } else {
                String term = '%' + String.escapeSingleQuotes(searchTerm.trim()) + '%';
                users = [SELECT Id, Name FROM User WHERE IsActive = TRUE AND Name LIKE :term WITH USER_MODE ORDER BY Name LIMIT 50];
            }
            for (User u : users) {
                options.add(new Map<String, String>{
                    'label' => u.Name,
                    'value' => u.Id
                });
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error in searchUsers: ' + e.getMessage());
        }
        return options;
    }

    /**
     * @description Resolves user display name for a given user ID.
     */
    @AuraEnabled(cacheable=true)
    public static String getUserName(Id userId) {
        if (userId == null) {
            return '';
        }
        try {
            List<User> users = [SELECT Name FROM User WHERE Id = :userId WITH USER_MODE LIMIT 1];
            return users.isEmpty() ? '' : users[0].Name;
        } catch (Exception e) {
            return '';
        }
    }

    /**
     * @description Searches Accounts matching search term.
     */
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> searchAccounts(String searchTerm) {
        List<Map<String, String>> options = new List<Map<String, String>>();
        try {
            List<Account> accounts;
            if (String.isBlank(searchTerm)) {
                accounts = [SELECT Id, Name FROM Account WITH USER_MODE ORDER BY Name LIMIT 50];
            } else {
                String term = '%' + String.escapeSingleQuotes(searchTerm.trim()) + '%';
                accounts = [SELECT Id, Name FROM Account WHERE Name LIKE :term WITH USER_MODE ORDER BY Name LIMIT 50];
            }
            for (Account acc : accounts) {
                options.add(new Map<String, String>{
                    'label' => acc.Name,
                    'value' => acc.Id
                });
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error in searchAccounts: ' + e.getMessage());
        }
        return options;
    }

    /**
     * @description Resolves Account Name for a given Account ID.
     */
    @AuraEnabled(cacheable=true)
    public static String getAccountName(Id accountId) {
        if (accountId == null) {
            return '';
        }
        try {
            List<Account> accounts = [SELECT Name FROM Account WHERE Id = :accountId WITH USER_MODE LIMIT 1];
            return accounts.isEmpty() ? '' : accounts[0].Name;
        } catch (Exception e) {
            return '';
        }
    }

    /**
     * @description Searches Places (RetailStore / Location) matching search term.
     */
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> searchPlaces(String searchTerm) {
        List<Map<String, String>> options = new List<Map<String, String>>();
        try {
            String term = String.isNotBlank(searchTerm) ? '%' + String.escapeSingleQuotes(searchTerm.trim()) + '%' : '%';
            if (Schema.getGlobalDescribe().containsKey('retailstore')) {
                List<SObject> stores = Database.query('SELECT Id, Name FROM RetailStore WHERE Name LIKE :term ORDER BY Name LIMIT 25');
                for (SObject rs : stores) {
                    options.add(new Map<String, String>{
                        'label' => (String) rs.get('Name') + ' (Retail Store)',
                        'value' => (String) rs.get('Id')
                    });
                }
            }
            if (Schema.getGlobalDescribe().containsKey('location')) {
                List<SObject> locs = Database.query('SELECT Id, Name FROM Location WHERE Name LIKE :term ORDER BY Name LIMIT 25');
                for (SObject loc : locs) {
                    options.add(new Map<String, String>{
                        'label' => (String) loc.get('Name') + ' (Location)',
                        'value' => (String) loc.get('Id')
                    });
                }
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error in searchPlaces: ' + e.getMessage());
        }
        return options;
    }

    /**
     * @description Resolves Place Name for a given Place ID.
     */
    @AuraEnabled(cacheable=true)
    public static String getPlaceName(Id placeId) {
        if (placeId == null) {
            return '';
        }
        try {
            if (Schema.getGlobalDescribe().containsKey('retailstore')) {
                List<SObject> stores = Database.query('SELECT Name FROM RetailStore WHERE Id = :placeId LIMIT 1');
                if (!stores.isEmpty()) {
                    return (String) stores[0].get('Name');
                }
            }
            if (Schema.getGlobalDescribe().containsKey('location')) {
                List<SObject> locs = Database.query('SELECT Name FROM Location WHERE Id = :placeId LIMIT 1');
                if (!locs.isEmpty()) {
                    return (String) locs[0].get('Name');
                }
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error in getPlaceName: ' + e.getMessage());
        }
        return '';
    }

    /**
     * @description Searches CG Cloud Visit Templates matching search term.
     */
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> searchTemplates(String searchTerm) {
        List<Map<String, String>> options = new List<Map<String, String>>();
        try {
            if (Schema.getGlobalDescribe().containsKey('cgcloud__visit_template__c')) {
                String term = String.isNotBlank(searchTerm) ? '%' + String.escapeSingleQuotes(searchTerm.trim()) + '%' : '%';
                List<SObject> templates = Database.query('SELECT Id, Name FROM cgcloud__Visit_Template__c WHERE Name LIKE :term ORDER BY Name LIMIT 50');
                for (SObject vt : templates) {
                    options.add(new Map<String, String>{
                        'label' => (String) vt.get('Name'),
                        'value' => (String) vt.get('Id')
                    });
                }
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error in searchTemplates: ' + e.getMessage());
        }
        return options;
    }

    /**
     * @description Resolves Template Name for a given Template ID.
     */
    @AuraEnabled(cacheable=true)
    public static String getTemplateName(Id templateId) {
        if (templateId == null) {
            return '';
        }
        try {
            if (Schema.getGlobalDescribe().containsKey('cgcloud__visit_template__c')) {
                List<SObject> templates = Database.query('SELECT Name FROM cgcloud__Visit_Template__c WHERE Id = :templateId LIMIT 1');
                return templates.isEmpty() ? '' : (String) templates[0].get('Name');
            }
        } catch (Exception e) {
            return '';
        }
        return '';
    }

    /**
     * @description Retrieves pre-populated Visit data for LWC modal editor.
     */
    @AuraEnabled(cacheable=true)
    public static CreateVisitWrapper getVisitDataForLwc(Id visitId) {
        if (visitId == null) {
            return null;
        }
        try {
            if (!Schema.getGlobalDescribe().containsKey('visit')) {
                return null;
            }
            Boolean hasTemplate = Schema.getGlobalDescribe().get('Visit').getDescribe().fields.getMap().containsKey('cgcloud__visit_template__c');
            Boolean hasAccountable = Schema.getGlobalDescribe().get('Visit').getDescribe().fields.getMap().containsKey('cgcloud__accountable__c');
            Boolean hasResponsible = Schema.getGlobalDescribe().get('Visit').getDescribe().fields.getMap().containsKey('cgcloud__responsible__c');

            String query = 'SELECT Id, Name, AccountId, PlaceId, Status, PlannedVisitStartTime, PlannedVisitEndTime';
            if (hasTemplate) query += ', cgcloud__Visit_Template__c';
            if (hasAccountable) query += ', cgcloud__Accountable__c';
            if (hasResponsible) query += ', cgcloud__Responsible__c';
            query += ' FROM Visit WHERE Id = :visitId LIMIT 1';

            List<SObject> visits = Database.query(query);
            if (visits.isEmpty()) {
                return null;
            }
            SObject v = visits[0];
            CreateVisitWrapper wrapper = new CreateVisitWrapper();
            wrapper.subject = (String) v.get('Name');
            wrapper.accountId = (String) v.get('AccountId');
            wrapper.placeId = (String) v.get('PlaceId');
            if (hasTemplate) wrapper.visitTemplateId = (String) v.get('cgcloud__Visit_Template__c');
            if (hasAccountable) wrapper.accountableId = (String) v.get('cgcloud__Accountable__c');
            if (hasResponsible) wrapper.responsibleId = (String) v.get('cgcloud__Responsible__c');
            wrapper.plannedStartTime = (DateTime) v.get('PlannedVisitStartTime');
            wrapper.plannedEndTime = (DateTime) v.get('PlannedVisitEndTime');
            return wrapper;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error in getVisitDataForLwc: ' + e.getMessage());
            return null;
        }
    }

    /**
     * @description Retrieves the current user's profile and ID for Responsible Rep assignments.
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getResponsibleUserContext() {
        Map<String, Object> result = new Map<String, Object>();
        try {
            User u = [SELECT Id, Name, Profile.Name FROM User WHERE Id = :UserInfo.getUserId() WITH USER_MODE LIMIT 1];
            result.put('userId', u.Id);
            result.put('userName', u.Name);
            result.put('isCGCloudUser', (u.Profile.Name == 'CGCloud_User_Profile'));
        } catch (Exception e) {
            result.put('userId', UserInfo.getUserId());
            result.put('userName', UserInfo.getUserName());
            result.put('isCGCloudUser', false);
        }
        return result;
    }

    /**
     * @description Retrieves dynamic field values for a given visit record.
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getVisitFieldValues(Id visitId) {
        Map<String, Object> result = new Map<String, Object>();
        if (visitId == null) {
            return result;
        }
        try {
            if (!Schema.getGlobalDescribe().containsKey('visit')) {
                return result;
            }
            Boolean hasNote = Schema.getGlobalDescribe().get('Visit').getDescribe().fields.getMap().containsKey('cgcloud__note__c');
            Boolean hasResponsible = Schema.getGlobalDescribe().get('Visit').getDescribe().fields.getMap().containsKey('cgcloud__responsible__c');

            String query = 'SELECT Id, Name, Status, AccountId, Account.Name, PlaceId, PlannedVisitStartTime, PlannedVisitEndTime';
            if (hasNote) query += ', cgcloud__Note__c';
            if (hasResponsible) query += ', cgcloud__Responsible__c, cgcloud__Responsible__r.Name';
            query += ' FROM Visit WHERE Id = :visitId LIMIT 1';

            List<SObject> visits = Database.query(query);
            if (!visits.isEmpty()) {
                SObject v = visits[0];
                result.put('id', (String) v.get('Id'));
                result.put('name', (String) v.get('Name'));
                result.put('status', (String) v.get('Status'));
                result.put('accountId', (String) v.get('AccountId'));
                SObject acc = v.getSObject('Account');
                result.put('accountName', acc != null ? (String) acc.get('Name') : '');
                result.put('placeId', (String) v.get('PlaceId'));
                result.put('plannedStartTime', (DateTime) v.get('PlannedVisitStartTime'));
                result.put('plannedEndTime', (DateTime) v.get('PlannedVisitEndTime'));
                if (hasNote) result.put('notes', (String) v.get('cgcloud__Note__c'));
                if (hasResponsible) {
                    result.put('responsibleId', (String) v.get('cgcloud__Responsible__c'));
                    SObject resp = v.getSObject('cgcloud__Responsible__r');
                    result.put('responsibleName', resp != null ? (String) resp.get('Name') : '');
                }
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error in getVisitFieldValues: ' + e.getMessage());
        }
        return result;
    }
}
