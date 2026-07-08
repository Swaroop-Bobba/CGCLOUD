public with sharing class Agent_Response {
    @InvocableVariable(description='True if operation succeeded.')
    public Boolean success;

    @InvocableVariable(description='Outcome message.')
    public String message;
    @InvocableVariable(description='Current user profile name')
    public String profileName;
    @InvocableVariable(description='List of users')
    public List<UserOption> users;

    @InvocableVariable(description='The CreateVisitWrapper object populated with the current visit details.')
    public CreateVisitWrapper createVisitWrapper;

    // Generic IDs and Names
    @InvocableVariable(description='The Account ID.')
    public String accountId;
    @InvocableVariable(description='The Account Name.')
    public String accountName;
    @InvocableVariable(description='The Visit ID.')
    public String visitId;
    @InvocableVariable(description='The Order ID.')
    public String orderId;
    @InvocableVariable(description='The Order Name.')
    public String orderName;
    @InvocableVariable(description='The Place ID.')
    public String placeId;
    @InvocableVariable(description='The Place Name.')
    public String placeName;
    @InvocableVariable(description='The Template ID.')
    public String templateId;
    @InvocableVariable(description='The Template Name.')
    public String templateName;

    // Common Strings
    @InvocableVariable(description='Store brief markdown summary.')
    public String summary;
    @InvocableVariable(description='Visit summary report.')
    public String visitSummary;
    @InvocableVariable(description='Visit summary wrapper object.')
    public VisitSummaryWrapper visitSummaryObj;
    @InvocableVariable(description='The Visit Status.')
    public String visitStatus;
    @InvocableVariable(description='The Visit Date.')
    public String visitDate;
    @InvocableVariable(description='The Assigned User.')
    public String assignedUser;
    @InvocableVariable(description='The parsed planned start date/time (ISO string).')
    public String plannedStartTimeStr;
    @InvocableVariable(description='Serialized list of matched IDs if ambiguous.')
    public String suggestions;
    @InvocableVariable(description='True if user input has been submitted.')
    public Boolean isSubmitted;

    // Order/Recommendation Specific
    @InvocableVariable(description='The Order Status/Phase.')
    public String orderStatus;
    @InvocableVariable(description='Total orders.')
    public Integer totalOrders;
    @InvocableVariable(description='Total spend.')
    public Decimal totalSpend;
    @InvocableVariable(description='AI buying insight.')
    public String buyingInsight;
    @InvocableVariable(description='Phase breakdown.')
    public String phaseBreakdown;
    @InvocableVariable(description='Recent orders list.')
    public String recentOrders;
    @InvocableVariable(description='Formatted list of recommended products.')
    public String recommendations;
    @InvocableVariable(description='Total number of line items.')
    public Integer itemCount;
    @InvocableVariable(description='Formatted text summary of line items.')
    public String itemsSummary;
    @InvocableVariable(description='Formatted recent orders text.')
    public String recentOrdersText;

    // Account Specific Counts
    @InvocableVariable(description='Total Contacts count.')
    public Integer totalContacts;
    @InvocableVariable(description='Total Visits count.')
    public Integer totalVisits;
    @InvocableVariable(description='Pending Visit Tasks count.')
    public Integer pendingVisitTasks;
    @InvocableVariable(description='Active Promotions count.')
    public Integer activePromotions;
    @InvocableVariable(description='Out of Stock count.')
    public Integer outOfStockCount;
    @InvocableVariable(description='Total Retail Stores count.')
    public Integer totalRetailStores;
    @InvocableVariable(description='Total Store Assortments count.')
    public Integer totalAssortments;
    @InvocableVariable(description='Total Store Products count.')
    public Integer totalStoreProducts;
    @InvocableVariable(description='Total Tactics count.')
    public Integer totalTactics;
    @InvocableVariable(description='Total Assortment Products count.')
    public Integer totalAssortmentProducts;

    // List structures
    @InvocableVariable(description='List of available/matching visits.')
    public List<VisitOption> visits;
    @InvocableVariable(description='List of matching orders.')
    public List<OrderOption> orders;
    @InvocableVariable(description='List of matching accounts.')
    public List<AccountOption> accounts;
    @InvocableVariable(description='Line items.')
    public List<OrderItem> items;
    @InvocableVariable(description='List of related records.')
    public List<RecordInfo> records;
    @InvocableVariable(description='List of activities and questions/surveys associated with the visit.')
    public List<ActivityInfo> activities;
    @InvocableVariable(description='List of visit jobs (questions/surveys) with answer status.')
    public List<JobStatusInfo> jobs;
    @InvocableVariable(description='List of next steps options.')
    public List<ItemDetail> itemDetails;

    // Inner Classes


    /**
     * @description Auto-generated ApexDoc for class.
     */
    public class UserOption {
        @InvocableVariable(description='The User ID.')
        public String userId;
        @InvocableVariable(description='The User Name.')
        public String name;
        @InvocableVariable(description='The User Alias.')
        public String alias;
        @InvocableVariable(description='The Profile Name of the User.')
        public String profileName;
    }

    /**
     * @description Auto-generated ApexDoc for class.
     */
    public class VisitOption {
        @InvocableVariable(description='The Visit ID.')
        public String visitId;
        @InvocableVariable(description='The associated Account ID.')
        public String accountId;
        @InvocableVariable(description='The associated Account Name.')
        public String accountName;
        @InvocableVariable(description='Formatted label.')
        public String label;
        @InvocableVariable(description='Category (e.g. Today, Upcoming).')
        public String category;

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
    public class OrderOption {
        @InvocableVariable(description='The Order ID.')
        public String orderId;
        @InvocableVariable(description='The Order Name/Number.')
        public String orderName;
        @InvocableVariable(description='The parent Account ID.')
        public String accountId;
        @InvocableVariable(description='The parent Account Name.')
        public String accountName;
        @InvocableVariable(description='Formatted label with order info.')
        public String label;

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
    public class AccountOption {
        @InvocableVariable(description='The Account ID.')
        public String accountId;
        @InvocableVariable(description='The Account Name.')
        public String accountName;
        @InvocableVariable(description='Formatted label with account name.')
        public String label;

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
    public class OrderItem {
        @InvocableVariable(description='Product name.')
        public String productName;
        @InvocableVariable(description='Quantity ordered.')
        public Decimal quantity;
        @InvocableVariable(description='Unit of measure.')
        public String uom;
    }

    /**
     * @description Auto-generated ApexDoc for class.
     */
    public class RecordInfo {
        @InvocableVariable(description='Record name.')
        public String name;
        @InvocableVariable(description='Record status.')
        public String status;
        @InvocableVariable(description='Record owner.')
        public String owner;
        @InvocableVariable(description='Record last modified date.')
        public DateTime lastModified;
        @InvocableVariable(description='Formatted label.')
        public String label;

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
    public class ActivityInfo {
        @InvocableVariable(description='The ID of the Job Definition List record.')
        public String activityId;
        @InvocableVariable(description='The Name of the activity.')
        public String activityName;
        @InvocableVariable(description='The description of the activity.')
        public String description;
        @InvocableVariable(description='List of related questions/surveys.')
        public List<QuestionInfo> questions;
    }

    /**
     * @description Auto-generated ApexDoc for class.
     */
    public class QuestionInfo {
        @InvocableVariable(description='The ID of the Job Definition Template record.')
        public String questionId;
        @InvocableVariable(description='The Name of the question/survey.')
        public String questionName;
        @InvocableVariable(description='The description of the question/survey.')
        public String description;
        @InvocableVariable(description='Is this question mandatory?')
        public Boolean mandatory;
        @InvocableVariable(description='The type of job definition template: Question or Survey.')
        public String jobType;
    }

    /**
     * @description Auto-generated ApexDoc for class.
     */
    public class JobStatusInfo {
        @InvocableVariable(description='The ID of the Visit Job record.')
        public String jobId;
        @InvocableVariable(description='The Name of the job definition template.')
        public String questionName;
        @InvocableVariable(description='The description of the question/survey.')
        public String questionDescription;
        @InvocableVariable(description='Whether the question/survey has been answered.')
        public Boolean isDone;
        @InvocableVariable(description='The raw answer value.')
        public String value;
        @InvocableVariable(description='The formatted display answer value.')
        public String displayValue;
        @InvocableVariable(description='Associated product name if applicable.')
        public String productName;
        @InvocableVariable(description='Associated promotion name if applicable.')
        public String promotionName;
        @InvocableVariable(description='The type of job: Question or Survey.')
        public String jobType;
        @InvocableVariable(description='The total number of products to check for this survey.')
        public Integer totalProductCount;
    }

    /**
     * @description Auto-generated ApexDoc for class.
     */
    public class ItemDetail {
        @InvocableVariable(description='The text label of the option.')
        public String itemName;
        @InvocableVariable(description='The description of the option.')
        public String itemDescriptionText;
        @InvocableVariable(description='The image URL of the option.')
        public String itemImageUrl;
        @InvocableVariable(description='The MIME type of the option image.')
        public String itemMimeType;

        public ItemDetail() { /* empty block */ }
        public ItemDetail(String itemName, String itemDescriptionText) {
            this.itemName = itemName;
            this.itemDescriptionText = itemDescriptionText;
            this.itemImageUrl = null;
            this.itemMimeType = null;
        }
    }
}
