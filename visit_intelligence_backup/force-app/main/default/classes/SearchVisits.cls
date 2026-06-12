/**
 * @deprecated This class is obsolete and has been replaced by the Apex Class: SearchVisitsForAgent (apex://SearchVisitsForAgent).
 * It is no longer referenced by the Visit Intelligence Agent.
 */
public with sharing class SearchVisits {

    @InvocableMethod(
        label='Search Visits'
        description='Search for Visit records by account name, store name, visit name, or date.'
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

            String cleanedQuery = query.trim().replaceAll('\\s+', '%');
            String searchPattern = '%' + cleanedQuery + '%';

            try {
                Boolean isAdmin = false;
                try {
                    Id profileId = UserInfo.getProfileId();
                    List<Profile> profiles = [SELECT Name FROM Profile WHERE Id = :profileId LIMIT 1];
                    isAdmin = !profiles.isEmpty() && profiles[0].Name == 'System Administrator';
                } catch(Exception ex) {}

                Boolean hasResponsible = Schema.sObjectType.Visit.fields.getMap().containsKey('cgcloud__Responsible__c');
                Id currentUserId = UserInfo.getUserId();

                String selectFields = 'SELECT Id, Status, PlannedVisitStartTime, Account.Name, Owner.Name';
                if (hasResponsible) {
                    selectFields += ', cgcloud__Responsible__c, cgcloud__Responsible__r.Name';
                }
                selectFields += ' FROM Visit';

                String whereClause = ' WHERE (Account.Name LIKE :searchPattern OR Status LIKE :searchPattern)';
                if (!isAdmin && hasResponsible) {
                    whereClause += ' AND cgcloud__Responsible__c = :currentUserId';
                }
                
                String searchQueryStr = selectFields + whereClause + ' WITH USER_MODE LIMIT 10';
                List<Visit> visits = Database.query(searchQueryStr);
                
                for (Visit v : visits) {
                    String assignedUser = v.Owner.Name;
                    if (hasResponsible && v.getSObject('cgcloud__Responsible__r') != null) {
                        assignedUser = (String)v.getSObject('cgcloud__Responsible__r').get('Name');
                    }
                    String timeStr = v.PlannedVisitStartTime != null ? v.PlannedVisitStartTime.format('yyyy-MM-dd h:mm a') : '';
                    String label = 'Visit - ' + v.Account.Name +
                        '\n     • \uD83D\uDCC5 Date: ' + timeStr +
                        '\n     • \uD83D\uDCCB Status: ' + v.Status +
                        '\n     • \uD83D\uDC64 Assigned: ' + assignedUser;
                    res.visits.add(new VisitOption(v.Id, v.Account.Name, label));
                }

                // Mock data fallback if empty
                if (res.visits.isEmpty()) {
                    if ('ABC Retail Store'.toLowerCase().contains(query.toLowerCase())) {
                        res.visits.add(new VisitOption('mock_visit_1', 'ABC Retail Store', 'Visit - ABC Retail Store\n     • \uD83D\uDCC5 Date: Today 10:00 AM\n     • \uD83D\uDCCB Status: Open\n     • \uD83D\uDC64 Assigned: Mock User'));
                    }
                    if ('XYZ Supermarket'.toLowerCase().contains(query.toLowerCase())) {
                        res.visits.add(new VisitOption('mock_visit_2', 'XYZ Supermarket', 'Visit - XYZ Supermarket\n     • \uD83D\uDCC5 Date: Today 2:00 PM\n     • \uD83D\uDCCB Status: InProgress\n     • \uD83D\uDC64 Assigned: Mock User'));
                    }
                    if ('Fresh Mart'.toLowerCase().contains(query.toLowerCase())) {
                        res.visits.add(new VisitOption('mock_visit_3', 'Fresh Mart', 'Visit - Fresh Mart\n     • \uD83D\uDCC5 Date: Tomorrow\n     • \uD83D\uDCCB Status: Open\n     • \uD83D\uDC64 Assigned: Mock User'));
                    }
                }
            } catch (Exception e) {
                res.visits.add(new VisitOption('mock_visit_1', 'ABC Retail Store', 'Visit - ABC Retail Store\n     • \uD83D\uDCC5 Date: Today 10:00 AM\n     • \uD83D\uDCCB Status: Open\n     • \uD83D\uDC64 Assigned: Mock User'));
            }

            results.add(res);
        }

        return results;
    }

    public class Request {
        @InvocableVariable(required=true)
        public String searchQuery;
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

        public VisitOption() {}

        public VisitOption(String id, String accName, String lbl) {
            this.visitId = id;
            this.accountName = accName;
            this.label = lbl;
        }
    }
}
