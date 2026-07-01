@isTest
private class CreateVisitActionTest {
    @isTest
    static void testAsSiriFieldRep() {
        User u = [SELECT Id FROM User WHERE Username = 'siri123@force.com.partialsbx' LIMIT 1];
        System.runAs(u) {
            Test.startTest();
            // Call context method
            Map<String, Object> context = CreateVisitAction.getResponsibleUserContext();
            System.debug('TEST LOG: context is ' + context);
            
            // Search accounts
            List<Map<String, String>> accounts = CreateVisitAction.searchAccounts('Reliance');
            System.debug('TEST LOG: accounts size is ' + accounts.size());
            
            // Search places
            List<Map<String, String>> places = CreateVisitAction.searchPlaces('Reliance');
            System.debug('TEST LOG: places size is ' + places.size());
            
            // Search templates
            List<Map<String, String>> templates = CreateVisitAction.searchTemplates('Stock');
            System.debug('TEST LOG: templates size is ' + templates.size());

            // Search users
            List<Map<String, String>> users = CreateVisitAction.searchUsers('Swaroop');
            System.debug('TEST LOG: users size is ' + users.size());
            
            Test.stopTest();
        }
    }
}
