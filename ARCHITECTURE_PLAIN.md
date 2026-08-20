# Salesforce Consumer Goods Cloud (CGC) Visit Intelligence Agent
## Technical Architecture & Implementation Documentation

---

## 1. Executive Summary & Solution Architecture

The **CGC Visit Intelligence Agent** is an enterprise AI solution built natively on the Salesforce Agentforce platform for **Salesforce Consumer Goods (CG) Cloud**. It empowers field representatives and retail sales supervisors to perform pre-visit planning, retail store execution audits, order history analysis, dynamic metric calculations, predictive sales forecasting, visit rescheduling, and interactive visit creation directly within natural language chat interfaces.

### High-Level System Architecture Diagram

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                       1. INTERACTION & CLIENT LAYER                          │
├──────────────────────────────────────┬───────────────────────────────────────┤
│          DESKTOP EXPERIENCE          │           MOBILE EXPERIENCE           │
│  (Agentforce Chat + LWC Editors)     │       (Multi-Turn Conversational)     │
└──────────────────┬───────────────────┴───────────────────┬───────────────────┘
                   │                                       │
                   ▼                                       ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│            2. AGENTFORCE INTELLIGENCE ENGINE (aiAuthoringBundles)            │
├──────────────────────────────────────────────────────────────────────────────┤
│                         agent_router (Context & Router)                      │
│                                       │                                      │
│  ┌─────────────────┬──────────────────┼──────────────────┬────────────────┐  │
│  ▼                 ▼                  ▼                  ▼                ▼  │
│visit_intelligence visit_activities forecasting_insights record_calc_insights │  │
│  │                 │                  │                  │                   │
│  │                 │                  ▼                  ▼                   │
│  │                 │             create_visit       visit_updater            │
│  │                 │                                                         │
│  └─────────────────┴──────────────────┬───────────────────────────────────┘  │
└───────────────────────────────────────┼──────────────────────────────────────┘
                                        │
        ┌───────────────────────────────┼───────────────────────────────┐
        ▼                               ▼                               ▼
┌──────────────────────┐    ┌──────────────────────┐    ┌──────────────────────┐
│  3. LIGHTNING TYPES  │    │  4. FLOW AUTOMATION  │    │ 5. DOMAIN CONTROLLERS│
│     & LWC EDITORS    │    │                      │    │   (@InvocableMethod) │
├──────────────────────┤    ├──────────────────────┤    ├──────────────────────┤
│ • createVisitEditor  │    │ • Get_Visit_Details  │    │ • VisitAgentCtrl     │
│ • visitUpdaterWizard │    │   (AutoLaunched Flow)│    │ • AccountAgentCtrl   │
│ • Wrapper Types      │    │   Extracts Visit &   │    │ • OrderAgentCtrl     │
│   (DTO Bindings)     │    │   Account Context    │    │ • VisitActivityCtrl  │
└──────────┬───────────┘    └──────────┬───────────┘    │ • SalesForecastCtrl  │
           │                           │                │ • RecordCalcCtrl     │
           │                           │                │ • UserContextCtrl    │
           │                           │                │ • VisitUpdaterAction │
           │                           │                └──────────┬───────────┘
           ▼                           ▼                           ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│               6. SUPPORT APEX, UTILITIES & SECURITY LAYER                    │
├──────────────────────────────────────────────────────────────────────────────┤
│ • CreateVisitLwcController & VisitUpdaterLwcController (@AuraEnabled)        │
│ • AgentFuzzyMatchUtility (Levenshtein Distance & Natural Language Date NLP)  │
│ • Security: Visit_Intel_Access Permission Set & Google CSP Trusted Sites     │
└──────────────────────────────────────────────────────────────────────────────┘
```

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

### Subagent Architecture & Routing Flow

```
[Session Start / User Input]
             │
             ▼
      [agent_router]
             │
             ├─▶ (currentRecordId exists on Visit) ──▶ [Get_Visit_Details Flow]
             │                                                  │
             │◀────────────── (Context Variables Set) ──────────┘
             │
             ├─▶ [visit_intelligence] (Default & Core Analytics Hub)
             │          │
             │          ├── Option 1 ──▶ Account Overview / 360 Summary
             │          ├── Option 2 ──▶ Key Contacts
             │          ├── Option 3 ──▶ Promotions Audit
             │          ├── Option 4 ──▶ Pre-Visit Brief
             │          ├── Option 5 ──▶ Inventory & Out of Stock
             │          ├── Option 6 ──▶ Order History & Top Products
             │          ├── Option 7 ──▶ [visit_updater] (Reschedule / Edit)
             │          ├── Option 8 ──▶ Assortment Products
             │          └── Option 9 ──▶ [visit_activities] (Tasks & Surveys)
             │
             ├─▶ [create_visit] ──────────────▶ Plan / Insert New Visit
             ├─▶ [forecasting_insights] ──────▶ Statistical & AI Sales Predictions
             ├─▶ [record_calculations_insights] Dynamic User-Mode SOQL Calculations
             └─▶ [clear_context] ─────────────▶ Switch Visit / Reset State
