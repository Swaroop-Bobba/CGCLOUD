# Architecture & Domain Services Reference Guide

This document provides a comprehensive technical reference for the domain services, handlers, and utility classes supporting `VisitIntelDesktop` and `VisitIntelMobile`.

---

## 1. Core Router: `Agent_Global_Handler`

* **File Location:** [Agent_Global_Handler.cls](file:///c:/Users/Bhanu%20Bobba/Videos/CGCLOUD/CGCPackagable/force-app/main/default/classes/Agent_Global_Handler.cls)
* **Test Class:** [Agent_Global_HandlerTest.cls](file:///c:/Users/Bhanu%20Bobba/Videos/CGCLOUD/CGCPackagable/force-app/main/default/classes/Agent_Global_HandlerTest.cls)
* **Pattern:** Factory / Router Pattern.
* **Invocable Method:** `@InvocableMethod public static List<Agent_Response> execute(List<Agent_Request> requests)`

### Routing Logic Matrix

| Request `domain` / Action Prefix | Target Service Class | Executed Interface Method |
| :--- | :--- | :--- |
| `Visit` or `visit_*` | `Visit_Agent_Service` | `service.execute(req)` |
| `Account` or `account_*` | `Account_Agent_Service` | `service.execute(req)` |
| `Order` or `order_*` | `Order_Agent_Service` | `service.execute(req)` |
| `VisitActivity` / `Activity` | `Visit_Activity_Service` | `service.execute(req)` |
| `OrderRecommendation` | `Order_Recommendation_Service` | `service.execute(req)` |
| `SalesForecasting` / `Forecast` | `Sales_Forecasting_Service` | `service.execute(req)` |
| `User` / `user_*` | `User_Agent_Service` | `service.execute(req)` |

---

## 2. Visit Domain: `Visit_Agent_Service`

* **File Location:** [Visit_Agent_Service.cls](file:///c:/Users/Bhanu%20Bobba/Videos/CGCLOUD/CGCPackagable/force-app/main/default/classes/Visit_Agent_Service.cls)
* **Test Class:** [Visit_Agent_ServiceTest.cls](file:///c:/Users/Bhanu%20Bobba/Videos/CGCLOUD/CGCPackagable/force-app/main/default/classes/Visit_Agent_ServiceTest.cls)

### Supported Actions & Methods

1. **`getAvailable` / `getAvailableVisits()`**:
   Queries open/planned visits for the current running user assigned for today or overdue.
2. **`getAccountVisits` / `getAccountVisits(String accountId)`**:
   Queries past and upcoming visits associated with a specific store Account.
3. **`getOosVisits` / `getOosVisits(String accountId)`**:
   Identifies visits where Out-of-Stock issues were flagged during store assessment tasks.
4. **`getStoreBrief` / `getStoreBrief(String visitId, String accountId)`**:
   Assembles a high-level briefing card for a store visit including account contacts, recent order spend, open tasks, and overdue alerts.
5. **`generateSummary` / `generateSummary(String visitId)`**:
   Populates `VisitSummaryWrapper` with store name, date, completion metrics, and interactive suggestion buttons.
6. **`update_visit_status` / `updateVisitStatus(String visitId, String status)`**:
   Updates `Visit.Status` field (e.g. `InProgress`, `Completed`, `Cancelled`).
7. **`update_visit_notes_mobile_action` / `updateVisitNotesMobileAction(String visitId, String notes)`**:
   Appends representative field notes to the visit record.
8. **`create_visit_record` / `createVisitRecord(CreateVisitWrapper wrapper)`**:
   Inserts new `Visit` SObject record linked to `AccountId` and `PlaceId` (`Schema.Location`).
9. **`getstalevisits` / `getStaleVisits(String accountId)`**:
   Finds accounts that haven't been visited in > 30 days.
10. **`sendvisitalerts` / `sendVisitAlerts(List<String> visitIds)`**:
    Generates notification alerts for urgent or overdue visits.
11. **`prompt_visit_mobile` / `promptVisitMobileAction(Agent_Request req)`**:
    Processes natural language inputs on mobile (fuzzy account lookup & relative date parsing).

---

## 3. Account Domain: `Account_Agent_Service`

* **File Location:** [Account_Agent_Service.cls](file:///c:/Users/Bhanu%20Bobba/Videos/CGCLOUD/CGCPackagable/force-app/main/default/classes/Account_Agent_Service.cls)
* **Test Class:** [Account_Agent_ServiceTest.cls](file:///c:/Users/Bhanu%20Bobba/Videos/CGCLOUD/CGCPackagable/force-app/main/default/classes/Account_Agent_ServiceTest.cls)

### Key Functionality
* **Direct Google Maps Web Link Generation:**
  Generates `res.googleMapsUrl = 'https://www.google.com/maps?q=' + EncodingUtil.urlEncode(address, 'UTF-8')` for direct one-click navigation without Visualforce wrappers.
* **Related Record Retrieval (`getRelatedRecords`):**
  Supports category queries for `contacts`, `opportunities`, `cases`, `visits`, `promotions`, `orders`, and `assortments`.
* **Related Record Counts (`getRelatedCounts`):**
  Executes fast aggregate counts across related child SObjects.

---

## 4. Order Domain: `Order_Agent_Service`

* **File Location:** [Order_Agent_Service.cls](file:///c:/Users/Bhanu%20Bobba/Videos/CGCLOUD/CGCPackagable/force-app/main/default/classes/Order_Agent_Service.cls)
* **Test Class:** [Order_Agent_ServiceTest.cls](file:///c:/Users/Bhanu%20Bobba/Videos/CGCLOUD/CGCPackagable/force-app/main/default/classes/Order_Agent_ServiceTest.cls)

### Key Functionality
* **`getOrderDetails(String orderId)`:** Queries `cgcloud__Order__c` details and status.
* **`getAccountOrderSummary(String accountId)`:** Calculates total spend, phase breakdowns (Draft, Submitted, Released), and top-selling products.
* **`getOrderLineItems(String orderId)`:** Queries child `cgcloud__Order_Item__c` records.
* **`updateOrderNotes(String orderIdentifier, String deliveryNote, String invoiceNote)`:** Updates delivery and invoice instructions on order headers.

---

## 5. Utility & Matching Engine: `MobileAgentUtility`

* **File Location:** [MobileAgentUtility.cls](file:///c:/Users/Bhanu%20Bobba/Videos/CGCLOUD/CGCPackagable/force-app/main/default/classes/MobileAgentUtility.cls)
* **Test Class:** [MobileAgentUtilityTest.cls](file:///c:/Users/Bhanu%20Bobba/Videos/CGCLOUD/CGCPackagable/force-app/main/default/classes/MobileAgentUtilityTest.cls)

### Algorithms & Parser Methods

1. **Levenshtein Distance Match Score:**
   ```apex
   public static Integer getMatchScore(String str1, String str2)
   ```
   Computes edit distance between search input and record names, returning a match score from `0` (no match) to `100` (exact match).

2. **Natural Language DateTime Parser:**
   ```apex
   public static DateTime parseDateTimeNaturalLanguage(String dateStr)
   ```
   Parses natural language strings such as `"Tomorrow at 10:00 am"`, `"Next Monday 2pm"`, `"Today 4:30pm"`, or ISO strings (`"2026-07-25T10:00:00Z"`).
