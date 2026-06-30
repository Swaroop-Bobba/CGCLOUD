# Architecture Comparison: Design-Time vs. Run-Time CGC Config

This document outlines the difference in behavior when retrieving planned activities versus retrieving visit job statuses under the Salesforce Consumer Goods Cloud (CGC) data model, and documents the resolution implemented.

---

## 1. The Core Data Model Discrepancy

| Aspect | Design-Time (Activities List) | Run-Time (Visit Jobs Status) |
| :--- | :--- | :--- |
| **Object Queried** | `cgcloud__Job_Definition_List__c` (JDL) | `cgcloud__Visit_Job__c` (Visit Job) |
| **Lookup Scope** | Mapped directly to `cgcloud__Visit_Template__c` | Created specifically for `cgcloud__Visit__c` |
| **Customer Context** | Ignored by default. Pulls checklists assigned to the template. | Respected. Instantiated dynamically based on customer targeting rules. |
| **Impact** | Pulls activities intended for other customer profiles. | Shows only activities/questions applicable to this visit. |

---

## 2. Logical Flow & Alignment Evolution

### Step 1: Initial Implementation (Design-Time Only)
Initially, `getVisitActivities` queried JDL templates mapped to the `Visit_Template__c` directly. This returned all design-time activities (e.g. `Coke Activities` and customer-specific checklist lists like `Cool Drinks (Hyderabad)`), but it failed to respect Customer/Account-specific exclusions or JDL targeting rules.

### Step 2: Intermediate Alignment (Job Instantiation Filtered)
To filter JDLs to only respect customer context, the architecture was modified to:
1. Retrieve unique template IDs (`cgcloud__Job_Definition_Template__c`) from actual instantiated `cgcloud__Visit_Job__c` records for the specific `Visit ID`.
2. Query JDL templates mapping to the `Visit_Template__c`, but filter the subquery of child questions to only include those matching the instantiated IDs.
3. Omit any JDL template/activity that does not have at least one active, instantiated question.

**The Flaw with Step 2:**
While this aligned the activities list with the instantiated jobs, once a user started the visit and some jobs became active, the checklist locked down to *only* JDLs with active/started jobs. Uninstantiated checklists (e.g. pending or newly targeted activities) were hidden from view.

### Step 3: Final Alignment (Account-Targeted In-Memory Filtering)
To ensure representatives see all planned activities mapped to the Visit Template while respecting Customer/Account targeting:
1. `getVisitActivities` queries active JDLs linked to the `Visit_Template__c`.
2. Direct account-specific JDL inclusions/exclusions (`cgcloud__Job_Definition_List_Account__c`) and Account Set inclusions (`cgcloud__Account_Set_Account__c` junction via JDL Account Sets) are queried in System Mode.
3. The candidate JDL list is filtered in-memory to discard JDLs marked with `cgcloud__Consider_Account__c = true` unless the account has an inclusion record and no exclusion records.
4. The remaining questions and surveys are queried and rendered, regardless of whether a job record has been instantiated/started.

```
[Visit Page] -> Fetch JDLs -> Query Account Inclusions/Exclusions -> Filter JDLs -> All Targeted Checklists
```

---

## 3. Key Permissions Workaround
Salesforce CG Cloud representatives do not have read access to setup-time configuration objects like `cgcloud__Job_Definition_List_Account__c` and `cgcloud__Account_Set_Account__c`. 

To allow standard profiles (e.g. `CGCloud_User_Profile`) to retrieve activities successfully without requiring setup object access permissions:
- Setup-time queries in [Visit_Activity_Service.cls](file:///c:/Users/Bhanu%20Bobba/Documents/CGCCloud/CGCMain/CGCLOUD/force-app/main/default/classes/Visit_Activity_Service.cls) are executed in **System Mode** (omitting the `WITH USER_MODE` query suffix).
- Context-level query blocks (such as querying the active `Visit` and `cgcloud__Visit_Job__c` records) retain the `WITH USER_MODE` suffix to respect organization-wide sharing rules and row-level access controls.