```

---

### Desktop vs. Mobile Modality Comparison

The core architectural divergence between `VisitIntelDesktop` and `VisitIntelMobile` lies in how user input is solicited and processed:

#### A. Desktop Modality (Interactive LWC Modal Forms):
```
User                          Agentforce Engine                   LWC / Apex Backend
 │                                    │                                    │
 ├─── "Create visit" ────────────────▶│                                    │
 │                                    ├─── Render c/createVisitEditor ────▶│
 │                                    │    (via c__createVisitWrapperType) │
 │◀── Displays Interactive LWC Form ──┤                                    │
 │    (Search Account, Place, User)   │                                    │
 │                                    │                                    │
 ├─── Submits Form with Values ───────────────────────────────────────────▶│
 │                                    │    Calls VisitAgentController      │
 │                                    │    .createVisitRecord(wrapper)     │
 │                                    │◀── Returns {success: true, id} ────┤
 │◀── "✅ Successfully created Visit" ─┤                                    │
```

#### B. Mobile Modality (Conversational Multi-Turn State Machine):
```
User                          Agentforce Engine                 AgentFuzzyMatchUtility
 │                                    │                                    │
 ├─── "Create visit" ────────────────▶│                                    │
 │◀── "Enter Account name:" ──────────┤                                    │
 │                                    │                                    │
 ├─── "Fresh Mart" ──────────────────▶│─── Fuzzy Match Account ───────────▶│
 │                                    │◀── Matched Account ID & Name ──────┤
 │◀── "Matched Fresh Mart. Store?:" ──┤                                    │
 │                                    │                                    │
 ├─── "Downtown Store" ──────────────▶│─── Fuzzy Match RetailStore ───────▶│
 │                                    │◀── Matched Place ID & Name ────────┤
 │◀── "Matched Store. Start Time?:" ──┤                                    │
 │                                    │                                    │
 ├─── "Tomorrow at 10 AM" ───────────▶│─── Parse NLP Datetime ────────────▶│
 │                                    │◀── Returns ISO 2026-08-20T10:00 ───┤
 │                                    │                                    │
 │                                    ├─── Calls create_visit_record ─────▶ (DML Insert)
 │◀── "🎉 Visit Created: V-00370" ────┤                                    │
```

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

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                             CUSTOM LIGHTNING TYPES                          │
├──────────────────────────────────────┬──────────────────────────────────────┤
│       createVisitWrapperType         │        visitUpdatePayloadType        │
│  Schema: @apexClassType/             │   Schema: @apexClassType/            │
│          c__CreateVisitWrapper       │           c__VisitUpdatePayload      │
│  Editor: c/createVisitEditor         │   Editor: c/visitUpdaterWizard       │
└──────────────────┬───────────────────┴──────────────────┬───────────────────┘
                   │                                      │
                   ▼                                      ▼
┌──────────────────────────────────────┐  ┌───────────────────────────────────┐
│        c/createVisitEditor LWC       │  │       c/visitUpdaterWizard LWC    │
├──────────────────────────────────────┤  ├───────────────────────────────────┤
│ • Dynamic Debounced Search Lookups:  │  │ • 4-Stage Step-by-Step Wizard:    │
│   Account, Store, Template, User     │  │   1. Field Selection (Checkboxes) │
│ • Auto-detects Responsible User      │  │   2. Dynamic Field Inputs         │
│ • Binds CreateVisitWrapper DTO       │  │   3. Side-by-Side Review Diff     │
│ • Emits 'change' event to Agent      │  │   4. Finalized Confirmation State │
└──────────────────────────────────────┘  └───────────────────────────────────┘
```

### Component Breakdown

