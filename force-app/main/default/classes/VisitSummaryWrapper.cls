/**
 * @description Wrapper class for Visit Summary properties.
 */
public class VisitSummaryWrapper {
    @AuraEnabled
    @InvocableVariable(description='The store name.')
    public String storeName;

    @AuraEnabled
    @InvocableVariable(description='The visit date string.')
    public String visitDate;

    @AuraEnabled
    @InvocableVariable(description='The visit status.')
    public String visitStatus;

    @AuraEnabled
    @InvocableVariable(description='The assigned representative.')
    public String assignedUser;

    @AuraEnabled
    @InvocableVariable(description='The number of completed tasks.')
    public Integer completedTasks;

    @AuraEnabled
    @InvocableVariable(description='The number of pending tasks.')
    public Integer pendingTasks;

    @AuraEnabled
    @InvocableVariable(description='The number of promotions checked.')
    public Integer promotionsChecked;

    @AuraEnabled
    @InvocableVariable(description='The number of out-of-stock issues found.')
    public Integer outOfStockIssues;

    @AuraEnabled
    @InvocableVariable(description='The number of orders created during this visit.')
    public Integer ordersCreated;

    @AuraEnabled
    @InvocableVariable(description='The total value of orders created.')
    public Decimal orderValue;

    @AuraEnabled
    @InvocableVariable(description='The notes recorded for this visit.')
    public String representativeNotes;

    @AuraEnabled
    @InvocableVariable(description='The overall outcome of the visit.')
    public String overallOutcome;

    @AuraEnabled
    @InvocableVariable(description='Recommended next steps for the user.')
    public List<Suggestion> suggestions;

    /**
     * @description Auto-generated ApexDoc for class.
     */
    public class Suggestion {
        @AuraEnabled
        @InvocableVariable(description='ID of the suggestion.')
        public String id;

        @AuraEnabled
        @InvocableVariable(description='The label to display on the button.')
        public String label;

        @AuraEnabled
        @InvocableVariable(description='The text command to inject on click.')
        public String command;

        @AuraEnabled
        @InvocableVariable(description='The SLDS icon name for the button.')
        public String icon;

        /**
         * @description Default empty constructor required for serialization.
         */
        @SuppressWarnings('PMD.EmptyStatementBlock')
        public Suggestion() { /* empty block */ }
        /**
         * @description Parameterized constructor for Suggestion.
         * @param id The ID of the suggestion.
         * @param label The label to display.
         * @param command The text command.
         * @param icon The SLDS icon name.
         */
        @SuppressWarnings('PMD.ExcessiveParameterList')
        public Suggestion(String id, String label, String command, String icon) {
            this.id = id;
            this.label = label;
            this.command = command;
            this.icon = icon;
        }
    }

    /**
     * @description Default empty constructor required for serialization.
     */
    @SuppressWarnings('PMD.EmptyStatementBlock')
    public VisitSummaryWrapper() { /* empty block */ }
}
