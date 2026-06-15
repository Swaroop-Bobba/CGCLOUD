public with sharing class Account_Agent_Handler {

    public class Request {
        @InvocableVariable(required=true description='The name of the agent executing the request (e.g. CGC_Intelligence or Visit_Intelligence).')
        public String agentName;

        @InvocableVariable(required=true description='The type of action to perform (e.g. getDetails, search, getCounts, getRecords, suggestProducts).')
        public String actionType;

        @InvocableVariable(description='The Account ID.')
        public String accountId;

        @InvocableVariable(description='The search query.')
        public String searchQuery;

        @InvocableVariable(description='The record type/category to retrieve related records for.')
        public String recordType;
    }

    public class Result {
        @InvocableVariable(description='The Account ID.')
        public String accountId;

        @InvocableVariable(description='The Account Name.')
        public String accountName;

        @InvocableVariable(description='List of matching accounts.')
        public List<AccountOption> accounts;

        // Count variables
        @InvocableVariable(description='Total Contacts count.')
        public Integer totalContacts;
        @InvocableVariable(description='Total Visits count.')
        public Integer totalVisits;
        @InvocableVariable(description='Pending Visit Tasks count.')
        public Integer pendingVisitTasks;
        @InvocableVariable(description='Active Promotions count.')
        public Integer activePromotions;
        @InvocableVariable(description='Out of Stock count.')
        public Integer outOfStockCount;
        @InvocableVariable(description='Total Retail Stores count.')
        public Integer totalRetailStores;
        @InvocableVariable(description='Total Store Assortments count.')
        public Integer totalAssortments;
        @InvocableVariable(description='Total Store Products count.')
        public Integer totalStoreProducts;
        @InvocableVariable(description='Total Tactics count.')
        public Integer totalTactics;
        @InvocableVariable(description='Total Assortment Products count.')
        public Integer totalAssortmentProducts;

        // Records list
        @InvocableVariable(description='List of related records.')
        public List<RecordInfo> records;

        // Product suggestions
        @InvocableVariable(description='Formatted list of recommended products.')
        public String recommendations;
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

    public class RecordInfo {
        @InvocableVariable(description='Record name.')
        public String name;
        @InvocableVariable(description='Record status.')
        public String status;
        @InvocableVariable(description='Record owner.')
        public String owner;
        @InvocableVariable(description='Record last modified date.')
        public DateTime lastModified;
        @InvocableVariable(description='Formatted label.')
        public String label;

        public RecordInfo() {}
        public RecordInfo(String n, String s, String o, DateTime lm) {
            this.name = n;
            this.status = s;
            this.owner = o;
            this.lastModified = lm;
            this.label = n + '\n   - Status: ' + s + '\n   - Owner: ' + o;
        }
        public RecordInfo(String n, String s, String o, DateTime lm, String lbl) {
            this.name = n;
            this.status = s;
            this.owner = o;
            this.lastModified = lm;
            this.label = lbl;
        }
    }

    @InvocableMethod(
        label='Account Agent Handler'
        description='Handles all Account operations for Agents'
    )
    public static List<Result> execute(List<Request> requests) {
        List<Result> results = new List<Result>();
        for (Request req : requests) {
            Result res = new Result();
            String action = req.actionType != null ? req.actionType.toLowerCase().trim() : '';

            if (action == 'getdetails') {
                res = Account_Agent_Service.getAccountDetails(req.accountId);
            } else if (action == 'search') {
                res.accounts = Account_Agent_Service.searchAccounts(req.searchQuery);
            } else if (action == 'getcounts') {
                res = Account_Agent_Service.getRelatedCounts(req.accountId);
            } else if (action == 'getrecords') {
                res.records = Account_Agent_Service.getRelatedRecords(req.accountId, req.recordType);
            } else if (action == 'suggestproducts') {
                res.recommendations = Account_Agent_Service.suggestProducts(req.accountId);
            }
            results.add(res);
        }
        return results;
    }
}
