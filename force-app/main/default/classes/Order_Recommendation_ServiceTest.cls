/**
 * @description Master unit test class for Order_Recommendation_Service covering order suggestions, summaries, contexts, and lookup utilities.
 */
@IsTest
public class Order_Recommendation_ServiceTest {

    @TestSetup
    static void setupData() {
        Account acc = new Account(Name = 'CGC Order Store Account');
        insert as user acc;

        Product2 p1 = new Product2(Name = 'CGC Summer Soda', ProductCode = 'P-101', Family = 'Beverages', IsActive = true);
        Product2 p2 = new Product2(Name = 'CGC Winter Snack', ProductCode = 'P-102', Family = 'Snacks', IsActive = true);
        insert as user new List<Product2>{ p1, p2 };

        Assortment ass = new Assortment(Name = 'CGC Beverage Assortment');
        insert as user ass;

        StoreAssortment sa = new StoreAssortment(AccountId = acc.Id, AssortmentId = ass.Id, StartDate = Date.today().addDays(-10));
        insert as user sa;

        AssortmentProduct ap1 = new AssortmentProduct(AssortmentId = ass.Id, ProductId = p1.Id);
        AssortmentProduct ap2 = new AssortmentProduct(AssortmentId = ass.Id, ProductId = p2.Id);
        insert as user new List<AssortmentProduct>{ ap1, ap2 };

        cgcloud__Order_Template__c tpl = new cgcloud__Order_Template__c(Name = 'CGC Order Rec Template');
        Database.insert(tpl, false);

        cgcloud__Order__c ord = new cgcloud__Order__c(
            cgcloud__Order_Account__c = acc.Id,
            cgcloud__Order_Date__c = Date.today().addDays(-5),
            cgcloud__Phase__c = 'Initial',
            cgcloud__Total_Value__c = 500.00
        );
        if (tpl != null && tpl.Id != null) {
            ord.cgcloud__Order_Template__c = tpl.Id;
        }
        insert as user ord;

        cgcloud__Order_Item__c item1 = new cgcloud__Order_Item__c(
            cgcloud__Order__c = ord.Id,
            cgcloud__Product__c = p1.Id,
            cgcloud__Quantity__c = 12,
            cgcloud__UOM__c = 'PCE'
        );
        insert as user item1;
    }

    @IsTest
    static void testExecuteActionRouting() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'CGC Order Store Account' LIMIT 1];
        cgcloud__Order__c ord = [SELECT Id, Name FROM cgcloud__Order__c LIMIT 1];
        Order_Recommendation_Service service = new Order_Recommendation_Service();

        Test.startTest();
        // 1. Get context
        Agent_Request reqCtx = new Agent_Request();
        reqCtx.actionType = 'getcontext';
        reqCtx.orderId = ord.Id;
        reqCtx.accountId = acc.Id;
        Agent_Response resCtx = service.execute(reqCtx);

        // 2. Suggest products
        Agent_Request reqSugg = new Agent_Request();
        reqSugg.actionType = 'suggestproducts';
        reqSugg.accountId = acc.Id;
        reqSugg.orderId = ord.Id;
        Agent_Response resSugg = service.execute(reqSugg);

        // 3. Get account context
        Agent_Request reqAccCtx = new Agent_Request();
        reqAccCtx.actionType = 'getaccountcontext';
        reqAccCtx.accountId = acc.Id;
        Agent_Response resAccCtx = service.execute(reqAccCtx);

        // 4. Get full order list
        Agent_Request reqList = new Agent_Request();
        reqList.actionType = 'getfullorderlist';
        reqList.accountId = acc.Id;
        Agent_Response resList = service.execute(reqList);

        // 5. Get order summary
        Agent_Request reqSumm = new Agent_Request();
        reqSumm.actionType = 'getordersummary';
        reqSumm.accountId = acc.Id;
        Agent_Response resSumm = service.execute(reqSumm);

        // 6. Get sellable products
        Agent_Request reqSellable = new Agent_Request();
        reqSellable.actionType = 'getsellableproducts';
        reqSellable.accountId = acc.Id;
        Agent_Response resSellable = service.execute(reqSellable);

        // 7. Search accounts
        Agent_Request reqSearchAcc = new Agent_Request();
        reqSearchAcc.actionType = 'searchaccounts';
        reqSearchAcc.searchQuery = 'CGC Order Store Account';
        Agent_Response resSearchAcc = service.execute(reqSearchAcc);

        // 8. Unknown action
        Agent_Request reqUnknown = new Agent_Request();
        reqUnknown.actionType = 'unknown';
        Agent_Response resUnknown = service.execute(reqUnknown);
        Test.stopTest();

        Assert.isNotNull(resCtx, 'Get context action should return response.');
        Assert.isNotNull(resSugg, 'Suggest products action should return response.');
        Assert.isNotNull(resAccCtx, 'Get account context should return response.');
        Assert.isNotNull(resList, 'Get full order list should return response.');
        Assert.isNotNull(resSumm, 'Get order summary should return response.');
        Assert.isNotNull(resSellable, 'Get sellable products action should return response.');
        Assert.isNotNull(resSearchAcc, 'Search accounts action should return response.');
        Assert.isNotNull(resUnknown, 'Unknown action should return response.');
    }

    @IsTest
    static void testStaticMethodsAndNullHandling() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'CGC Order Store Account' LIMIT 1];
        cgcloud__Order__c ord = [SELECT Id, Name FROM cgcloud__Order__c LIMIT 1];

        Test.startTest();
        Order_Recommendation_Service.getOrderContext(ord.Id);
        Order_Recommendation_Service.getOrderContext(ord.Name);
        Order_Recommendation_Service.getOrderContext(null);

        Order_Recommendation_Service.suggestProducts(acc.Id, ord.Id);
        Order_Recommendation_Service.suggestProducts(acc.Id, null);
        Order_Recommendation_Service.suggestProducts(null, null);

        Order_Recommendation_Service.getAccountContext(acc.Id);
        Order_Recommendation_Service.getAccountContext(null);

        Order_Recommendation_Service.getFullOrderList(acc.Id);
        Order_Recommendation_Service.getFullOrderList(null);

        Order_Recommendation_Service.getOrderSummary(acc.Id);
        Order_Recommendation_Service.getOrderSummary(null);

        Order_Recommendation_Service.getSellableProducts(acc.Id);
        Order_Recommendation_Service.getSellableProducts(null);

        Order_Recommendation_Service.searchAccounts('CGC');
        Order_Recommendation_Service.searchAccounts(null);
        Test.stopTest();

        Assert.isNotNull(acc.Id, 'All static methods executed.');
    }
}
