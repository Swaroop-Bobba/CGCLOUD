# Salesforce Consumer Goods Cloud (CGC) Visit Intelligence Agent
## Technical Architecture & Implementation Documentation

---

## 1. Executive Summary & Solution Architecture

The **CGC Visit Intelligence Agent** is an enterprise AI solution built natively on the Salesforce Agentforce platform for **Salesforce Consumer Goods (CG) Cloud**. It empowers field representatives and retail sales supervisors to perform pre-visit planning, retail store execution audits, order history analysis, dynamic metric calculations, predictive sales forecasting, visit rescheduling, and interactive visit creation directly within natural language chat interfaces.

### System Architecture Layer Breakdown

| Layer # | Layer Name | Core Components | Technical Role & Capabilities |
| :--- | :--- | :--- | :--- |
| **1** | **Interaction & Client Layer** | Desktop UI & Mobile UI | Renders Agentforce chat interface, interactive LWC forms (Desktop), and conversational multi-turn prompts (Mobile). |
| **2** | **Agentforce Intelligence Engine** | `VisitIntelDesktop.agent`, `VisitIntelMobile.agent` | Orchestrates context loading, intent routing, reasoning logic, and subagent action dispatching. |
| **3** | **Custom Lightning Types & LWCs** | `createVisitWrapperType`, `visitUpdatePayloadType`, `createVisitEditor`, `visitUpdaterWizard` | Bridges Agentforce generative context with custom LWC input components and DTO wrappers. |
| **4** | **Flow Automation** | `Get_Visit_Details` (AutoLaunched Flow) | Automatically queries and populates Visit and Account context variables upon session startup. |
| **5** | **Domain Controllers** | `VisitAgentController`, `AccountAgentController`, `OrderAgentController`, `VisitActivityController`, `SalesForecastingController`, `RecordCalculationController`, `UserContextController`, `VisitUpdaterActionController` | Invocable Apex services executing business logic, SOQL queries, forecasting calculations, and DML operations. |
| **6** | **Support Apex & Utilities** | `CreateVisitLwcController`, `VisitUpdaterLwcController`, `AgentFuzzyMatchUtility` | Provides `@AuraEnabled` backend methods for LWCs, string distance fuzzy matching, and NLP datetime parsing. |
| **7** | **Security & Governance** | `Visit_Intel_Access` Permission Set, `Google1` & `Google2` CSP Trusted Sites | Grants role-based permissions to all agent classes/flows and configures image and map endpoint security. |

---

## 2. Agentforce AI Agent Bundles (`aiAuthoringBundles`)

The workspace contains two dedicated Agentforce agent authoring bundles configured with the **Anthropic Claude 3.5 Sonnet** model (`model://sfdc_ai__DefaultBedrockAnthropicClaude45Sonnet`).

### Agent Specification Overview

| Attribute | `VisitIntelDesktop` | `VisitIntelMobile` |
| :--- | :--- | :--- |
| **Agent Label** | Visit Intelligence Desktop | Visit Intelligence Mobile |
| **Agent Type** | `AgentforceEmployeeAgent` | `AgentforceEmployeeAgent` |
| **Target User** | Supervisors & Reps on Desktop | Field Reps on Salesforce Mobile App |
| **UI Modality** | Interactive LWC Editors & Wizards | 100% Plain Text Multi-Turn State Machine |
| **Locales** | `en_US` (default), `en_GB` | `en_US` (default), `en_GB` |

---

### Subagent Architecture & Routing Matrix

