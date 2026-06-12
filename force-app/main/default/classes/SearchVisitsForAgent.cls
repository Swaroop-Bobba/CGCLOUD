public with sharing class SearchVisitsForAgent {
 
     @InvocableMethod(
         label='Search Visits (Agent)'
         description='Search for Visit records by account name, store name, visit name, or date. Supports natural language dates like today, tomorrow, this week, and explicit date formats.'
     )
     public static List<Result> execute(List<Request> requests) {
         List<Result> results = new List<Result>();
 
         for (Request req : requests) {
             Result res = new Result();
             res.visits = new List<VisitOption>();
 
             String query = req.searchQuery;
             if (String.isBlank(query)) {
                 results.add(res);
                 continue;
             }
 
             try {
                 // Determine admin status
                 Boolean isAdmin = false;
                 try {
                     Id profileId = UserInfo.getProfileId();
                     List<Profile> profiles = [SELECT Name FROM Profile WHERE Id = :profileId LIMIT 1];
                     isAdmin = !profiles.isEmpty() && profiles[0].Name == 'System Administrator';
                 } catch (Exception ex) {}
 
                 Boolean hasResponsible = Schema.sObjectType.Visit.fields.getMap().containsKey('cgcloud__Responsible__c');
                 Id currentUserId = UserInfo.getUserId();
 
                 // Parse the search query for date keywords and text terms
                 ParsedQuery parsed = parseSearchQuery(query);
 
                 // Build SELECT fields
                 String selectFields = 'SELECT Id, Name, Status, Account.Name, Account.Id, Owner.Name, PlaceId';
                 if (hasResponsible) {
                     selectFields += ', cgcloud__Responsible__c, cgcloud__Responsible__r.Name';
                 }
                 // Use cgcloud__Start_Date__c for date display and filtering
                 selectFields += ', cgcloud__Start_Date__c';
                 selectFields += ' FROM Visit';
 
                 // Build WHERE clause
                 List<String> conditions = new List<String>();
 
                 // Text filter (account name, visit name, status, or related place name)
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
 
                 // Date filter using cgcloud__Start_Date__c
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
 
                 // Non-admin user filter
                 if (!isAdmin && hasResponsible) {
                     conditions.add('cgcloud__Responsible__c = :currentUserId');
                 }
 
                 String whereClause = '';
                 if (!conditions.isEmpty()) {
                     whereClause = ' WHERE ' + String.join(conditions, ' AND ');
                 }
 
                 String searchQueryStr = selectFields + whereClause + ' WITH USER_MODE ORDER BY cgcloud__Start_Date__c DESC LIMIT 15';
                 List<SObject> visits = Database.query(searchQueryStr);
 
                 // Collect Place IDs to query their names/descriptions
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
                         '\n   - \uD83D\uDCC5 Date: ' + dateStr +
                         '\n   - \uD83D\uDCCB Status: ' + status +
                         '\n   - \uD83D\uDC64 Assigned: ' + assignedUser;
 
                     res.visits.add(new VisitOption(visitId, accId, accountName, label));
                 }
 
             } catch (Exception e) {
                 // No mock data — return empty with a debug-friendly message
                 // The agent will handle empty results gracefully via its instructions
             }
 
             results.add(res);
         }
 
         return results;
     }
 
     // ---- Date Parsing Logic ----
 
     private static ParsedQuery parseSearchQuery(String rawQuery) {
         ParsedQuery result = new ParsedQuery();
         String lowerQuery = rawQuery.toLowerCase().trim();
 
         // Check for natural language date keywords
         // Order matters: check multi-word phrases first
 
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
 
         // Try to parse explicit date formats: yyyy-MM-dd, dd/MM/yyyy, dd-MM-yyyy
         Date parsedDate = tryParseExplicitDate(lowerQuery);
         if (parsedDate != null) {
             result.dateType = 'SINGLE';
             result.startDate = parsedDate;
             result.textPart = removeDatePattern(lowerQuery);
             return result;
         }
 
         // Try to parse month-name dates: "29 May 2026", "May 29 2026", "May 29"
         Date monthNameDate = tryParseMonthNameDate(lowerQuery);
         if (monthNameDate != null) {
             result.dateType = 'SINGLE';
             result.startDate = monthNameDate;
             result.textPart = removeMonthNameDate(lowerQuery);
             return result;
         }
 
         // No date found — treat entire query as text search
         result.dateType = 'NONE';
         result.textPart = rawQuery.trim();
         return result;
     }
 
     private static String removeKeyword(String input, String keyword) {
         String cleaned = input.replace(keyword, '').trim();
         // Clean up common filler words left over
         cleaned = cleaned.replaceAll('(?i)\\bvisits?\\b', '').trim();
         cleaned = cleaned.replaceAll('(?i)\\bfor\\b', '').trim();
         cleaned = cleaned.replaceAll('(?i)\\bon\\b', '').trim();
         cleaned = cleaned.replaceAll('(?i)\\bmy\\b', '').trim();
         cleaned = cleaned.replaceAll('\\s+', ' ').trim();
         return cleaned;
     }
 
     private static Date tryParseExplicitDate(String input) {
         // Match yyyy-MM-dd
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
 
         // Match dd/MM/yyyy or dd-MM-yyyy (day first)
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
             'jan' => 1, 'january' => 1,
             'feb' => 2, 'february' => 2,
             'mar' => 3, 'march' => 3,
             'apr' => 4, 'april' => 4,
             'may' => 5,
             'jun' => 6, 'june' => 6,
             'jul' => 7, 'july' => 7,
             'aug' => 8, 'august' => 8,
             'sep' => 9, 'september' => 9,
             'oct' => 10, 'october' => 10,
             'nov' => 11, 'november' => 11,
             'dec' => 12, 'december' => 12
         };
 
         // Pattern: "29 May 2026" or "29 May"
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
 
         // Pattern: "May 29 2026" or "May 29"
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
         // Remove patterns like "29 May 2026", "May 29, 2026", "May 29"
         String cleaned = input.replaceAll('(?i)\\d{1,2}\\s+(?:jan(?:uary)?|feb(?:ruary)?|mar(?:ch)?|apr(?:il)?|may|june?|july?|aug(?:ust)?|sep(?:tember)?|oct(?:ober)?|nov(?:ember)?|dec(?:ember)?)\\s*\\d{0,4}', '').trim();
         cleaned = cleaned.replaceAll('(?i)(?:jan(?:uary)?|feb(?:ruary)?|mar(?:ch)?|apr(?:il)?|may|june?|july?|aug(?:ust)?|sep(?:tember)?|oct(?:ober)?|nov(?:ember)?|dec(?:ember)?)\\s+\\d{1,2}\\s*,?\\s*\\d{0,4}', '').trim();
         cleaned = removeKeyword(cleaned, '');
         return cleaned;
     }
 
     // ---- Date Formatting ----
 
     private static String formatDate(Date d) {
         if (d == null) return 'N/A';
         List<String> months = new List<String>{
             'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
             'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
         };
         return String.valueOf(d.day()) + ' ' + months[d.month() - 1] + ' ' + String.valueOf(d.year());
     }
 
     // ---- Inner Classes ----
 
     private class ParsedQuery {
         public String dateType = 'NONE';  // NONE, SINGLE, RANGE
         public Date startDate;
         public Date endDate;
         public String textPart = '';
     }
 
     public class Request {
         @InvocableVariable(required=true description='The search query. Supports account names, visit names, dates (today, tomorrow, this week, yyyy-MM-dd, dd/MM/yyyy, 29 May 2026), or combinations.')
         public String searchQuery;
     }
 
     public class Result {
         @InvocableVariable(description='List of matching visits.')
         public List<VisitOption> visits;
     }
 
     public class VisitOption {
         @InvocableVariable(description='The Visit record ID. Use this value as the recordId when selecting a visit.')
         public String visitId;
 
         @InvocableVariable(description='The associated Account ID.')
         public String accountId;
 
         @InvocableVariable(description='The associated Account Name.')
         public String accountName;
 
         @InvocableVariable(description='Formatted label with visit name, account, date, status, and assigned user.')
         public String label;
 
         public VisitOption() {}
 
         public VisitOption(String id, String accId, String accName, String lbl) {
             this.visitId = id;
             this.accountId = accId;
             this.accountName = accName;
             this.label = lbl;
         }
     }
 }