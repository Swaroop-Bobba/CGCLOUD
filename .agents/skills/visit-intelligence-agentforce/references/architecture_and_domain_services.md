# Architecture & Domain Controllers Reference Guide

This document provides a comprehensive technical reference for the domain controllers, actions, and utility classes supporting `VisitIntelDesktop` and `VisitIntelMobile`.

---

## 1. Controller Architecture & Invocable Mapping

Agentforce agents dispatch actions directly to domain controllers:

| Agent Action Domain | Target Invocable Controller | Test Class | Role |
| :--- | :--- | :--- | :--- |
| **Account Intelligence** | `AccountAgentController` | `AccountAgentControllerTest` | Account summaries, record counts, store briefs, promotions, products |
| **Visit Intelligence** | `VisitAgentController` | `VisitAgentControllerTest` | Available visits, search, details, summaries, stale visits, alerts |
| **Order Intelligence** | `OrderAgentController` | `OrderAgentControllerTest` | Order summaries, details, line items, order notes |
| **Visit Activities** | `VisitActivityController` | `VisitActivityControllerTest` | Activities, tasks, surveys, execution jobs, deliveries, next steps |
| **Sales Forecasting** | `SalesForecastingController` | `SalesForecastingControllerTest` | Sales forecasts, product stock depletion, replenishment AI |
| **Calculations** | `RecordCalculationController` | `RecordCalculationControllerTest` | Dynamic SOQL calculation execution in User Mode |
| **User Profile** | `UserContextController` | `UserContextControllerTest` | Current logged-in user profile & execution context |
| **Visit Updater Launcher** | `VisitUpdaterActionController` | `VisitUpdaterLwcControllerTest` | Launches and executes updates from the Visit Updater Wizard |
| **Create Visit UI** | `CreateVisitLwcController` | `CreateVisitLwcControllerTest` | `@AuraEnabled` lookups for `createVisitEditor` LWC |
| **Visit Updater UI** | `VisitUpdaterLwcController` | `VisitUpdaterLwcControllerTest` | `@AuraEnabled` lookups and saves for `visitUpdaterWizard` LWC |
| **Fuzzy Match & Dates** | `AgentFuzzyMatchUtility` | `AgentFuzzyMatchUtilityTest` | Levenshtein distance matching and natural language date parsing |
| **Test Data Seeder** | `AgentTestData` | `AgentTestDataTest` | Seeder for sample test and demo data |

---

## 2. Interactive UI Controllers & Lightning Types

Custom DTO Apex wrappers are mapped to Custom Lightning Types to render rich interactive cards in the Agentforce chat window:

| Apex DTO Wrapper | Lightning Type | LWC Renderer / Editor | Function |
| :--- | :--- | :--- | :--- |
| `CreateVisitWrapper` | `createVisitWrapperType` | `createVisitEditor` | Interactive form to edit and create new visits directly in chat. |
| `VisitSummaryWrapper` | `visitSummaryWrapperType` | `visitSummaryRenderer` | Summary card displaying completed visit KPIs, store details, and next steps. |
| `VisitUpdatePayload` | `visitUpdatePayloadType` | `visitUpdaterWizard` | Interactive step wizard to reschedule visits, update status, and notes. |
