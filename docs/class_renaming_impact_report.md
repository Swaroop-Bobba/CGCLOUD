# 🏗️ Apex Class Renaming & Architecture Refactoring Report

**Document Version:** 1.1  
**Generated Date:** August 17, 2026  
**Status:** Review & Awaiting Execution Approval  

---

## 📋 Executive Summary
This document provides a complete impact analysis and detailed migration blueprint for renaming and standardizing all Apex classes in the **Visit Intelligence / CGC AI Agent** project. 

The refactoring aligns all Agentforce entry points with the **Controller** naming convention, replaces ambiguous legacy class names (e.g., `ExecuteSOQLQuery`), establishes dedicated symmetric backend controllers for interactive LWC forms (`CreateVisitLwcController` and `VisitUpdaterLwcController`), and ensures 100% 2GP Managed Package stability.

---

## 1. 🗂️ Master Class Renaming Matrix

| # | Current Main Class File | Current Local Test Class File | New Main Class Name | New Test Class Name | Layer / Architectural Role |
| :- | :--- | :--- | :--- | :--- | :--- |
| **1** | `Account_Agent_Handler.cls` | `Account_Agent_HandlerTest.cls` | **`AccountAgentController.cls`** | `AccountAgentControllerTest.cls` | 🤖 **Agent Invocable**: Account Intelligence & Summary |
| **2** | `Visit_Agent_Handler.cls` | `Visit_Agent_HandlerTest.cls` | **`VisitAgentController.cls`** | `VisitAgentControllerTest.cls` | 🤖 **Agent Invocable**: Visit Intelligence, Search & Reports |
| **3** | `Order_Agent_Handler.cls` | `Order_Agent_HandlerTest.cls` | **`OrderAgentController.cls`** | `OrderAgentControllerTest.cls` | 🤖 **Agent Invocable**: Order History, Notes & Line Items |
| **4** | `Visit_Activity_Handler.cls` | `Visit_Activity_HandlerTest.cls` | **`VisitActivityController.cls`** | `VisitActivityControllerTest.cls` | 🤖 **Agent Invocable**: Visit Activities, Surveys & Checks |
| **5** | `Sales_Forecasting_Handler.cls` | `Sales_Forecasting_HandlerTest.cls` | **`SalesForecastingController.cls`** | `SalesForecastingControllerTest.cls` | 🤖 **Agent Invocable**: Predictive Sales & Next-Visit AI |
| **6** | `ExecuteSOQLQuery.cls` | `ExecuteSOQLQueryTest.cls` | **`RecordCalculationController.cls`** | `RecordCalculationControllerTest.cls` | 🤖 **Agent Invocable**: Dynamic Calculations & Insights |
| **7** | `GetCurrentUserProfile.cls` | `GetCurrentUserProfileTest.cls` | **`UserContextController.cls`** | `UserContextControllerTest.cls` | 🤖 **Agent Invocable**: Profile & Execution Context |
| **8** | `VisitUpdaterAction.cls` | *(Covered in VisitUpdaterControllerTest.cls)* | **`VisitUpdaterActionController.cls`** | *(Covered in VisitUpdaterLwcControllerTest.cls)* | 🤖 **Agent Invocable**: Interactive Updater Wizard Launcher |
| **9** | `Visit_Agent_Service.cls` | `Visit_Agent_ServiceTest.cls` | **`CreateVisitLwcController.cls`** | `CreateVisitLwcControllerTest.cls` | 💻 **LWC Controller**: `@AuraEnabled` lookups for Create Visit Form |
| **10** | `VisitUpdaterController.cls` | `VisitUpdaterControllerTest.cls` | **`VisitUpdaterLwcController.cls`** | `VisitUpdaterLwcControllerTest.cls` | 💻 **LWC Controller**: `@AuraEnabled` lookups & saves for Update Wizard |
| **11** | `MobileAgentUtility.cls` | `MobileAgentUtilityTest.cls` | **`AgentFuzzyMatchUtility.cls`** | `AgentFuzzyMatchUtilityTest.cls` | 🛠️ **Utility**: Natural Language Date/Time & Fuzzy Matching |
| **12** | `AgentMockDataSeeder.cls` | `AgentMockDataSeederTest.cls` | *(Moved to `docs/agent_test_data.md`)* | *(Moved to `docs/agent_test_data.md`)* | 📄 **Docs / Scratch Utility**: Decoupled from Package |

