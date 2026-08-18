# 🧪 Agent Test Data Seeder Utility

This document contains the source code for `AgentTestData.cls` and `AgentTestDataTest.cls`.  
These classes are designed for development, demonstration, and scratch org seeding. They are intentionally decoupled from the 2GP managed package to prevent mock data pollution in customer production environments.

---

## 1. 📄 `AgentTestData.cls`

```apex
/**
 * @description Utility class to seed mock data in Salesforce org for CG Cloud Visit Intelligence Agent testing and demonstration.
 */
public with sharing class AgentTestData {
    @TestVisible private static Boolean forceException = false;

    @InvocableMethod(label='Seed Agent Mock Data' description='Creates sample Accounts, Locations, Visits, Contacts, Opportunities, Cases, Products, and CG Cloud Orders/Activities.')
    public static List<String> seedDataInvocable() {
        Map<String, Integer> results = seedAllData();
        return new List<String>{ JSON.serializePretty(results) };
    }

    public static Map<String, Integer> seedAllData() {
        Map<String, Integer> counts = new Map<String, Integer>();
        Database.DMLOptions dmo = new Database.DMLOptions();
        dmo.duplicateRuleHeader.allowSave = true;

        List<Account> existingAccs = [SELECT Id, Name FROM Account WHERE Name LIKE 'CGC %' LIMIT 5];
        List<Schema.Location> locList = new List<Schema.Location>();
        List<Account> accList = new List<Account>();

        if (!existingAccs.isEmpty()) {
            accList = existingAccs;
            locList = [SELECT Id, Name FROM Location WHERE Name LIKE 'CGC %' LIMIT 5];
            counts.put('Account', accList.size());
            counts.put('Schema.Location', locList.size());
        } else {
            // 1. Locations
            locList.add(new Schema.Location(Name = 'CGC Metro Supermarket Location'));
            locList.add(new Schema.Location(Name = 'CGC Downtown Mart Location'));
            locList.add(new Schema.Location(Name = 'CGC Express Store Location'));
            locList.add(new Schema.Location(Name = 'CGC Sunshine Groceries Location'));
            locList.add(new Schema.Location(Name = 'CGC Corner Fresh Location'));
            insert locList;
            counts.put('Schema.Location', locList.size());

            // 2. Accounts
            accList.add(new Account(
                Name = 'CGC Metro Supermarket',
                Phone = '555-0100',
                ShippingStreet = '123 Main St',
                ShippingCity = 'New York',
                ShippingState = 'NY',
                ShippingPostalCode = '10001',
                ShippingCountry = 'USA',
                BillingStreet = '123 Main St',
                BillingCity = 'New York',
                BillingState = 'NY',
                BillingPostalCode = '10001',
                BillingCountry = 'USA',
                Type = 'Customer',
                AnnualRevenue = 1500000
            ));
            accList.add(new Account(
                Name = 'CGC Downtown Mart',
                Phone = '555-0200',
                ShippingStreet = '456 Market St',
                ShippingCity = 'San Francisco',
                ShippingState = 'CA',
                ShippingPostalCode = '94105',
                ShippingCountry = 'USA',
                BillingStreet = '456 Market St',
                BillingCity = 'San Francisco',
                BillingState = 'CA',
                BillingPostalCode = '94105',
                BillingCountry = 'USA',
                Type = 'Customer',
                AnnualRevenue = 2200000
            ));
            accList.add(new Account(
                Name = 'CGC Express Store',
                Phone = '555-0300',
                ShippingStreet = '789 Broadway',
                ShippingCity = 'Chicago',
                ShippingState = 'IL',
                ShippingPostalCode = '60601',
                ShippingCountry = 'USA',
                BillingStreet = '789 Broadway',
                BillingCity = 'Chicago',
                BillingState = 'IL',
                BillingPostalCode = '60601',
                BillingCountry = 'USA',
                Type = 'Customer',
                AnnualRevenue = 850000
            ));
            accList.add(new Account(
                Name = 'CGC Sunshine Groceries',
                Phone = '555-0400',
                ShippingStreet = '101 Sunset Blvd',
                ShippingCity = 'Los Angeles',
                ShippingState = 'CA',
                ShippingPostalCode = '90028',
                ShippingCountry = 'USA',
                BillingStreet = '101 Sunset Blvd',
                BillingCity = 'Los Angeles',
                BillingState = 'CA',
                BillingPostalCode = '90028',
                BillingCountry = 'USA',
                Type = 'Customer',
                AnnualRevenue = 3100000
            ));
            accList.add(new Account(
                Name = 'CGC Corner Fresh',
                Phone = '555-0500',
                ShippingStreet = '202 Ocean Ave',
                ShippingCity = 'Miami',
                ShippingState = 'FL',
                ShippingPostalCode = '33139',
                ShippingCountry = 'USA',
                BillingStreet = '202 Ocean Ave',
                BillingCity = 'Miami',
                BillingState = 'FL',
                BillingPostalCode = '33139',
                BillingCountry = 'USA',
                Type = 'Customer',
                AnnualRevenue = 600000
            ));
            Database.insert(accList, dmo);
            counts.put('Account', accList.size());
        }

        // 3. RetailStore (if object exists)
        try {
            if (Test.isRunningTest() && forceException) {
                throw new DmlException('Forced RetailStore Exception');
            }
            if (Schema.getGlobalDescribe().containsKey('RetailStore')) {
                List<SObject> rsList = new List<SObject>();
                Schema.SObjectType rsType = Schema.getGlobalDescribe().get('RetailStore');
                for (Integer i = 0; i < accList.size(); i++) {
                    SObject rs = rsType.newSObject();
                    rs.put('Name', accList[i].Name + ' Store');
                    rs.put('AccountId', accList[i].Id);
                    rs.put('LocationId', locList[i].Id);
                    rsList.add(rs);
                }
                insert rsList;
                counts.put('RetailStore', rsList.size());
            }
        } catch (Exception e) {
            System.debug('RetailStore creation skipped: ' + e.getMessage());
        }

        // 4. Contacts
        List<Contact> conList = new List<Contact>();
        conList.add(new Contact(AccountId = accList[0].Id, FirstName = 'John', LastName = 'Smith', Title = 'Store Manager', Phone = '555-0101', Email = 'john.smith@metro.com'));
        conList.add(new Contact(AccountId = accList[1].Id, FirstName = 'Sarah', LastName = 'Connor', Title = 'Operations Director', Phone = '555-0102', Email = 'sarah.c@downtown.com'));
        conList.add(new Contact(AccountId = accList[2].Id, FirstName = 'Mike', LastName = 'Johnson', Title = 'Head Buyer', Phone = '555-0103', Email = 'mike.j@express.com'));
        conList.add(new Contact(AccountId = accList[3].Id, FirstName = 'Emily', LastName = 'Davis', Title = 'Category Manager', Phone = '555-0104', Email = 'emily.d@sunshine.com'));
        conList.add(new Contact(AccountId = accList[4].Id, FirstName = 'David', LastName = 'Wilson', Title = 'Owner', Phone = '555-0105', Email = 'david.w@cornerfresh.com'));
        Database.insert(conList, dmo);
        counts.put('Contact', conList.size());

        // 5. Opportunities
        List<Opportunity> oppList = new List<Opportunity>();
        oppList.add(new Opportunity(AccountId = accList[0].Id, Name = 'Metro Q3 Shelf Expansion', StageName = 'Proposal/Price Quote', CloseDate = Date.today().addDays(30), Amount = 50000, Probability = 75));
        oppList.add(new Opportunity(AccountId = accList[1].Id, Name = 'Downtown Beverage Restock', StageName = 'Closed Won', CloseDate = Date.today().addDays(-15), Amount = 25000, Probability = 100));
        oppList.add(new Opportunity(AccountId = accList[2].Id, Name = 'Express New Product Launch', StageName = 'Qualification', CloseDate = Date.today().addDays(45), Amount = 15000, Probability = 20));
        oppList.add(new Opportunity(AccountId = accList[3].Id, Name = 'Sunshine Summer Promo Deal', StageName = 'Negotiation/Review', CloseDate = Date.today().addDays(10), Amount = 35000, Probability = 90));
        insert oppList;
        counts.put('Opportunity', oppList.size());

        // 6. Cases
        List<Case> caseList = new List<Case>();
        caseList.add(new Case(AccountId = accList[0].Id, Subject = 'Cooler Maintenance Required', Status = 'New', Priority = 'High', Origin = 'Phone', Description = 'Display cooler temperature fluctuation detected. Requires service technician inspection.'));
        caseList.add(new Case(AccountId = accList[2].Id, Subject = 'Delayed Delivery Query', Status = 'Working', Priority = 'Medium', Origin = 'Email', Description = 'Delivery #ORD-8921 delayed by 2 days. Customer requesting ETA update.'));
        caseList.add(new Case(AccountId = accList[3].Id, Subject = 'Damaged Stock Report', Status = 'Closed', Priority = 'Low', Origin = 'Web', Description = '2 cases of mineral water arrived damaged. Credit memo requested.'));
        insert caseList;
        counts.put('Case', caseList.size());

        // 7. Product2
        List<Product2> prodList = new List<Product2>();
        prodList.add(new Product2(Name = 'Empower Cola 0.5L', ProductCode = 'PROD-COL-01', IsActive = true, Family = 'Beverages'));
        prodList.add(new Product2(Name = 'Empower Energy Drink 250ml', ProductCode = 'PROD-ENG-02', IsActive = true, Family = 'Beverages'));
        prodList.add(new Product2(Name = 'CGC Premium Chips 100g', ProductCode = 'PROD-CHP-03', IsActive = true, Family = 'Snacks'));
        prodList.add(new Product2(Name = 'CGC Organic Juice 1L', ProductCode = 'PROD-JUC-04', IsActive = true, Family = 'Beverages'));
        prodList.add(new Product2(Name = 'CGC Mineral Water 500ml', ProductCode = 'PROD-WTR-05', IsActive = true, Family = 'Beverages'));
        insert prodList;
        counts.put('Product2', prodList.size());

        // 8. Visits
        Id currentUserId = UserInfo.getUserId();
        List<Visit> visitList = new List<Visit>();
        visitList.add(new Visit(
            AccountId = accList[0].Id,
            PlaceId = locList[0].Id,
            Status = 'Planned',
            PlannedVisitStartTime = DateTime.now(),
            PlannedVisitEndTime = DateTime.now().addHours(2),
            cgcloud__Accountable__c = currentUserId,
            cgcloud__Responsible__c = currentUserId,
            cgcloud__Note__c = 'Check cooler display and inventory levels.'
        ));
        visitList.add(new Visit(
            AccountId = accList[1].Id,
            PlaceId = locList[1].Id,
            Status = 'InProgress',
            PlannedVisitStartTime = DateTime.now().addHours(-1),
            PlannedVisitEndTime = DateTime.now().addHours(1),
            cgcloud__Accountable__c = currentUserId,
            cgcloud__Responsible__c = currentUserId,
            cgcloud__Note__c = 'Review promotional displays and collect audit survey.'
        ));
        visitList.add(new Visit(
            AccountId = accList[2].Id,
            PlaceId = locList[2].Id,
            Status = 'Completed',
            PlannedVisitStartTime = DateTime.now().addDays(-1),
            PlannedVisitEndTime = DateTime.now().addDays(-1).addHours(2),
            cgcloud__Accountable__c = currentUserId,
            cgcloud__Responsible__c = currentUserId,
            cgcloud__Note__c = 'Completed weekly routine audit and order placement.'
        ));
        visitList.add(new Visit(
            AccountId = accList[3].Id,
            PlaceId = locList[3].Id,
            Status = 'Planned',
            PlannedVisitStartTime = DateTime.now().addDays(1),
            PlannedVisitEndTime = DateTime.now().addDays(1).addHours(2),
            cgcloud__Accountable__c = currentUserId,
            cgcloud__Responsible__c = currentUserId,
            cgcloud__Note__c = 'Upcoming store briefing for promotional launch.'
        ));
        visitList.add(new Visit(
            AccountId = accList[4].Id,
            PlaceId = locList[4].Id,
            Status = 'Planned',
            PlannedVisitStartTime = DateTime.now().addDays(2),
            PlannedVisitEndTime = DateTime.now().addDays(2).addHours(2),
            cgcloud__Accountable__c = currentUserId,
            cgcloud__Responsible__c = currentUserId,
            cgcloud__Note__c = 'Scheduled compliance and stock balance check.'
        ));
        insert visitList;
        counts.put('Visit', visitList.size());

        // 9. CG Cloud Orders (cgcloud__Order__c & cgcloud__Order_Item__c)
        try {
            if (Test.isRunningTest() && forceException) {
                throw new DmlException('Forced Order Exception');
            }
            cgcloud__Order_Template__c ordTmpl = new cgcloud__Order_Template__c(Name = 'Standard Order Template');
            insert ordTmpl;

            List<cgcloud__Order__c> ordList = new List<cgcloud__Order__c>();
            ordList.add(new cgcloud__Order__c(
                cgcloud__Order_Account__c = accList[0].Id,
                cgcloud__Order_Template__c = ordTmpl.Id,
                cgcloud__Phase__c = 'ReadyForDelivery',
                cgcloud__Total_Value__c = 1500.00,
                cgcloud__Gross_Total_Value__c = 1450.00,
                cgcloud__Order_Date__c = Date.today().addDays(-3),
                cgcloud__Delivery_Date__c = Date.today().addDays(1),
                cgcloud__Delivery_Note__c = 'Deliver to rear loading dock Gate B.',
                cgcloud__Invoice_Note__c = 'Payment terms Net 30.'
            ));
            ordList.add(new cgcloud__Order__c(
                cgcloud__Order_Account__c = accList[1].Id,
                cgcloud__Order_Template__c = ordTmpl.Id,
                cgcloud__Phase__c = 'Submitted',
                cgcloud__Total_Value__c = 3200.00,
                cgcloud__Gross_Total_Value__c = 3100.00,
                cgcloud__Order_Date__c = Date.today().addDays(-1),
                cgcloud__Delivery_Date__c = Date.today().addDays(2),
                cgcloud__Delivery_Note__c = 'Call store manager prior to unloading.',
                cgcloud__Invoice_Note__c = 'PO-2026-991A'
            ));
            ordList.add(new cgcloud__Order__c(
                cgcloud__Order_Account__c = accList[2].Id,
                cgcloud__Order_Template__c = ordTmpl.Id,
                cgcloud__Phase__c = 'Initial',
                cgcloud__Total_Value__c = 850.00,
                cgcloud__Gross_Total_Value__c = 800.00,
                cgcloud__Order_Date__c = Date.today(),
                cgcloud__Delivery_Date__c = Date.today().addDays(3),
                cgcloud__Delivery_Note__c = 'Standard morning delivery window.',
                cgcloud__Invoice_Note__c = 'Electronic invoice requested.'
            ));
            insert ordList;
            counts.put('cgcloud__Order__c', ordList.size());

            List<cgcloud__Order_Item__c> itemList = new List<cgcloud__Order_Item__c>();
            itemList.add(new cgcloud__Order_Item__c(
                cgcloud__Order__c = ordList[0].Id,
                cgcloud__Product__c = prodList[0].Id,
                cgcloud__Quantity__c = 50,
                cgcloud__UOM__c = 'PCS'
            ));
            itemList.add(new cgcloud__Order_Item__c(
                cgcloud__Order__c = ordList[0].Id,
                cgcloud__Product__c = prodList[1].Id,
                cgcloud__Quantity__c = 25,
                cgcloud__UOM__c = 'PCS'
            ));
            itemList.add(new cgcloud__Order_Item__c(
                cgcloud__Order__c = ordList[1].Id,
                cgcloud__Product__c = prodList[2].Id,
                cgcloud__Quantity__c = 100,
                cgcloud__UOM__c = 'PCS'
            ));
            itemList.add(new cgcloud__Order_Item__c(
                cgcloud__Order__c = ordList[2].Id,
                cgcloud__Product__c = prodList[3].Id,
                cgcloud__Quantity__c = 30,
                cgcloud__UOM__c = 'PCS'
            ));
            insert itemList;
            counts.put('cgcloud__Order_Item__c', itemList.size());
        } catch (Exception e) {
            System.debug('CG Cloud Orders creation skipped: ' + e.getMessage());
        }

        // 10. CG Cloud Visit Activities / Templates / Jobs
        try {
            if (Test.isRunningTest() && forceException) {
                throw new DmlException('Forced Jobs Exception');
            }
            cgcloud__Visit_Template__c template = new cgcloud__Visit_Template__c(Name = 'Standard Store Audit Template');
            insert template;

            cgcloud__Job_Template__c jtQ = new cgcloud__Job_Template__c(Name = 'Question');
            insert jtQ;

            cgcloud__Job_Definition_Template__c jdt1 = new cgcloud__Job_Definition_Template__c(
                Name = 'Check Cooler Temperature',
                cgcloud__Job_Template__c = jtQ.Id,
                cgcloud__Data_Type__c = 'String'
            );
            cgcloud__Job_Definition_Template__c jdt2 = new cgcloud__Job_Definition_Template__c(
                Name = 'Verify Promotional Shelf Placement',
                cgcloud__Job_Template__c = jtQ.Id,
                cgcloud__Data_Type__c = 'String'
            );
            insert new List<cgcloud__Job_Definition_Template__c>{ jdt1, jdt2 };

            List<cgcloud__Visit_Job__c> vjList = new List<cgcloud__Visit_Job__c>();
            vjList.add(new cgcloud__Visit_Job__c(
                cgcloud__Visit__c = visitList[0].Id,
                cgcloud__Job_Definition_Template__c = jdt1.Id,
                cgcloud__Done__c = true,
                cgcloud__Value__c = '38 F'
            ));
            vjList.add(new cgcloud__Visit_Job__c(
                cgcloud__Visit__c = visitList[0].Id,
                cgcloud__Job_Definition_Template__c = jdt2.Id,
                cgcloud__Done__c = true,
                cgcloud__Value__c = 'Compliant'
            ));
            vjList.add(new cgcloud__Visit_Job__c(
                cgcloud__Visit__c = visitList[1].Id,
                cgcloud__Job_Definition_Template__c = jdt1.Id,
                cgcloud__Done__c = false,
                cgcloud__Value__c = ''
            ));
            insert vjList;
            counts.put('cgcloud__Visit_Job__c', vjList.size());
        } catch (Exception e) {
            System.debug('CG Cloud Visit Jobs creation skipped: ' + e.getMessage());
        }

        return counts;
    }
}
```

