public with sharing class SearchAccounts_CGC_Intelligence {
    public class Request {
        @InvocableVariable(required=true description='The search query.')
        public String searchQuery;
    }
    public class Result {
        @InvocableVariable(description='List of matching accounts.')
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
        label='Search Accounts (CGC_Intelligence)'
        description='Search for Account records by name.'
    )
    public static List<Result> execute(List<Request> requests) {
        List<Result> results = new List<Result>();
        for (Request req : requests) {
            Result res = new Result();
            res.accounts = new List<AccountOption>();
            String q = req.searchQuery;
            if (String.isNotBlank(q)) {
                String pattern = '%' + q.trim().replaceAll('\\s+', '%') + '%';
                List<Account> accs = [
                    SELECT Id, Name, BillingCity FROM Account 
                    WHERE Name LIKE :pattern 
                    WITH USER_MODE 
                    LIMIT 15
                ];
                for (Account a : accs) {
                    String lbl = a.Name + (String.isNotBlank(a.BillingCity) ? ' (' + a.BillingCity + ')' : '');
                    res.accounts.add(new AccountOption(a.Id, a.Name, lbl));
                }
            }
            results.add(res);
        }
        return results;
    }
}