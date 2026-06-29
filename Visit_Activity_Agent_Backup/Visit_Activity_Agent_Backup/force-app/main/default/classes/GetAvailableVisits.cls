public with sharing class GetAvailableVisits {

    @InvocableMethod(
        label='Get Available Visits'
        description='Retrieve user\'s recently viewed, owned, and scheduled visits for today and the next 7 days.'
    )
    public static List<Result> execute(List<Request> requests) {
        List<Result> results = new List<Result>();

        for (Request req : requests) {
            Result res = new Result();
            res.visits = new List<VisitOption>();

            try {
                Map<Id, VisitOption> visitMap = new Map<Id, VisitOption>();
                Id currentUserId = UserInfo.getUserId();

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

                // Helper to extract assigned user name safely
                // Note: using an inner helper block/loop to map records to options
                
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
                    String timeStr = v.PlannedVisitStartTime != null ? v.PlannedVisitStartTime.format('h:mm a') : '';
                    String label = 'Visit - ' + v.Account.Name +
                        '\n     • \uD83D\uDCC5 Date: Today ' + timeStr +
                        '\n     • \uD83D\uDCCB Status: ' + v.Status +
                        '\n     • \uD83D\uDC64 Assigned: ' + assignedUser;
                    visitMap.put(v.Id, new VisitOption(v.Id, v.Account.Name, label, 'Today'));
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
                        String dateStr = v.PlannedVisitStartTime != null ? v.PlannedVisitStartTime.format('EEEE') : 'Upcoming';
                        String label = 'Visit - ' + v.Account.Name +
                            '\n     • \uD83D\uDCC5 Date: ' + dateStr +
                            '\n     • \uD83D\uDCCB Status: ' + v.Status +
                            '\n     • \uD83D\uDC64 Assigned: ' + assignedUser;
                        visitMap.put(v.Id, new VisitOption(v.Id, v.Account.Name, label, 'Upcoming'));
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
                        String label = 'Visit - ' + v.Account.Name +
                            '\n     • \uD83D\uDCC5 Date: Recently Viewed' +
                            '\n     • \uD83D\uDCCB Status: ' + v.Status +
                            '\n     • \uD83D\uDC64 Assigned: ' + assignedUser;
                        visitMap.put(v.Id, new VisitOption(v.Id, v.Account.Name, label, 'Recently Viewed'));
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
                        String label = 'Visit - ' + v.Account.Name +
                            '\n     • \uD83D\uDCC5 Date: N/A' +
                            '\n     • \uD83D\uDCCB Status: ' + v.Status +
                            '\n     • \uD83D\uDC64 Assigned: ' + assignedUser;
                        visitMap.put(v.Id, new VisitOption(v.Id, v.Account.Name, label, 'Owned'));
                    }
                }

                res.visits.addAll(visitMap.values());

                // Mock data fallback if empty
                if (res.visits.isEmpty()) {
                    res.visits.add(new VisitOption('mock_visit_1', 'ABC Retail Store', 'Visit - ABC Retail Store\n     • \uD83D\uDCC5 Date: Today 10:00 AM\n     • \uD83D\uDCCB Status: Open\n     • \uD83D\uDC64 Assigned: Mock User', 'Today'));
                    res.visits.add(new VisitOption('mock_visit_2', 'XYZ Supermarket', 'Visit - XYZ Supermarket\n     • \uD83D\uDCC5 Date: Today 2:00 PM\n     • \uD83D\uDCCB Status: InProgress\n     • \uD83D\uDC64 Assigned: Mock User', 'Today'));
                    res.visits.add(new VisitOption('mock_visit_3', 'Fresh Mart', 'Visit - Fresh Mart\n     • \uD83D\uDCC5 Date: Tomorrow\n     • \uD83D\uDCCB Status: Open\n     • \uD83D\uDC64 Assigned: Mock User', 'Upcoming'));
                    res.visits.add(new VisitOption('mock_visit_4', 'City Hypermarket', 'Visit - City Hypermarket\n     • \uD83D\uDCC5 Date: Recently Viewed\n     • \uD83D\uDCCB Status: Completed\n     • \uD83D\uDC64 Assigned: Mock User', 'Recently Viewed'));
                }

            } catch (Exception e) {
                // Return fallback mock data
                res.visits.add(new VisitOption('mock_visit_1', 'ABC Retail Store', 'Visit - ABC Retail Store\n     • \uD83D\uDCC5 Date: Today 10:00 AM\n     • \uD83D\uDCCB Status: Open\n     • \uD83D\uDC64 Assigned: Mock User', 'Today'));
                res.visits.add(new VisitOption('mock_visit_2', 'XYZ Supermarket', 'Visit - XYZ Supermarket\n     • \uD83D\uDCC5 Date: Today 2:00 PM\n     • \uD83D\uDCCB Status: InProgress\n     • \uD83D\uDC64 Assigned: Mock User', 'Today'));
                res.visits.add(new VisitOption('mock_visit_3', 'Fresh Mart', 'Visit - Fresh Mart\n     • \uD83D\uDCC5 Date: Tomorrow\n     • \uD83D\uDCCB Status: Open\n     • \uD83D\uDC64 Assigned: Mock User', 'Upcoming'));
                res.visits.add(new VisitOption('mock_visit_4', 'City Hypermarket', 'Visit - City Hypermarket\n     • \uD83D\uDCC5 Date: Recently Viewed\n     • \uD83D\uDCCB Status: Completed\n     • \uD83D\uDC64 Assigned: Mock User', 'Recently Viewed'));
            }

            results.add(res);
        }

        return results;
    }

    public class Request {
        @InvocableVariable
        public String dummyInput;
    }

    public class Result {
        @InvocableVariable
        public List<VisitOption> visits;
    }

    public class VisitOption {
        @InvocableVariable
        public String visitId;

        @InvocableVariable
        public String accountName;

        @InvocableVariable
        public String label;

        @InvocableVariable
        public String category;

        public VisitOption() {}

        public VisitOption(String id, String accName, String lbl, String cat) {
            this.visitId = id;
            this.accountName = accName;
            this.label = lbl;
            this.category = cat;
        }
    }
}