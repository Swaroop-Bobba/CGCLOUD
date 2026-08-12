/**
 * @description Master unit test class for Sales_Forecasting_Handler invocable action.
 */
@IsTest
public class Sales_Forecasting_HandlerTest {

    @TestSetup
    static void setupData() {
        Account acc = new Account(Name = 'CGC Forecast Handler Store');
        insert as user acc;
    }

    @IsTest
    static void testExecuteActionRouting() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'CGC Forecast Handler Store' LIMIT 1];

        Test.startTest();
        List<Sales_Forecasting_Handler.Request> reqs = new List<Sales_Forecasting_Handler.Request>();

        Sales_Forecasting_Handler.Request r1 = new Sales_Forecasting_Handler.Request();
        r1.agentName = 'SalesForecastingAgent';
        r1.actionType = 'getOrderForecast';
        r1.accountId = acc.Id;
        reqs.add(r1);

        Sales_Forecasting_Handler.Request r2 = new Sales_Forecasting_Handler.Request();
        r2.agentName = 'SalesForecastingAgent';
        r2.actionType = 'getProductForecast';
        r2.accountId = acc.Id;
        reqs.add(r2);

        Sales_Forecasting_Handler.Request r3 = new Sales_Forecasting_Handler.Request();
        r3.agentName = 'SalesForecastingAgent';
        r3.actionType = 'getCustomerForecast';
        r3.accountId = acc.Id;
        reqs.add(r3);

        Sales_Forecasting_Handler.Request r4 = new Sales_Forecasting_Handler.Request();
        r4.agentName = 'SalesForecastingAgent';
        r4.actionType = 'getSalesForecast';
        r4.accountId = acc.Id;
        r4.period = 'Monthly';
        r4.forecastBy = 'Product';
        reqs.add(r4);

        Sales_Forecasting_Handler.Request r5 = new Sales_Forecasting_Handler.Request();
        r5.agentName = 'SalesForecastingAgent';
        r5.actionType = 'getInventoryForecast';
        r5.accountId = acc.Id;
        reqs.add(r5);

        Sales_Forecasting_Handler.Request r6 = new Sales_Forecasting_Handler.Request();
        r6.agentName = 'SalesForecastingAgent';
        r6.actionType = 'getVisitForecast';
        r6.accountId = acc.Id;
        reqs.add(r6);

        Sales_Forecasting_Handler.Request r7 = new Sales_Forecasting_Handler.Request();
        r7.agentName = 'SalesForecastingAgent';
        r7.actionType = 'searchAccounts';
        r7.searchQuery = 'Forecast';
        reqs.add(r7);

        Sales_Forecasting_Handler.Request rInvalid = new Sales_Forecasting_Handler.Request();
        rInvalid.agentName = 'SalesForecastingAgent';
        rInvalid.actionType = 'invalid_action';
        reqs.add(rInvalid);

        List<Sales_Forecasting_Handler.Result> results = Sales_Forecasting_Handler.execute(reqs);
        Test.stopTest();

        Assert.isNotNull(results, 'Results list should be returned.');
        Assert.areEqual(8, results.size(), 'All 8 request options should return a result.');

        // Inner class test
        Sales_Forecasting_Handler.AccountOption aOpt = new Sales_Forecasting_Handler.AccountOption('acc1', 'Acc', 'Label');
        Assert.isNotNull(aOpt.accountId, 'AccountOption constructor verified.');
    }
}