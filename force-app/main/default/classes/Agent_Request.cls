/**
 * @description Represents a generic request payload used by Agent handlers and services.
 *              Contains all necessary fields to route and execute agent actions.
 */
@SuppressWarnings('PMD.ExcessivePublicCount, PMD.TooManyFields')
public with sharing class Agent_Request {
    @InvocableVariable(required=false description='The domain of the agent (e.g. Visit, Account, Order, OrderRecommendation, VisitActivity).')
    public String domain;

    @InvocableVariable(required=true description='The type of action to perform.')
    public String actionType;

    @InvocableVariable(description='The name of the agent executing the request.')
    public String agentName;

    @InvocableVariable(description='Matched Template')
    public String matchedTemplate;

    @InvocableVariable(description='The search query.')
    public String searchQuery;

    @InvocableVariable(description='The Account ID.')
    public String accountId;

    @InvocableVariable(description='The Visit ID.')
    public String visitId;

    @InvocableVariable(description='The Order ID.')
    public String orderId;

    @InvocableVariable(description='The Place ID.')
    public String placeId;

    // Visit Wrappers
    @InvocableVariable(description='Visit Creation details (wrapper).')
    public CreateVisitWrapper createVisitWrapper;

    // String inputs
    @InvocableVariable(description='New status value (string).')
    public String status;
    @InvocableVariable(description='Notes.')
    public String notes;
    @InvocableVariable(description='Name of the user to assign.')
    public String ownerName;
    @InvocableVariable(description='Record ID of the user to assign.')
    public String ownerId;
    @InvocableVariable(description='Alias of the user to assign.')
    public String ownerAlias;
    @InvocableVariable(description='Profile Name of the user to assign.')
    public String ownerProfileName;

    @InvocableVariable(description='Actual start date/time.')
    public DateTime startTime;
    @InvocableVariable(description='Actual end date/time.')
    public DateTime endTime;
    @InvocableVariable(description='New planned start date/time (DateTime).')
    public DateTime plannedStartTime;
    @InvocableVariable(description='New planned end date/time (DateTime).')
    public DateTime plannedEndTime;

    // Conversational Inputs
    @InvocableVariable(description='Account name or ID input.')
    public String accountInput;
    @InvocableVariable(description='Place name or ID input.')
    public String placeInput;
    @InvocableVariable(description='Template name or ID input.')
    public String templateInput;
    @InvocableVariable(description='Planned start time input string.')
    public String plannedStartTimeStr;
    @InvocableVariable(description='Planned end time input string.')
    public String plannedEndTimeStr;
    @InvocableVariable(description='Visit subject.')
    public String subject;
    @InvocableVariable(description='True if it is an all-day event.')
    public Boolean isAllDayEvent;
    @InvocableVariable(description='Accountable user input.')
    public String accountableInput;
    @InvocableVariable(description='Responsible user input.')
    public String responsibleInput;
    @InvocableVariable(description='Suggestions string for conversational retry.')
    public String suggestions;

    // Order specifics
    @InvocableVariable(description='The Order ID or Name for notes updates.')
    public String orderIdentifier;
    @InvocableVariable(description='New delivery note text.')
    public String deliveryNote;
    @InvocableVariable(description='New invoice note text.')
    public String invoiceNote;

    // Account specifics
    @InvocableVariable(description='The record type/category to retrieve related records for.')
    public String recordType;

    // Activity specifics
    @InvocableVariable(description='Filter status for visit jobs (all, answered, pending).')
    public String statusFilter;
    @InvocableVariable(description='The option label to exclude.')
    public String excludeOption;
    @InvocableVariable(description='Filter by question type: all, question, survey')
    public String questionOrSurveyFilter;
    // Promotion specifics
    @InvocableVariable(description='The Promotion ID or Name.')
    public String promotionId;

    @InvocableVariable(description='The query offset for pagination.')
    public String searchOffset;
}