| User Input / Intent | Target Subagent | Functional Description | Primary Invocable Action / Tool |
| :--- | :--- | :--- | :--- |
| **Session Startup** | `agent_router` | Detects `currentRecordId`, executes context loader, and routes user. | `Get_Visit_Details` Flow |
| **Option 1 / "Account Summary"** | `visit_intelligence` | Displays full Account 360 overview, address, and maps navigation link. | `AccountAgentController.getAccountDetails` |
| **Option 2 / "Contacts"** | `visit_intelligence` | Lists key account contacts, phone numbers, and email links. | `AccountAgentController.getAccountContacts` |
| **Option 3 / "Promotions"** | `visit_intelligence` | Audits active trade promotions and merchandising compliance. | `AccountAgentController.getPromotions` |
| **Option 4 / "Pre-Visit Brief"** | `visit_intelligence` | Delivers account background, revenue trends, and focus points. | `AccountAgentController.getStoreBrief` |
| **Option 5 / "Inventory / OOS"** | `visit_intelligence` | Audits out-of-stock items and retail inventory levels. | `OrderAgentController.getInventoryChecks` |
| **Option 6 / "Order History"** | `visit_intelligence` | Summarizes past orders, total spend, and recent line items. | `OrderAgentController.getAccountOrderSummary` |
| **Option 7 / "Update Visit"** | `visit_updater` | Reschedules visit dates, updates status, notes, or assigned users. | `VisitUpdaterActionController.executeUpdate` |
| **Option 8 / "Products"** | `visit_intelligence` | Displays authorized assortment products for the retail store. | `AccountAgentController.getProducts` |
| **Option 9 / "Activities"** | `visit_activities` | Inspects retail assessment tasks, survey jobs, and delivery checklists. | `VisitActivityController.getActivities` |
| **"Create Visit" / "Schedule"** | `create_visit` | Captures parameters (via LWC form or conversational prompts) to insert a visit. | `VisitAgentController.create_visit_record` |
| **"Forecast" / "Predict Sales"** | `forecasting_insights` | Projects future sales volumes, product demand, and account churn risks. | `SalesForecastingController.getSalesForecast` |
| **"Calculate" / "Sum" / "Average"** | `record_calculations_insights` | Computes dynamic SOQL aggregate totals strictly in user mode. | `RecordCalculationController.execute` |
| **"Switch Visit" / "Reset"** | `clear_context` | Clears active visit memory and resets to visit selection list. | System Context Reset |

---

### Desktop vs. Mobile Modality Step-by-Step Flow

| Step # | Interaction Stage | Desktop Modality Flow | Mobile Modality Flow | Backend Execution |
| :--- | :--- | :--- | :--- | :--- |
| **1** | **User Initiation** | User types "Create visit". | User types "Create visit". | `agent_router` delegates to `create_visit` subagent. |
| **2** | **Data Solicitation** | Displays interactive modal form `createVisitEditor`. | Prompts user: "Please enter the Account name:". | Desktop loads LWC; Mobile enters conversational state machine. |
| **3** | **Lookup & Selection** | User types in search box; debounced SOSL queries populate dropdowns. | User enters text; fuzzy matching resolves closest account name. | `CreateVisitLwcController.searchAccounts` (Desktop) vs. `AgentFuzzyMatchUtility.findBestMatchAccount` (Mobile). |
| **4** | **Date & Parameter Entry** | User picks datetime from standard UI calendar and time picker. | User enters "Tomorrow at 10 AM"; NLP engine parses date. | Standard UI binding (Desktop) vs. `AgentFuzzyMatchUtility.parseDateTime` (Mobile). |
| **5** | **Execution & Submission** | Form emits `change` event with populated `CreateVisitWrapper` DTO. | Subagent gathers all slot variables and invokes create action. | `VisitAgentController.create_visit_record` executes atomic DML insert. |
| **6** | **Confirmation Response** | Displays confirmation card with direct Lightning navigation link. | Displays success message with direct Lightning navigation link. | `[Visit Record](/lightning/r/Visit/{Id}/view)` rendered to user. |

---

### Global Agent Directives & Formatting Constraints

1. **Strict Lightning Navigation URLs**:
   All record references for Visits, Accounts, Orders, Contacts, Opportunities, Cases, and Products MUST be formatted as complete Lightning view paths starting with a leading slash:
   - `[V-00000370](/lightning/r/Visit/0Z5f6000000DWeqCAG/view)`
   - `[Fresh Mart](/lightning/r/Account/001f6000003XyzAAC/view)`
   - `[O-00518](/lightning/r/Order/02hdn00000qckbua0/view)`

   *Note: Using the `/lightning/r/<ObjectName>/<RecordId>/view` format ensures that users clicking record links in chat are routed seamlessly inside Salesforce Lightning Experience without page reloads.*

2. **Direct Google Maps Protocol**:
   All location links use direct Google Maps search parameters:
   - `[Open in Google Maps](https://www.google.com/maps?q=123+Main+St+San+Francisco+CA)`
   
   Direct telephony and email links use standard RFC protocols:
   - Phone: `[(415) 555-0199](tel:4155550199)` (Numeric digits only in URL parameter).
   - Email: `[contact@domain.com](mailto:contact@domain.com)`.

3. **Numbered List Rendering for Visits**:
   Search and list actions enforce sequentially numbered lists starting at `1` to enable unambiguous integer-based index selection by users.

---

## 3. Custom Lightning Types & LWC Architecture

Custom Lightning Types bridge Agentforce's generative AI context with custom Lightning Web Components.

### Lightning Types and LWC Mapping Table

