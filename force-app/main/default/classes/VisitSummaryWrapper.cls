global class VisitSummaryWrapper {
    @AuraEnabled
    @InvocableVariable(description='The store name.')
    global String storeName;

    @AuraEnabled
    @InvocableVariable(description='The visit date string.')
    global String visitDate;

    @AuraEnabled
    @InvocableVariable(description='The visit status.')
    global String visitStatus;

    @AuraEnabled
    @InvocableVariable(description='The assigned representative.')
    global String assignedUser;

    @AuraEnabled
    @InvocableVariable(description='The number of completed tasks.')
    global Integer completedTasks;

    @AuraEnabled
    @InvocableVariable(description='The number of pending tasks.')
    global Integer pendingTasks;

    @AuraEnabled
    @InvocableVariable(description='The number of promotions checked.')
    global Integer promotionsChecked;

    @AuraEnabled
    @InvocableVariable(description='The number of out-of-stock issues found.')
    global Integer outOfStockIssues;

    @AuraEnabled
    @InvocableVariable(description='The number of orders created during this visit.')
    global Integer ordersCreated;

    @AuraEnabled
    @InvocableVariable(description='The total value of orders created.')
    global Decimal orderValue;

    @AuraEnabled
    @InvocableVariable(description='The notes recorded for this visit.')
    global String representativeNotes;

    @AuraEnabled
    @InvocableVariable(description='The overall outcome of the visit.')
    global String overallOutcome;

    @AuraEnabled
    @InvocableVariable(description='Recommended next steps for the user.')
    global List<Suggestion> suggestions;

    global class Suggestion {
        @AuraEnabled
        @InvocableVariable(description='ID of the suggestion.')
        global String id;

        @AuraEnabled
        @InvocableVariable(description='The label to display on the button.')
        global String label;

        @AuraEnabled
        @InvocableVariable(description='The text command to inject on click.')
        global String command;

        @AuraEnabled
        @InvocableVariable(description='The SLDS icon name for the button.')
        global String icon;

        global Suggestion() {}
        global Suggestion(String id, String label, String command, String icon) {
            this.id = id;
            this.label = label;
            this.command = command;
            this.icon = icon;
        }
    }

    global VisitSummaryWrapper() {}
}
