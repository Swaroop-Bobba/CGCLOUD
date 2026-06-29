public with sharing class GetNextStepsOptions {
    @InvocableMethod(
        label='Get Next Steps Options'
        description='Returns a list of next steps options for the CGC Visit Activity Agent to be rendered as clickable choice cards.'
    )
    public static List<Result> execute(List<Request> requests) {
        List<Result> results = new List<Result>();
        
        for (Request req : requests) {
            Result res = new Result();
            res.itemDetails = new List<ItemDetail>();
            
            addOption(res.itemDetails, 'View today\'s activities or surveys', 'View planned activities and surveys for the current visit.', req.excludeOption);
            addOption(res.itemDetails, 'See answered or pending questions', 'Check completed vs pending questions/surveys for the current visit.', req.excludeOption);
            addOption(res.itemDetails, 'Check all questions and survey statuses', 'List all questions and surveys status for the current visit.', req.excludeOption);
            addOption(res.itemDetails, 'Switch to another visit', 'Clear active visit context and select a different visit.', req.excludeOption);
            
            results.add(res);
        }
        
        return results;
    }
    
    private static void addOption(List<ItemDetail> itemDetails, String label, String description, String excludeOption) {
        if (String.isNotBlank(excludeOption) && label.equalsIgnoreCase(excludeOption)) {
            return;
        }
        itemDetails.add(new ItemDetail(label, description));
    }
    
    public class Request {
        @InvocableVariable(description='The option label to exclude from the returned list.')
        public String excludeOption;
    }
    
    public class Result {
        @InvocableVariable(description='List of next steps options.')
        public List<ItemDetail> itemDetails;
    }
    
    public class ItemDetail {
        @InvocableVariable(description='The text label of the option.')
        public String itemName;
        
        @InvocableVariable(description='The description of the option.')
        public String itemDescriptionText;
        
        @InvocableVariable(description='The image URL of the option.')
        public String itemImageUrl;
        
        @InvocableVariable(description='The MIME type of the option image.')
        public String itemMimeType;
        
        public ItemDetail() {}
        
        public ItemDetail(String itemName, String itemDescriptionText) {
            this.itemName = itemName;
            this.itemDescriptionText = itemDescriptionText;
            this.itemImageUrl = null;
            this.itemMimeType = null;
        }
    }
}