| Lightning Type Name | Apex Schema DTO | Paired LWC Editor | Key UI & Functional Capabilities |
| :--- | :--- | :--- | :--- |
| **`createVisitWrapperType`** | `CreateVisitWrapper.cls` | `c/createVisitEditor` | • Debounced SOSL lookups for Account, Place/Store, Visit Template, and Users.<br/>• Auto-detects and pre-populates the assigned Responsible User based on login context.<br/>• Binds user selections directly to the agent's `createVisitWrapper` DTO variable. |
| **`visitUpdatePayloadType`** | `VisitUpdatePayload.cls` | `c/visitUpdaterWizard` | • 4-stage interactive wizard: (1) Field Selection, (2) Dynamic Inputs, (3) Review Diff, (4) Confirmation.<br/>• Supports updating Subject, Status, Planned Dates, Responsible, Accountable, and Notes.<br/>• Outputs JSON payload in `updatesJson` for transactional DML execution. |

---

## 4. Automation & Flow Layer (`flows`)

### Flow: `Get_Visit_Details`
- **Flow**: `Get_Visit_Details.flow-meta.xml`
- **Type**: `AutoLaunchedFlow` (API v61.0).
- **Description**: High-performance, self-contained record context extractor executed automatically by the `agent_router` subagent when a session initiates.

### Flow Execution Steps Table

| Step # | Flow Action / Decision | Logic & Evaluation | Resulting Variable Assignment |
| :--- | :--- | :--- | :--- |
| **1** | **Lookup Visit** | Queries `Visit` record by incoming `recordId`. | Populates Visit `AccountId`, `PlaceId`, `PlannedStartTime`, `PlannedEndTime`, `Status`, and `Name`. |
| **2** | **Account Evaluation** | Checks if `AccountId` is populated on Visit. | If blank, queries associated `RetailStore` using `PlaceId` to resolve `AccountId`. |
| **3** | **Rep User Evaluation** | Checks if `cgcloud__Responsible__c` is populated. | If populated, sets query user to Responsible User; otherwise falls back to `OwnerId`. |
| **4** | **Lookup Account Name** | Queries `Account.Name` using resolved `AccountId`. | Sets `accountName` output variable. |
| **5** | **Lookup Assigned Rep** | Queries `User.Name` using resolved user ID. | Sets `assignedUser` output variable. |
| **6** | **Lookup Accountable User** | Queries `User.Name` using `cgcloud__Accountable__c`. | Sets `accountableUser` output variable. |
| **7** | **Return Context** | Completes Flow execution. | Returns all context variables to Agentforce session memory. |

#### Flow Variable Specifications

| Variable | Type | In / Out | Purpose |
| :--- | :--- | :--- | :--- |
| `recordId` | String | Input / Output | The Visit record ID being inspected. |
| `accountId` | String | Output | The associated Account ID (resolved from Visit or RetailStore). |
| `accountName` | String | Output | The Account Name. |
| `assignedUser` | String | Output | Name of the assigned rep (`cgcloud__Responsible__c` or `Owner`). |
| `accountableUser`| String | Output | Name of the accountable supervisor (`cgcloud__Accountable__c`). |
| `visitStatus` | String | Output | Current status of the visit. |
| `visitDate` | String | Output | Planned Visit Start Date & Time. |
| `visitEndDate` | String | Output | Planned Visit End Date & Time. |
| `visitName` | String | Output | Visit identifier name (e.g. `V-00000370`). |

---

## 5. Apex Domain Controllers Reference (`classes`)

The backend architecture is structured around modular domain controllers. Each controller implements an `@InvocableMethod` dispatcher with unified request and response DTOs:

### Comprehensive Controller Reference Matrix

