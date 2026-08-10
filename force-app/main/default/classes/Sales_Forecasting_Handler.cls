global with sharing class Sales_Forecasting_Handler {

    global class Request {
        @InvocableVariable(required=true description='The name of the agent executing the request.')
        global String agentName;

        @InvocableVariable(required=true description='The type of action to perform (e.g. getOrderForecast, getProductForecast, getCustomerForecast, getSalesForecast, getInventoryForecast, getVisitForecast, searchAccounts).')
        global String actionType;

        @InvocableVariable(description='The Account ID.')
        global String accountId;

        @InvocableVariable(description='The Visit ID.')
        global String visitId;

        @InvocableVariable(description='The Order ID.')
        global String orderId;

        @InvocableVariable(description='The Product ID.')
        global String productId;

        @InvocableVariable(description='The forecasting period: week, month, quarter.')
        global String period;

        @InvocableVariable(description='The forecast breakdown dimension: account, route, rep.')
        global String forecastBy;

        @InvocableVariable(description='The search query.')
        global String searchQuery;
    }

    global class Result {
        @InvocableVariable(description='Whether the forecast calculation was successful.')
        global Boolean success;

        @InvocableVariable(description='The generated forecast summary.')
        global String forecastSummary;

        @InvocableVariable(description='The confidence level of the prediction (High, Medium, Low).')
        global String confidenceLevel;

        @InvocableVariable(description='Key factors and reasoning data points.')
        global String reasoning;

        @InvocableVariable(description='List of matching accounts from search.')
        global List<AccountOption> accounts;
    }

    global class AccountOption {
        @InvocableVariable(description='The Account ID.')
        global String accountId;
        @InvocableVariable(description='The Account Name.')
        global String accountName;
        @InvocableVariable(description='Formatted label with account name.')
        global String label;

        global AccountOption() {}
        global AccountOption(String id, String name, String lbl) {
            this.accountId = id;
            this.accountName = name;
            this.label = lbl;
        }
    }

    @InvocableMethod(
        label='Sales Forecasting Agent Handler'
        description='Handles order, product, customer, sales, inventory, and visit predictions'
    )
    global static List<Result> execute(List<Request> requests) {
        List<Result> results = new List<Result>();
        for (Request req : requests) {
            Result res = new Result();
            String action = req.actionType != null ? req.actionType.toLowerCase().trim() : '';

            if (action == 'getorderforecast') {
                res = Sales_Forecasting_Service.getOrderForecast(req.accountId, req.orderId);
            } else if (action == 'getproductforecast') {
                res = Sales_Forecasting_Service.getProductForecast(req.accountId, req.productId);
            } else if (action == 'getcustomerforecast') {
                res = Sales_Forecasting_Service.getCustomerForecast(req.accountId);
            } else if (action == 'getsalesforecast') {
                res = Sales_Forecasting_Service.getSalesForecast(req.accountId, req.period, req.forecastBy);
            } else if (action == 'getinventoryforecast') {
                res = Sales_Forecasting_Service.getInventoryForecast(req.accountId, req.productId);
            } else if (action == 'getvisitforecast') {
                res = Sales_Forecasting_Service.getVisitForecast(req.accountId);
            } else if (action == 'searchaccounts') {
                res.accounts = Sales_Forecasting_Service.searchAccounts(req.searchQuery);
                res.success = true;
            } else {
                res.success = false;
                res.forecastSummary = 'Unknown forecasting action type: ' + req.actionType;
            }
            results.add(res);
        }
        return results;
    }
}