---

## 2. 📦 Retained Supporting DTOs & Package Lifecycle

These classes already follow standard Salesforce naming guidelines and remain unchanged:

| # | Class Name | Current Local Test Class File | Purpose |
| :- | :--- | :--- | :--- |
| **13** | **`CreateVisitWrapper.cls`** | *(Covered via Handler / Service tests)* | Lightning Type DTO for Create Visit Form |
| **14** | **`VisitSummaryWrapper.cls`** | `VisitSummaryWrapperTest.cls` | Lightning Type DTO for Visit Summary Card |
| **15** | **`VisitUpdatePayload.cls`** | *(Covered via Controller tests)* | Lightning Type DTO for Update Wizard Payload |
| **16** | **`PostInstallScript.cls`** | `PostInstallScriptTest.cls` | 2GP Managed Package Installation Script |

---

## 3. 🤖 Agent Authoring Bundles Impact Matrix

The following action target URIs will be updated across all 3 agent bundles:
* `force-app/main/default/aiAuthoringBundles/VisitIntelDesktop/VisitIntelDesktop.agent`
* `force-app/main/default/aiAuthoringBundles/VisitIntelMobile/VisitIntelMobile.agent`
* `force-app/main/default/aiAuthoringBundles/SupervisitAi/SupervisitAi.agent`

```diff
- target: "apex://Account_Agent_Handler"
+ target: "apex://AccountAgentController"

- target: "apex://Visit_Agent_Handler"
+ target: "apex://VisitAgentController"

- target: "apex://Order_Agent_Handler"
+ target: "apex://OrderAgentController"

- target: "apex://Visit_Activity_Handler"
+ target: "apex://VisitActivityController"

- target: "apex://Sales_Forecasting_Handler"
+ target: "apex://SalesForecastingController"

- target: "apex://ExecuteSOQLQuery"
+ target: "apex://RecordCalculationController"

- target: "apex://GetCurrentUserProfile"
+ target: "apex://UserContextController"

- target: "apex://VisitUpdaterAction"
+ target: "apex://VisitUpdaterActionController"
```

---

## 4. 💻 Lightning Web Components (LWC) Impact Matrix

Two LWC components import Apex methods that will be updated:

### A. `createVisitEditor` (`force-app/main/default/lwc/createVisitEditor/createVisitEditor.js`)
```diff
- import searchAccounts from '@salesforce/apex/Visit_Agent_Service.searchAccounts';
- import getAccountName from '@salesforce/apex/Visit_Agent_Service.getAccountName';
- import searchPlaces from '@salesforce/apex/Visit_Agent_Service.searchPlaces';
- import getPlaceName from '@salesforce/apex/Visit_Agent_Service.getPlaceName';
- import searchTemplates from '@salesforce/apex/Visit_Agent_Service.searchTemplates';
- import getTemplateName from '@salesforce/apex/Visit_Agent_Service.getTemplateName';
- import searchUsers from '@salesforce/apex/Visit_Agent_Service.searchUsers';
- import getUserName from '@salesforce/apex/Visit_Agent_Service.getUserName';
- import getResponsibleUserContext from '@salesforce/apex/Visit_Agent_Service.getResponsibleUserContext';
- import getVisitDataForLwc from '@salesforce/apex/Visit_Agent_Service.getVisitDataForLwc';
+ import searchAccounts from '@salesforce/apex/CreateVisitLwcController.searchAccounts';
+ import getAccountName from '@salesforce/apex/CreateVisitLwcController.getAccountName';
+ import searchPlaces from '@salesforce/apex/CreateVisitLwcController.searchPlaces';
+ import getPlaceName from '@salesforce/apex/CreateVisitLwcController.getPlaceName';
+ import searchTemplates from '@salesforce/apex/CreateVisitLwcController.searchTemplates';
+ import getTemplateName from '@salesforce/apex/CreateVisitLwcController.getTemplateName';
+ import searchUsers from '@salesforce/apex/CreateVisitLwcController.searchUsers';
+ import getUserName from '@salesforce/apex/CreateVisitLwcController.getUserName';
+ import getResponsibleUserContext from '@salesforce/apex/CreateVisitLwcController.getResponsibleUserContext';
+ import getVisitDataForLwc from '@salesforce/apex/CreateVisitLwcController.getVisitDataForLwc';
```