#### 1. `c/createVisitEditor`
- **Component**: `createVisitEditor`
- **Target Contract**: `lightning__AgentforceInput` with `targetType="c__createVisitWrapperType"`.
- **Form Factors**: Large (Desktop) and Small (Tablet/Mobile).
- **Core Capabilities**:
  - **Dynamic Lookups**: Debounced SOSL/SOQL queries against `Account`, `RetailStore`/`Location`, `cgcloud__Visit_Template__c`, and `User`.
  - **User Context Auto-Detection**: Calls `CreateVisitLwcController.getResponsibleUserContext`. If the running user is assigned to a CG Cloud sales organization or profile, automatically populates and locks the `Responsible` user field.
  - **Payload Binding**: Emits `change` custom events to bind field values directly to the agent's `createVisitWrapper` variable.

#### 2. `c/visitUpdaterWizard`
- **Component**: `visitUpdaterWizard`
- **Target Contract**: `lightning__AgentforceInput` with `targetType="c__visitUpdatePayloadType"`.
- **Core Capabilities**:
  - **Contextual ID Resolution**: Uses `@wire(CurrentPageReference)` to auto-extract `recordId` when opened on a `Visit` record page.
  - **4-Stage Stepper**:
    1. *Field Selection*: Checkbox grid (`Subject`, `Status`, `PlannedStartTime`, `PlannedEndTime`, `Responsible`, `Accountable`, `Notes`).
    2. *Field Inputs*: Dynamic input fields based on selected checkboxes.
    3. *Review & Confirm*: Side-by-side diff comparing original values against staged changes.
    4. *Finalized State*: Read-only receipt confirming update payload generation.
  - **Payload Serialization**: Outputs a JSON payload string in `updatesJson` (e.g. `{"Status":"Completed","cgcloud__Note__c":"Audit done"}`).

---

## 4. Automation & Flow Layer (`flows`)

### Flow: `Get_Visit_Details`
- **Flow**: `Get_Visit_Details.flow-meta.xml`
- **Type**: `AutoLaunchedFlow` (API v61.0).
- **Description**: High-performance, self-contained record context extractor executed automatically by the `agent_router` subagent when a session initiates.

```
[Start: recordId Input]
          │
          ▼
[1. Lookup Visit Record by recordId]
          │
          ├─────────────────────────────────────────┐
          ▼                                         ▼
 (AccountId is populated?)                (AccountId is blank?)
          │                                         │
          │                                         ▼
          │                            [Lookup RetailStore with PlaceId]
          │                                         │
          ├─────────────────────────────────────────┘
          ▼
 (Responsible/Visitor Populated?)
          │
          ├─── YES ──▶ Set userIdToQuery = Responsible / Visitor ID
          └─── NO  ──▶ Set userIdToQuery = OwnerId
          │
          ▼
[2. Lookup Account Name]
          │
          ▼
[3. Lookup Assigned User Name]
          │
          ▼
[4. Lookup Accountable User Name]
          │
          ▼
[Return Context Variables to Agent: accountId, accountName, assignedUser, accountableUser, visitStatus, visitDate, visitEndDate, visitName]
```

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

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                      APEX DOMAIN INVOCABLE DISPATCHERS                      │
├──────────────────────────────────────┬──────────────────────────────────────┤
│  VisitAgentController                │  AccountAgentController              │
│  • getAvailableVisits / searchVisits │  • getAccountDetails / getCounts     │
│  • getVisitDetails / getVisitSummary │  • getProducts / getPromotions       │
│  • prompt_visit_mobile / createVisit │  • getAccountContacts / Opportunities│
├──────────────────────────────────────┼──────────────────────────────────────┤
│  OrderAgentController                │  VisitActivityController             │
│  • getOrders / getOrderDetails       │  • getActivities / getJobsStatus     │
│  • getAccountOrderSummary            │  • getDeliveryActivities             │
│  • getOrderRecommendations           │  • getNextSteps                      │
├──────────────────────────────────────┼──────────────────────────────────────┤
│  SalesForecastingController          │  RecordCalculationController         │
│  • getOrderForecast / ProductForecast│  • execute dynamic SOQL aggregates   │
│  • getCustomerForecast / Run-Rates   │  • Enforces AccessLevel.USER_MODE    │
├──────────────────────────────────────┼──────────────────────────────────────┤
│  UserContextController               │  VisitUpdaterActionController        │
│  • getProfile & Active User Details  │  • Deserializes JSON & executes DML  │
└──────────────────────────────────────┴──────────────────────────────────────┘
```

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

### 1. Permission Set: `Visit_Intel_Access`
- **File**: `Visit_Intel_Access.permissionset-meta.xml`
- **Role**: Master permission set granting access to all execution artifacts required by the Visit Intelligence agent.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                 Visit_Intel_Access (Master Permission Set)                  │
├─────────────────────────────────────────────────────────────────────────────┤
│ • User Permission: RunFlow                                                  │
│ • Flow Access: Get_Visit_Details                                            │
│ • Enabled Apex Classes:                                                     │
│   1. VisitAgentController               7. UserContextController            │
│   2. AccountAgentController             8. VisitUpdaterActionController     │
│   3. OrderAgentController               9. CreateVisitLwcController         │
│   4. VisitActivityController           10. VisitUpdaterLwcController        │
│   5. SalesForecastingController        11. AgentFuzzyMatchUtility           │
│   6. RecordCalculationController                                            │
└─────────────────────────────────────────────────────────────────────────────┘
```

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

