public with sharing class Sales_Forecasting_Handler {

    public class Request {
        @InvocableVariable(required=true description='The name of the agent executing the request.')
        public String agentName;

        @InvocableVariable(required=true description='The type of action to perform (e.g. getOrderForecast, getProductForecast, getCustomerForecast, getSalesForecast, getInventoryForecast, getVisitForecast, searchAccounts).')
        public String actionType;

        @InvocableVariable(description='The Account ID.')
        public String accountId;

        @InvocableVariable(description='The Visit ID.')
        public String visitId;

        @InvocableVariable(description='The Order ID.')
        public String orderId;

        @InvocableVariable(description='The Product ID.')
        public String productId;

        @InvocableVariable(description='The forecasting period: week, month, quarter.')
        public String period;

        @InvocableVariable(description='The forecast breakdown dimension: account, route, rep.')
        public String forecastBy;

        @InvocableVariable(description='The search query.')
        public String searchQuery;
    }

    public class Result {
        @InvocableVariable(description='Whether the forecast calculation was successful.')
        public Boolean success;

        @InvocableVariable(description='The generated forecast summary.')
        public String forecastSummary;

        @InvocableVariable(description='The confidence level of the prediction (High, Medium, Low).')
        public String confidenceLevel;

        @InvocableVariable(description='Key factors and reasoning data points.')
        public String reasoning;

        @InvocableVariable(description='List of matching accounts from search.')
        public List<AccountOption> accounts;
    }

    public class AccountOption {
        @InvocableVariable(description='The Account ID.')
        public String accountId;
        @InvocableVariable(description='The Account Name.')
        public String accountName;
        @InvocableVariable(description='Formatted label with account name.')
        public String label;

        public AccountOption() {}
        public AccountOption(String id, String name, String lbl) {
            this.accountId = id;
            this.accountName = name;
            this.label = lbl;
        }
    }

    @InvocableMethod(
        label='Sales Forecasting Agent Handler'
        description='Handles order, product, customer, sales, inventory, and visit predictions'
    )
    public static List<Result> execute(List<Request> requests) {
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