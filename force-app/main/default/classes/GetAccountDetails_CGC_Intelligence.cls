public with sharing class GetAccountDetails_CGC_Intelligence {
    public class Request {
        @InvocableVariable(required=true description='The Account ID.')
        public String accountId;
    }
    public class Result {
        @InvocableVariable(description='The Account ID.')
        public String accountId;
        @InvocableVariable(description='The Account Name.')
        public String accountName;
    }
    @InvocableMethod(
        label='Get Account Details (CGC_Intelligence)'
        description='Retrieve Account Name from Account ID.'
    )
    public static List<Result> execute(List<Request> requests) {
        List<Result> results = new List<Result>();
        Set<Id> accountIds = new Set<Id>();
        for (Request req : requests) {
            if (String.isNotBlank(req.accountId)) {
                try {
                    accountIds.add((Id) req.accountId.trim());
                } catch (Exception e) {}
            }
        }
        Map<Id, Account> accountsMap = new Map<Id, Account>([
            SELECT Id, Name FROM Account WHERE Id IN :accountIds WITH USER_MODE
        ]);
        for (Request req : requests) {
            Result res = new Result();
            if (String.isNotBlank(req.accountId)) {
                String trimmedId = req.accountId.trim();
                res.accountId = trimmedId;
                if (accountsMap.containsKey(trimmedId)) {
                    res.accountName = accountsMap.get(trimmedId).Name;
                }
            }
            results.add(res);
        }
        return results;
    }
}