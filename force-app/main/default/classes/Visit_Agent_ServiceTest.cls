@IsTest
private class Visit_Agent_ServiceTest {

    @TestSetup
    static void setupTestData() {
        Account acc = new Account(Name = 'Service Test Store');
        insert acc;

        String locId = null;
        if (Schema.getGlobalDescribe().containsKey('location')) {
            Schema.Location loc = new Schema.Location(Name = 'Service Test Location');
            insert loc;
            locId = loc.Id;
        }

        String rsId = null;
        if (Schema.getGlobalDescribe().containsKey('retailstore')) {
            try {
                SObject rs = Schema.getGlobalDescribe().get('RetailStore').newSObject();
                rs.put('Name', 'Service Test Retail Store');
                rs.put('AccountId', acc.Id);
                if (locId != null) { rs.put('LocationId', locId); }
                Database.insert(rs, AccessLevel.USER_MODE);
                rsId = (String) rs.get('Id');
            } catch (Exception e) {}
        }

        String vtId = null;
        if (Schema.getGlobalDescribe().containsKey('cgcloud__visit_template__c')) {
            SObject vt = Schema.getGlobalDescribe().get('cgcloud__Visit_Template__c').newSObject();
            vt.put('Name', 'Service Standard Template');
            Database.insert(vt, AccessLevel.USER_MODE);
            vtId = (String) vt.get('Id');
        }

        if (Schema.getGlobalDescribe().containsKey('visit')) {
            try {
                SObject vis = Schema.getGlobalDescribe().get('Visit').newSObject();
                vis.put('AccountId', acc.Id);
                if (locId != null) {
                    vis.put('PlaceId', locId);
                } else if (rsId != null) {
                    vis.put('PlaceId', rsId);
                }
                vis.put('Status', 'Planned');
                vis.put('PlannedVisitStartTime', System.now().addDays(1));
                vis.put('PlannedVisitEndTime', System.now().addDays(1).addHours(2));
                Map<String, Schema.SObjectField> fMap = Schema.getGlobalDescribe().get('Visit').getDescribe().fields.getMap();
                if (fMap.containsKey('cgcloud__note__c')) {
                    vis.put('cgcloud__Note__c', 'Service visit test note');
                }
                Database.insert(vis, AccessLevel.USER_MODE);
            } catch (Exception e) {
                // Ignore org validation rules in test setup
            }
        }
    }