| Class Name | Test Class | Core Action Types (`actionType`) | Key Description & Capabilities |
| :--- | :--- | :--- | :--- |
| `VisitAgentController` | `VisitAgentControllerTest` | `getAvailableVisits`, `searchVisits`, `getVisitDetails`, `getVisitSummary`, `getStoreBrief`, `prompt_visit_mobile`, `create_visit_record`, `update_status`, `update_owner`, `update_notes`, `update_start_time`, `update_end_time` | Primary domain engine for all visit operations, pagination, conversational fuzzy matching, notes and date updates, and visit insertion. |
| `AccountAgentController` | `AccountAgentControllerTest` | `getAccountDetails`, `getCounts`, `getRelatedRecords`, `getProducts`, `getPromotions`, `getStoreBrief`, `getAccountContacts`, `getAccountOpportunities`, `getAccountCases`, `getAccountVisits` | Provides complete Account 360 intelligence, related record rollups, sellable product assortments, and active promotion audits. |
| `OrderAgentController` | `OrderAgentControllerTest` | `getOrders`, `getOrderDetails`, `getAccountOrderSummary`, `getVisitOrderSummary`, `getOrderRecommendations`, `getInventoryChecks` | Queries order history, line item quantities/prices, account spend insights, predictive product recommendations, and inventory checks. |
| `VisitActivityController` | `VisitActivityControllerTest` | `getActivities`, `getJobsStatus`, `getDeliveryActivities`, `getNextSteps` | Inspects `AssessmentTask`, `RetailStoreKpi`, `cgcloud__Visit_Job__c`, survey question responses, and pending retail audit checklists. |
| `SalesForecastingController` | `SalesForecastingControllerTest` | `getOrderForecast`, `getProductForecast`, `getCustomerForecast`, `getSalesForecast`, `getInventoryForecast`, `getVisitForecast` | Statistical and historical trend forecasting engine calculating projected order volumes, revenue run-rates, balance projections, and churn risks. |
| `RecordCalculationController` | `RecordCalculationControllerTest` | `execute` (takes dynamic `query` string) | Executes dynamic SOQL aggregate queries strictly in `AccessLevel.USER_MODE` to compute custom totals, averages, and durations safely. |
| `UserContextController` | `UserContextControllerTest` | `getProfile` | Resolves the logged-in user profile, role, and identity to customize agent responses and permission checks. |
| `VisitUpdaterActionController` | `VisitUpdaterLwcControllerTest` | `executeUpdate` | Deserializes `VisitUpdatePayload` JSON and executes atomic DML updates on `Visit` records. |
| `CreateVisitLwcController` | `CreateVisitLwcControllerTest` | `@AuraEnabled`: `searchAccounts`, `searchPlaces`, `searchTemplates`, `searchUsers`, `getResponsibleUserContext`, `getVisitDataForLwc` | Provides lookup search endpoints, status picklist options, and context resolution for the `createVisitEditor` LWC. |
| `VisitUpdaterLwcController` | `VisitUpdaterLwcControllerTest` | `@AuraEnabled`: `getAvailableVisits`, `getVisitDetails`, `getActiveUsers`, `updateVisitRecord` | Provides visit detail loading, active user lookups, and update execution for the `visitUpdaterWizard` LWC. |
| `AgentFuzzyMatchUtility` | `AgentFuzzyMatchUtilityTest` | Utility: `findBestMatchAccount`, `findBestMatchPlace`, `findBestMatchTemplate`, `findBestMatchUser`, `parseDateTime` | Implements Levenshtein string distance algorithm (0–100 similarity score) and natural language datetime parser ("tomorrow at 10am", "next Monday"). |

---

## 6. Security, Permissions & CSP Configuration

### 1. Permission Set Access Matrix: `Visit_Intel_Access`

| Access Category | Component / Artifact Name | Access Type | Purpose / Description |
| :--- | :--- | :--- | :--- |
| **System Permission** | `RunFlow` | User Permission | Grants permission to execute autolaunched context flows. |
| **Flow Access** | `Get_Visit_Details` | Flow Definition | Allows Agentforce to automatically invoke context extraction flow. |
| **Apex Class Access** | `VisitAgentController` | Apex Class | Enables execution of core visit domain operations and DML actions. |
| **Apex Class Access** | `AccountAgentController` | Apex Class | Enables execution of Account 360, Contacts, and Promotions actions. |
| **Apex Class Access** | `OrderAgentController` | Apex Class | Enables execution of Order History and Inventory audit actions. |
| **Apex Class Access** | `VisitActivityController` | Apex Class | Enables execution of Retail Tasks, Surveys, and Job checklist actions. |
| **Apex Class Access** | `SalesForecastingController` | Apex Class | Enables execution of statistical demand and revenue forecasting. |
| **Apex Class Access** | `RecordCalculationController`| Apex Class | Enables execution of dynamic SOQL calculations in user mode. |
| **Apex Class Access** | `UserContextController` | Apex Class | Enables user profile and sales role resolution. |
| **Apex Class Access** | `VisitUpdaterActionController`| Apex Class | Enables execution of Visit Updater Wizard DML updates. |
| **Apex Class Access** | `CreateVisitLwcController` | Apex Class | Enables `@AuraEnabled` endpoints for Create Visit LWC editor. |
| **Apex Class Access** | `VisitUpdaterLwcController` | Apex Class | Enables `@AuraEnabled` endpoints for Visit Updater LWC wizard. |
| **Apex Class Access** | `AgentFuzzyMatchUtility` | Apex Class | Enables Levenshtein distance matching and NLP date parsing. |