### B. `visitUpdaterWizard` (`force-app/main/default/lwc/visitUpdaterWizard/visitUpdaterWizard.js`)
```diff
- import getActiveUsers from '@salesforce/apex/VisitUpdaterController.getActiveUsers';
- import getVisitDetails from '@salesforce/apex/VisitUpdaterController.getVisitDetails';
- import updateVisitRecord from '@salesforce/apex/VisitUpdaterController.updateVisitRecord';
+ import getActiveUsers from '@salesforce/apex/VisitUpdaterLwcController.getActiveUsers';
+ import getVisitDetails from '@salesforce/apex/VisitUpdaterLwcController.getVisitDetails';
+ import updateVisitRecord from '@salesforce/apex/VisitUpdaterLwcController.updateVisitRecord';
```

---

## 5. 🛡️ Permission Set Configuration (`Visit_Intel_Access`)

File: `force-app/main/default/permissionsets/Visit_Intel_Access.permissionset-meta.xml`

All 12 class access blocks will be synchronized:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<PermissionSet xmlns="http://soap.sforce.com/2006/04/metadata">
    <description>Grants access to Visit Intelligence Controller Apex classes</description>
    <hasActivationRequired>false</hasActivationRequired>
    <label>Visit Intel Access</label>
    <userPermissions>
        <enabled>true</enabled>
        <name>RunFlow</name>
    </userPermissions>
    <flowAccesses>
        <enabled>true</enabled>
        <flow>Get_Visit_Details</flow>
    </flowAccesses>
    <classAccesses>
        <apexClass>AccountAgentController</apexClass>
        <enabled>true</enabled>
    </classAccesses>
    <classAccesses>
        <apexClass>VisitAgentController</apexClass>
        <enabled>true</enabled>
    </classAccesses>
    <classAccesses>
        <apexClass>OrderAgentController</apexClass>
        <enabled>true</enabled>
    </classAccesses>
    <classAccesses>
        <apexClass>VisitActivityController</apexClass>
        <enabled>true</enabled>
    </classAccesses>
    <classAccesses>
        <apexClass>SalesForecastingController</apexClass>
        <enabled>true</enabled>
    </classAccesses>
    <classAccesses>
        <apexClass>RecordCalculationController</apexClass>
        <enabled>true</enabled>
    </classAccesses>
    <classAccesses>
        <apexClass>UserContextController</apexClass>
        <enabled>true</enabled>
    </classAccesses>
    <classAccesses>
        <apexClass>VisitUpdaterActionController</apexClass>
        <enabled>true</enabled>
    </classAccesses>
    <classAccesses>
        <apexClass>CreateVisitLwcController</apexClass>
        <enabled>true</enabled>
    </classAccesses>
    <classAccesses>
        <apexClass>VisitUpdaterLwcController</apexClass>
        <enabled>true</enabled>
    </classAccesses>
    <classAccesses>
        <apexClass>AgentFuzzyMatchUtility</apexClass>
        <enabled>true</enabled>
    </classAccesses>
    <classAccesses>
        <apexClass>AgentTestData</apexClass>
        <enabled>true</enabled>
    </classAccesses>
</PermissionSet>
```

---

## 6. 🔒 2GP Managed Package & Error Prevention Guarantee

This refactoring strictly complies with the **5 Rules for Zero 500 Errors**:
1. **Direct Compile-Time Bindings**: No dynamic reflection (`Type.forName`).
2. **Top-Level Error Shielding**: All `@InvocableMethod` controllers encapsulate domain logic in `try / catch` blocks to prevent unhandled exceptions from bubbling to Agentforce.
3. **Flat DTO Responses**: All invocable action return types are flat primitives or dedicated top-level Lightning Type DTOs.
4. **Complete Permission Coverage**: All 12 classes are included in `Visit_Intel_Access`.
5. **Clean Sharing Model**: All classes specify explicit sharing (`with sharing` or `inherited sharing`).

---

## 7. 🚀 Execution Plan (When You Trigger Change)

1. **Write New Apex & Test Classes**: Create the new controller & utility files with updated class signatures.
2. **Update LWC & Agent Script References**: Update `.agent` files and LWC JavaScript imports.
3. **Update Permission Set**: Update `Visit_Intel_Access.permissionset-meta.xml`.
4. **Deploy to Target Orgs**: Deploy metadata to `CGCloudDevHub` and `MyDevHubcgc`.
5. **Clean Up Old Metadata**: Delete deprecated Apex classes from source and target orgs.
