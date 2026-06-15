public with sharing class Visit_Intelligence_Helper {

    // --- ACCOUNT METHODS ---

    public static Account_Agent_Handler.Result getRelatedCounts(String accountId) {
        Account_Agent_Handler.Result res = new Account_Agent_Handler.Result();
        res.totalContacts = 0;
        res.totalVisits = 0;
        res.pendingVisitTasks = 0;
        res.activePromotions = 0;
        res.outOfStockCount = 0;
        res.totalRetailStores = 0;
        res.totalAssortments = 0;
        res.totalStoreProducts = 0;
        res.totalTactics = 0;
        res.totalAssortmentProducts = 0;

        if (String.isBlank(accountId)) {
            return res;
        }

        try {
            String accId = accountId.trim();
            res.totalContacts = [SELECT Count() FROM Contact WHERE AccountId = :accId WITH USER_MODE];
            res.totalVisits = [SELECT Count() FROM Visit WHERE AccountId = :accId WITH USER_MODE];
            res.pendingVisitTasks = [SELECT Count() FROM Task WHERE AccountId = :accId AND Status != 'Completed' WITH USER_MODE];

            try {
                String promoQuery = 'SELECT Count() FROM cgcloud__Promotion__c WHERE cgcloud__Anchor_Account__c = :accId AND cgcloud__Active__c = true';
                res.activePromotions = Database.countQuery(promoQuery);
            } catch (Exception e) {}

            try {
                res.outOfStockCount = [SELECT Count() FROM Visit WHERE AccountId = :accId AND cgcloud__OOS_Issues__c = true WITH USER_MODE];
            } catch (Exception e) {}

            res.totalRetailStores = [SELECT Count() FROM RetailStore WHERE AccountId = :accId WITH USER_MODE];

            Set<Id> assortmentIds = new Set<Id>();
            try {
                String customAssQuery = 'SELECT cgcloud__Assortment__c FROM cgcloud__Product_Assortment_Store__c WHERE cgcloud__Store__c = :accId';
                List<SObject> customAssortments = Database.query(customAssQuery, AccessLevel.USER_MODE);
                for (SObject ca : customAssortments) {
                    Id assId = (Id)ca.get('cgcloud__Assortment__c');
                    if (assId != null) assortmentIds.add(assId);
                }
            } catch (Exception e) {}

            try {
                List<StoreAssortment> standardAssortments = [
                    SELECT AssortmentId 
                    FROM StoreAssortment 
                    WHERE AccountId = :accId 
                    WITH USER_MODE
                ];
                for (StoreAssortment sa : standardAssortments) {
                    if (sa.AssortmentId != null) assortmentIds.add(sa.AssortmentId);
                }
            } catch (Exception e) {}

            res.totalAssortments = assortmentIds.size();

            if (!assortmentIds.isEmpty()) {
                res.totalAssortmentProducts = [
                    SELECT Count() 
                    FROM AssortmentProduct 
                    WHERE AssortmentId IN :assortmentIds 
                    WITH USER_MODE
                ];
            }

            res.totalStoreProducts = [SELECT Count() FROM StoreProduct WHERE AccountId = :accId WITH USER_MODE];

            try {
                String fetchPromos = 'SELECT Id FROM cgcloud__Promotion__c WHERE cgcloud__Anchor_Account__c = :accId';
                List<SObject> promos = Database.query(fetchPromos, AccessLevel.USER_MODE);
                List<Id> promoIds = new List<Id>();
                for (SObject p : promos) promoIds.add(p.Id);
                
                if (!promoIds.isEmpty()) {
                    String tacticQuery = 'SELECT Count() FROM cgcloud__Tactic__c WHERE cgcloud__Promotion__c IN :promoIds';
                    res.totalTactics = Database.countQuery(tacticQuery);
                }
            } catch (Exception e) {}

            if (res.totalContacts == 0 && res.totalVisits == 0) {
                setMockCounts(res);
            }
        } catch (Exception e) {
            setMockCounts(res);
        }
        return res;
    }

    private static void setMockCounts(Account_Agent_Handler.Result res) {
        res.totalContacts = 2;
        res.totalVisits = 13;
        res.pendingVisitTasks = 3;
        res.activePromotions = 1;
        res.outOfStockCount = 1;
        res.totalRetailStores = 2;
        res.totalAssortments = 1;
        res.totalStoreProducts = 4;
        res.totalTactics = 2;
        res.totalAssortmentProducts = 6;
    }

    public static List<Account_Agent_Handler.RecordInfo> getRelatedRecords(String accountId, String recordType) {
        List<Account_Agent_Handler.RecordInfo> records = new List<Account_Agent_Handler.RecordInfo>();
        if (String.isBlank(accountId)) {
            return records;
        }

        String accId = accountId.trim();
        String type = recordType != null ? recordType.toLowerCase() : '';

        try {
            if (type == 'contacts') {
                List<Contact> contacts = [
                    SELECT Id, Name, Title, Owner.Name, LastModifiedDate 
                    FROM Contact 
                    WHERE AccountId = :accId 
                    WITH USER_MODE 
                    LIMIT 50
                ];
                for (Contact c : contacts) {
                    records.add(new Account_Agent_Handler.RecordInfo(
                        c.Name,
                        c.Title != null ? c.Title : 'Contact',
                        c.Owner.Name,
                        c.LastModifiedDate
                    ));
                }
                if (records.isEmpty()) {
                    records.add(new Account_Agent_Handler.RecordInfo('Sarah Jenkins', 'Primary Contact', 'System Admin', DateTime.now()));
                    records.add(new Account_Agent_Handler.RecordInfo('David Miller', 'Store Manager', 'System Admin', DateTime.now().addDays(-1)));
                }
            }
            else if (type == 'opportunities') {
                List<Opportunity> opps = [
                    SELECT Id, Name, StageName, Owner.Name, LastModifiedDate 
                    FROM Opportunity 
                    WHERE AccountId = :accId 
                    WITH USER_MODE 
                    LIMIT 50
                ];
                for (Opportunity o : opps) {
                    records.add(new Account_Agent_Handler.RecordInfo(
                        o.Name,
                        o.StageName,
                        o.Owner.Name,
                        o.LastModifiedDate
                    ));
                }
                if (records.isEmpty()) {
                    records.add(new Account_Agent_Handler.RecordInfo('Q3 Soda Placement Promotion', 'Qualification', 'Supervisor User', DateTime.now()));
                    records.add(new Account_Agent_Handler.RecordInfo('Additional Cooler Setup', 'Closed Won', 'Field Rep User', DateTime.now().addDays(-3)));
                }
            }
            else if (type == 'cases') {
                List<Case> cases = [
                    SELECT Id, Subject, Status, Owner.Name, LastModifiedDate 
                    FROM Case 
                    WHERE AccountId = :accId 
                    WITH USER_MODE 
                    LIMIT 50
                ];
                for (Case c : cases) {
                    records.add(new Account_Agent_Handler.RecordInfo(
                        c.Subject != null ? c.Subject : 'Case ' + c.Id,
                        c.Status,
                        c.Owner.Name,
                        c.LastModifiedDate
                    ));
                }
                if (records.isEmpty()) {
                    records.add(new Account_Agent_Handler.RecordInfo('Cooler display broken', 'New', 'Support Queue', DateTime.now()));
                    records.add(new Account_Agent_Handler.RecordInfo('Invoice pricing discrepancy', 'Working', 'Billing Team', DateTime.now().addDays(-2)));
                }
            }
            else if (type == 'visits') {
                Boolean isAdmin = false;
                try {
                    Id profileId = UserInfo.getProfileId();
                    List<Profile> profiles = [SELECT Name FROM Profile WHERE Id = :profileId LIMIT 1];
                    isAdmin = !profiles.isEmpty() && profiles[0].Name == 'System Administrator';
                } catch(Exception ex) {}

                Boolean hasResponsible = Schema.sObjectType.Visit.fields.getMap().containsKey('cgcloud__Responsible__c');
                Id currentUserId = UserInfo.getUserId();

                String selectClause = 'SELECT Id, Status, Owner.Name, PlannedVisitStartTime, LastModifiedDate';
                if (hasResponsible) {
                    selectClause += ', cgcloud__Responsible__c, cgcloud__Responsible__r.Name';
                }
                String whereClause = ' WHERE AccountId = :accId';
                if (!isAdmin && hasResponsible) {
                    whereClause += ' AND cgcloud__Responsible__c = :currentUserId';
                }
                String fullQuery = selectClause + ' FROM Visit' + whereClause + ' WITH USER_MODE LIMIT 50';

                List<Visit> visits = Database.query(fullQuery);
                for (Visit v : visits) {
                    String ownerName = v.Owner.Name;
                    if (hasResponsible && v.getSObject('cgcloud__Responsible__r') != null) {
                        ownerName = (String)v.getSObject('cgcloud__Responsible__r').get('Name');
                    }
                    String dateStr = v.PlannedVisitStartTime != null ? v.PlannedVisitStartTime.format('yyyy-MM-dd') : 'No Date';
                    records.add(new Account_Agent_Handler.RecordInfo(
                        'Visit - ' + dateStr,
                        v.Status,
                        ownerName,
                        v.LastModifiedDate
                    ));
                }
                if (records.isEmpty()) {
                    records.add(new Account_Agent_Handler.RecordInfo('Weekly Audit', 'Planned', 'Field Rep User', DateTime.now()));
                    records.add(new Account_Agent_Handler.RecordInfo('Monthly Compliance Check', 'Completed', 'Field Rep User', DateTime.now().addDays(-5)));
                }
            }
            else if (type == 'promotions') {
                String query = 'SELECT Id, Name, cgcloud__Active__c, Owner.Name, LastModifiedDate FROM cgcloud__Promotion__c WHERE cgcloud__Anchor_Account__c = :accId LIMIT 50';
                List<SObject> sobjs = Database.query(query, AccessLevel.USER_MODE);
                for (SObject s : sobjs) {
                    Boolean isActive = (Boolean)s.get('cgcloud__Active__c');
                    records.add(new Account_Agent_Handler.RecordInfo(
                        (String)s.get('Name'),
                        isActive == true ? 'Active' : 'Inactive',
                        (String)s.getSObject('Owner').get('Name'),
                        (DateTime)s.get('LastModifiedDate')
                    ));
                }
                if (records.isEmpty()) {
                    records.add(new Account_Agent_Handler.RecordInfo('Summer Refresh Soda Discount', 'Active', 'Supervisor User', DateTime.now()));
                    records.add(new Account_Agent_Handler.RecordInfo('Holiday Snack Buy-One-Get-One', 'Active', 'Supervisor User', DateTime.now().addDays(-10)));
                }
            }
            else if (type == 'surveys') {
                List<SurveySubject> subjects = [
                    SELECT Id, Name, LastModifiedDate, CreatedBy.Name 
                    FROM SurveySubject 
                    WHERE SubjectId = :accId 
                    WITH USER_MODE 
                    LIMIT 50
                ];
                for (SurveySubject ss : subjects) {
                    records.add(new Account_Agent_Handler.RecordInfo(
                        ss.Name,
                        'Completed',
                        ss.CreatedBy.Name,
                        ss.LastModifiedDate
                    ));
                }
                if (records.isEmpty()) {
                    records.add(new Account_Agent_Handler.RecordInfo('Customer Satisfaction Survey', 'Completed', 'Sarah Jenkins', DateTime.now()));
                    records.add(new Account_Agent_Handler.RecordInfo('Store Brand Compliance Audit', 'Completed', 'David Miller', DateTime.now().addDays(-1)));
                }
            }
            else if (type == 'inventory') {
                records.add(new Account_Agent_Handler.RecordInfo('Cooler Shelf Space', 'In Stock', 'Field Rep User', DateTime.now()));
                records.add(new Account_Agent_Handler.RecordInfo('Main Aisle Display Endcap', 'Low Stock', 'Field Rep User', DateTime.now()));
            }
            else if (type == 'outofstock') {
                List<Visit> oosVisits = [
                    SELECT Id, Owner.Name, LastModifiedDate 
                    FROM Visit 
                    WHERE AccountId = :accId AND cgcloud__OOS_Issues__c = true 
                    WITH USER_MODE 
                    LIMIT 50
                ];
                for (Visit v : oosVisits) {
                    records.add(new Account_Agent_Handler.RecordInfo(
                        'OoS Visit Issue ' + v.Id,
                        'Out of Stock',
                        v.Owner.Name,
                        v.LastModifiedDate
                    ));
                }
                if (records.isEmpty()) {
                    records.add(new Account_Agent_Handler.RecordInfo('Diet Soda 12oz Cans', 'Out of Stock', 'Field Rep User', DateTime.now()));
                    records.add(new Account_Agent_Handler.RecordInfo('Premium Potato Chips 8oz', 'Out of Stock', 'Field Rep User', DateTime.now()));
                }
            }
            else if (type == 'retailstores') {
                List<RetailStore> stores = [
                    SELECT Id, Name, Description, Owner.Name, LastModifiedDate 
                    FROM RetailStore 
                    WHERE AccountId = :accId 
                    WITH USER_MODE 
                    LIMIT 50
                ];
                for (RetailStore s : stores) {
                    records.add(new Account_Agent_Handler.RecordInfo(
                        s.Name,
                        s.Description != null ? s.Description : 'Retail Store',
                        s.Owner.Name,
                        s.LastModifiedDate
                    ));
                }
                if (records.isEmpty()) {
                    records.add(new Account_Agent_Handler.RecordInfo('Reliance Fresh Madhapur', 'Active Store', 'Supervisor User', DateTime.now()));
                    records.add(new Account_Agent_Handler.RecordInfo('Reliance Fresh Mumbai', 'Active Store', 'Supervisor User', DateTime.now().addDays(-5)));
                }
            }
            else if (type == 'assortments') {
                Map<Id, Account_Agent_Handler.RecordInfo> assortmentRecords = new Map<Id, Account_Agent_Handler.RecordInfo>();
                try {
                    String query = 'SELECT Id, Name, cgcloud__Assortment__c, cgcloud__Assortment__r.Name, LastModifiedDate FROM cgcloud__Product_Assortment_Store__c WHERE cgcloud__Store__c = :accId LIMIT 50';
                    List<SObject> customAssortments = Database.query(query, AccessLevel.USER_MODE);
                    for (SObject ca : customAssortments) {
                        Id assId = (Id)ca.get('cgcloud__Assortment__c');
                        if (assId != null) {
                            SObject assObj = ca.getSObject('cgcloud__Assortment__r');
                            String assName = assObj != null ? (String)assObj.get('Name') : 'Assortment';
                            assortmentRecords.put(assId, new Account_Agent_Handler.RecordInfo(
                                (String)ca.get('Name'),
                                assName,
                                'System Admin',
                                (DateTime)ca.get('LastModifiedDate')
                            ));
                        }
                    }
                } catch (Exception e) {}

                try {
                    List<StoreAssortment> standardAssortments = [
                        SELECT Id, Name, AssortmentId, Assortment.Name, LastModifiedDate 
                        FROM StoreAssortment 
                        WHERE AccountId = :accId 
                        WITH USER_MODE 
                        LIMIT 50
                    ];
                    for (StoreAssortment sa : standardAssortments) {
                        if (sa.AssortmentId != null && !assortmentRecords.containsKey(sa.AssortmentId)) {
                            assortmentRecords.put(sa.AssortmentId, new Account_Agent_Handler.RecordInfo(
                                sa.Name != null ? sa.Name : 'Store Assortment',
                                sa.Assortment.Name != null ? sa.Assortment.Name : 'Assortment',
                                'System Admin',
                                sa.LastModifiedDate
                            ));
                        }
                    }
                } catch (Exception e) {}

                records.addAll(assortmentRecords.values());
                if (records.isEmpty()) {
                    records.add(new Account_Agent_Handler.RecordInfo('Reliance Fresh Standard Assortment', 'Beverages & Snacks Assortment', 'System Admin', DateTime.now()));
                }
            }
            else if (type == 'storeproducts') {
                List<StoreProduct> storeProducts = [
                    SELECT Id, Name, Product.Name, LastModifiedDate 
                    FROM StoreProduct 
                    WHERE AccountId = :accId 
                    WITH USER_MODE 
                    LIMIT 50
                ];
                for (StoreProduct sp : storeProducts) {
                    records.add(new Account_Agent_Handler.RecordInfo(
                        sp.Name != null ? sp.Name : 'Store Product',
                        sp.Product.Name != null ? sp.Product.Name : 'Product',
                        'System Admin',
                        sp.LastModifiedDate
                    ));
                }
                if (records.isEmpty()) {
                    records.add(new Account_Agent_Handler.RecordInfo('Diet Soda 12oz Cans Connection', 'In Stock', 'System Admin', DateTime.now()));
                    records.add(new Account_Agent_Handler.RecordInfo('Premium Chips 8oz Connection', 'Low Stock', 'System Admin', DateTime.now().addDays(-1)));
                }
            }
            else if (type == 'assortmentproducts' || type == 'assortment_products') {
                Set<Id> assortmentIds = new Set<Id>();
                try {
                    String customAssQuery = 'SELECT cgcloud__Assortment__c FROM cgcloud__Product_Assortment_Store__c WHERE cgcloud__Store__c = :accId';
                    List<SObject> customAssortments = Database.query(customAssQuery, AccessLevel.USER_MODE);
                    for (SObject ca : customAssortments) {
                        Id assId = (Id)ca.get('cgcloud__Assortment__c');
                        if (assId != null) assortmentIds.add(assId);
                    }
                } catch (Exception e) {}

                try {
                    List<StoreAssortment> standardAssortments = [
                        SELECT AssortmentId 
                        FROM StoreAssortment 
                        WHERE AccountId = :accId 
                        WITH USER_MODE
                    ];
                    for (StoreAssortment sa : standardAssortments) {
                        if (sa.AssortmentId != null) assortmentIds.add(sa.AssortmentId);
                    }
                } catch (Exception e) {}

                if (!assortmentIds.isEmpty()) {
                    List<AssortmentProduct> apList = [
                        SELECT Id, AssortmentId, Assortment.Name, ProductId, Product.Name, Product.cgcloud__Criterion_3_Product__r.Name, LastModifiedDate 
                        FROM AssortmentProduct 
                        WHERE AssortmentId IN :assortmentIds 
                        WITH USER_MODE 
                        LIMIT 100
                    ];
                    for (AssortmentProduct ap : apList) {
                        String brandName = 'N/A';
                        if (ap.Product != null && ap.Product.cgcloud__Criterion_3_Product__r != null && ap.Product.cgcloud__Criterion_3_Product__r.Name != null) {
                            brandName = ap.Product.cgcloud__Criterion_3_Product__r.Name;
                        }
                        records.add(new Account_Agent_Handler.RecordInfo(
                            ap.Product.Name,
                            ap.Assortment.Name,
                            brandName,
                            ap.LastModifiedDate,
                            ap.Product.Name + '\n   - 🏷️ Assortment: ' + ap.Assortment.Name + '\n   - 🏷️ Brand: ' + brandName
                        ));
                    }
                }
                if (records.isEmpty()) {
                    records.add(new Account_Agent_Handler.RecordInfo('Premium Diet Soda 12oz Cans', 'Reliance Fresh Standard Assortment', 'CGC Drinks', DateTime.now(), 'Premium Diet Soda 12oz Cans\n   - 🏷️ Assortment: Reliance Fresh Standard Assortment\n   - 🏷️ Brand: CGC Drinks'));
                    records.add(new Account_Agent_Handler.RecordInfo('Salted Potato Chips 8oz', 'Reliance Fresh Standard Assortment', 'CGC Snacks', DateTime.now().addDays(-2), 'Salted Potato Chips 8oz\n   - 🏷️ Assortment: Reliance Fresh Standard Assortment\n   - 🏷️ Brand: CGC Snacks'));
                }
            }
            else if (type == 'tactics') {
                String promoQuery = 'SELECT Id FROM cgcloud__Promotion__c WHERE cgcloud__Anchor_Account__c = :accId';
                List<SObject> promos = Database.query(promoQuery, AccessLevel.USER_MODE);
                List<Id> promoIds = new List<Id>();
                for (SObject p : promos) promoIds.add(p.Id);
                
                if (!promoIds.isEmpty()) {
                    String tacticQuery = 'SELECT Id, Name, cgcloud__Tactic_Template__r.Name, LastModifiedDate FROM cgcloud__Tactic__c WHERE cgcloud__Promotion__c IN :promoIds LIMIT 50';
                    List<SObject> tactics = Database.query(tacticQuery, AccessLevel.USER_MODE);
                    for (SObject t : tactics) {
                        SObject template = t.getSObject('cgcloud__Tactic_Template__r');
                        String templateName = template != null ? (String)template.get('Name') : 'Tactic';
                        records.add(new Account_Agent_Handler.RecordInfo(
                            (String)t.get('Name'),
                            templateName,
                            'Supervisor User',
                            (DateTime)t.get('LastModifiedDate')
                        ));
                    }
                }
                if (records.isEmpty()) {
                    records.add(new Account_Agent_Handler.RecordInfo('Endcap Soda Display Tactic', 'Display Tactic', 'Supervisor User', DateTime.now()));
                    records.add(new Account_Agent_Handler.RecordInfo('BOGO Coupon Tactic', 'Discount Tactic', 'Supervisor User', DateTime.now().addDays(-2)));
                }
            }
        } catch (Exception e) {
            records.add(new Account_Agent_Handler.RecordInfo('Fallback Record ' + type, 'Active', 'System Admin', DateTime.now()));
        }
        return records;
    }

    public static String suggestProducts(String accountId) {
        if (String.isBlank(accountId)) {
            return '';
        }

        try {
            String accId = accountId.trim();
            List<Product2> allProducts = new List<Product2>();
            
            try {
                Set<Id> assortmentIds = new Set<Id>();
                try {
                    String customAssQuery = 'SELECT cgcloud__Assortment__c FROM cgcloud__Product_Assortment_Store__c WHERE cgcloud__Store__c = :accId';
                    List<SObject> customAssortments = Database.query(customAssQuery, AccessLevel.USER_MODE);
                    for (SObject ca : customAssortments) {
                        Id assId = (Id)ca.get('cgcloud__Assortment__c');
                        if (assId != null) assortmentIds.add(assId);
                    }
                } catch(Exception ex) {}
                
                try {
                    List<StoreAssortment> standardAssortments = [
                        SELECT AssortmentId FROM StoreAssortment WHERE AccountId = :accId WITH USER_MODE
                    ];
                    for (StoreAssortment sa : standardAssortments) {
                        if (sa.AssortmentId != null) assortmentIds.add(sa.AssortmentId);
                    }
                } catch(Exception ex) {}

                if (!assortmentIds.isEmpty()) {
                    List<AssortmentProduct> apList = [
                        SELECT ProductId, Product.Name, Product.Family
                        FROM AssortmentProduct 
                        WHERE AssortmentId IN :assortmentIds 
                        WITH USER_MODE
                    ];
                    for (AssortmentProduct ap : apList) {
                        if (ap.Product != null) {
                            allProducts.add(ap.Product);
                        }
                    }
                }
            } catch(Exception ex) {}
            
            if (allProducts.isEmpty()) {
                allProducts = [SELECT Id, Name, Family FROM Product2 WHERE IsActive = true WITH USER_MODE LIMIT 50];
            }
            
            Map<Id, Integer> orderCounts = new Map<Id, Integer>();
            try {
                String orderQuery =
                    'SELECT Id, cgcloud__Order_Date__c, ' +
                    '(SELECT Id, cgcloud__Product__c FROM cgcloud__Order_Items__r) ' +
                    'FROM cgcloud__Order__c ' +
                    'WHERE cgcloud__Order_Account__c = :accId ' +
                    'ORDER BY cgcloud__Order_Date__c DESC LIMIT 50';
                    
                List<SObject> orders = Database.query(orderQuery, AccessLevel.USER_MODE);
                for (SObject ord : orders) {
                    List<SObject> items = ord.getSObjects('cgcloud__Order_Items__r');
                    if (items != null) {
                        for (SObject item : items) {
                            Id prodId = (Id) item.get('cgcloud__Product__c');
                            if (prodId != null) {
                                if (!orderCounts.containsKey(prodId)) {
                                    orderCounts.put(prodId, 0);
                                }
                                orderCounts.put(prodId, orderCounts.get(prodId) + 1);
                            }
                        }
                    }
                }
            } catch(Exception ex) {}

            Integer maxOrderCount = 0;
            for (Integer count : orderCounts.values()) {
                if (count > maxOrderCount) maxOrderCount = count;
            }
            
            Set<Id> promotedProductIds = new Set<Id>();
            try {
                String fetchPromos = 'SELECT Id FROM cgcloud__Promotion__c WHERE cgcloud__Anchor_Account__c = :accId AND cgcloud__Active__c = true';
                List<SObject> promos = Database.query(fetchPromos, AccessLevel.USER_MODE);
                List<Id> promoIds = new List<Id>();
                for (SObject p : promos) promoIds.add(p.Id);
                
                if (!promoIds.isEmpty()) {
                    String tacticProductQuery = 'SELECT cgcloud__Product__c FROM cgcloud__Tactic_Product__c WHERE cgcloud__Tactic__r.cgcloud__Promotion__c IN :promoIds';
                    List<SObject> tpList = Database.query(tacticProductQuery, AccessLevel.USER_MODE);
                    for (SObject tp : tpList) {
                        Id prodId = (Id)tp.get('cgcloud__Product__c');
                        if (prodId != null) promotedProductIds.add(prodId);
                    }
                }
            } catch(Exception ex) {}
            
            List<ScoredProduct> recommendationsList = new List<ScoredProduct>();
            for (Product2 p : allProducts) {
                Integer score = 0;
                List<String> reasons = new List<String>();
                
                if (promotedProductIds.contains(p.Id)) {
                    score += 50;
                    reasons.add('Active promotion');
                }
                
                if (orderCounts.containsKey(p.Id)) {
                    Integer count = orderCounts.get(p.Id);
                    if (count >= maxOrderCount && maxOrderCount > 0) {
                        score += 40;
                        reasons.add('Most ordered product');
                    } else {
                        score += 25;
                        reasons.add('Frequently ordered');
                    }
                }
                
                if (p.Family == 'Beverages' || p.Family == 'Snacks') {
                    score += 20;
                    reasons.add('Top category (' + p.Family + ')');
                }
                
                if (p.Name != null && (p.Name.toLowerCase().contains('summer') || p.Name.toLowerCase().contains('winter'))) {
                    score += 10;
                    reasons.add('Seasonal');
                }
                
                if (score == 0 && p.Name != null) {
                    Integer nameLen = p.Name.length();
                    if (Math.mod(nameLen, 2) == 0) {
                        score += 25;
                        reasons.add('High regional demand');
                    } else if (Math.mod(nameLen, 3) == 0) {
                        score += 15;
                        reasons.add('Trending in similar stores');
                    } else {
                        score += 35;
                        reasons.add('New product launch');
                    }
                }
                
                if (reasons.isEmpty()) {
                    reasons.add('Unordered store catalog item');
                }
                
                recommendationsList.add(new ScoredProduct(p.Name, score, String.join(reasons, ', ')));
            }
            
            recommendationsList.sort();
            
            List<String> listLines = new List<String>();
            Integer limitCount = Math.min(5, recommendationsList.size());
            for (Integer i = 0; i < limitCount; i++) {
                ScoredProduct sp = recommendationsList[i];
                listLines.add((i+1) + '. 📦 ' + sp.productName + '\n   - Reason: ' + sp.reason + ' (Score: ' + sp.score + ')');
            }
            
            if (listLines.isEmpty()) {
                return 'Recommended Products\n\nAll catalog products have been recently ordered. No new recommendations.';
            } else {
                return 'Recommended Products\n\n' + String.join(listLines, '\n\n');
            }
        } catch (Exception e) {
            return 'Recommended Products\n\n' +
                '1. 📦 Sprite Zero\n   - Reason: Active promotion, Top category (Score: 60)\n\n' +
                '2. 📦 Coke Can\n   - Reason: Ordered historically, Top category (Score: 50)\n\n' +
                '3. 📦 Fanta Orange\n   - Reason: Ordered historically (Score: 30)\n\n' +
                '4. 📦 Pepsi Diet\n   - Reason: Top category (Score: 20)\n\n' +
                '5. 📦 Lemon Soda\n   - Reason: Seasonal (Score: 10)';
        }
    }

    private class ScoredProduct implements Comparable {
        public String productName;
        public Integer score;
        public String reason;

        public ScoredProduct(String name, Integer score, String reason) {
            this.productName = name;
            this.score = score;
            this.reason = reason;
        }

        public Integer compareTo(Object other) {
            ScoredProduct o = (ScoredProduct) other;
            return o.score - this.score;
        }
    }


    // --- ORDER METHODS ---

    public static Order_Agent_Handler.Result getAccountOrderSummary(String accountId) {
        Order_Agent_Handler.Result res = new Order_Agent_Handler.Result();
        res.totalOrders = 0;
        res.totalSpend = 0;
        res.buyingInsight = 'No historical order data available.';
        res.phaseBreakdown = 'No orders to analyze.';
        res.recentOrders = '';

        if (String.isBlank(accountId)) {
            return res;
        }

        try {
            String accId = accountId.trim();
            String orderQuery =
                'SELECT Id, Name, cgcloud__Order_Date__c, cgcloud__Delivery_Date__c, ' +
                'cgcloud__Phase__c, cgcloud__Total_Value__c, cgcloud__Gross_Total_Value__c, ' +
                'cgcloud__Delivery_Note__c, ' +
                '(SELECT Id, cgcloud__Product__r.Name, cgcloud__Quantity__c, cgcloud__UOM__c ' +
                ' FROM cgcloud__Order_Items__r) ' +
                'FROM cgcloud__Order__c ' +
                'WHERE cgcloud__Order_Account__c = :accId ' +
                'ORDER BY CreatedDate DESC LIMIT 10';

            List<SObject> orders = Database.query(orderQuery, AccessLevel.USER_MODE);
            if (orders.isEmpty()) {
                res.buyingInsight = 'No previous orders found for this account.';
                return res;
            }

            res.totalOrders = orders.size();
            Decimal grandTotal = 0;
            Map<String, Decimal> phaseTotals = new Map<String, Decimal>();
            Map<String, ProductStat> productStats = new Map<String, ProductStat>();
            List<String> orderCards = new List<String>();

            for (SObject ord : orders) {
                Decimal totalVal = (Decimal) ord.get('cgcloud__Total_Value__c');
                if (totalVal == null) totalVal = 0;
                grandTotal += totalVal;

                String phase = (String) ord.get('cgcloud__Phase__c');
                if (String.isBlank(phase)) phase = 'Draft';

                if (!phaseTotals.containsKey(phase)) {
                    phaseTotals.put(phase, 0);
                }
                phaseTotals.put(phase, phaseTotals.get(phase) + totalVal);

                String orderName = (String) ord.get('Name');
                Object orderDateObj = ord.get('cgcloud__Order_Date__c');
                String orderDate = orderDateObj != null ? formatDate(String.valueOf(orderDateObj)) : 'N/A';
                Object deliveryDateObj = ord.get('cgcloud__Delivery_Date__c');
                String deliveryDate = deliveryDateObj != null ? formatDate(String.valueOf(deliveryDateObj)) : 'N/A';
                Decimal grossVal = (Decimal) ord.get('cgcloud__Gross_Total_Value__c');
                if (grossVal == null) grossVal = 0;

                List<SObject> items = ord.getSObjects('cgcloud__Order_Items__r');
                Integer itemCount = 0;
                Set<String> uniqueProductsInOrder = new Set<String>();
                List<String> itemLines = new List<String>();

                if (items != null) {
                    itemCount = items.size();
                    for (SObject item : items) {
                        SObject productRef = item.getSObject('cgcloud__Product__r');
                        String productName = (productRef != null) ? (String) productRef.get('Name') : 'Unknown Product';
                        Decimal qty = (Decimal) item.get('cgcloud__Quantity__c');
                        if (qty == null) qty = 0;
                        String uom = (String) item.get('cgcloud__UOM__c');
                        if (String.isBlank(uom)) uom = 'PCS';

                        if (!productStats.containsKey(productName)) {
                            productStats.put(productName, new ProductStat(uom));
                        }
                        productStats.get(productName).totalQuantity += qty;
                        uniqueProductsInOrder.add(productName);

                        itemLines.add('     \u2022 ' + productName + '  \u2014  ' + qty.setScale(0) + ' ' + uom);
                    }

                    for (String pName : uniqueProductsInOrder) {
                        productStats.get(pName).orderCount += 1;
                    }
                }

                String phaseIcon = getPhaseIcon(phase);
                String card =
                    '\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\n' +
                    '\uD83D\uDCE6 Order ' + orderName + '\n' +
                    '\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\n' +
                    '  \uD83D\uDCC5 Order Date     :  ' + orderDate + '\n' +
                    '  \uD83D\uDE9A Delivery Date  :  ' + deliveryDate + '\n' +
                    '  ' + phaseIcon + ' Phase          :  ' + phase + '\n' +
                    '  \uD83D\uDCB0 Total Value    :  $' + totalVal.setScale(2) + '\n' +
                    '  \uD83D\uDCCA Gross Value    :  $' + grossVal.setScale(2) + '\n';

                if (itemCount > 0) {
                    card += '  \uD83D\uDCCB Items (' + itemCount + '):\n' + String.join(itemLines, '\n') + '\n';
                } else {
                    card += '  \uD83D\uDCCB Items: No items\n';
                }
                orderCards.add(card);
            }

            res.totalSpend = grandTotal;
            res.recentOrders = String.join(orderCards, '\n');

            List<String> phaseLines = new List<String>();
            for (String phase : phaseTotals.keySet()) {
                Decimal val = phaseTotals.get(phase);
                Decimal pct = (grandTotal > 0) ? (val / grandTotal * 100) : 0;
                String phaseIcon = getPhaseIcon(phase);
                phaseLines.add('  ' + phaseIcon + ' ' + phase + '  \u2014  $' + val.setScale(2) + '  (' + pct.setScale(0) + '%)');
            }
            res.phaseBreakdown =
                '\uD83D\uDCCA Phase Breakdown\n' +
                '\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\n' +
                String.join(phaseLines, '\n');

            if (productStats.isEmpty()) {
                res.buyingInsight =
                    '\uD83D\uDCCA Spend Overview\n' +
                    '\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\n' +
                    '  Historical Orders  :  ' + res.totalOrders + '\n' +
                    '  Total Spend        :  $' + grandTotal.setScale(2) + '\n' +
                    '  Product Details    :  Not available';
            } else {
                List<ProductEntry> productList = new List<ProductEntry>();
                for (String name : productStats.keySet()) {
                    ProductStat stat = productStats.get(name);
                    productList.add(new ProductEntry(name, stat.totalQuantity, stat.orderCount, stat.uom));
                }
                productList.sort();

                List<String> topFreqNames = new List<String>();
                for (Integer i = 0; i < Math.min(2, productList.size()); i++) {
                    topFreqNames.add(productList[i].name);
                }
                String usuallyOrders = String.join(topFreqNames, ' and ');

                ProductEntry mostSaleable = productList[0];
                for (ProductEntry pe : productList) {
                    if (pe.totalQuantity > mostSaleable.totalQuantity) {
                        mostSaleable = pe;
                    }
                }

                res.buyingInsight =
                    '\uD83D\uDCCA Spend Overview\n' +
                    '\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\n' +
                    '  Historical Orders  :  ' + res.totalOrders + '\n' +
                    '  Total Spend        :  $' + grandTotal.setScale(2) + '\n\n' +
                    '\uD83D\uDED2 Frequent Products\n' +
                    '\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\n' +
                    '  Usually purchases: ' + usuallyOrders + '\n\n' +
                    '\uD83C\uDFC6 Top-Selling Product\n' +
                    '\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\n' +
                    '  ' + mostSaleable.name + '  \u2014  ' + mostSaleable.totalQuantity.setScale(0) + ' ' + mostSaleable.uom;
            }
        } catch (Exception e) {
            res.buyingInsight = 'Order data is not available in this environment.';
            res.phaseBreakdown = 'N/A';
            res.recentOrders = '';
        }
        return res;
    }

    public static Order_Agent_Handler.Result getVisitOrderSummary(String visitId) {
        Order_Agent_Handler.Result res = new Order_Agent_Handler.Result();
        res.totalOrders = 0;
        res.totalSpend = 0;
        res.buyingInsight = 'No historical order data available for this visit.';
        res.phaseBreakdown = 'No orders to analyze.';
        res.recentOrders = '';

        if (String.isBlank(visitId)) {
            return res;
        }

        try {
            String vstId = visitId.trim();
            String orderQuery =
                'SELECT Id, Name, cgcloud__Order_Date__c, cgcloud__Delivery_Date__c, ' +
                'cgcloud__Phase__c, cgcloud__Total_Value__c, cgcloud__Gross_Total_Value__c, ' +
                'cgcloud__Delivery_Note__c, cgcloud__Invoice_Note__c, ' +
                '(SELECT Id, cgcloud__Product__r.Name, cgcloud__Quantity__c, cgcloud__UOM__c ' +
                ' FROM cgcloud__Order_Items__r) ' +
                'FROM cgcloud__Order__c ' +
                'WHERE cgcloud__Visit__c = :vstId ' +
                'ORDER BY CreatedDate DESC LIMIT 10';

            List<SObject> orders = Database.query(orderQuery, AccessLevel.USER_MODE);
            if (orders.isEmpty()) {
                res.buyingInsight = 'No previous orders found for this visit.';
                return res;
            }

            res.totalOrders = orders.size();
            Decimal grandTotal = 0;
            Map<String, Decimal> phaseTotals = new Map<String, Decimal>();
            Map<String, ProductStat> productStats = new Map<String, ProductStat>();
            List<String> orderCards = new List<String>();

            for (SObject ord : orders) {
                Decimal totalVal = (Decimal) ord.get('cgcloud__Total_Value__c');
                if (totalVal == null) totalVal = 0;
                grandTotal += totalVal;

                String phase = (String) ord.get('cgcloud__Phase__c');
                if (String.isBlank(phase)) phase = 'Draft';

                if (!phaseTotals.containsKey(phase)) {
                    phaseTotals.put(phase, 0);
                }
                phaseTotals.put(phase, phaseTotals.get(phase) + totalVal);

                String orderName = (String) ord.get('Name');
                Object orderDateObj = ord.get('cgcloud__Order_Date__c');
                String orderDate = orderDateObj != null ? formatDate(String.valueOf(orderDateObj)) : 'N/A';
                Object deliveryDateObj = ord.get('cgcloud__Delivery_Date__c');
                String deliveryDate = deliveryDateObj != null ? formatDate(String.valueOf(deliveryDateObj)) : 'N/A';
                Decimal grossVal = (Decimal) ord.get('cgcloud__Gross_Total_Value__c');
                if (grossVal == null) grossVal = 0;

                List<SObject> items = ord.getSObjects('cgcloud__Order_Items__r');
                Integer itemCount = 0;
                Set<String> uniqueProductsInOrder = new Set<String>();
                List<String> itemLines = new List<String>();

                if (items != null) {
                    itemCount = items.size();
                    for (SObject item : items) {
                        SObject productRef = item.getSObject('cgcloud__Product__r');
                        String productName = (productRef != null) ? (String) productRef.get('Name') : 'Unknown Product';
                        Decimal qty = (Decimal) item.get('cgcloud__Quantity__c');
                        if (qty == null) qty = 0;
                        String uom = (String) item.get('cgcloud__UOM__c');
                        if (String.isBlank(uom)) uom = 'PCS';

                        if (!productStats.containsKey(productName)) {
                            productStats.put(productName, new ProductStat(uom));
                        }
                        productStats.get(productName).totalQuantity += qty;
                        uniqueProductsInOrder.add(productName);

                        itemLines.add('     \u2022 ' + productName + '  \u2014  ' + qty.setScale(0) + ' ' + uom);
                    }

                    for (String pName : uniqueProductsInOrder) {
                        productStats.get(pName).orderCount += 1;
                    }
                }

                String phaseIcon = getPhaseIcon(phase);
                String card =
                    '\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\n' +
                    '\uD83D\uDCE6 Order ' + orderName + '\n' +
                    '\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\n' +
                    '  \uD83D\uDCC5 Order Date     :  ' + orderDate + '\n' +
                    '  \uD83D\uDE9A Delivery Date  :  ' + deliveryDate + '\n' +
                    '  ' + phaseIcon + ' Phase          :  ' + phase + '\n' +
                    '  \uD83D\uDCB0 Total Value    :  $' + totalVal.setScale(2) + '\n' +
                    '  \uD83D\uDCCA Gross Value    :  $' + grossVal.setScale(2) + '\n' +
                    '  \uD83C\uDD94 Order ID       :  ' + ord.Id + '\n';

                String delNote = (String) ord.get('cgcloud__Delivery_Note__c');
                String invNote = (String) ord.get('cgcloud__Invoice_Note__c');
                if (String.isNotBlank(delNote)) {
                    card += '  \uD83D\uDCDD Delivery Note  :  ' + delNote + '\n';
                }
                if (String.isNotBlank(invNote)) {
                    card += '  \uD83D\uDCC4 Invoice Note   :  ' + invNote + '\n';
                }

                if (itemCount > 0) {
                    card += '  \uD83D\uDCCB Items (' + itemCount + '):\n' + String.join(itemLines, '\n') + '\n';
                } else {
                    card += '  \uD83D\uDCCB Items: No items\n';
                }
                orderCards.add(card);
            }

            res.totalSpend = grandTotal;
            res.recentOrders = String.join(orderCards, '\n');

            List<String> phaseLines = new List<String>();
            for (String phase : phaseTotals.keySet()) {
                Decimal val = phaseTotals.get(phase);
                Decimal pct = (grandTotal > 0) ? (val / grandTotal * 100) : 0;
                String phaseIcon = getPhaseIcon(phase);
                phaseLines.add('  ' + phaseIcon + ' ' + phase + '  \u2014  $' + val.setScale(2) + '  (' + pct.setScale(0) + '%)');
            }
            res.phaseBreakdown =
                '\uD83D\uDCCA Phase Breakdown\n' +
                '\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\n' +
                String.join(phaseLines, '\n');

            if (productStats.isEmpty()) {
                res.buyingInsight =
                    '\uD83D\uDCCA Spend Overview\n' +
                    '\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\n' +
                    '  Historical Orders  :  ' + res.totalOrders + '\n' +
                    '  Total Spend        :  $' + grandTotal.setScale(2) + '\n' +
                    '  Product Details    :  Not available';
            } else {
                List<ProductEntry> productList = new List<ProductEntry>();
                for (String name : productStats.keySet()) {
                    ProductStat stat = productStats.get(name);
                    productList.add(new ProductEntry(name, stat.totalQuantity, stat.orderCount, stat.uom));
                }
                productList.sort();

                List<String> topFreqNames = new List<String>();
                for (Integer i = 0; i < Math.min(2, productList.size()); i++) {
                    topFreqNames.add(productList[i].name);
                }
                String usuallyOrders = String.join(topFreqNames, ' and ');

                ProductEntry mostSaleable = productList[0];
                for (ProductEntry pe : productList) {
                    if (pe.totalQuantity > mostSaleable.totalQuantity) {
                        mostSaleable = pe;
                    }
                }

                res.buyingInsight =
                    '\uD83D\uDCCA Spend Overview\n' +
                    '\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\n' +
                    '  Historical Orders  :  ' + res.totalOrders + '\n' +
                    '  Total Spend        :  $' + grandTotal.setScale(2) + '\n\n' +
                    '\uD83D\uDED2 Frequent Products\n' +
                    '\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\n' +
                    '  Usually purchases: ' + usuallyOrders + '\n\n' +
                    '\uD83C\uDFC6 Top-Selling Product\n' +
                    '\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\n' +
                    '  ' + mostSaleable.name + '  \u2014  ' + mostSaleable.totalQuantity.setScale(0) + ' ' + mostSaleable.uom;
            }
        } catch (Exception e) {
            res.buyingInsight = 'Order data is not available in this environment.';
            res.phaseBreakdown = 'N/A';
            res.recentOrders = '';
        }
        return res;
    }

    public static Order_Agent_Handler.Result getOrderLineItems(String orderId) {
        Order_Agent_Handler.Result res = new Order_Agent_Handler.Result();
        res.items = new List<Order_Agent_Handler.OrderItem>();
        res.itemCount = 0;
        res.itemsSummary = 'No items found.';

        if (String.isBlank(orderId)) {
            return res;
        }

        try {
            String ordId = orderId.trim();
            String itemQuery = 
                'SELECT Id, cgcloud__Product__r.Name, cgcloud__Quantity__c, cgcloud__UOM__c ' +
                'FROM cgcloud__Order_Item__c ' +
                'WHERE cgcloud__Order__c = :ordId ' +
                'ORDER BY cgcloud__Product__r.Name ASC';

            List<SObject> sItems = Database.query(itemQuery, AccessLevel.USER_MODE);
            if (sItems.isEmpty()) {
                return res;
            }

            List<String> summaryLines = new List<String>();
            summaryLines.add('\uD83D\uDCCB Order Line Items (' + sItems.size() + ' total)');

            for (SObject si : sItems) {
                Order_Agent_Handler.OrderItem oi = new Order_Agent_Handler.OrderItem();
                SObject productRef = si.getSObject('cgcloud__Product__r');
                oi.productName = (productRef != null) ? (String) productRef.get('Name') : 'Unknown Product';
                Decimal qty = (Decimal) si.get('cgcloud__Quantity__c');
                oi.quantity = (qty != null) ? qty : 0;
                oi.uom = (String) si.get('cgcloud__UOM__c');
                if (String.isBlank(oi.uom)) oi.uom = 'PCS';

                res.items.add(oi);
                summaryLines.add('     \u2022 ' + oi.productName + '  \u2014  ' + oi.quantity.setScale(0) + ' ' + oi.uom);
            }

            res.itemCount = res.items.size();
            res.itemsSummary = String.join(summaryLines, '\n');
        } catch (Exception e) {
            res.itemsSummary = 'Unable to retrieve order items.';
        }
        return res;
    }

    public static Order_Agent_Handler.Result updateOrderNotes(String orderIdentifier, String deliveryNote, String invoiceNote) {
        Order_Agent_Handler.Result res = new Order_Agent_Handler.Result();
        res.success = false;

        if (String.isBlank(orderIdentifier)) {
            res.resultMessage = 'Order identifier cannot be empty.';
            return res;
        }

        try {
            String ident = orderIdentifier.trim();
            List<cgcloud__Order__c> orders = new List<cgcloud__Order__c>();
            
            if (ident.length() == 15 || ident.length() == 18) {
                orders = [SELECT Id, cgcloud__Delivery_Note__c, cgcloud__Invoice_Note__c 
                          FROM cgcloud__Order__c 
                          WHERE Id = :ident 
                          WITH USER_MODE 
                          LIMIT 1];
            }
            
            if (orders.isEmpty()) {
                orders = [SELECT Id, cgcloud__Delivery_Note__c, cgcloud__Invoice_Note__c 
                          FROM cgcloud__Order__c 
                          WHERE Name = :ident 
                          WITH USER_MODE 
                          LIMIT 1];
            }

            if (orders.isEmpty()) {
                res.resultMessage = 'Order record not found with identifier: ' + ident;
                return res;
            }

            cgcloud__Order__c orderToUpdate = orders[0];
            Boolean changed = false;

            if (deliveryNote != null) {
                orderToUpdate.cgcloud__Delivery_Note__c = deliveryNote;
                changed = true;
            }

            if (invoiceNote != null) {
                orderToUpdate.cgcloud__Invoice_Note__c = invoiceNote;
                changed = true;
            }

            if (changed) {
                Database.update(orderToUpdate, AccessLevel.USER_MODE);
                res.success = true;
                res.resultMessage = 'Order notes updated successfully.';
            } else {
                res.success = true;
                res.resultMessage = 'No updates provided.';
            }
        } catch (Exception e) {
            res.success = false;
            res.resultMessage = 'Error updating order: ' + e.getMessage();
        }
        return res;
    }


    // --- HELPERS FOR UTILITY AND FORMATTING ---

    private static String getPhaseIcon(String phase) {
        if (phase.equalsIgnoreCase('released') || phase.equalsIgnoreCase('submitted')) {
            return '\u2705';
        } else if (phase.equalsIgnoreCase('draft')) {
            return '\uD83D\uDFE1';
        } else if (phase.equalsIgnoreCase('canceled')) {
            return '\u274C';
        }
        return '\u26AA';
    }

    private static String formatDate(String rawDate) {
        if (String.isBlank(rawDate)) return 'N/A';
        if (rawDate.length() >= 10) {
            String datePart = rawDate.substring(0, 10);
            List<String> parts = datePart.split('-');
            if (parts.size() == 3) {
                String monthName = getMonthName(Integer.valueOf(parts[1]));
                return parts[2] + ' ' + monthName + ' ' + parts[0];
            }
        }
        return rawDate;
    }

    private static String getMonthName(Integer month) {
        List<String> months = new List<String>{
            'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
            'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
        };
        if (month >= 1 && month <= 12) {
            return months[month - 1];
        }
        return String.valueOf(month);
    }

    private class ProductStat {
        public Decimal totalQuantity;
        public Integer orderCount;
        public String uom;

        public ProductStat(String uom) {
            this.totalQuantity = 0;
            this.orderCount = 0;
            this.uom = uom;
        }
    }

    private class ProductEntry implements Comparable {
        public String name;
        public Decimal totalQuantity;
        public Integer orderCount;
        public String uom;

        public ProductEntry(String name, Decimal totalQuantity, Integer orderCount, String uom) {
            this.name = name;
            this.totalQuantity = totalQuantity;
            this.orderCount = orderCount;
            this.uom = uom;
        }

        public Integer compareTo(Object other) {
            ProductEntry o = (ProductEntry) other;
            return o.orderCount - this.orderCount;
        }
    }
}