---

## 2. 🧪 `AgentTestDataTest.cls`

```apex
/**
 * @description Master unit test class for AgentTestData targeting 100% code coverage.
 */
@IsTest
public class AgentTestDataTest {

    @IsTest
    static void testSeedAllDataFirstAndSecondRun() {
        Test.startTest();
        Map<String, Integer> countsFirst = AgentTestData.seedAllData();
        List<String> invocableResults = AgentTestData.seedDataInvocable();

        // Second run exercises existing Account/Location detection branch
        Map<String, Integer> countsSecond = AgentTestData.seedAllData();
        Test.stopTest();

        Assert.isNotNull(countsFirst, 'Counts map should be populated.');
        Assert.areEqual(5, countsFirst.get('Account'), '5 Accounts created on first run.');
        Assert.areEqual(5, countsSecond.get('Account'), '5 Accounts retrieved on second run.');
        Assert.isNotNull(invocableResults, 'Invocable result list should not be null.');
    }

    @IsTest
    static void testSeedAllDataExceptions() {
        AgentTestData.forceException = true;

        Test.startTest();
        Map<String, Integer> counts = AgentTestData.seedAllData();
        Test.stopTest();

        Assert.isNotNull(counts, 'Counts map should be populated.');
        AgentTestData.forceException = false;
    }
}
```

---

## 3. 🚀 How to Run in Anonymous Apex

If you ever need to seed test data in any Salesforce org (Scratch Org or Sandbox), simply run:

```apex
Map<String, Integer> results = AgentTestData.seedAllData();
System.debug('Seeded records: ' + JSON.serializePretty(results));
```
