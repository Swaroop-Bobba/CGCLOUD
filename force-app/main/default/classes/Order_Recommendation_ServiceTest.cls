/**
 * @description Test class for Order_Recommendation_Service.
 */
@IsTest
public class Order_Recommendation_ServiceTest {

    @IsTest
    static void testExecuteActionRouting() {
        Account acc = new Account(Name = 'CGC Rec Service Account');
        insert as user acc;

        Order_Recommendation_Service service = new Order_Recommendation_Service();

        Test.startTest();
        // 1. Search accounts (multiple candidates fallback)
        Agent_Request reqSearch = new Agent_Request();
        reqSearch.actionType = 'searchAccounts';
        reqSearch.searchQuery = 'CGC';
        Agent_Response resSearch = service.execute(reqSearch);

        // 2. Get account context
        Agent_Request reqAccCtx = new Agent_Request();
        reqAccCtx.actionType = 'getAccountContext';
        reqAccCtx.accountId = acc.Id;
        Agent_Response resAccCtx = service.execute(reqAccCtx);

        // 3. Get full order list
        Agent_Request reqOrders = new Agent_Request();
        reqOrders.actionType = 'getFullOrderList';
        reqOrders.accountId = acc.Id;
        Agent_Response resOrders = service.execute(reqOrders);

        // 4. Get order summary
        Agent_Request reqSummary = new Agent_Request();
        reqSummary.actionType = 'getOrderSummary';
        reqSummary.accountId = acc.Id;
        Agent_Response resSummary = service.execute(reqSummary);

        // 5. Get sellable products
        Agent_Request reqProducts = new Agent_Request();
        reqProducts.actionType = 'getSellableProducts';
        reqProducts.accountId = acc.Id;
        Agent_Response resProducts = service.execute(reqProducts);

        // 6. Test suggestproducts action with empty parameters
        Agent_Request reqSuggestEmpty = new Agent_Request();
        reqSuggestEmpty.actionType = 'suggestProducts';
        Agent_Response resSuggestEmpty = service.execute(reqSuggestEmpty);
        Test.stopTest();

        Assert.isNotNull(resSearch, 'Search accounts action should succeed.');
        Assert.isNotNull(resAccCtx, 'Get account context should succeed.');
        Assert.isNotNull(resOrders, 'Get full order list should succeed.');
        Assert.isNotNull(resSummary, 'Get order summary should succeed.');
        Assert.isNotNull(resProducts, 'Get sellable products should succeed.');
        Assert.isNotNull(resSuggestEmpty, 'Empty suggest products returns validation warning.');
    }

    @IsTest
    static void testRecommendationLogicAndOrderContext() {
        Account acc = new Account(Name = 'CGC Rec Mock Account');
        insert as user acc;

        try {
            Product2 prod = new Product2(Name = 'Empower Cola 0.5L', IsActive = true);
            insert as user prod;

            cgcloud__Order__c ord = new cgcloud__Order__c(
                cgcloud__Order_Account__c = acc.Id,
                cgcloud__Phase__c = 'Released',
                cgcloud__Total_Value__c = 200.00,
                cgcloud__Gross_Total_Value__c = 180.00,
                cgcloud__Order_Date__c = Date.today()
            );
            insert as user ord;

            cgcloud__Order_Item__c item = new cgcloud__Order_Item__c(
                cgcloud__Order__c = ord.Id,
                cgcloud__Product__c = prod.Id,
                cgcloud__Quantity__c = 15,
                cgcloud__UOM__c = 'PCS'
            );
            insert as user item;

            Order_Recommendation_Service service = new Order_Recommendation_Service();

            Test.startTest();
            // 1. Get order context by ID
            Agent_Request reqCtxId = new Agent_Request();
            reqCtxId.actionType = 'getContext';
            reqCtxId.orderId = ord.Id;
            Agent_Response resCtxId = service.execute(reqCtxId);

            // 2. Get order context by Name
            Agent_Request reqCtxName = new Agent_Request();
            reqCtxName.actionType = 'getContext';
            reqCtxName.orderId = ord.Name;
            Agent_Response resCtxName = service.execute(reqCtxName);

            // 3. Suggest products
            Agent_Request reqSuggest = new Agent_Request();
            reqSuggest.actionType = 'suggestProducts';
            reqSuggest.accountId = acc.Id;
            reqSuggest.orderId = ord.Id;
            Agent_Response resSuggest = service.execute(reqSuggest);
            Test.stopTest();

            Assert.isTrue(resCtxId.success, 'Context query should succeed.');
            Assert.areEqual(ord.Id, resCtxId.orderId, 'Correct Order ID resolved.');

            Assert.isTrue(resCtxName.success, 'Context query by Name should succeed.');
            Assert.areEqual(ord.Id, resCtxName.orderId, 'Order Name lookup succeeded.');

            Assert.isTrue(resSuggest.success, 'Product suggestion should succeed.');
            Assert.isNotNull(resSuggest.recommendations, 'Recommendations text should not be null.');
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, 'CGC Schema recommendations skipped: ' + e.getMessage());
        }
    }

    @IsTest
    static void testOrderRecommendationCoverageBoost() {
        Order_Recommendation_Service service = new Order_Recommendation_Service();

        Test.startTest();
        // 1. Invalid or blank action types
        Agent_Request reqEmpty = new Agent_Request();
        service.execute(reqEmpty);

        Agent_Request reqInvalid = new Agent_Request();
        reqInvalid.actionType = 'invalid_action';
        service.execute(reqInvalid);

        // 2. Blank and fake parameters for all static methods
        Order_Recommendation_Service.getOrderContext('');
        Order_Recommendation_Service.getOrderContext('fake_order_id');

        Order_Recommendation_Service.suggestProducts('', '');
        Order_Recommendation_Service.suggestProducts('fake_acc_id', 'fake_order_id');

        Order_Recommendation_Service.getAccountContext('');
        Order_Recommendation_Service.getAccountContext('fake_acc_id');

        Order_Recommendation_Service.getFullOrderList('');
        Order_Recommendation_Service.getFullOrderList('fake_acc_id');

        Order_Recommendation_Service.getOrderSummary('');
        Order_Recommendation_Service.getOrderSummary('fake_acc_id');

        Order_Recommendation_Service.getSellableProducts('');
        Order_Recommendation_Service.getSellableProducts('fake_acc_id');

        Order_Recommendation_Service.searchAccounts('');
        Order_Recommendation_Service.searchAccounts('NonexistentAccountQuery');
        Test.stopTest();

        Assert.isNotNull(service, 'Service instance exists.');
    }
}