### Deployment Verification Commands (Salesforce CLI)

```bash
# 1. Validate / Deploy all metadata to target Org
sf project deploy start --target-org <ORG_ALIAS>

# 2. Run all Visit Intelligence Apex Unit Tests
sf apex run test --test-level RunSpecifiedTests --tests VisitAgentControllerTest,AccountAgentControllerTest,OrderAgentControllerTest,VisitActivityControllerTest,SalesForecastingControllerTest,RecordCalculationControllerTest,UserContextControllerTest,CreateVisitLwcControllerTest,VisitUpdaterLwcControllerTest,AgentFuzzyMatchUtilityTest --target-org <ORG_ALIAS> --result-format human

# 3. Assign master Permission Set to active user
sf org assign permset --name Visit_Intel_Access --target-org <ORG_ALIAS>

# 4. Preview / Test the Agentforce Agent Script
sf agent preview --agent VisitIntelDesktop --target-org <ORG_ALIAS>
```

---

## 8. Comprehensive Directory Map

```
force-app/main/default/
├── aiAuthoringBundles/             # Agentforce AI Agent specifications
│   ├── VisitIntelDesktop/          # Desktop Agent (Interactive LWC Forms)
│   └── VisitIntelMobile/           # Mobile Agent (Conversational Multi-Turn)
├── classes/                        # Invocable Domain Controllers & Tests
│   ├── VisitAgentController.cls    # Visits & Scheduling Domain Handler
│   ├── AccountAgentController.cls  # Account 360 Domain Handler
│   ├── OrderAgentController.cls    # Orders & Spend Insights Handler
│   ├── VisitActivityController.cls # Surveys & Tasks Handler
│   ├── SalesForecastingController.cls # Predictive Analytics Handler
│   ├── RecordCalculationController.cls # Dynamic SOQL Engine (User Mode)
│   ├── UserContextController.cls   # Profile & Context Resolver
│   ├── VisitUpdaterActionController.cls # Wizard DML Processor
│   ├── CreateVisitLwcController.cls# Lookups for Create Visit LWC
│   ├── VisitUpdaterLwcController.cls # Data for Updater Wizard LWC
│   ├── AgentFuzzyMatchUtility.cls  # Levenshtein & NLP Date Utility
│   ├── CreateVisitWrapper.cls      # DTO for Visit Creation
│   ├── VisitUpdatePayload.cls      # DTO for Wizard Payload
│   └── *Test.cls                   # Apex Test Suites
├── cspTrustedSites/                # CSP Trusted Sites
│   ├── Google1.cspTrustedSite-meta.xml # https://*.google.com
│   └── Google2.cspTrustedSite-meta.xml # https://google.com
├── flows/                          # Autolaunched Flows
│   └── Get_Visit_Details.flow-meta.xml # Context Loader Flow
├── lightningTypes/                 # Custom Lightning Types for Agentforce
│   ├── createVisitWrapperType/     # Mapped to CreateVisitWrapper DTO
│   └── visitUpdatePayloadType/     # Mapped to VisitUpdatePayload DTO
├── lwc/                            # Lightning Web Components
│   ├── createVisitEditor/          # Interactive Visit Creation Form
│   └── visitUpdaterWizard/         # Multi-Step Visit Updater Wizard
└── permissionsets/                 # Security & Permissions
    └── Visit_Intel_Access.permissionset-meta.xml
```
