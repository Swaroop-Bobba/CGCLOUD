# Architectural Refactoring & 2GP Managed Package Optimization Proposals

**Document Version:** 1.1  
**Project:** Visit Intelligence / CGC AI Agent  
**Last Updated:** August 17, 2026  

---

## 1. 2-Tier Controller Pattern

The system has been modernized into a clean, direct **2-Tier Model**:
* **Controller Layer**: Autonomous domain controllers (`AccountAgentController`, `VisitAgentController`, `OrderAgentController`, `VisitActivityController`, `SalesForecastingController`, `RecordCalculationController`, `UserContextController`, `VisitUpdaterActionController`, `CreateVisitLwcController`, `VisitUpdaterLwcController`).
* **Database / SObject Layer**: Standard User Mode SOQL & DML execution (`WITH USER_MODE`, `AccessLevel.USER_MODE`).

---

## 2. Master Class Inventory

1. **`AccountAgentController`**: Account intelligence, summaries, related records, store briefs.
2. **`VisitAgentController`**: Visit intelligence, search, details, summaries, stale visits, alerts.
3. **`OrderAgentController`**: Order intelligence, notes, line items, summaries.
4. **`VisitActivityController`**: Visit activities, execution jobs, tasks, surveys, deliveries, next steps.
5. **`SalesForecastingController`**: Sales trend forecasting, stock depletion predictions.
6. **`RecordCalculationController`**: Secure dynamic SOQL calculations in User Mode.
7. **`UserContextController`**: Logged-in user profile resolver.
8. **`VisitUpdaterActionController`**: Invocable updater wizard launcher.
9. **`CreateVisitLwcController`**: Dedicated `@AuraEnabled` lookup controller for `createVisitEditor` LWC.
10. **`VisitUpdaterLwcController`**: Dedicated `@AuraEnabled` lookup and save controller for `visitUpdaterWizard` LWC.
11. **`AgentFuzzyMatchUtility`**: Natural language relative date parsing and Levenshtein candidate scoring.
12. **`AgentTestData`**: Test and demo mock data generator.