    @IsTest
    static void testAuraEnabledLookups() {
        Account acc = [SELECT Id, Name FROM Account LIMIT 1];
        String locId = null;
        if (Schema.getGlobalDescribe().containsKey('location')) {
            List<SObject> locs = Database.query('SELECT Id FROM Location LIMIT 1');
            if (!locs.isEmpty()) locId = (String) locs[0].get('Id');
        }
        String rsId = null;
        if (Schema.getGlobalDescribe().containsKey('retailstore')) {
            List<SObject> stores = Database.query('SELECT Id FROM RetailStore LIMIT 1');
            if (!stores.isEmpty()) rsId = (String) stores[0].get('Id');
        }
        String vtId = null;
        if (Schema.getGlobalDescribe().containsKey('cgcloud__visit_template__c')) {
            List<SObject> vts = Database.query('SELECT Id FROM cgcloud__Visit_Template__c LIMIT 1');
            if (!vts.isEmpty()) vtId = (String) vts[0].get('Id');
        }
        String visId = null;
        if (Schema.getGlobalDescribe().containsKey('visit')) {
            List<SObject> vList = Database.query('SELECT Id FROM Visit LIMIT 1');
            if (!vList.isEmpty()) visId = (String) vList[0].get('Id');
        }
        User currentUser = [SELECT Id, Name FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

        Test.startTest();
        // 1. Status & Active Users
        List<Map<String, String>> statuses = Visit_Agent_Service.getStatusOptions();
        Assert.isNotNull(statuses, 'Status options should not be null');

        List<Map<String, String>> activeUsers = Visit_Agent_Service.getActiveUsers();
        Assert.isNotNull(activeUsers, 'Active users should not be null');

        // 2. User searches
        List<Map<String, String>> usersFound = Visit_Agent_Service.searchUsers(currentUser.Name.substring(0, 2));
        List<Map<String, String>> usersNone = Visit_Agent_Service.searchUsers('NonExistentUserZ99');
        List<Map<String, String>> allUsers = Visit_Agent_Service.searchUsers('');
        String userName = Visit_Agent_Service.getUserName(currentUser.Id);
        String emptyUserName = Visit_Agent_Service.getUserName(null);
        Assert.isNotNull(userName, 'User name should resolve');
        Assert.areEqual('', emptyUserName, 'Empty user ID should return empty string');

        // 3. Account searches
        List<Map<String, String>> accsFound = Visit_Agent_Service.searchAccounts('Service');
        List<Map<String, String>> accsNone = Visit_Agent_Service.searchAccounts('NonExistentAccountZ99');
        List<Map<String, String>> allAccs = Visit_Agent_Service.searchAccounts('');
        String accName = Visit_Agent_Service.getAccountName(acc.Id);
        String emptyAccName = Visit_Agent_Service.getAccountName(null);
        Assert.areEqual('Service Test Store', accName, 'Account name resolved');
        Assert.areEqual('', emptyAccName, 'Empty account ID returns empty string');

        // 4. Place searches
        List<Map<String, String>> placesFound = Visit_Agent_Service.searchPlaces('Service');
        List<Map<String, String>> placesNone = Visit_Agent_Service.searchPlaces('NonExistentPlaceZ99');
        List<Map<String, String>> allPlaces = Visit_Agent_Service.searchPlaces('');
        if (locId != null) {
            String locName = Visit_Agent_Service.getPlaceName(locId);
            Assert.isNotNull(locName, 'Location name resolved');
        }
        if (rsId != null) {
            String storeName = Visit_Agent_Service.getPlaceName(rsId);
            Assert.isNotNull(storeName, 'Store name resolved');
        }
        String emptyPlaceName = Visit_Agent_Service.getPlaceName(null);
        Assert.areEqual('', emptyPlaceName, 'Empty place ID returns empty string');

        // 5. Template searches
        List<Map<String, String>> templatesFound = Visit_Agent_Service.searchTemplates('Standard');
        List<Map<String, String>> templatesNone = Visit_Agent_Service.searchTemplates('NonExistentTemplateZ99');
        List<Map<String, String>> allTemplates = Visit_Agent_Service.searchTemplates('');
        String templateName = Visit_Agent_Service.getTemplateName(vtId);
        String emptyTemplateName = Visit_Agent_Service.getTemplateName(null);
        Assert.areEqual('', emptyTemplateName, 'Empty template ID returns empty string');

        // 6. LWC Visit Data & Context
        if (visId != null) {
            CreateVisitWrapper wrapper = Visit_Agent_Service.getVisitDataForLwc(visId);
            Assert.isNotNull(wrapper, 'Visit wrapper should be returned');
            Map<String, Object> fieldValues = Visit_Agent_Service.getVisitFieldValues(visId);
            Assert.isFalse(fieldValues.isEmpty(), 'Visit field values should be returned');
        }
        CreateVisitWrapper emptyWrapper = Visit_Agent_Service.getVisitDataForLwc(null);
        Assert.isNull(emptyWrapper, 'Null visit ID returns null wrapper');

        Map<String, Object> userContext = Visit_Agent_Service.getResponsibleUserContext();
        Assert.isNotNull(userContext, 'Responsible user context returned');

        Map<String, Object> emptyFieldValues = Visit_Agent_Service.getVisitFieldValues(null);
        Assert.isTrue(emptyFieldValues.isEmpty(), 'Null visit ID returns empty map');

        // Constructor test
        Visit_Agent_Service instance = new Visit_Agent_Service();
        Assert.isNotNull(instance, 'Instance created');
        Test.stopTest();
    }
}
