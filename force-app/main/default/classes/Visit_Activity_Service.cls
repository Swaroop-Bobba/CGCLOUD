public with sharing class Visit_Activity_Service {

    // --- 1. GET AVAILABLE VISITS ---
    public static List<Visit_Activity_Handler.VisitOption> getAvailableVisits() {
        List<Visit_Activity_Handler.VisitOption> options = new List<Visit_Activity_Handler.VisitOption>();
        try {
            Map<Id, Visit_Activity_Handler.VisitOption> visitMap = new Map<Id, Visit_Activity_Handler.VisitOption>();
            Id currentUserId = UserInfo.getUserId();

            Boolean isAdmin = false;
            try {
                Id profileId = UserInfo.getProfileId();
                List<Profile> profiles = [SELECT Name FROM Profile WHERE Id = :profileId LIMIT 1];
                isAdmin = !profiles.isEmpty() && profiles[0].Name == 'System Administrator';
            } catch(Exception ex) {}

            Boolean hasResponsible = Schema.sObjectType.Visit.fields.getMap().containsKey('cgcloud__Responsible__c');

            String selectFields = 'SELECT Id, Status, PlannedVisitStartTime, Account.Name, Account.Id, Owner.Name';
            if (hasResponsible) {
                selectFields += ', cgcloud__Responsible__c, cgcloud__Responsible__r.Name';
            }
            selectFields += ' FROM Visit';

            // Today's Visits
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
                String timeStr = v.PlannedVisitStartTime != null ? v.PlannedVisitStartTime.format('h:mm a') : '';
                String label = 'Visit - ' + v.Account.Name +
                    '\n     • \uD83D\uDCC5 Date: Today ' + timeStr +
                    '\n     • \uD83D\uDCCB Status: ' + v.Status +
                    '\n     • \uD83D\uDC64 Assigned: ' + assignedUser;
                visitMap.put(v.Id, new Visit_Activity_Handler.VisitOption(v.Id, v.AccountId, v.Account.Name, label));
            }

            // Upcoming (Next 7 Days)
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
                    String dateStr = v.PlannedVisitStartTime != null ? v.PlannedVisitStartTime.format('EEEE') : 'Upcoming';
                    String label = 'Visit - ' + v.Account.Name +
                        '\n     • \uD83D\uDCC5 Date: ' + dateStr +
                        '\n     • \uD83D\uDCCB Status: ' + v.Status +
                        '\n     • \uD83D\uDC64 Assigned: ' + assignedUser;
                    visitMap.put(v.Id, new Visit_Activity_Handler.VisitOption(v.Id, v.AccountId, v.Account.Name, label));
                }
            }

            // Recently Viewed
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
                    String label = 'Visit - ' + v.Account.Name +
                        '\n     • \uD83D\uDCC5 Date: Recently Viewed' +
                        '\n     • \uD83D\uDCCB Status: ' + v.Status +
                        '\n     • \uD83D\uDC64 Assigned: ' + assignedUser;
                    visitMap.put(v.Id, new Visit_Activity_Handler.VisitOption(v.Id, v.AccountId, v.Account.Name, label));
                }
            }

            options.addAll(visitMap.values());

            // Mock Fallback
            if (options.isEmpty()) {
                addMockVisits(options);
            }
        } catch (Exception e) {
            addMockVisits(options);
        }
        return options;
    }

    private static void addMockVisits(List<Visit_Activity_Handler.VisitOption> options) {
        options.add(new Visit_Activity_Handler.VisitOption('mock_visit_1', 'mock_account_id', 'ABC Retail Store', 'Visit - ABC Retail Store\n     • \uD83D\uDCC5 Date: Today 10:00 AM\n     • \uD83D\uDCCB Status: Open\n     • \uD83D\uDC64 Assigned: Mock User'));
        options.add(new Visit_Activity_Handler.VisitOption('mock_visit_2', 'mock_account_id', 'XYZ Supermarket', 'Visit - XYZ Supermarket\n     • \uD83D\uDCC5 Date: Today 2:00 PM\n     • \uD83D\uDCCB Status: InProgress\n     • \uD83D\uDC64 Assigned: Mock User'));
    }

    // --- 2. SEARCH VISITS FOR AGENT ---
    public static List<Visit_Activity_Handler.VisitOption> searchVisits(String searchQuery) {
        List<Visit_Activity_Handler.VisitOption> options = new List<Visit_Activity_Handler.VisitOption>();
        if (String.isBlank(searchQuery)) {
            return options;
        }

        try {
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

            // Text search pattern
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

            // Date Filters
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

            // Non-admin filter
            if (!isAdmin && hasResponsible) {
                conditions.add('cgcloud__Responsible__c = :currentUserId');
            }

            String whereClause = '';
            if (!conditions.isEmpty()) {
                whereClause = ' WHERE ' + String.join(conditions, ' AND ');
            }

            String searchQueryStr = selectFields + whereClause + ' WITH USER_MODE ORDER BY cgcloud__Start_Date__c DESC LIMIT 15';
            List<SObject> visits = Database.query(searchQueryStr);

            // Fetch Place details
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

                String label = visitName + '  \u2014  ' + displayAccount +
                    '\n     • \uD83D\uDCC5 Date: ' + dateStr +
                    '\n     • \uD83D\uDCCB Status: ' + status +
                    '\n     • \uD83D\uDC64 Assigned: ' + assignedUser;

                options.add(new Visit_Activity_Handler.VisitOption(visitId, accId, accountName, label));
            }
        } catch (Exception e) {}
        return options;
    }

    // --- 3. GET VISIT ACTIVITIES ---
    public static List<Visit_Activity_Handler.ActivityInfo> getVisitActivities(String visitId, String typeFilter) {
        List<Visit_Activity_Handler.ActivityInfo> options = new List<Visit_Activity_Handler.ActivityInfo>();
        if (String.isBlank(visitId)) {
            return options;
        }

        try {
            List<Visit> visits = [
                SELECT Id, cgcloud__Visit_Template__c
                FROM Visit
                WHERE Id = :visitId
                WITH USER_MODE
                LIMIT 1
            ];
            if (visits.isEmpty() || visits[0].cgcloud__Visit_Template__c == null) {
                return options;
            }

            Id visitTemplateId = visits[0].cgcloud__Visit_Template__c;

            // 1. Query unique instantiated template IDs for this specific visit
            List<cgcloud__Visit_Job__c> actualJobs = [
                SELECT cgcloud__Job_Definition_Template__c
                FROM cgcloud__Visit_Job__c
                WHERE cgcloud__Visit__c = :visitId
                WITH USER_MODE
            ];
            Set<Id> instantiatedJdtIds = new Set<Id>();
            for (cgcloud__Visit_Job__c job : actualJobs) {
                if (job.cgcloud__Job_Definition_Template__c != null) {
                    instantiatedJdtIds.add(job.cgcloud__Job_Definition_Template__c);
                }
            }

            String resolvedType = String.isNotBlank(typeFilter) ? typeFilter.toLowerCase().trim() : '';

            // 2. Query links to identify which JDLs contain at least one instantiated question template (or fallback to all active links if no jobs exist yet)
            String linksQuery = 'SELECT cgcloud__Job_Definition_List__c FROM cgcloud__Job_DL_Job_Definition_Template__c WHERE cgcloud__Job_Definition_List__r.cgcloud__Visit_Template__c = :visitTemplateId AND cgcloud__Job_Definition_List__r.cgcloud__Active__c = true';
            if (!instantiatedJdtIds.isEmpty()) {
                linksQuery += ' AND cgcloud__Job_Definition_Template__c IN :instantiatedJdtIds';
            }
            if (resolvedType == 'question' || resolvedType == 'questions') {
                linksQuery += ' AND cgcloud__Job_Definition_Template__r.cgcloud__Job_Template__r.Name = \'Question\'';
            } else if (resolvedType == 'survey' || resolvedType == 'surveys') {
                linksQuery += ' AND cgcloud__Job_Definition_Template__r.cgcloud__Job_Template__r.Name = \'Survey\'';
            }
            List<cgcloud__Job_DL_Job_Definition_Template__c> links = Database.query(linksQuery);
            Set<Id> activeJdlIds = new Set<Id>();
            for (cgcloud__Job_DL_Job_Definition_Template__c link : links) {
                activeJdlIds.add(link.cgcloud__Job_Definition_List__c);
            }

            // 3. Query the active JDLs and pull their planned questions (retaining pending/uninstantiated questions)
            String subqueryFilter = '';
            if (resolvedType == 'question' || resolvedType == 'questions') {
                subqueryFilter = ' WHERE cgcloud__Job_Definition_Template__r.cgcloud__Job_Template__r.Name = \'Question\'';
            } else if (resolvedType == 'survey' || resolvedType == 'surveys') {
                subqueryFilter = ' WHERE cgcloud__Job_Definition_Template__r.cgcloud__Job_Template__r.Name = \'Survey\'';
            }

            String jdlQueryStr = 'SELECT Id, Name, cgcloud__Description__c, cgcloud__Visit_Template__c, ' +
                'cgcloud__Field_Sales_Activity__c, cgcloud__Field_Sales_Activity__r.Name, cgcloud__Field_Sales_Activity__r.cgcloud__Description__c, ' +
                '(SELECT Id, Name, cgcloud__Job_Definition_Template__c, cgcloud__Job_Definition_Template__r.Name, ' +
                'cgcloud__Job_Definition_Template__r.cgcloud__Description__c, cgcloud__Job_Definition_Template__r.cgcloud__Data_Type__c, ' +
                'cgcloud__Mandatory__c FROM cgcloud__Job_Definition_Links__r' + subqueryFilter + ') ' +
                'FROM cgcloud__Job_Definition_List__c WHERE Id IN :activeJdlIds WITH USER_MODE';

            List<cgcloud__Job_Definition_List__c> jdls = Database.query(jdlQueryStr);

            for (cgcloud__Job_Definition_List__c jdl : jdls) {
                Visit_Activity_Handler.ActivityInfo act = new Visit_Activity_Handler.ActivityInfo();
                act.activityId = jdl.Id;
                
                if (jdl.cgcloud__Field_Sales_Activity__c != null) {
                    act.activityName = jdl.cgcloud__Field_Sales_Activity__r.Name;
                    act.description = jdl.cgcloud__Field_Sales_Activity__r.cgcloud__Description__c;
                } else {
                    act.activityName = jdl.Name;
                    act.description = jdl.cgcloud__Description__c;
                }
                
                act.questions = new List<Visit_Activity_Handler.QuestionInfo>();
                if (jdl.cgcloud__Job_Definition_Links__r != null) {
                    for (cgcloud__Job_DL_Job_Definition_Template__c linkItem : jdl.cgcloud__Job_Definition_Links__r) {
                        Visit_Activity_Handler.QuestionInfo q = new Visit_Activity_Handler.QuestionInfo();
                        q.questionId = linkItem.cgcloud__Job_Definition_Template__c;
                        q.questionName = linkItem.cgcloud__Job_Definition_Template__r.Name;
                        q.description = linkItem.cgcloud__Job_Definition_Template__r.cgcloud__Description__c;
                        q.mandatory = linkItem.cgcloud__Mandatory__c;
                        act.questions.add(q);
                    }
                }
                options.add(act);
            }
        } catch (Exception e) {}
        return options;
    }

    // --- 4. GET VISIT JOBS STATUS ---
    public static List<Visit_Activity_Handler.JobStatusInfo> getVisitJobsStatus(String visitId, String statusFilter, String typeFilter) {
        List<Visit_Activity_Handler.JobStatusInfo> options = new List<Visit_Activity_Handler.JobStatusInfo>();
        if (String.isBlank(visitId)) {
            return options;
        }

        try {
            List<Visit> visits = [
                SELECT Id, cgcloud__Visit_Template__c
                FROM Visit
                WHERE Id = :visitId
                WITH USER_MODE
                LIMIT 1
            ];
            if (visits.isEmpty()) {
                return options;
            }

            Visit v = visits[0];
            Id visitTemplateId = v.cgcloud__Visit_Template__c;
            String filter = String.isNotBlank(statusFilter) ? statusFilter.toLowerCase().trim() : 'all';
            String resolvedType = String.isNotBlank(typeFilter) ? typeFilter.toLowerCase().trim() : '';

            // Query planned template questions
            Map<Id, cgcloud__Job_DL_Job_Definition_Template__c> plannedMap = new Map<Id, cgcloud__Job_DL_Job_Definition_Template__c>();
            if (visitTemplateId != null) {
                String plannedQueryStr = 'SELECT cgcloud__Job_Definition_Template__c, cgcloud__Job_Definition_Template__r.Name, cgcloud__Job_Definition_Template__r.cgcloud__Description__c FROM cgcloud__Job_DL_Job_Definition_Template__c WHERE cgcloud__Job_Definition_List__r.cgcloud__Visit_Template__c = :visitTemplateId AND cgcloud__Job_Definition_List__r.cgcloud__Active__c = true';
                if (resolvedType == 'question' || resolvedType == 'questions') {
                    plannedQueryStr += ' AND cgcloud__Job_Definition_Template__r.cgcloud__Job_Template__r.Name = \'Question\'';
                } else if (resolvedType == 'survey' || resolvedType == 'surveys') {
                    plannedQueryStr += ' AND cgcloud__Job_Definition_Template__r.cgcloud__Job_Template__r.Name = \'Survey\'';
                }

                List<cgcloud__Job_DL_Job_Definition_Template__c> plannedList = Database.query(plannedQueryStr);
                for (cgcloud__Job_DL_Job_Definition_Template__c planned : plannedList) {
                    plannedMap.put(planned.cgcloud__Job_Definition_Template__c, planned);
                }
            }

            // Query actual jobs
            String jobQueryStr = 'SELECT Id, Name, cgcloud__Job_Definition_Template__c, cgcloud__Job_Definition_Template__r.Name, cgcloud__Job_Definition_Template_Description__c, cgcloud__Done__c, cgcloud__Value__c, cgcloud__Display_Value__c, cgcloud__Product__r.Name, cgcloud__Promotion__r.Name FROM cgcloud__Visit_Job__c WHERE cgcloud__Visit__c = :visitId';
            if (resolvedType == 'question' || resolvedType == 'questions') {
                jobQueryStr += ' AND cgcloud__Job_Definition_Template__r.cgcloud__Job_Template__r.Name = \'Question\'';
            } else if (resolvedType == 'survey' || resolvedType == 'surveys') {
                jobQueryStr += ' AND cgcloud__Job_Definition_Template__r.cgcloud__Job_Template__r.Name = \'Survey\'';
            }
            List<cgcloud__Visit_Job__c> actualJobs = Database.query(jobQueryStr);

            Map<Id, List<cgcloud__Visit_Job__c>> templateToActualJobs = new Map<Id, List<cgcloud__Visit_Job__c>>();
            for (cgcloud__Visit_Job__c job : actualJobs) {
                if (job.cgcloud__Job_Definition_Template__c != null) {
                    if (!templateToActualJobs.containsKey(job.cgcloud__Job_Definition_Template__c)) {
                        templateToActualJobs.put(job.cgcloud__Job_Definition_Template__c, new List<cgcloud__Visit_Job__c>());
                    }
                    templateToActualJobs.get(job.cgcloud__Job_Definition_Template__c).add(job);
                }
            }

            List<Visit_Activity_Handler.JobStatusInfo> answeredJobsList = new List<Visit_Activity_Handler.JobStatusInfo>();
            List<Visit_Activity_Handler.JobStatusInfo> pendingJobsList = new List<Visit_Activity_Handler.JobStatusInfo>();

            for (cgcloud__Visit_Job__c job : actualJobs) {
                Boolean isDone = (job.cgcloud__Done__c == true || String.isNotBlank(job.cgcloud__Value__c));
                
                Visit_Activity_Handler.JobStatusInfo info = new Visit_Activity_Handler.JobStatusInfo();
                info.jobId = job.Id;
                info.questionName = job.cgcloud__Job_Definition_Template__r != null ? job.cgcloud__Job_Definition_Template__r.Name : '';
                info.questionDescription = job.cgcloud__Job_Definition_Template_Description__c;
                info.value = job.cgcloud__Value__c;
                info.displayValue = job.cgcloud__Display_Value__c;
                info.productName = job.cgcloud__Product__r != null ? job.cgcloud__Product__r.Name : '';
                info.promotionName = job.cgcloud__Promotion__r != null ? job.cgcloud__Promotion__r.Name : '';

                if (isDone) {
                    info.isDone = true;
                    answeredJobsList.add(info);
                } else {
                    info.isDone = false;
                    pendingJobsList.add(info);
                }
            }

            // Fallback for templates without job records
            Set<Id> addedPendingIds = new Set<Id>();
            for (Id tId : plannedMap.keySet()) {
                if (!templateToActualJobs.containsKey(tId) && !addedPendingIds.contains(tId)) {
                    addedPendingIds.add(tId);
                    cgcloud__Job_DL_Job_Definition_Template__c planned = plannedMap.get(tId);
                    
                    Visit_Activity_Handler.JobStatusInfo info = new Visit_Activity_Handler.JobStatusInfo();
                    info.jobId = '';
                    info.questionName = planned.cgcloud__Job_Definition_Template__r.Name;
                    info.questionDescription = planned.cgcloud__Job_Definition_Template__r.cgcloud__Description__c;
                    info.isDone = false;
                    info.value = '';
                    info.displayValue = '';
                    info.productName = '';
                    info.promotionName = '';
                    pendingJobsList.add(info);
                }
            }

            if (filter == 'answered' || filter == 'completed') {
                options.addAll(answeredJobsList);
            } else if (filter == 'pending' || filter == 'unanswered') {
                options.addAll(pendingJobsList);
            } else {
                options.addAll(answeredJobsList);
                options.addAll(pendingJobsList);
            }
        } catch (Exception e) {}
        return options;
    }

    // --- 5. GET NEXT STEPS OPTIONS ---
    public static List<Visit_Activity_Handler.ItemDetail> getNextStepsOptions(String excludeOption) {
        List<Visit_Activity_Handler.ItemDetail> options = new List<Visit_Activity_Handler.ItemDetail>();
        try {
            addNextStep(options, 'View today\'s activities or surveys', 'View planned activities and surveys for the current visit.', excludeOption);
            addNextStep(options, 'See answered or pending questions', 'Check completed vs pending questions/surveys for the current visit.', excludeOption);
            addNextStep(options, 'Check all questions and survey statuses', 'List all questions and surveys status for the current visit.', excludeOption);
            addNextStep(options, 'Switch to another visit', 'Clear active visit context and select a different visit.', excludeOption);
        } catch(Exception e) {}
        return options;
    }

    private static void addNextStep(List<Visit_Activity_Handler.ItemDetail> options, String label, String descText, String excludeOption) {
        if (String.isNotBlank(excludeOption) && label.equalsIgnoreCase(excludeOption.trim())) {
            return;
        }
        options.add(new Visit_Activity_Handler.ItemDetail(label, descText));
    }

    // --- 6. DATE & QUERY PARSING HELPERS ---
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
