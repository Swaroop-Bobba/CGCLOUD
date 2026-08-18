/**
 * Unit tests verifying customer churn estimation, order forecasts,
 * product velocity, and account searches in SalesForecastingController.
 */
@IsTest
public class SalesForecastingControllerTest {

    @TestSetup
    static void setupData() {
        Account acc = new Account(
            Name = 'CGC Forecast Handler Store',
            Industry = 'Retail',
            AnnualRevenue = 500000
        );
        insert as user acc;
    }

    @IsTest
    static void testExecuteActionRouting() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'CGC Forecast Handler Store' LIMIT 1];

        Test.startTest();
        List<SalesForecastingController.Request> reqs = new List<SalesForecastingController.Request>();

        SalesForecastingController.Request r1 = new SalesForecastingController.Request();
        r1.agentName = 'SalesForecastingAgent';
        r1.actionType = 'getOrderForecast';
        r1.accountId = acc.Id;
        reqs.add(r1);

        SalesForecastingController.Request r2 = new SalesForecastingController.Request();
        r2.agentName = 'SalesForecastingAgent';
        r2.actionType = 'getProductForecast';
        r2.accountId = acc.Id;
        reqs.add(r2);

        SalesForecastingController.Request r3 = new SalesForecastingController.Request();
        r3.agentName = 'SalesForecastingAgent';
        r3.actionType = 'getCustomerForecast';
        r3.accountId = acc.Id;
        reqs.add(r3);

        SalesForecastingController.Request r4 = new SalesForecastingController.Request();
        r4.agentName = 'SalesForecastingAgent';
        r4.actionType = 'getSalesForecast';
        r4.accountId = acc.Id;
        r4.period = 'Monthly';
        reqs.add(r4);

        SalesForecastingController.Request r5 = new SalesForecastingController.Request();
        r5.agentName = 'SalesForecastingAgent';
        r5.actionType = 'getInventoryForecast';
        r5.accountId = acc.Id;
        reqs.add(r5);

        SalesForecastingController.Request r6 = new SalesForecastingController.Request();
        r6.agentName = 'SalesForecastingAgent';
        r6.actionType = 'getVisitForecast';
        r6.accountId = acc.Id;
        reqs.add(r6);

        SalesForecastingController.Request r7 = new SalesForecastingController.Request();
        r7.agentName = 'SalesForecastingAgent';
        r7.actionType = 'searchAccounts';
        r7.searchQuery = 'Forecast';
        reqs.add(r7);

        SalesForecastingController.Request rInvalid = new SalesForecastingController.Request();
        rInvalid.agentName = 'SalesForecastingAgent';
        rInvalid.actionType = 'invalid_action';
        reqs.add(rInvalid);

        List<SalesForecastingController.Result> results = SalesForecastingController.execute(reqs);
        Test.stopTest();

        Assert.isNotNull(results, 'Results list should be returned.');
        Assert.areEqual(8, results.size(), 'All 8 request options should return a result.');
        Assert.isTrue(results[0].success, 'Order forecast should succeed.');
        Assert.isTrue(results[2].success, 'Customer forecast should succeed.');
    }

    @IsTest
    static void testBlankAccountAndEmptySearch() {
        Test.startTest();
        List<SalesForecastingController.Request> reqs = new List<SalesForecastingController.Request>();

        SalesForecastingController.Request rOrderBlank = new SalesForecastingController.Request();
        rOrderBlank.actionType = 'getOrderForecast';
        rOrderBlank.accountId = '';
        reqs.add(rOrderBlank);

        SalesForecastingController.Request rCustBlank = new SalesForecastingController.Request();
        rCustBlank.actionType = 'getCustomerForecast';
        rCustBlank.accountId = '';
        reqs.add(rCustBlank);

        SalesForecastingController.Request rSearchEmpty = new SalesForecastingController.Request();
        rSearchEmpty.actionType = 'searchAccounts';
        rSearchEmpty.searchQuery = 'NonExistentStore12345';
        reqs.add(rSearchEmpty);

        List<SalesForecastingController.Result> results = SalesForecastingController.execute(reqs);
        Test.stopTest();

        Assert.areEqual(3, results.size(), 'All 3 edge cases should return.');
        Assert.isFalse(results[0].success, 'Order forecast without account should fail gracefully.');
        Assert.isFalse(results[1].success, 'Customer forecast without account should fail gracefully.');
        Assert.isTrue(results[2].success, 'Empty search should succeed with no matches message.');
    }
}