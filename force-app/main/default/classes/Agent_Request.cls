/**
 * @description Represents a generic request payload used by Agent handlers and services.
 *              Contains all necessary fields to route and execute agent actions.
 */
@SuppressWarnings('PMD.ExcessivePublicCount, PMD.TooManyFields')
global with sharing class Agent_Request {
    @InvocableVariable(required=false description='The domain of the agent (e.g. Visit, Account, Order, OrderRecommendation, VisitActivity).')
    global String domain;

    @InvocableVariable(required=true description='The type of action to perform.')
    global String actionType;

    @InvocableVariable(description='The name of the agent executing the request.')
    global String agentName;

    @InvocableVariable(description='Matched Template')
    global String matchedTemplate;

    @InvocableVariable(description='The search query.')
    global String searchQuery;

    @InvocableVariable(description='The Account ID.')
    global String accountId;

    @InvocableVariable(description='The Visit ID.')
    global String visitId;

    @InvocableVariable(description='List of Visit record IDs to send notifications for.')
    global List<String> visitIds;

    @InvocableVariable(description='The Order ID.')
    global String orderId;

    @InvocableVariable(description='The Place ID.')
    global String placeId;

    // Visit Wrappers
    @InvocableVariable(description='Visit Creation details (wrapper).')
    global CreateVisitWrapper createVisitWrapper;

    // String inputs
    @InvocableVariable(description='New status value (string).')
    global String status;
    @InvocableVariable(description='Notes.')
    global String notes;
    @InvocableVariable(description='Name of the user to assign.')
    global String ownerName;
    @InvocableVariable(description='Record ID of the user to assign.')
    global String ownerId;
    @InvocableVariable(description='Alias of the user to assign.')
    global String ownerAlias;
    @InvocableVariable(description='Profile Name of the user to assign.')
    global String ownerProfileName;

    @InvocableVariable(description='Actual start date/time.')
    global DateTime startTime;
    @InvocableVariable(description='Actual end date/time.')
    global DateTime endTime;
    @InvocableVariable(description='New planned start date/time (DateTime).')
    global DateTime plannedStartTime;
    @InvocableVariable(description='New planned end date/time (DateTime).')
    global DateTime plannedEndTime;

    // Conversational Inputs
    @InvocableVariable(description='Account name or ID input.')
    global String accountInput;
    @InvocableVariable(description='Place name or ID input.')
    global String placeInput;
    @InvocableVariable(description='Template name or ID input.')
    global String templateInput;
    @InvocableVariable(description='Planned start time input string.')
    global String plannedStartTimeStr;
    @InvocableVariable(description='Planned end time input string.')
    global String plannedEndTimeStr;
    @InvocableVariable(description='Visit subject.')
    global String subject;
    @InvocableVariable(description='True if it is an all-day event.')
    global Boolean isAllDayEvent;
    @InvocableVariable(description='Accountable user input.')
    global String accountableInput;
    @InvocableVariable(description='Responsible user input.')
    global String responsibleInput;
    @InvocableVariable(description='Suggestions string for conversational retry.')
    global String suggestions;

    // Order specifics
    @InvocableVariable(description='The Order ID or Name for notes updates.')
    global String orderIdentifier;
    @InvocableVariable(description='New delivery note text.')
    global String deliveryNote;
    @InvocableVariable(description='New invoice note text.')
    global String invoiceNote;

    // Account specifics
    @InvocableVariable(description='The record type/category to retrieve related records for.')
    global String recordType;

    // Activity specifics
    @InvocableVariable(description='Filter status for visit jobs (all, answered, pending).')
    global String statusFilter;
    @InvocableVariable(description='The option label to exclude.')
    global String excludeOption;
    @InvocableVariable(description='Filter by question type: all, question, survey')
    global String questionOrSurveyFilter;
    // Promotion specifics
    @InvocableVariable(description='The Promotion ID or Name.')
    global String promotionId;

    @InvocableVariable(description='The query offset for pagination.')
    global String searchOffset;
}