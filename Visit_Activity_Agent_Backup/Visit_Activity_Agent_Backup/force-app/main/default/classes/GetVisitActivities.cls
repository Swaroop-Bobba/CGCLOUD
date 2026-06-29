public with sharing class GetVisitActivities {

    public class Request {
        @InvocableVariable(label='Visit ID' description='The ID of the Visit record' required=true)
        public String visitId;
    }

    public class Result {
        @InvocableVariable(label='Activities' description='List of activities and questions/surveys associated with the visit template')
        public List<ActivityInfo> activities;
    }

    public class ActivityInfo {
        @InvocableVariable(label='Activity ID' description='The ID of the Job Definition List record')
        public String activityId;

        @InvocableVariable(label='Activity Name' description='The Name of the activity')
        public String activityName;

        @InvocableVariable(label='Description' description='The description of the activity')
        public String description;

        @InvocableVariable(label='Questions' description='List of related questions/surveys')
        public List<QuestionInfo> questions;
    }

    public class QuestionInfo {
        @InvocableVariable(label='Question ID' description='The ID of the Job Definition Template record')
        public String questionId;

        @InvocableVariable(label='Question Name' description='The Name of the question/survey')
        public String questionName;

        @InvocableVariable(label='Description' description='The description of the question/survey')
        public String description;

        @InvocableVariable(label='Mandatory' description='Is this question mandatory?')
        public Boolean mandatory;
    }

    @InvocableMethod(
        label='Get Visit Activities'
        description='Retrieves activities, questions, and surveys associated with a visit based on its visit template.'
    )
    public static List<Result> execute(List<Request> requests) {
        List<Result> results = new List<Result>();
        
        // Collect visit IDs
        Set<Id> visitIds = new Set<Id>();
        for (Request req : requests) {
            if (String.isNotBlank(req.visitId)) {
                visitIds.add((Id)req.visitId);
            }
        }
        
        if (visitIds.isEmpty()) {
            for (Integer i = 0; i < requests.size(); i++) {
                results.add(new Result());
            }
            return results;
        }

        // Query Visit records to get their templates
        Map<Id, Visit> visitsMap = new Map<Id, Visit>([
            SELECT Id, cgcloud__Visit_Template__c
            FROM Visit
            WHERE Id IN :visitIds
            WITH USER_MODE
        ]);

        // Map visit template IDs to visit IDs
        Map<Id, Set<Id>> templateToVisits = new Map<Id, Set<Id>>();
        for (Visit v : visitsMap.values()) {
            if (v.cgcloud__Visit_Template__c != null) {
                if (!templateToVisits.containsKey(v.cgcloud__Visit_Template__c)) {
                    templateToVisits.put(v.cgcloud__Visit_Template__c, new Set<Id>());
                }
                templateToVisits.get(v.cgcloud__Visit_Template__c).add(v.Id);
            }
        }

        // Query Job Definition Lists for these templates
        Map<Id, List<cgcloud__Job_Definition_List__c>> templateToJDLs = new Map<Id, List<cgcloud__Job_Definition_List__c>>();
        if (!templateToVisits.isEmpty()) {
            Set<Id> templateIds = templateToVisits.keySet();
            List<cgcloud__Job_Definition_List__c> jdls = [
                SELECT Id, Name, cgcloud__Description__c, cgcloud__Visit_Template__c,
                       cgcloud__Field_Sales_Activity__c, cgcloud__Field_Sales_Activity__r.Name, cgcloud__Field_Sales_Activity__r.cgcloud__Description__c,
                       (SELECT Id, Name,
                               cgcloud__Job_Definition_Template__c,
                               cgcloud__Job_Definition_Template__r.Name,
                               cgcloud__Job_Definition_Template__r.cgcloud__Description__c,
                               cgcloud__Job_Definition_Template__r.cgcloud__Data_Type__c,
                               cgcloud__Mandatory__c
                        FROM cgcloud__Job_Definition_Links__r)
                FROM cgcloud__Job_Definition_List__c
                WHERE cgcloud__Visit_Template__c IN :templateIds
                  AND cgcloud__Active__c = true
                WITH USER_MODE
            ];
            for (cgcloud__Job_Definition_List__c jdl : jdls) {
                if (!templateToJDLs.containsKey(jdl.cgcloud__Visit_Template__c)) {
                    templateToJDLs.put(jdl.cgcloud__Visit_Template__c, new List<cgcloud__Job_Definition_List__c>());
                }
                templateToJDLs.get(jdl.cgcloud__Visit_Template__c).add(jdl);
            }
        }

        // Populate results mapping back to each request
        for (Request req : requests) {
            Result res = new Result();
            res.activities = new List<ActivityInfo>();
            
            if (String.isNotBlank(req.visitId)) {
                Visit v = visitsMap.get(req.visitId);
                if (v != null && v.cgcloud__Visit_Template__c != null && templateToJDLs.containsKey(v.cgcloud__Visit_Template__c)) {
                    for (cgcloud__Job_Definition_List__c jdl : templateToJDLs.get(v.cgcloud__Visit_Template__c)) {
                        ActivityInfo act = new ActivityInfo();
                        act.activityId = jdl.Id;
                        
                        // Use Field Sales Activity details if lookup is populated, else fallback to JDL name
                        if (jdl.cgcloud__Field_Sales_Activity__c != null) {
                            act.activityName = jdl.cgcloud__Field_Sales_Activity__r.Name;
                            act.description = jdl.cgcloud__Field_Sales_Activity__r.cgcloud__Description__c;
                        } else {
                            act.activityName = jdl.Name;
                            act.description = jdl.cgcloud__Description__c;
                        }
                        
                        act.questions = new List<QuestionInfo>();
                        if (jdl.cgcloud__Job_Definition_Links__r != null) {
                            for (cgcloud__Job_DL_Job_Definition_Template__c link : jdl.cgcloud__Job_Definition_Links__r) {
                                QuestionInfo q = new QuestionInfo();
                                q.questionId = link.cgcloud__Job_Definition_Template__c;
                                q.questionName = link.cgcloud__Job_Definition_Template__r.Name;
                                q.description = link.cgcloud__Job_Definition_Template__r.cgcloud__Description__c;
                                q.mandatory = link.cgcloud__Mandatory__c;
                                act.questions.add(q);
                            }
                        }
                        res.activities.add(act);
                    }
                }
            }
            results.add(res);
        }

        return results;
    }
}
