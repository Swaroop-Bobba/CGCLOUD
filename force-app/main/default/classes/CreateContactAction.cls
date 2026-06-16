public class CreateContactAction {
    public class Request {
        @InvocableVariable(label='Account ID' required=true)
        public String accountId;
        @InvocableVariable(label='Contact Name' required=true)
        public String contactName;
        @InvocableVariable(label='Email Address' required=true)
        public String emailAddress;
        @InvocableVariable(label='Mobile Number' required=true)
        public String mobileNumber;
        @InvocableVariable(label='Designation' required=true)
        public String designation;
        @InvocableVariable(label='Is Primary' required=true)
        public Boolean isPrimary;
    }
    
    public class Result {
        @InvocableVariable(label='Contact ID')
        public String contactId;
        @InvocableVariable(label='Success')
        public Boolean success;
        @InvocableVariable(label='Error Message')
        public String errorMessage;
    }
    
    @InvocableMethod(label='Create Contact' description='Creates a Contact and links it to an Account')
    public static List<Result> createContact(List<Request> requests) {
        List<Result> results = new List<Result>();
        for (Request req : requests) {
            Result res = new Result();
            try {
                // Split contactName assuming First Last format
                String firstName = '';
                String lastName = req.contactName;
                if (req.contactName != null && req.contactName.contains(' ')) {
                    firstName = req.contactName.substringBefore(' ');
                    lastName = req.contactName.substringAfter(' ');
                }
                
                Contact con = new Contact(
                    AccountId = req.accountId,
                    FirstName = firstName,
                    LastName = lastName,
                    Email = req.emailAddress,
                    MobilePhone = req.mobileNumber,
                    Title = req.designation,
                    cgcloud__Job_Title__c = req.designation
                );
                insert con;
                res.contactId = con.Id;
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