> Whenever new domain controllers, LWC helpers, or action wrappers are created, they must be registered in `Visit_Intel_Access.permissionset-meta.xml`.

---

### 2. Content Security Policy (CSP Trusted Sites)
To permit Google Maps imagery, previews, and map tiles inside Agentforce components, two CSP Trusted Sites are configured:

| Name | File | Endpoint URL | Context | Directives Enabled |
| :--- | :--- | :--- | :--- | :--- |
| **Google1** | `Google1.cspTrustedSite-meta.xml` | `https://*.google.com` | `All` | `isApplicableToImgSrc = true` |
| **Google2** | `Google2.cspTrustedSite-meta.xml` | `https://google.com` | `All` | `isApplicableToImgSrc = true` |

---

### 3. Data Sharing & Security Enforcement
- **User Mode Enforcement**: Controllers executing dynamic SOQL (e.g. `RecordCalculationController`, `CreateVisitLwcController`) execute with `AccessLevel.USER_MODE` or `WITH USER_MODE` to strictly adhere to Field-Level Security (FLS) and Object-Level Security (OLS).
- **`with sharing` Keywords**: Applied across all utility and LWC controller classes to prevent unauthorized record traversal.
- **Defensive Schema Checks**: All SOQL statements utilize `Schema.getGlobalDescribe()` field and object existence checks before querying optional Consumer Goods Cloud managed package fields (`cgcloud__*`).

---

## 7. Packaging & Deployment Configuration

- **Project Definition**: `sfdx-project.json`
- **Package Name**: `CGC_AI_Agent`
- **Namespace**: `VisitIntel`
- **Source API Version**: `67.0`
- **Post-Install Handler**: `PostInstallScript.cls` (automatically validates schema availability upon 2GP package installation).

### Deployment Verification Commands Table

| Command Step | Action Description | CLI Command Line |
| :--- | :--- | :--- |
| **Step 1** | Validate & Deploy Metadata | `sf project deploy start --target-org <ORG_ALIAS>` |
| **Step 2** | Run Apex Unit Test Suite | `sf apex run test --test-level RunSpecifiedTests --tests VisitAgentControllerTest,AccountAgentControllerTest,OrderAgentControllerTest,VisitActivityControllerTest,SalesForecastingControllerTest,RecordCalculationControllerTest,UserContextControllerTest,CreateVisitLwcControllerTest,VisitUpdaterLwcControllerTest,AgentFuzzyMatchUtilityTest --target-org <ORG_ALIAS> --result-format human` |
| **Step 3** | Assign Permission Set | `sf org assign permset --name Visit_Intel_Access --target-org <ORG_ALIAS>` |
| **Step 4** | Preview Agentforce Agent | `sf agent preview --agent VisitIntelDesktop --target-org <ORG_ALIAS>` |

---

## 8. Comprehensive Directory Map Table

| Directory Path | Content Type | Detailed Description & Artifacts |
| :--- | :--- | :--- |
| `force-app/main/default/aiAuthoringBundles/` | Agentforce Agent Bundles | `VisitIntelDesktop` (Desktop LWC modality) and `VisitIntelMobile` (Conversational modality). |
| `force-app/main/default/classes/` | Apex Domain Controllers & Tests | `VisitAgentController`, `AccountAgentController`, `OrderAgentController`, `VisitActivityController`, `SalesForecastingController`, `RecordCalculationController`, `UserContextController`, `VisitUpdaterActionController`, `CreateVisitLwcController`, `VisitUpdaterLwcController`, `AgentFuzzyMatchUtility`, DTOs, and Test classes. |
| `force-app/main/default/cspTrustedSites/` | CSP Trusted Sites | `Google1` and `Google2` metadata files configuring Google Maps image sources. |
| `force-app/main/default/flows/` | Autolaunched Flows | `Get_Visit_Details.flow-meta.xml` context extraction flow. |
| `force-app/main/default/lightningTypes/` | Custom Lightning Types | `createVisitWrapperType` (mapped to `CreateVisitWrapper`) and `visitUpdatePayloadType` (mapped to `VisitUpdatePayload`). |
| `force-app/main/default/lwc/` | Lightning Web Components | `c/createVisitEditor` (Visit Creation Form) and `c/visitUpdaterWizard` (Multi-Step Update Wizard). |
| `force-app/main/default/permissionsets/` | Security & Permissions | `Visit_Intel_Access.permissionset-meta.xml` granting access to classes, flows, and user permissions. |
