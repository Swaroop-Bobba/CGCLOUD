public class CreateAccountAction {
    public class Request {
        @InvocableVariable(label='Account Name' required=true)
        public String accountName;
        @InvocableVariable(label='Mobile Number' required=true)
        public String mobileNumber;
        @InvocableVariable(label='Email Address' required=true)
        public String emailAddress;
        @InvocableVariable(label='Address' required=true)
        public String address;
        @InvocableVariable(label='City' required=true)
        public String city;
        @InvocableVariable(label='State' required=true)
        public String state;
        @InvocableVariable(label='Postal Code' required=true)
        public String postalCode;
        @InvocableVariable(label='Country' required=true)
        public String country;
    }
    
    public class Result {
        @InvocableVariable(label='Account ID')
        public String accountId;
        @InvocableVariable(label='Success')
        public Boolean success;
        @InvocableVariable(label='Error Message')
        public String errorMessage;
    }
    
    @InvocableMethod(label='Create Account' description='Creates a new customer account')
    public static List<Result> createAccount(List<Request> requests) {
        List<Result> results = new List<Result>();
        for (Request req : requests) {
            Result res = new Result();
            try {
                Account acc = new Account(
                    Name = req.accountName,
                    Phone = req.mobileNumber,
                    cgcloud__Account_Email__c = req.emailAddress,
                    // Billing Address
                    BillingStreet = req.address,
                    BillingCity = req.city,
                    BillingState = req.state,
                    BillingPostalCode = req.postalCode,
                    BillingCountry = req.country,
                    // Shipping Address
                    ShippingStreet = req.address,
                    ShippingCity = req.city,
                    ShippingState = req.state,
                    ShippingPostalCode = req.postalCode,
                    ShippingCountry = req.country
                );
                insert acc;
                res.accountId = acc.Id;
                res.success = true;
                res.errorMessage = '';
            } catch (Exception e) {
                res.success = false;
                res.errorMessage = e.getMessage();
            }
            results.add(res);
        }
        return results;
    }
}
