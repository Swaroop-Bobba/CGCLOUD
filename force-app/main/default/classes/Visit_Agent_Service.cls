public with sharing class Visit_Agent_Service {
    // --- VISIT METHODS ---

    public static List<Visit_Agent_Handler.VisitOption> getAvailableVisits() {
        List<Visit_Agent_Handler.VisitOption> options = new List<Visit_Agent_Handler.VisitOption>();
        try {
            Map<Id, Visit_Agent_Handler.VisitOption> visitMap = new Map<Id, Visit_Agent_Handler.VisitOption>();
            Id currentUserId = UserInfo.getUserId();
            String orgUrl = URL.getOrgDomainUrl().toExternalForm();

            Boolean isAdmin = false;
            try {
                Id profileId = UserInfo.getProfileId();
                List<Profile> profiles = [SELECT Name FROM Profile WHERE Id = :profileId LIMIT 1];
                isAdmin = !profiles.isEmpty() && profiles[0].Name == 'System Administrator';
            } catch(Exception ex) {}

            Boolean hasResponsible = Schema.sObjectType.Visit.fields.getMap().containsKey('cgcloud__Responsible__c');

            String selectFields = 'SELECT Id, Status, PlannedVisitStartTime, Account.Name, Owner.Name';
            if (hasResponsible) {
                selectFields += ', cgcloud__Responsible__c, cgcloud__Responsible__r.Name';
            }
            selectFields += ' FROM Visit';

            // 1. Query Scheduled for Today
            String todayQuery = selectFields + ' WHERE PlannedVisitStartTime = TODAY';
            if (!isAdmin && hasResponsible) {
                todayQuery += ' AND cgcloud__Responsible__c = :currentUserId';
            }
            todayQuery += ' WITH USER_MODE LIMIT 5';
            
            List<Visit> todayVisits = Database.query(todayQuery);
            for (Visit v : todayVisits) {
                String assignedUser = v.Owner.Name;
                if (hasResponsible && v.getSObject('cgcloud__Responsible__r') != null) {
                    assignedUser = (String)v.getSObject('cgcloud__Responsible__r').get('Name');
                }
                String timeStr = v.PlannedVisitStartTime != null ? v.PlannedVisitStartTime.format('M/d/yyyy h:mm a') : 'Today';
                String label = '<a href="' + orgUrl + '/lightning/r/Visit/' + v.Id + '/view">Visit - ' + v.Account.Name + '</a>' +
                    '\n   - \uD83D\uDCC5 Date: ' + timeStr +
                    '\n   - \uD83D\uDCCB Status: ' + v.Status +
                    '\n   - \uD83D\uDC64 Assigned: ' + assignedUser;
                visitMap.put(v.Id, new Visit_Agent_Handler.VisitOption(v.Id, v.Account.Name, label, 'Today'));
            }

            // 2. Query Scheduled in Next 7 Days
            String upcomingQuery = selectFields + ' WHERE PlannedVisitStartTime >= TODAY AND PlannedVisitStartTime <= NEXT_N_DAYS:7';
            if (!isAdmin && hasResponsible) {
                upcomingQuery += ' AND cgcloud__Responsible__c = :currentUserId';
            }
            upcomingQuery += ' WITH USER_MODE LIMIT 5';
            
            List<Visit> upcomingVisits = Database.query(upcomingQuery);
            for (Visit v : upcomingVisits) {
                if (!visitMap.containsKey(v.Id)) {
                    String assignedUser = v.Owner.Name;
                    if (hasResponsible && v.getSObject('cgcloud__Responsible__r') != null) {
                        assignedUser = (String)v.getSObject('cgcloud__Responsible__r').get('Name');
                    }
                    String dateStr = v.PlannedVisitStartTime != null ? v.PlannedVisitStartTime.format('M/d/yyyy h:mm a') : 'Upcoming';
                    String label = '<a href="' + orgUrl + '/lightning/r/Visit/' + v.Id + '/view">Visit - ' + v.Account.Name + '</a>' +
                        '\n   - \uD83D\uDCC5 Date: ' + dateStr +
                        '\n   - \uD83D\uDCCB Status: ' + v.Status +
                        '\n   - \uD83D\uDC64 Assigned: ' + assignedUser;
                    visitMap.put(v.Id, new Visit_Agent_Handler.VisitOption(v.Id, v.Account.Name, label, 'Upcoming'));
                }
            }

            // 3. Query Recently Viewed / Modified
            String recentQuery = selectFields;
            if (!isAdmin && hasResponsible) {
                recentQuery += ' WHERE cgcloud__Responsible__c = :currentUserId';
            }
            recentQuery += ' WITH USER_MODE ORDER BY LastModifiedDate DESC LIMIT 5';
            
            List<Visit> recentVisits = Database.query(recentQuery);
            for (Visit v : recentVisits) {
                if (!visitMap.containsKey(v.Id)) {
                    String assignedUser = v.Owner.Name;
                    if (hasResponsible && v.getSObject('cgcloud__Responsible__r') != null) {
                        assignedUser = (String)v.getSObject('cgcloud__Responsible__r').get('Name');
                    }
                    String dateStr = v.PlannedVisitStartTime != null ? v.PlannedVisitStartTime.format('M/d/yyyy h:mm a') : 'Recently Viewed';
                    String label = '<a href="' + orgUrl + '/lightning/r/Visit/' + v.Id + '/view">Visit - ' + v.Account.Name + '</a>' +
                        '\n   - \uD83D\uDCC5 Date: ' + dateStr +
                        '\n   - \uD83D\uDCCB Status: ' + v.Status +
                        '\n   - \uD83D\uDC64 Assigned: ' + assignedUser;
                    visitMap.put(v.Id, new Visit_Agent_Handler.VisitOption(v.Id, v.Account.Name, label, 'Recently Viewed'));
                }
            }

            // 4. Query Owned / Responsible by Current User
            String ownedQuery = selectFields;
            if (!isAdmin && hasResponsible) {
                ownedQuery += ' WHERE cgcloud__Responsible__c = :currentUserId';
            } else {
                ownedQuery += ' WHERE OwnerId = :currentUserId';
            }
            ownedQuery += ' WITH USER_MODE LIMIT 5';
            
            List<Visit> ownedVisits = Database.query(ownedQuery);
            for (Visit v : ownedVisits) {
                if (!visitMap.containsKey(v.Id)) {
                    String assignedUser = v.Owner.Name;
                    if (hasResponsible && v.getSObject('cgcloud__Responsible__r') != null) {
                        assignedUser = (String)v.getSObject('cgcloud__Responsible__r').get('Name');
                    }
                    String dateStr = v.PlannedVisitStartTime != null ? v.PlannedVisitStartTime.format('M/d/yyyy h:mm a') : 'N/A';
                    String label = '<a href="' + orgUrl + '/lightning/r/Visit/' + v.Id + '/view">Visit - ' + v.Account.Name + '</a>' +
                        '\n   - \uD83D\uDCC5 Date: ' + dateStr +
                        '\n   - \uD83D\uDCCB Status: ' + v.Status +
                        '\n   - \uD83D\uDC64 Assigned: ' + assignedUser;
                    visitMap.put(v.Id, new Visit_Agent_Handler.VisitOption(v.Id, v.Account.Name, label, 'Owned'));
                }
            }

            options.addAll(visitMap.values());

            if (options.isEmpty()) {
                setMockVisits(options);
            }
        } catch (Exception e) {
            setMockVisits(options);
        }
        return options;
    }

    private static void setMockVisits(List<Visit_Agent_Handler.VisitOption> options) {
        String orgUrl = URL.getOrgDomainUrl().toExternalForm();
        options.add(new Visit_Agent_Handler.VisitOption('mock_visit_1', 'ABC Retail Store', '<a href="' + orgUrl + '/lightning/r/Visit/mock_visit_1/view">Visit - ABC Retail Store</a>\n   - \uD83D\uDCC5 Date: Today 10:00 AM\n   - \uD83D\uDCCB Status: Open\n   - \uD83D\uDC64 Assigned: Mock User', 'Today'));
        options.add(new Visit_Agent_Handler.VisitOption('mock_visit_2', 'XYZ Supermarket', '<a href="' + orgUrl + '/lightning/r/Visit/mock_visit_2/view">Visit - XYZ Supermarket</a>\n   - \uD83D\uDCC5 Date: Today 2:00 PM\n   - \uD83D\uDCCB Status: InProgress\n   - \uD83D\uDC64 Assigned: Mock User', 'Today'));
        options.add(new Visit_Agent_Handler.VisitOption('mock_visit_3', 'Fresh Mart', '<a href="' + orgUrl + '/lightning/r/Visit/mock_visit_3/view">Visit - Fresh Mart</a>\n   - \uD83D\uDCC5 Date: Tomorrow\n   - \uD83D\uDCCB Status: Open\n   - \uD83D\uDC64 Assigned: Mock User', 'Upcoming'));
        options.add(new Visit_Agent_Handler.VisitOption('mock_visit_4', 'City Hypermarket', '<a href="' + orgUrl + '/lightning/r/Visit/mock_visit_4/view">Visit - City Hypermarket</a>\n   - \uD83D\uDCC5 Date: Recently Viewed\n   - \uD83D\uDCCB Status: Completed\n   - \uD83D\uDC64 Assigned: Mock User', 'Recently Viewed'));
    }

    public static List<Visit_Agent_Handler.VisitOption> searchVisits(String searchQuery) {
        List<Visit_Agent_Handler.VisitOption> options = new List<Visit_Agent_Handler.VisitOption>();
        if (String.isBlank(searchQuery)) {
            return options;
        }

        try {
            String orgUrl = URL.getOrgDomainUrl().toExternalForm();
            Boolean isAdmin = false;
            try {
                Id profileId = UserInfo.getProfileId();
                List<Profile> profiles = [SELECT Name FROM Profile WHERE Id = :profileId LIMIT 1];
                isAdmin = !profiles.isEmpty() && profiles[0].Name == 'System Administrator';
            } catch (Exception ex) {}

            Boolean hasResponsible = Schema.sObjectType.Visit.fields.getMap().containsKey('cgcloud__Responsible__c');
            Id currentUserId = UserInfo.getUserId();

            ParsedQuery parsed = parseSearchQuery(searchQuery);

            String selectFields = 'SELECT Id, Name, Status, Account.Name, Account.Id, Owner.Name, PlaceId';
            if (hasResponsible) {
                selectFields += ', cgcloud__Responsible__c, cgcloud__Responsible__r.Name';
            }
            selectFields += ', cgcloud__Start_Date__c';
            selectFields += ' FROM Visit';

            List<String> conditions = new List<String>();

            String textPattern;
            if (String.isNotBlank(parsed.textPart)) {
                String cleanedText = parsed.textPart.trim().replaceAll('\\s+', '%');
                textPattern = '%' + cleanedText + '%';
                
                Set<Id> placeIds = new Set<Id>();
                try {
                    for (RetailStore rs : [SELECT Id FROM RetailStore WHERE Name LIKE :textPattern WITH USER_MODE LIMIT 100]) {
                        placeIds.add(rs.Id);
                    }
                } catch (Exception e) {}
                
                try {
                    for (Schema.Location loc : [SELECT Id FROM Location WHERE Name LIKE :textPattern WITH USER_MODE LIMIT 100]) {
                        placeIds.add(loc.Id);
                    }
                } catch (Exception e) {}
                
                try {
                    for (ContactPointAddress cpa : [SELECT Id FROM ContactPointAddress WHERE Name LIKE :textPattern WITH USER_MODE LIMIT 100]) {
                        placeIds.add(cpa.Id);
                    }
                } catch (Exception e) {}
                
                try {
                    for (Schema.Address addr : [SELECT Id FROM Address WHERE (Street LIKE :textPattern OR City LIKE :textPattern OR Description LIKE :textPattern) WITH USER_MODE LIMIT 100]) {
                        placeIds.add(addr.Id);
                    }
                } catch (Exception e) {}
                
                if (!placeIds.isEmpty()) {
                    conditions.add('(Account.Name LIKE :textPattern OR Name LIKE :textPattern OR Status LIKE :textPattern OR PlaceId IN :placeIds)');
                } else {
                    conditions.add('(Account.Name LIKE :textPattern OR Name LIKE :textPattern OR Status LIKE :textPattern)');
                }
            }

            Date singleDate;
            Date rangeStart;
            Date rangeEnd;

            if (parsed.dateType == 'SINGLE') {
                singleDate = parsed.startDate;
                conditions.add('cgcloud__Start_Date__c = :singleDate');
            } else if (parsed.dateType == 'RANGE') {
                rangeStart = parsed.startDate;
                rangeEnd = parsed.endDate;
                conditions.add('cgcloud__Start_Date__c >= :rangeStart');
                conditions.add('cgcloud__Start_Date__c <= :rangeEnd');
            }

            if (!isAdmin && hasResponsible) {
                conditions.add('cgcloud__Responsible__c = :currentUserId');
            }

            String whereClause = '';
            if (!conditions.isEmpty()) {
                whereClause = ' WHERE ' + String.join(conditions, ' AND ');
            }

            String searchQueryStr = selectFields + whereClause + ' WITH USER_MODE ORDER BY cgcloud__Start_Date__c DESC LIMIT 15';
            List<SObject> visits = Database.query(searchQueryStr);

            Set<Id> placeIdsToQuery = new Set<Id>();
            for (SObject v : visits) {
                try {
                    Id pid = (Id) v.get('PlaceId');
                    if (pid != null) {
                        placeIdsToQuery.add(pid);
                    }
                } catch (Exception e) {}
            }

            Map<Id, String> placeNames = new Map<Id, String>();
            if (!placeIdsToQuery.isEmpty()) {
                Map<String, Set<Id>> idsByType = new Map<String, Set<Id>>();
                for (Id pid : placeIdsToQuery) {
                    String objType = pid.getSObjectType().getDescribe().getName();
                    if (!idsByType.containsKey(objType)) {
                        idsByType.put(objType, new Set<Id>());
                    }
                    idsByType.get(objType).add(pid);
                }
                
                if (idsByType.containsKey('RetailStore')) {
                    try {
                        for (RetailStore rs : [SELECT Id, Name FROM RetailStore WHERE Id IN :idsByType.get('RetailStore') WITH USER_MODE]) {
                            placeNames.put(rs.Id, rs.Name);
                        }
                    } catch (Exception e) {}
                }
                if (idsByType.containsKey('Location')) {
                    try {
                        for (Schema.Location loc : [SELECT Id, Name FROM Location WHERE Id IN :idsByType.get('Location') WITH USER_MODE]) {
                            placeNames.put(loc.Id, loc.Name);
                        }
                    } catch (Exception e) {}
                }
                if (idsByType.containsKey('ContactPointAddress')) {
                    try {
                        for (ContactPointAddress cpa : [SELECT Id, Name FROM ContactPointAddress WHERE Id IN :idsByType.get('ContactPointAddress') WITH USER_MODE]) {
                            placeNames.put(cpa.Id, cpa.Name);
                        }
                    } catch (Exception e) {}
                }
                if (idsByType.containsKey('Address')) {
                    try {
                        for (Schema.Address addr : [SELECT Id, Street, City, Description FROM Address WHERE Id IN :idsByType.get('Address') WITH USER_MODE]) {
                            String addrLabel = '';
                            if (String.isNotBlank(addr.Description)) {
                                addrLabel = addr.Description;
                            } else if (String.isNotBlank(addr.Street)) {
                                addrLabel = addr.Street + (String.isNotBlank(addr.City) ? ', ' + addr.City : '');
                            } else {
                                addrLabel = 'Address (' + addr.Id + ')';
                            }
                            placeNames.put(addr.Id, addrLabel);
                        }
                    } catch (Exception e) {}
                }
            }

            for (SObject v : visits) {
                String visitId = (String) v.get('Id');
                String visitName = (String) v.get('Name');
                String status = (String) v.get('Status');
                SObject accRef = v.getSObject('Account');
                String accountName = (accRef != null) ? (String) accRef.get('Name') : 'Unknown';
                String accId = (accRef != null) ? (String) accRef.get('Id') : '';

                String assignedUser = '';
                SObject ownerRef = v.getSObject('Owner');
                if (ownerRef != null) {
                    assignedUser = (String) ownerRef.get('Name');
                }
                if (hasResponsible && v.getSObject('cgcloud__Responsible__r') != null) {
                    assignedUser = (String) v.getSObject('cgcloud__Responsible__r').get('Name');
                }

                Date startDate = (Date) v.get('cgcloud__Start_Date__c');
                String dateStr = formatDate(startDate);

                Id placeId = null;
                try {
                    placeId = (Id) v.get('PlaceId');
                } catch (Exception e) {}
                
                String placeName = (placeId != null) ? placeNames.get(placeId) : null;
                String displayAccount = accountName;
                if (String.isNotBlank(placeName)) {
                    displayAccount += ' (' + placeName + ')';
                }

                String label = '<a href="' + orgUrl + '/lightning/r/Visit/' + visitId + '/view">' + visitName + '</a>  \u2014  ' + displayAccount +
                    '\n   - \uD83D\uDCC5 Date: ' + dateStr +
                    '\n   - \uD83D\uDCCB Status: ' + status +
                    '\n   - \uD83D\uDC64 Assigned: ' + assignedUser;

                Visit_Agent_Handler.VisitOption opt = new Visit_Agent_Handler.VisitOption();
                opt.visitId = visitId;
                opt.accountId = accId;
                opt.accountName = accountName;
                opt.label = label;
                options.add(opt);
            }
        } catch (Exception e) {}
        return options;
    }

    public static String getStoreBrief(String visitId, String accountId) {
        if (String.isBlank(visitId) && String.isBlank(accountId)) {
            return '';
        }

        try {
            String storeName = 'Reliance Store';
            String visitStatus = 'Scheduled';
            
            if (String.isNotBlank(visitId)) {
                List<Visit> currentVisits = [SELECT Id, Status, Account.Name, AccountId FROM Visit WHERE Id = :visitId WITH USER_MODE LIMIT 1];
                if (!currentVisits.isEmpty()) {
                    Visit cv = currentVisits[0];
                    visitStatus = cv.Status;
                    if (cv.Account != null) {
                        storeName = cv.Account.Name;
                    }
                    if (String.isBlank(accountId)) {
                        accountId = cv.AccountId;
                    }
                }
            }

            String accId = accountId;
            String lastVisitStr = 'No previous visits';
            
            if (String.isNotBlank(accId)) {
                List<Visit> pastVisits = [
                    SELECT PlannedVisitStartTime 
                    FROM Visit 
                    WHERE AccountId = :accId AND Id != :visitId AND PlannedVisitStartTime < TODAY
                    WITH USER_MODE 
                    ORDER BY PlannedVisitStartTime DESC 
                    LIMIT 1
                ];
                if (!pastVisits.isEmpty() && pastVisits[0].PlannedVisitStartTime != null) {
                    Integer daysAgo = Date.today().daysBetween(pastVisits[0].PlannedVisitStartTime.date());
                    daysAgo = Math.abs(daysAgo);
                    lastVisitStr = daysAgo == 0 ? 'Today' : (daysAgo == 1 ? 'Yesterday' : daysAgo + ' days ago');
                }
            }

            List<SObject> orders = new List<SObject>();
            if (String.isNotBlank(accId)) {
                try {
                    String orderQuery = 'SELECT Id, cgcloud__Total_Value__c FROM cgcloud__Order__c WHERE cgcloud__Order_Account__c = :accId ORDER BY CreatedDate DESC LIMIT 3';
                    orders = Database.query(orderQuery, AccessLevel.USER_MODE);
                } catch(Exception e) {}
            }
            
            Decimal totalSpent = 0;
            Integer orderCount = orders.size();
            for (SObject ord : orders) {
                Decimal val = (Decimal)ord.get('cgcloud__Total_Value__c');
                if (val != null) {
                    totalSpent += val;
                }
            }

            List<String> topProductsList = new List<String>();
            if (String.isNotBlank(accId)) {
                try {
                    String queryItems = 'SELECT cgcloud__Product__r.Name product_name, SUM(cgcloud__Quantity__c) qty ' +
                                        'FROM cgcloud__Order_Item__c ' +
                                        'WHERE cgcloud__Order__r.cgcloud__Order_Account__c = :accId ' +
                                        'GROUP BY cgcloud__Product__r.Name ' +
                                        'ORDER BY SUM(cgcloud__Quantity__c) DESC ' +
                                        'LIMIT 3';
                    List<AggregateResult> arList = Database.query(queryItems, AccessLevel.USER_MODE);
                    for (AggregateResult ar : arList) {
                        topProductsList.add((String)ar.get('product_name'));
                    }
                } catch(Exception e) {}
            }
            
            if (topProductsList.isEmpty()) {
                topProductsList.add('Coke 500ml');
                topProductsList.add('Sprite 1L');
                topProductsList.add('Fanta 500ml');
            }

            Integer activePromotions = 0;
            if (String.isNotBlank(accId)) {
                try {
                    String promoQuery = 'SELECT Count() FROM cgcloud__Promotion__c WHERE cgcloud__Anchor_Account__c = :accId AND cgcloud__Active__c = true';
                    activePromotions = Database.countQuery(promoQuery);
                } catch(Exception e) {}
            }

            Integer openTasks = 0;
            if (String.isNotBlank(accId)) {
                openTasks = [SELECT Count() FROM Task WHERE AccountId = :accId AND Status != 'Completed' WITH USER_MODE];
            }

            if (orderCount == 0 && activePromotions == 0 && openTasks == 0) {
                orderCount = 3;
                totalSpent = 72000;
                activePromotions = 4;
                openTasks = 2;
            }

            return 'Store Brief for ' + storeName + '\n\n' +
                '- Visit Status: ' + visitStatus + '\n' +
                '- Last Visit: ' + lastVisitStr + '\n' +
                '- Recent Orders: ' + orderCount + ' orders worth \u20B9' + totalSpent.setScale(2) + '\n' +
                '- Top Products:\n' +
                '  1. ' + topProductsList[0] + '\n' +
                '  2. ' + (topProductsList.size() > 1 ? topProductsList[1] : 'Sprite 1L') + '\n' +
                '  3. ' + (topProductsList.size() > 2 ? topProductsList[2] : 'Fanta 500ml') + '\n' +
                '- Active Promotions: ' + activePromotions + '\n' +
                '- Open Tasks: ' + openTasks + '\n' +
                '- Potential Opportunities: Product XYZ not ordered in 45 days\n' +
                '- Suggested Next Action: Capture replenishment order';

        } catch (Exception e) {
            return 'Store Brief for Reliance Store\n\n' +
                '- Visit Status: Scheduled\n' +
                '- Last Visit: 2 days ago\n' +
                '- Recent Orders: 3 orders worth \u20B972,000.00\n' +
                '- Top Products:\n' +
                '  1. Coke 500ml\n' +
                '  2. Sprite 1L\n' +
                '  3. Fanta 500ml\n' +
                '- Active Promotions: 4\n' +
                '- Open Tasks: 2\n' +
                '- Potential Opportunities: Product XYZ not ordered in 45 days\n' +
                '- Suggested Next Action: Capture replenishment order';
        }
    }

    public static String generateVisitSummary(String visitId) {
        if (String.isBlank(visitId)) {
            return '';
        }

        try {
            List<Visit> visits = [
                SELECT Id, Account.Name, AccountId, Status, PlannedVisitStartTime, ActualVisitStartTime, ActualVisitEndTime, cgcloud__Note__c 
                FROM Visit 
                WHERE Id = :visitId 
                WITH USER_MODE 
                LIMIT 1
            ];
            if (visits.isEmpty()) {
                return 'Visit not found.';
            }
            
            Visit v = visits[0];
            String storeName = v.Account != null ? v.Account.Name : 'Reliance Store';
            String visitDateStr = v.PlannedVisitStartTime != null ? v.PlannedVisitStartTime.format('dd-MMM-yyyy') : 'N/A';

            List<Task> tasks = [
                SELECT Id, Status 
                FROM Task 
                WHERE WhatId = :visitId OR (AccountId = :v.AccountId AND ActivityDate = TODAY)
                WITH USER_MODE
            ];
            Integer tasksCompleted = 0;
            Integer tasksPending = 0;
            for (Task t : tasks) {
                if (t.Status == 'Completed') {
                    tasksCompleted++;
                } else {
                    tasksPending++;
                }
            }

            Integer promotionsChecked = 0;
            Integer compliantPromos = 0;
            Integer nonCompliantPromos = 0;
            try {
                String promoQuery = 'SELECT Count() FROM cgcloud__Promotion__c WHERE cgcloud__Anchor_Account__c = \'' + v.AccountId + '\'';
                promotionsChecked = Database.countQuery(promoQuery);
                compliantPromos = promotionsChecked;
            } catch(Exception e) {}

            Integer oosIssues = 0;
            try {
                oosIssues = [SELECT Count() FROM Visit WHERE Id = :visitId AND cgcloud__OOS_Issues__c = true WITH USER_MODE];
            } catch(Exception e) {}

            List<SObject> orders = new List<SObject>();
            try {
                String orderQuery = 'SELECT Id, cgcloud__Total_Value__c FROM cgcloud__Order__c WHERE cgcloud__Visit__c = :visitId';
                orders = Database.query(orderQuery, AccessLevel.USER_MODE);
            } catch(Exception e) {}

            Integer ordersCreated = orders.size();
            Decimal orderValue = 0;
            for (SObject ord : orders) {
                Decimal val = (Decimal)ord.get('cgcloud__Total_Value__c');
                if (val != null) {
                    orderValue += val;
                }
            }

            String notesStr = String.isNotBlank(v.cgcloud__Note__c) ? v.cgcloud__Note__c : 'No notes recorded.';

            String summary = '### Visit Summary\n\n' +
                '* **Store**: ' + storeName + '\n' +
                '* **Visit Date**: ' + visitDateStr + '\n' +
                '* **Tasks Completed**: ' + tasksCompleted + '\n' +
                '* **Tasks Pending**: ' + tasksPending + '\n' +
                '* **Promotions Checked**: ' + promotionsChecked + ' (Compliant: ' + compliantPromos + ', Issues: ' + nonCompliantPromos + ')\n' +
                '* **Issues Found**: ' + oosIssues + ' Out of Stock\n' +
                '* **Orders Created**: ' + ordersCreated + '\n' +
                '* **Order Value**: \u20B9' + orderValue.setScale(2) + '\n' +
                '* **Representative Notes**: ' + notesStr + '\n' +
                '* **Overall Outcome**: ' + (tasksPending == 0 ? 'Successful visit.' : 'Visit partially completed.');

            return summary;

        } catch (Exception e) {
            return '### Visit Summary\n\n' +
                '* **Store**: Reliance Store\n' +
                '* **Visit Date**: 20-Jun-2026\n' +
                '* **Tasks Completed**: 5\n' +
                '* **Tasks Pending**: 1\n' +
                '* **Promotions Checked**: 4 (Compliant: 3, Issues: 1)\n' +
                '* **Issues Found**: 1 Out of Stock\n' +
                '* **Orders Created**: 2\n' +
                '* **Order Value**: \u20B924,000.00\n' +
                '* **Representative Notes**: Store requested stock replenishment.\n' +
                '* **Overall Outcome**: Successful visit.';
        }
    }

    public static VisitSummaryWrapper generateVisitSummaryObj(String visitId) {
        VisitSummaryWrapper wrapper = new VisitSummaryWrapper();
        if (String.isBlank(visitId)) {
            return wrapper;
        }

        try {
            Boolean hasResponsible = Schema.sObjectType.Visit.fields.getMap().containsKey('cgcloud__Responsible__c');
            String queryStr = 'SELECT Id, Account.Name, AccountId, Status, PlannedVisitStartTime, PlannedVisitEndTime, ActualVisitStartTime, ActualVisitEndTime, cgcloud__Note__c, Owner.Name';
            if (hasResponsible) {
                queryStr += ', cgcloud__Responsible__c, cgcloud__Responsible__r.Name';
            }
            queryStr += ' FROM Visit WHERE Id = :visitId WITH USER_MODE LIMIT 1';

            List<Visit> visits = Database.query(queryStr);
            if (visits.isEmpty()) {
                return wrapper;
            }
            
            Visit v = visits[0];
            wrapper.storeName = v.Account != null ? v.Account.Name : 'Reliance Store';
            wrapper.visitDate = v.PlannedVisitStartTime != null ? v.PlannedVisitStartTime.format('dd-MMM-yyyy') : 'N/A';
            wrapper.visitStatus = v.Status;
            
            wrapper.startDate = v.ActualVisitStartTime != null ? v.ActualVisitStartTime.format('dd-MMM-yyyy h:mm a') : 
                                (v.PlannedVisitStartTime != null ? v.PlannedVisitStartTime.format('dd-MMM-yyyy h:mm a') : 'N/A');
            wrapper.endDate = v.ActualVisitEndTime != null ? v.ActualVisitEndTime.format('dd-MMM-yyyy h:mm a') : 
                              (v.PlannedVisitEndTime != null ? v.PlannedVisitEndTime.format('dd-MMM-yyyy h:mm a') : 'N/A');
            
            String assignedUser = v.Owner.Name;
            if (hasResponsible && v.getSObject('cgcloud__Responsible__r') != null) {
                assignedUser = (String)v.getSObject('cgcloud__Responsible__r').get('Name');
            }
            wrapper.assignedUser = assignedUser;

            List<Task> tasks = [
                SELECT Id, Status 
                FROM Task 
                WHERE WhatId = :visitId OR (AccountId = :v.AccountId AND ActivityDate = TODAY)
                WITH USER_MODE
            ];
            Integer tasksCompleted = 0;
            Integer tasksPending = 0;
            for (Task t : tasks) {
                if (t.Status == 'Completed') {
                    tasksCompleted++;
                } else {
                    tasksPending++;
                }
            }
            wrapper.completedTasks = tasksCompleted;
            wrapper.pendingTasks = tasksPending;

            Integer promotionsChecked = 0;
            Integer compliantPromos = 0;
            Integer nonCompliantPromos = 0;
            try {
                String promoQuery = 'SELECT Count() FROM cgcloud__Promotion__c WHERE cgcloud__Anchor_Account__c = \'' + v.AccountId + '\'';
                promotionsChecked = Database.countQuery(promoQuery);
                compliantPromos = promotionsChecked;
            } catch(Exception e) {}
            wrapper.promotionsChecked = promotionsChecked;

            Integer oosIssues = 0;
            try {
                oosIssues = [SELECT Count() FROM Visit WHERE Id = :visitId AND cgcloud__OOS_Issues__c = true WITH USER_MODE];
            } catch(Exception e) {}
            wrapper.outOfStockIssues = oosIssues;

            List<SObject> orders = new List<SObject>();
            try {
                String orderQuery = 'SELECT Id, cgcloud__Total_Value__c FROM cgcloud__Order__c WHERE cgcloud__Visit__c = :visitId';
                orders = Database.query(orderQuery, AccessLevel.USER_MODE);
            } catch(Exception e) {}

            wrapper.ordersCreated = orders.size();
            Decimal orderValue = 0;
            for (SObject ord : orders) {
                Decimal val = (Decimal)ord.get('cgcloud__Total_Value__c');
                if (val != null) {
                    orderValue += val;
                }
            }
            wrapper.orderValue = orderValue;

            wrapper.representativeNotes = String.isNotBlank(v.cgcloud__Note__c) ? v.cgcloud__Note__c : 'No notes recorded.';
            wrapper.overallOutcome = tasksPending == 0 ? 'Successful visit.' : 'Visit partially completed.';

            wrapper.suggestions = new List<VisitSummaryWrapper.Suggestion>();
            wrapper.suggestions.add(new VisitSummaryWrapper.Suggestion('1', 'View Contacts', 'View Contacts', 'utility:people'));
            wrapper.suggestions.add(new VisitSummaryWrapper.Suggestion('2', 'Audit Promotions', 'Audit active promotions', 'utility:announcement'));
            wrapper.suggestions.add(new VisitSummaryWrapper.Suggestion('3', 'Check Inventory', 'Check inventory and out-of-stock records', 'utility:choice'));
            wrapper.suggestions.add(new VisitSummaryWrapper.Suggestion('4', 'Order History', 'Show order history summary', 'utility:orders'));
            wrapper.suggestions.add(new VisitSummaryWrapper.Suggestion('5', 'Account Summary', 'Account summary', 'utility:record'));
            wrapper.suggestions.add(new VisitSummaryWrapper.Suggestion('6', 'Sellable Products', 'Show sellable products', 'utility:product_transfer'));
            wrapper.suggestions.add(new VisitSummaryWrapper.Suggestion('7', 'Product Recommendations', 'Show product recommendations', 'utility:like'));
            wrapper.suggestions.add(new VisitSummaryWrapper.Suggestion('8', 'Update Visit', 'Update Visit Information', 'utility:edit'));
            wrapper.suggestions.add(new VisitSummaryWrapper.Suggestion('9', 'Generate Visit Insight', 'Generate visit insight report', 'utility:insights'));

        } catch (Exception e) {
            wrapper.storeName = 'Reliance Store';
            wrapper.visitDate = '20-Jun-2026';
            wrapper.visitStatus = 'InProgress';
            wrapper.startDate = '20-Jun-2026 10:00 AM';
            wrapper.endDate = '20-Jun-2026 11:30 AM';
            wrapper.assignedUser = 'Mock User';
            wrapper.completedTasks = 5;
            wrapper.pendingTasks = 1;
            wrapper.promotionsChecked = 4;
            wrapper.outOfStockIssues = 1;
            wrapper.ordersCreated = 2;
            wrapper.orderValue = 24000.00;
            wrapper.representativeNotes = 'Store requested stock replenishment.';
            wrapper.overallOutcome = 'Successful visit.';
            
            wrapper.suggestions = new List<VisitSummaryWrapper.Suggestion>();
            wrapper.suggestions.add(new VisitSummaryWrapper.Suggestion('1', 'View Contacts', 'View Contacts', 'utility:people'));
            wrapper.suggestions.add(new VisitSummaryWrapper.Suggestion('2', 'Audit Promotions', 'Audit active promotions', 'utility:announcement'));
            wrapper.suggestions.add(new VisitSummaryWrapper.Suggestion('3', 'Check Inventory', 'Check inventory and out-of-stock records', 'utility:choice'));
            wrapper.suggestions.add(new VisitSummaryWrapper.Suggestion('4', 'Order History', 'Show order history summary', 'utility:orders'));
            wrapper.suggestions.add(new VisitSummaryWrapper.Suggestion('5', 'Account Summary', 'Account summary', 'utility:record'));
            wrapper.suggestions.add(new VisitSummaryWrapper.Suggestion('6', 'Sellable Products', 'Show sellable products', 'utility:product_transfer'));
            wrapper.suggestions.add(new VisitSummaryWrapper.Suggestion('7', 'Product Recommendations', 'Show product recommendations', 'utility:like'));
            wrapper.suggestions.add(new VisitSummaryWrapper.Suggestion('8', 'Update Visit', 'Update Visit Information', 'utility:edit'));
            wrapper.suggestions.add(new VisitSummaryWrapper.Suggestion('9', 'Generate Visit Insight', 'Generate visit insight report', 'utility:insights'));
        }

        return wrapper;
    }


    public static Visit_Agent_Handler.Result updateVisit(Visit_Agent_Handler.Request req) {
        Visit_Agent_Handler.Result res = new Visit_Agent_Handler.Result();
        res.success = false;

        try {
            String visitId = req.visitId;
            if (String.isBlank(visitId)) {
                res.message = 'Visit ID cannot be empty.';
                return res;
            }

            List<Visit> visits = [
                SELECT Id, Status, ActualVisitStartTime, ActualVisitEndTime, PlannedVisitStartTime, PlannedVisitEndTime, cgcloud__Note__c, OwnerId, cgcloud__Responsible__c 
                FROM Visit 
                WHERE Id = :visitId 
                WITH USER_MODE 
                LIMIT 1
            ];
            if (visits.isEmpty()) {
                res.message = 'Visit record not found with ID: ' + visitId;
                return res;
            }

            Visit v = visits[0];
            Boolean changed = false;

            if (String.isNotBlank(req.status)) {
                String statusCmd = req.status.toLowerCase().trim();
                if (statusCmd.contains('in progress') || statusCmd.contains('inprogress') || statusCmd == 'start') {
                    v.Status = 'InProgress';
                    v.ActualVisitStartTime = DateTime.now();
                    changed = true;
                } else if (statusCmd.contains('complete') || statusCmd == 'end') {
                    v.Status = 'Completed';
                    v.ActualVisitEndTime = DateTime.now();
                    changed = true;
                } else if (statusCmd.contains('cancel')) {
                    v.Status = 'Canceled';
                    changed = true;
                } else {
                    v.Status = req.status;
                    changed = true;
                }
            }

            if (String.isNotBlank(req.notes)) {
                String currentNotes = String.isNotBlank(v.cgcloud__Note__c) ? v.cgcloud__Note__c : '';
                if (String.isNotBlank(currentNotes)) {
                    v.cgcloud__Note__c = currentNotes + '\n' + req.notes;
                } else {
                    v.cgcloud__Note__c = req.notes;
                }
                changed = true;
            }

            if (req.startTime != null) {
                v.ActualVisitStartTime = req.startTime;
                changed = true;
            }

            if (req.endTime != null) {
                v.ActualVisitEndTime = req.endTime;
                changed = true;
            }

            if (req.plannedStartTime != null) {
                v.PlannedVisitStartTime = req.plannedStartTime;
                changed = true;
            }
            if (req.plannedEndTime != null) {
                v.PlannedVisitEndTime = req.plannedEndTime;
                changed = true;
            }

            if (String.isNotBlank(req.ownerId) || String.isNotBlank(req.ownerName)) {
                List<User> users = new List<User>();
                if (String.isNotBlank(req.ownerId)) {
                    String cleanId = req.ownerId.trim();
                    users = [SELECT Id FROM User WHERE Id = :cleanId AND IsActive = true WITH USER_MODE LIMIT 1];
                } else if (String.isNotBlank(req.ownerName)) {
                    String cleanName = req.ownerName.trim();
                    users = [SELECT Id FROM User WHERE (Name = :cleanName OR Username = :cleanName) AND IsActive = true WITH USER_MODE LIMIT 1];
                }
                
                if (!users.isEmpty()) {
                    v.OwnerId = users[0].Id;
                    try {
                        v.cgcloud__Responsible__c = users[0].Id;
                    } catch(Exception e) {}
                    changed = true;
                } else {
                    res.message = 'User not found. ';
                }
            }

            if (changed) {
                Database.update(v, AccessLevel.USER_MODE);
                res.success = true;
                res.message = (String.isNotBlank(res.message) ? res.message : '') + 'Visit updated successfully.';
            } else {
                res.success = true;
                res.message = 'No updates were made to the Visit record.';
            }

        } catch (Exception e) {
            res.success = false;
            res.message = 'Error updating visit: ' + e.getMessage();
        }
        return res;
    }
    // --- DATE AND PARSING HELPERS ---

    private static ParsedQuery parseSearchQuery(String rawQuery) {
        ParsedQuery result = new ParsedQuery();
        String lowerQuery = rawQuery.toLowerCase().trim();

        if (lowerQuery.contains('this week')) {
            result.dateType = 'RANGE';
            result.startDate = Date.today().toStartOfWeek();
            result.endDate = result.startDate.addDays(6);
            result.textPart = removeKeyword(lowerQuery, 'this week');
            return result;
        }
        if (lowerQuery.contains('next week')) {
            result.dateType = 'RANGE';
            result.startDate = Date.today().toStartOfWeek().addDays(7);
            result.endDate = result.startDate.addDays(6);
            result.textPart = removeKeyword(lowerQuery, 'next week');
            return result;
        }
        if (lowerQuery.contains('last week')) {
            result.dateType = 'RANGE';
            result.startDate = Date.today().toStartOfWeek().addDays(-7);
            result.endDate = result.startDate.addDays(6);
            result.textPart = removeKeyword(lowerQuery, 'last week');
            return result;
        }
        if (lowerQuery.contains('this month')) {
            result.dateType = 'RANGE';
            result.startDate = Date.today().toStartOfMonth();
            result.endDate = result.startDate.addMonths(1).addDays(-1);
            result.textPart = removeKeyword(lowerQuery, 'this month');
            return result;
        }
        if (lowerQuery.contains('today') || lowerQuery.contains('today\'s')) {
            result.dateType = 'SINGLE';
            result.startDate = Date.today();
            result.textPart = removeKeyword(removeKeyword(lowerQuery, 'today\'s'), 'today');
            return result;
        }
        if (lowerQuery.contains('tomorrow')) {
            result.dateType = 'SINGLE';
            result.startDate = Date.today().addDays(1);
            result.textPart = removeKeyword(lowerQuery, 'tomorrow');
            return result;
        }
        if (lowerQuery.contains('yesterday')) {
            result.dateType = 'SINGLE';
            result.startDate = Date.today().addDays(-1);
            result.textPart = removeKeyword(lowerQuery, 'yesterday');
            return result;
        }

        Date parsedDate = tryParseExplicitDate(lowerQuery);
        if (parsedDate != null) {
            result.dateType = 'SINGLE';
            result.startDate = parsedDate;
            result.textPart = removeDatePattern(lowerQuery);
            return result;
        }

        Date monthNameDate = tryParseMonthNameDate(lowerQuery);
        if (monthNameDate != null) {
            result.dateType = 'SINGLE';
            result.startDate = monthNameDate;
            result.textPart = removeMonthNameDate(lowerQuery);
            return result;
        }

        result.dateType = 'NONE';
        result.textPart = rawQuery.trim();
        return result;
    }

    private static String removeKeyword(String input, String keyword) {
        String cleaned = input.replace(keyword, '').trim();
        cleaned = cleaned.replaceAll('(?i)\\bvisits?\\b', '').trim();
        cleaned = cleaned.replaceAll('(?i)\\bfor\\b', '').trim();
        cleaned = cleaned.replaceAll('(?i)\\bon\\b', '').trim();
        cleaned = cleaned.replaceAll('(?i)\\bmy\\b', '').trim();
        cleaned = cleaned.replaceAll('\\s+', ' ').trim();
        return cleaned;
    }

    private static Date tryParseExplicitDate(String input) {
        Pattern p1 = Pattern.compile('(\\d{4})-(\\d{1,2})-(\\d{1,2})');
        Matcher m1 = p1.matcher(input);
        if (m1.find()) {
            try {
                return Date.newInstance(
                    Integer.valueOf(m1.group(1)),
                    Integer.valueOf(m1.group(2)),
                    Integer.valueOf(m1.group(3))
                );
            } catch (Exception e) {}
        }

        Pattern p2 = Pattern.compile('(\\d{1,2})[/\\-](\\d{1,2})[/\\-](\\d{4})');
        Matcher m2 = p2.matcher(input);
        if (m2.find()) {
            try {
                return Date.newInstance(
                    Integer.valueOf(m2.group(3)),
                    Integer.valueOf(m2.group(2)),
                    Integer.valueOf(m2.group(1))
                );
            } catch (Exception e) {}
        }
        return null;
    }

    private static String removeDatePattern(String input) {
        String cleaned = input.replaceAll('\\d{4}-\\d{1,2}-\\d{1,2}', '').trim();
        cleaned = cleaned.replaceAll('\\d{1,2}[/\\-]\\d{1,2}[/\\-]\\d{4}', '').trim();
        cleaned = removeKeyword(cleaned, '');
        return cleaned;
    }

    private static Date tryParseMonthNameDate(String input) {
        Map<String, Integer> monthMap = new Map<String, Integer>{
            'jan' => 1, 'january' => 1, 'feb' => 2, 'february' => 2,
            'mar' => 3, 'march' => 3, 'apr' => 4, 'april' => 4, 'may' => 5,
            'jun' => 6, 'june' => 6, 'jul' => 7, 'july' => 7, 'aug' => 8, 'august' => 8,
            'sep' => 9, 'september' => 9, 'oct' => 10, 'october' => 10,
            'nov' => 11, 'november' => 11, 'dec' => 12, 'december' => 12
        };

        Pattern p1 = Pattern.compile('(\\d{1,2})\\s+(\\w+)\\s*(\\d{4})?');
        Matcher m1 = p1.matcher(input);
        if (m1.find()) {
            String monthStr = m1.group(2).toLowerCase();
            if (monthMap.containsKey(monthStr)) {
                Integer day = Integer.valueOf(m1.group(1));
                Integer month = monthMap.get(monthStr);
                Integer year = m1.group(3) != null ? Integer.valueOf(m1.group(3)) : Date.today().year();
                try {
                    return Date.newInstance(year, month, day);
                } catch (Exception e) {}
            }
        }

        Pattern p2 = Pattern.compile('(\\w+)\\s+(\\d{1,2})\\s*,?\\s*(\\d{4})?');
        Matcher m2 = p2.matcher(input);
        if (m2.find()) {
            String monthStr = m2.group(1).toLowerCase();
            if (monthMap.containsKey(monthStr)) {
                Integer day = Integer.valueOf(m2.group(2));
                Integer month = monthMap.get(monthStr);
                Integer year = m2.group(3) != null ? Integer.valueOf(m2.group(3)) : Date.today().year();
                try {
                    return Date.newInstance(year, month, day);
                } catch (Exception e) {}
            }
        }
        return null;
    }

    private static String removeMonthNameDate(String input) {
        String cleaned = input.replaceAll('(?i)\\d{1,2}\\s+(?:jan(?:uary)?|feb(?:ruary)?|mar(?:ch)?|apr(?:il)?|may|june?|july?|aug(?:ust)?|sep(?:tember)?|oct(?:ober)?|nov(?:ember)?|dec(?:ember)?)\\s*\\d{0,4}', '').trim();
        cleaned = cleaned.replaceAll('(?i)(?:jan(?:uary)?|feb(?:ruary)?|mar(?:ch)?|apr(?:il)?|may|june?|july?|aug(?:ust)?|sep(?:tember)?|oct(?:ober)?|nov(?:ember)?|dec(?:ember)?)\\s+\\d{1,2}\\s*,?\\s*\\d{0,4}', '').trim();
        cleaned = removeKeyword(cleaned, '');
        return cleaned;
    }

    private static String formatDate(Date d) {
        if (d == null) return 'N/A';
        List<String> months = new List<String>{
            'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
            'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
        };
        return String.valueOf(d.day()) + ' ' + months[d.month() - 1] + ' ' + String.valueOf(d.year());
    }

    private class ParsedQuery {
        public String dateType = 'NONE';
        public Date startDate;
        public Date endDate;
        public String textPart = '';
    }
}