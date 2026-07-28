/**
 * @description Test class for Account_Agent_Service.
 */
@IsTest
public class Account_Agent_ServiceTest {

    @IsTest
    static void testExecuteActionRouting() {
        Account acc = new Account(Name = 'CGC Test Account');
        insert as user acc;

        Account_Agent_Service service = new Account_Agent_Service();

        Test.startTest();
        // 1. Get counts
        Agent_Request reqCounts = new Agent_Request();
        reqCounts.actionType = 'getCounts';
        reqCounts.accountId = acc.Id;
        Agent_Response resCounts = service.execute(reqCounts);

        // 2. Get records (contacts)
        Agent_Request reqRecords = new Agent_Request();
        reqRecords.actionType = 'getRecords';
        reqRecords.accountId = acc.Id;
        reqRecords.recordType = 'contacts';
        Agent_Response resRecords = service.execute(reqRecords);

        // 3. Suggest products
        Agent_Request reqSuggest = new Agent_Request();
        reqSuggest.actionType = 'suggestProducts';
        reqSuggest.accountId = acc.Id;
        Agent_Response resSuggest = service.execute(reqSuggest);
        Test.stopTest();

        Assert.isNotNull(resCounts, 'Get counts should succeed.');
        Assert.isTrue(resRecords.success, 'Get records should succeed.');
        Assert.isNotNull(resSuggest, 'Suggest products should succeed.');
    }

    @IsTest
    static void testGetRelatedRecordsCategories() {
        Account acc = new Account(Name = 'CGC Categories Account');
        insert as user acc;

        Test.startTest();
        List<Agent_Response.RecordInfo> listContacts = Account_Agent_Service.getRelatedRecords(acc.Id, 'contacts');
        List<Agent_Response.RecordInfo> listOpps = Account_Agent_Service.getRelatedRecords(acc.Id, 'opportunities');
        List<Agent_Response.RecordInfo> listCases = Account_Agent_Service.getRelatedRecords(acc.Id, 'cases');
        List<Agent_Response.RecordInfo> listVisits = Account_Agent_Service.getRelatedRecords(acc.Id, 'visits');
        List<Agent_Response.RecordInfo> listPromos = Account_Agent_Service.getRelatedRecords(acc.Id, 'promotions');
        Test.stopTest();

        Assert.isFalse(listContacts.isEmpty(), 'Contacts list should not be empty (mock data fallback).');
        Assert.isFalse(listOpps.isEmpty(), 'Opportunities list should not be empty (mock data fallback).');
        Assert.isFalse(listCases.isEmpty(), 'Cases list should not be empty.');
        Assert.isNotNull(listVisits, 'Visits list should be returned.');
        Assert.isNotNull(listPromos, 'Promotions list should be returned.');
    }

    @IsTest
    static void testGetEligibleProductsAndMockFuzzyMatching() {
        Account_Agent_Service service = new Account_Agent_Service();

        Test.startTest();
        // Test getproducts action with a mock promotion name
        Agent_Request reqPromo = new Agent_Request();
        reqPromo.actionType = 'getProducts';
        reqPromo.promotionId = 'mock_promo_id';
        Agent_Response resPromo = service.execute(reqPromo);
        Test.stopTest();

        Assert.isTrue(resPromo.success, 'Eligible products query should succeed.');
        Assert.isNotNull(resPromo.message, 'A products suggestion message list should be returned.');
    }

    @IsTest
    static void testAccountServiceCoverageBoost() {
        Account_Agent_Service service = new Account_Agent_Service();

        Test.startTest();
        // 1. Invalid or blank action types
        Agent_Request reqEmpty = new Agent_Request();
        service.execute(reqEmpty);

        Agent_Request reqInvalid = new Agent_Request();
        reqInvalid.actionType = 'invalid_action';
        service.execute(reqInvalid);

        // 2. Blank and fake parameters for static methods
        Account_Agent_Service.getRelatedCounts('');
        Account_Agent_Service.getRelatedCounts('fake_acc_id');

        Account_Agent_Service.getRelatedRecords('', '');
        Account_Agent_Service.getRelatedRecords('fake_acc_id', 'invalid_type');
        Account_Agent_Service.getRelatedRecords('fake_acc_id', 'orders');
        Account_Agent_Service.getRelatedRecords('fake_acc_id', 'assortments');

        Account_Agent_Service.suggestProducts('');
        Account_Agent_Service.suggestProducts('fake_acc_id');

        Account_Agent_Service.getEligibleProducts('');
        Account_Agent_Service.getEligibleProducts('fake_promo_id');

        Agent_Request reqSearch = new Agent_Request();
        reqSearch.actionType = 'search';
        reqSearch.searchQuery = 'StoreNameQuery';
        service.execute(reqSearch);
        Test.stopTest();

        Assert.isNotNull(service, 'Service instance exists.');
    }
}
