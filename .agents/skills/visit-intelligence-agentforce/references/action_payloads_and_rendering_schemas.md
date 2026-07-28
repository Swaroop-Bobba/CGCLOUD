# Action Payloads & Custom UI Rendering Schemas

This document defines the data contracts (`Agent_Request`, `Agent_Response`), custom Lightning Types, and LWC component schemas used by `VisitIntelDesktop` and `VisitIntelMobile`.

---

## 1. Unified Request Payload: `Agent_Request`

* **File:** [Agent_Request.cls](file:///c:/Users/Bhanu%20Bobba/Videos/CGCLOUD/CGCPackagable/force-app/main/default/classes/Agent_Request.cls)

### Primary Fields

```apex
public class Agent_Request {
    @InvocableVariable public String domain;                // Domain: Visit, Account, Order, VisitActivity, etc.
    @InvocableVariable public String actionType;            // Action: getAvailable, getStoreBrief, search, etc.
    @InvocableVariable public String accountId;             // Target Account Record ID
    @InvocableVariable public String visitId;               // Target Visit Record ID
    @InvocableVariable public List<String> visitIds;        // Batch Visit Record IDs for alerts
    @InvocableVariable public String orderId;               // Target Order Record ID
    @InvocableVariable public String searchQuery;           // Search term for fuzzy matching
    @InvocableVariable public String status;                // New status value (e.g. InProgress, Completed)
    @InvocableVariable public String notes;                 // Representative field notes
    @InvocableVariable public CreateVisitWrapper createVisitWrapper; // DTO payload for new visit creation
    @InvocableVariable public String accountInput;          // Natural language account name input (Mobile)
    @InvocableVariable public String plannedStartTimeStr;   // Natural language date input (Mobile)
}
```

---

## 2. Unified Response Payload: `Agent_Response`

* **File:** [Agent_Response.cls](file:///c:/Users/Bhanu%20Bobba/Videos/CGCLOUD/CGCPackagable/force-app/main/default/classes/Agent_Response.cls)

### Key Output Attributes

```apex
public class Agent_Response {
    @InvocableVariable public Boolean success;              // Execution status (true/false)
    @InvocableVariable public String message;               // Primary display/status text message
    @InvocableVariable public String accountId;             // Resolved Account ID
    @InvocableVariable public String visitId;               // Resolved Visit ID
    @InvocableVariable public String googleMapsUrl;         // Direct Google Maps navigation URL
    @InvocableVariable public VisitSummaryWrapper visitSummary; // Custom DTO for summary card rendering
    @InvocableVariable public List<VisitOption> visits;     // List of matched visits for navigation
    @InvocableVariable public List<RecordInfo> relatedRecords; // List of related records (contacts, opps, etc.)
    @InvocableVariable public Decimal totalSpend;           // Aggregate spend total
    @InvocableVariable public String buyingInsight;         // Purchasing behavior insight summary
}
```

---

## 3. Custom Lightning Types & LWC Renderers

### A. `visitSummaryWrapperType` $\rightarrow$ `visitSummaryRenderer` LWC

* **Apex DTO Class:** [VisitSummaryWrapper.cls](file:///c:/Users/Bhanu%20Bobba/Videos/CGCLOUD/CGCPackagable/force-app/main/default/classes/VisitSummaryWrapper.cls)
* **Schema Definition:** `force-app/main/default/lightningTypes/visitSummaryWrapperType/schema.json`
* **Renderer Configuration:** `renderer.json` maps `@apexClassType/c__VisitSummaryWrapper` to `c/visitSummaryRenderer`.
* **LWC Component:** `force-app/main/default/lwc/visitSummaryRenderer/`

#### Rendered Card Structure
```html
<template>
    <lightning-card title={value.storeName} icon-name="standard:visit">
        <div class="slds-p-around_medium">
            <p><strong>Date:</strong> {value.visitDate}</p>
            <p><strong>Status:</strong> {value.visitStatus}</p>
            <p><strong>Tasks Completed:</strong> {value.completedTasks} / {totalTasks}</p>
            <p><strong>OOS Issues:</strong> {value.outOfStockIssues}</p>
            <p><strong>Order Spend:</strong> ${value.orderValue}</p>
            <div class="suggestions-container">
                <template for:each={value.suggestions} for:item="sugg">
                    <lightning-button key={sugg.id} label={sugg.label} icon-name={sugg.icon} onclick={handleSuggestionClick}></lightning-button>
                </template>
            </div>
        </div>
    </lightning-card>
</template>
```

---

### B. `createVisitWrapperType` $\rightarrow$ `createVisitEditor` LWC

* **Apex DTO Class:** [CreateVisitWrapper.cls](file:///c:/Users/Bhanu%20Bobba/Videos/CGCLOUD/CGCPackagable/force-app/main/default/classes/CreateVisitWrapper.cls)
* **Schema Definition:** `force-app/main/default/lightningTypes/createVisitWrapperType/schema.json`
* **Editor Configuration:** `editor.json` maps `@apexClassType/c__CreateVisitWrapper` to `c/createVisitEditor`.
* **LWC Component:** `force-app/main/default/lwc/createVisitEditor/`

---

### C. `visitUpdatePayloadType` $\rightarrow$ `visitUpdaterWizard` LWC

* **Apex DTO Class:** [VisitUpdatePayload.cls](file:///c:/Users/Bhanu%20Bobba/Videos/CGCLOUD/CGCPackagable/force-app/main/default/classes/VisitUpdatePayload.cls)
* **Schema Definition:** `force-app/main/default/lightningTypes/visitUpdatePayloadType/schema.json`
* **Editor Configuration:** `editor.json` maps `@apexClassType/c__VisitUpdatePayload` to `c/visitUpdaterWizard`.
* **LWC Component:** `force-app/main/default/lwc/visitUpdaterWizard/`
