// Updated to refresh local IDE compiler index
global with sharing class Agent_Response {
    @InvocableVariable(description='True if operation succeeded.')
    global Boolean success;

    @InvocableVariable(description='Outcome message.')
    global String message;
    @InvocableVariable(description='Current user profile name')
    global String profileName;
    @InvocableVariable(description='List of users')
    global List<UserOption> users;

    @InvocableVariable(description='The CreateVisitWrapper object populated with the current visit details.')
    public CreateVisitWrapper createVisitWrapper;

    // Generic IDs and Names
    @InvocableVariable(description='The Account ID.')
    global String accountId;
    @InvocableVariable(description='The Account Name.')
    global String accountName;
    @InvocableVariable(description='The Visit ID.')
    global String visitId;
    @InvocableVariable(description='The Order ID.')
    global String orderId;
    @InvocableVariable(description='The Order Name.')
    global String orderName;
    @InvocableVariable(description='The Place ID.')
    global String placeId;
    @InvocableVariable(description='The Place Name.')
    global String placeName;
    @InvocableVariable(description='The Template ID.')
    global String templateId;
    @InvocableVariable(description='The Template Name.')
    global String templateName;

    // Common Strings
    @InvocableVariable(description='Store brief markdown summary.')
    global String summary;
    @InvocableVariable(description='Visit summary report.')
    global String visitSummary;
    @InvocableVariable(description='Visit summary wrapper object.')
    public VisitSummaryWrapper visitSummaryObj;
    @InvocableVariable(description='The Visit Status.')
    global String visitStatus;
    @InvocableVariable(description='The Visit Date.')
    global String visitDate;
    @InvocableVariable(description='The Visit End Date.')
    global String visitEndDate;
    @InvocableVariable(description='The Accountable User.')
    global String accountableUser;
    @InvocableVariable(description='The Assigned User.')
    global String assignedUser;
    @InvocableVariable(description='The parsed planned start date/time (ISO string).')
    global String plannedStartTimeStr;
    @InvocableVariable(description='Serialized list of matched IDs if ambiguous.')
    global String suggestions;
    @InvocableVariable(description='True if user input has been submitted.')
    global Boolean isSubmitted;

    @InvocableVariable(description='The matched Owner/Responsible User ID.')
    global String ownerId;

    @InvocableVariable(description='The matched Owner/Responsible User Name.')
    global String ownerName;

    // Order/Recommendation Specific
    @InvocableVariable(description='The Order Status/Phase.')
    global String orderStatus;
    @InvocableVariable(description='Total orders.')
    global Integer totalOrders;
    @InvocableVariable(description='Total spend.')
    global Decimal totalSpend;
    @InvocableVariable(description='AI buying insight.')
    global String buyingInsight;
    @InvocableVariable(description='Phase breakdown.')
    global String phaseBreakdown;
    @InvocableVariable(description='Recent orders list.')
    global String recentOrders;
    @InvocableVariable(description='Formatted list of recommended products.')
    global String recommendations;
    @InvocableVariable(description='Total number of line items.')
    global Integer itemCount;
    @InvocableVariable(description='Formatted text summary of line items.')
    global String itemsSummary;
    @InvocableVariable(description='Formatted recent orders text.')
    global String recentOrdersText;

    // Account Specific Counts
    @InvocableVariable(description='Total Contacts count.')
    global Integer totalContacts;
    @InvocableVariable(description='Total Visits count.')
    global Integer totalVisits;
    @InvocableVariable(description='Pending Visit Tasks count.')
    global Integer pendingVisitTasks;
    @InvocableVariable(description='Total Activities count.')
    global Integer totalActivities;
    @InvocableVariable(description='Completed Activities count.')
    global Integer completedActivities;
    @InvocableVariable(description='Pending Activities count.')
    global Integer pendingActivities;
    @InvocableVariable(description='The Account Age in days.')
    global Integer accountAge;
    @InvocableVariable(description='The Account Phone number.')
    global String accountPhone;
    @InvocableVariable(description='The Account Email.')
    global String accountEmail;
    @InvocableVariable(description='The Account Location Navigate link.')
    global String locationNavigateLink;
    @InvocableVariable(description='Active Promotions count.')
    global Integer activePromotions;
    @InvocableVariable(description='Out of Stock count.')
    global Integer outOfStockCount;
    @InvocableVariable(description='Total Retail Stores count.')
    global Integer totalRetailStores;
    @InvocableVariable(description='Total Store Assortments count.')
    global Integer totalAssortments;
    @InvocableVariable(description='Total Store Products count.')
    global Integer totalStoreProducts;
    @InvocableVariable(description='Total Tactics count.')
    global Integer totalTactics;
    @InvocableVariable(description='Total Assortment Products count.')
    global Integer totalAssortmentProducts;

    // List structures
    @InvocableVariable(description='List of available/matching visits.')
    global List<VisitOption> visits;
    @InvocableVariable(description='List of overdue and stale visits.')
    global List<StaleVisitInfo> staleVisits;
    @InvocableVariable(description='List of matching orders.')
    global List<OrderOption> orders;
    @InvocableVariable(description='List of matching accounts.')
    global List<AccountOption> accounts;
    @InvocableVariable(description='Line items.')
    global List<OrderItem> items;
    @InvocableVariable(description='List of related records.')
    global List<RecordInfo> records;
    @InvocableVariable(description='List of activities and questions/surveys associated with the visit.')
    global List<ActivityInfo> activities;
    @InvocableVariable(description='List of visit jobs (questions/surveys) with answer status.')
    global List<JobStatusInfo> jobs;
    @InvocableVariable(description='List of next steps options.')
    global List<ItemDetail> itemDetails;

    // Inner Classes


    /**
     * @description Auto-generated ApexDoc for class.
     */
    global class UserOption {
        @InvocableVariable(description='The User ID.')
        global String userId;
        @InvocableVariable(description='The User Name.')
        global String name;
        @InvocableVariable(description='The User Alias.')
        global String alias;
        @InvocableVariable(description='The Profile Name of the User.')
        global String profileName;
    }

    /**
     * @description Auto-generated ApexDoc for class.
     */
    global class VisitOption {
        @InvocableVariable(description='The Visit ID.')
        global String visitId;
        @InvocableVariable(description='The associated Account ID.')
        global String accountId;
        @InvocableVariable(description='The associated Account Name.')
        global String accountName;
        @InvocableVariable(description='Formatted label.')
        global String label;
        @InvocableVariable(description='Category (e.g. Today, Upcoming).')
        global String category;

        public VisitOption() { /* empty block */ }
        public VisitOption(String id, String accId, String accName, String lbl) {
            this.visitId = id;
            this.accountId = accId;
            this.accountName = accName;
            this.label = lbl;
            this.category = null;
        }
        public VisitOption(String id, String accId, String accName, String lbl, String cat) {
            this.visitId = id;
            this.accountId = accId;
            this.accountName = accName;
            this.label = lbl;
            this.category = cat;
        }
    }

    /**
     * @description Auto-generated ApexDoc for class.
     */
    global class OrderOption {
        @InvocableVariable(description='The Order ID.')
        global String orderId;
        @InvocableVariable(description='The Order Name/Number.')
        global String orderName;
        @InvocableVariable(description='The parent Account ID.')
        global String accountId;
        @InvocableVariable(description='The parent Account Name.')
        global String accountName;
        @InvocableVariable(description='Formatted label with order info.')
        global String label;

        public OrderOption() { /* empty block */ }
        public OrderOption(String id, String name, String accId, String accName, String lbl) {
            this.orderId = id;
            this.orderName = name;
            this.accountId = accId;
            this.accountName = accName;
            this.label = lbl;
        }
    }

    /**
     * @description Auto-generated ApexDoc for class.
     */
    global class AccountOption {
        @InvocableVariable(description='The Account ID.')
        global String accountId;
        @InvocableVariable(description='The Account Name.')
        global String accountName;
        @InvocableVariable(description='Formatted label with account name.')
        global String label;

        public AccountOption() { /* empty block */ }
        public AccountOption(String id, String name, String lbl) {
            this.accountId = id;
            this.accountName = name;
            this.label = lbl;
        }
    }

    /**
     * @description Auto-generated ApexDoc for class.
     */
    global class OrderItem {
        @InvocableVariable(description='Product name.')
        global String productName;
        @InvocableVariable(description='Quantity ordered.')
        global Decimal quantity;
        @InvocableVariable(description='Unit of measure.')
        global String uom;
    }

    /**
     * @description Auto-generated ApexDoc for class.
     */
    global class RecordInfo {
        @InvocableVariable(description='Record name.')
        global String name;
        @InvocableVariable(description='Record status.')
        global String status;
        @InvocableVariable(description='Record owner.')
        global String owner;
        @InvocableVariable(description='Record last modified date.')
        global DateTime lastModified;
        @InvocableVariable(description='Formatted label.')
        global String label;

        public RecordInfo() { /* empty block */ }
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

    /**
     * @description Auto-generated ApexDoc for class.
     */
    global class ActivityInfo {
        @InvocableVariable(description='The ID of the Job Definition List record.')
        global String activityId;
        @InvocableVariable(description='The Name of the activity.')
        global String activityName;
        @InvocableVariable(description='The description of the activity.')
        global String description;
        @InvocableVariable(description='List of related questions/surveys.')
        global List<QuestionInfo> questions;
    }

    /**
     * @description Auto-generated ApexDoc for class.
     */
    global class QuestionInfo {
        @InvocableVariable(description='The ID of the Job Definition Template record.')
        global String questionId;
        @InvocableVariable(description='The Name of the question/survey.')
        global String questionName;
        @InvocableVariable(description='The description of the question/survey.')
        global String description;
        @InvocableVariable(description='Is this question mandatory?')
        global Boolean mandatory;
        @InvocableVariable(description='The type of job definition template: Question or Survey.')
        global String jobType;
    }

    /**
     * @description Auto-generated ApexDoc for class.
     */
    global class JobStatusInfo {
        @InvocableVariable(description='The ID of the Visit Job record.')
        global String jobId;
        @InvocableVariable(description='The Name of the job definition template.')
        global String questionName;
        @InvocableVariable(description='The description of the question/survey.')
        global String questionDescription;
        @InvocableVariable(description='Whether the question/survey has been answered.')
        global Boolean isDone;
        @InvocableVariable(description='The raw answer value.')
        global String value;
        @InvocableVariable(description='The formatted display answer value.')
        global String displayValue;
        @InvocableVariable(description='Associated product name if applicable.')
        global String productName;
        @InvocableVariable(description='Associated promotion name if applicable.')
        global String promotionName;
        @InvocableVariable(description='The type of job: Question or Survey.')
        global String jobType;
        @InvocableVariable(description='The total number of products to check for this survey.')
        global Integer totalProductCount;
    }

    /**
     * @description Auto-generated ApexDoc for class.
     */
    global class ItemDetail {
        @InvocableVariable(description='The text label of the option.')
        global String itemName;
        @InvocableVariable(description='The description of the option.')
        global String itemDescriptionText;
        @InvocableVariable(description='The image URL of the option.')
        global String itemImageUrl;
        @InvocableVariable(description='The MIME type of the option image.')
        global String itemMimeType;

        public ItemDetail() { /* empty block */ }
        public ItemDetail(String itemName, String itemDescriptionText) {
            this.itemName = itemName;
            this.itemDescriptionText = itemDescriptionText;
            this.itemImageUrl = null;
            this.itemMimeType = null;
        }
    }

    /**
     * @description Data structure representing a stale or overdue visit.
     */
    global class StaleVisitInfo {
        @InvocableVariable(description='The Visit Record ID.')
        global String visitId;
        @InvocableVariable(description='The Visit Name.')
        global String visitName;
        @InvocableVariable(description='The Account Name.')
        global String accountName;
        @InvocableVariable(description='The Current Status of the Visit.')
        global String status;
        @InvocableVariable(description='The Name of the Responsible Rep.')
        global String responsibleRepName;
        @InvocableVariable(description='The ID of the Responsible Rep.')
        global String responsibleRepId;
        @InvocableVariable(description='The Planned Start Time.')
        global DateTime plannedStartTime;
        @InvocableVariable(description='The Created Date of the Visit.')
        global DateTime createdDate;
    }
}