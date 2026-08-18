/**
 * Manages in-store assessment tasks, survey checklists, planogram checks,
 * promotion compliance audits, and delivery tracking.
 */
global with sharing class VisitActivityController {

    /**
     * @description Explicit zero-argument default constructor for 2GP serialization.
     */
    global VisitActivityController() {}

    /**
     * @description Input DTO for VisitActivityController.
     */
    global class Request {
        @InvocableVariable(required=true description='Action to perform (e.g. getAssessmentTasks, getActivities, getJobsStatus, getDeliveryActivities, getNextSteps).')
        global String actionType;

        @InvocableVariable(description='The name of the agent executing the request.')
        global String agentName;

        @InvocableVariable(description='Domain context.')
        global String domain;

        @InvocableVariable(description='Target Visit ID.')
        global String visitId;

        @InvocableVariable(description='Target Account ID.')
        global String accountId;

        @InvocableVariable(description='Status filter (e.g. Completed, Pending, In Progress).')
        global String statusFilter;

        @InvocableVariable(description='Filter by question or survey type.')
        global String questionOrSurveyFilter;

        @InvocableVariable(description='Exclude option string.')
        global String excludeOption;

        global Request() {}
    }

    /**
     * @description Output DTO for VisitActivityController.
     */
    global class Response {
        @InvocableVariable(description='True if operation succeeded.')
        global Boolean success;

        @InvocableVariable(description='Outcome message.')
        global String message;

        @InvocableVariable(description='Markdown formatted report or result list.')
        global String summary;

        @InvocableVariable(description='Total assessment activities count.')
        global Integer totalTasks;

        @InvocableVariable(description='Completed assessment activities count.')
        global Integer completedTasks;

        @InvocableVariable(description='Pending assessment activities count.')
        global Integer pendingTasks;

        global Response() {
            this.success = true;
            this.totalTasks = 0;
            this.completedTasks = 0;
            this.pendingTasks = 0;
        }
    }

    @InvocableMethod(
        label='Visit Activity Handler'
        description='Dispatches self-contained Visit Activity and Assessment Task actions for Visit Intelligence agents.'
    )
    global static List<Response> execute(List<Request> requests) {
        List<Response> results = new List<Response>();

        for (Request req : requests) {
            Response res = new Response();
            try {
                String action = req.actionType != null ? req.actionType.toLowerCase().trim() : '';

                if (action == 'getassessmenttasks' || action == 'get_assessment_tasks' || action == 'getactivities' || action == 'get_activities') {
                    res = handleGetActivities(req.visitId, req.questionOrSurveyFilter);
                } else if (action == 'getjobsstatus' || action == 'get_jobs_status') {
                    res = handleGetJobsStatus(req.visitId, req.statusFilter, req.questionOrSurveyFilter);
                } else if (action == 'getdeliveryactivities' || action == 'get_delivery_activities' || action == 'getdeliveries') {
                    res = handleGetDeliveryActivities(req.visitId);
                } else if (action == 'getnextsteps' || action == 'get_next_steps') {
                    res = handleGetNextSteps(req.visitId);
                } else {
                    res.success = false;
                    res.message = 'Unknown Activity action type: ' + req.actionType;
                    res.summary = 'The requested action "' + req.actionType + '" is not supported.';
                }
            } catch (Exception e) {
                res.success = false;
                res.message = 'Error executing activity action: ' + e.getMessage();
                res.summary = 'An error occurred while processing activity request: ' + e.getMessage();
            }
            results.add(res);
        }
        return results;
    }

    // =========================================================================
    // INLINED DOMAIN LOGIC: VISIT ACTIVITIES & QUESTIONS (No external helper calls)
    // =========================================================================

    private static Response handleGetActivities(String visitId, String typeFilter) {
        Response res = new Response();
        if (String.isBlank(visitId)) {
            res.success = false;
            res.message = 'Visit ID is required.';
            res.summary = 'Please provide a valid Visit ID to view activities.';
            return res;
        }

        Boolean hasCgVisit = Schema.getGlobalDescribe().containsKey('cgcloud__visit_template__c');
        Boolean hasVisit = Schema.getGlobalDescribe().containsKey('visit');

        if (hasVisit && hasCgVisit) {
            try {
                List<Visit> visits = [
                    SELECT Id, Name, cgcloud__Visit_Template__c, cgcloud__Visit_Template__r.Name, AccountId, Account.Name
                      FROM Visit
                     WHERE Id = :visitId
                     LIMIT 1
                ];

                if (!visits.isEmpty() && visits[0].cgcloud__Visit_Template__c != null) {
                    Visit v = visits[0];
                    Id visitTemplateId = v.cgcloud__Visit_Template__c;
                    Id visitAccountId = v.AccountId;

                    // Direct Account-specific JDL inclusions and exclusions
                    Set<Id> includedDirectJdlIds = new Set<Id>();
                    Set<Id> excludedDirectJdlIds = new Set<Id>();
                    Set<Id> includedSetJdlIds = new Set<Id>();

                    if (visitAccountId != null) {
                        for (cgcloud__Job_Definition_List_Account__c jda : [
                            SELECT cgcloud__Job_Definition_List__c, cgcloud__Excluded__c
                              FROM cgcloud__Job_Definition_List_Account__c
                             WHERE cgcloud__Account__c = :visitAccountId
                        ]) {
                            if (jda.cgcloud__Excluded__c == true) {
                                excludedDirectJdlIds.add(jda.cgcloud__Job_Definition_List__c);
                            } else {
                                includedDirectJdlIds.add(jda.cgcloud__Job_Definition_List__c);
                            }
                        }

                        Set<Id> accountSetIds = new Set<Id>();
                        for (cgcloud__Account_Set_Account__c csa : [
                            SELECT cgcloud__Account_Set__c
                              FROM cgcloud__Account_Set_Account__c
                             WHERE cgcloud__Account_Set_Account__c = :visitAccountId
                        ]) {
                            if (csa.cgcloud__Account_Set__c != null) {
                                accountSetIds.add(csa.cgcloud__Account_Set__c);
                            }
                        }

                        if (!accountSetIds.isEmpty()) {
                            for (cgcloud__Job_Definition_List_Account_Set__c jds : [
                                SELECT cgcloud__Job_Definition_List__c
                                  FROM cgcloud__Job_Definition_List_Account_Set__c
                                 WHERE cgcloud__Account_Set__c IN :accountSetIds
                            ]) {
                                includedSetJdlIds.add(jds.cgcloud__Job_Definition_List__c);
                            }
                        }
                    }

                    String resolvedType = String.isNotBlank(typeFilter) ? typeFilter.toLowerCase().trim() : 'all';

                    String linksQuery = 'SELECT cgcloud__Job_Definition_List__c FROM cgcloud__Job_DL_Job_Definition_Template__c WHERE cgcloud__Job_Definition_List__r.cgcloud__Visit_Template__c = :visitTemplateId AND cgcloud__Job_Definition_List__r.cgcloud__Active__c = true';
                    if (resolvedType == 'question' || resolvedType == 'questions') {
                        linksQuery += ' AND cgcloud__Job_Definition_Template__r.cgcloud__Job_Template__r.Name = \'Question\'';
                    } else if (resolvedType == 'survey' || resolvedType == 'surveys') {
                        linksQuery += ' AND cgcloud__Job_Definition_Template__r.cgcloud__Job_Template__r.Name = \'Survey\'';
                    }
                    List<cgcloud__Job_DL_Job_Definition_Template__c> links = Database.query(linksQuery);
                    Set<Id> candidateJdlIds = new Set<Id>();
                    for (cgcloud__Job_DL_Job_Definition_Template__c link : links) {
                        candidateJdlIds.add(link.cgcloud__Job_Definition_List__c);
                    }

                    Set<Id> activeJdlIds = new Set<Id>();
                    if (!candidateJdlIds.isEmpty()) {
                        for (cgcloud__Job_Definition_List__c jdl : [
                            SELECT Id, cgcloud__Consider_Account__c
                              FROM cgcloud__Job_Definition_List__c
                             WHERE Id IN :candidateJdlIds
                        ]) {
                            if (jdl.cgcloud__Consider_Account__c == false) {
                                activeJdlIds.add(jdl.Id);
                            } else {
                                if (excludedDirectJdlIds.contains(jdl.Id)) { continue; }
                                if (includedDirectJdlIds.contains(jdl.Id) || includedSetJdlIds.contains(jdl.Id)) {
                                    activeJdlIds.add(jdl.Id);
                                }
                            }
                        }
                    }

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
                        'cgcloud__Job_Definition_Template__r.cgcloud__Job_Template__r.Name, ' +
                        'cgcloud__Mandatory__c FROM cgcloud__Job_Definition_Links__r' + subqueryFilter + ') ' +
                        'FROM cgcloud__Job_Definition_List__c WHERE Id IN :activeJdlIds';

                    List<cgcloud__Job_Definition_List__c> jdls = Database.query(jdlQueryStr);

                    if (!jdls.isEmpty()) {
                        Integer totalQ = 0;
                        String sb = '### 📝 Planned Activities for ' + (v.Account != null ? v.Account.Name : 'Visit') + ':\n\n';

                        for (cgcloud__Job_Definition_List__c jdl : jdls) {
                            String actName = jdl.cgcloud__Field_Sales_Activity__c != null ? jdl.cgcloud__Field_Sales_Activity__r.Name : jdl.Name;
                            sb += '#### 🎯 Activity: ' + actName + '\n\n';

                            List<cgcloud__Job_DL_Job_Definition_Template__c> qList = new List<cgcloud__Job_DL_Job_Definition_Template__c>();
                            List<cgcloud__Job_DL_Job_Definition_Template__c> sList = new List<cgcloud__Job_DL_Job_Definition_Template__c>();

                            if (jdl.cgcloud__Job_Definition_Links__r != null) {
                                for (cgcloud__Job_DL_Job_Definition_Template__c linkItem : jdl.cgcloud__Job_Definition_Links__r) {
                                    String jobTypeName = (linkItem.cgcloud__Job_Definition_Template__r != null && linkItem.cgcloud__Job_Definition_Template__r.cgcloud__Job_Template__r != null) ? linkItem.cgcloud__Job_Definition_Template__r.cgcloud__Job_Template__r.Name : 'Question';
                                    if (jobTypeName == 'Survey') {
                                        sList.add(linkItem);
                                    } else {
                                        qList.add(linkItem);
                                    }
                                }
                            }

                            if (!qList.isEmpty()) {
                                sb += '##### Questions\n';
                                sb += '| 📝 Question | ⚠️ Mandatory? |\n';
                                sb += '|---|---|\n';
                                for (cgcloud__Job_DL_Job_Definition_Template__c q : qList) {
                                    totalQ++;
                                    String qName = q.cgcloud__Job_Definition_Template__r != null ? q.cgcloud__Job_Definition_Template__r.Name : q.Name;
                                    sb += '| ' + qName + ' | ' + (q.cgcloud__Mandatory__c == true ? 'Yes ⚠️' : 'No') + ' |\n';
                                }
                                sb += '\n';
                            }

                            if (!sList.isEmpty()) {
                                sb += '##### Surveys\n';
                                sb += '| 📝 Survey | ⚠️ Mandatory? |\n';
                                sb += '|---|---|\n';
                                for (cgcloud__Job_DL_Job_Definition_Template__c s : sList) {
                                    totalQ++;
                                    String sName = s.cgcloud__Job_Definition_Template__r != null ? s.cgcloud__Job_Definition_Template__r.Name : s.Name;
                                    sb += '| ' + sName + ' | ' + (s.cgcloud__Mandatory__c == true ? 'Yes ⚠️' : 'No') + ' |\n';
                                }
                                sb += '\n';
                            }
                        }

                        res.totalTasks = totalQ;
                        res.pendingTasks = totalQ;
                        res.completedTasks = 0;
                        res.success = true;
                        res.message = 'Retrieved ' + jdls.size() + ' planned activities with ' + totalQ + ' items.';
                        res.summary = sb;
                        return res;
                    }
                }
            } catch (Exception e) {
                // fall through
            }
        }

        // Fallback: Check cgcloud__Visit_Job__c directly
        if (Schema.getGlobalDescribe().containsKey('cgcloud__visit_job__c')) {
            try {
                List<cgcloud__Visit_Job__c> jobs = [
                    SELECT Id, Name, cgcloud__Job_Definition_Template__r.Name, cgcloud__Job_Definition_Template_Description__c,
                           cgcloud__Done__c, cgcloud__Value__c, cgcloud__Display_Value__c,
                           cgcloud__Job_Definition_Template__r.cgcloud__Job_Template__r.Name
                      FROM cgcloud__Visit_Job__c
                     WHERE cgcloud__Visit__c = :visitId
                     LIMIT 50
                ];
                if (!jobs.isEmpty()) {
                    String sb = '### 📝 Planned Activities & Jobs (' + jobs.size() + ' found):\n\n';
                    sb += '| 📝 Activity / Job | 🏷️ Description | ✅ Done? |\n';
                    sb += '|---|---|---|\n';
                    Integer doneCount = 0;
                    for (cgcloud__Visit_Job__c j : jobs) {
                        String jName = j.cgcloud__Job_Definition_Template__r != null ? j.cgcloud__Job_Definition_Template__r.Name : j.Name;
                        String descText = String.isNotBlank(j.cgcloud__Job_Definition_Template_Description__c) ? j.cgcloud__Job_Definition_Template_Description__c : '-';
                        Boolean isDone = j.cgcloud__Done__c == true || String.isNotBlank(j.cgcloud__Value__c);
                        if (isDone) doneCount++;
                        sb += '| ' + jName + ' | ' + descText + ' | ' + (isDone ? 'Yes' : 'No') + ' |\n';
                    }
                    res.totalTasks = jobs.size();
                    res.completedTasks = doneCount;
                    res.pendingTasks = jobs.size() - doneCount;
                    res.success = true;
                    res.message = 'Retrieved ' + jobs.size() + ' Visit Job(s).';
                    res.summary = sb;
                    return res;
                }
            } catch (Exception e) {
                // fall through
            }
        }

        // Fallback: Standard AssessmentTask
        return handleGetAssessmentTasks(visitId, null);
    }

    private static Response handleGetJobsStatus(String visitId, String statusFilter, String typeFilter) {
        Response res = new Response();
        if (String.isBlank(visitId)) {
            res.success = false;
            res.message = 'Visit ID is required.';
            res.summary = 'Please provide a valid Visit ID to check status.';
            return res;
        }

        Boolean hasCgVisit = Schema.getGlobalDescribe().containsKey('cgcloud__visit_template__c');
        Boolean hasVisit = Schema.getGlobalDescribe().containsKey('visit');

        if (hasVisit && hasCgVisit) {
            try {
                List<Visit> visits = [
                    SELECT Id, cgcloud__Visit_Template__c, AccountId, Account.Name
                      FROM Visit
                     WHERE Id = :visitId
                     LIMIT 1
                ];

                if (!visits.isEmpty()) {
                    Visit v = visits[0];
                    Id visitTemplateId = v.cgcloud__Visit_Template__c;
                    String resolvedType = String.isNotBlank(typeFilter) ? typeFilter.toLowerCase().trim() : 'all';

                    // 1. Query planned template questions from JDL
                    Map<Id, cgcloud__Job_DL_Job_Definition_Template__c> plannedMap = new Map<Id, cgcloud__Job_DL_Job_Definition_Template__c>();
                    if (visitTemplateId != null) {
                        String plannedQueryStr = 'SELECT cgcloud__Job_Definition_Template__c, cgcloud__Job_Definition_Template__r.Name, cgcloud__Job_Definition_Template__r.cgcloud__Job_Template__r.Name, cgcloud__Job_Definition_Template__r.cgcloud__Description__c, cgcloud__Mandatory__c FROM cgcloud__Job_DL_Job_Definition_Template__c WHERE cgcloud__Job_Definition_List__r.cgcloud__Visit_Template__c = :visitTemplateId AND cgcloud__Job_Definition_List__r.cgcloud__Active__c = true';
                        if (resolvedType == 'question' || resolvedType == 'questions') {
                            plannedQueryStr += ' AND cgcloud__Job_Definition_Template__r.cgcloud__Job_Template__r.Name = \'Question\'';
                        } else if (resolvedType == 'survey' || resolvedType == 'surveys') {
                            plannedQueryStr += ' AND cgcloud__Job_Definition_Template__r.cgcloud__Job_Template__r.Name = \'Survey\'';
                        }

                        for (cgcloud__Job_DL_Job_Definition_Template__c planned : (List<cgcloud__Job_DL_Job_Definition_Template__c>) Database.query(plannedQueryStr)) {
                            plannedMap.put(planned.cgcloud__Job_Definition_Template__c, planned);
                        }
                    }

                    // 2. Query actual jobs from cgcloud__Visit_Job__c
                    String jobQueryStr = 'SELECT Id, Name, cgcloud__Job_Definition_Template__c, cgcloud__Job_Definition_Template__r.Name, cgcloud__Job_Definition_Template__r.cgcloud__Job_Template__r.Name, cgcloud__Job_Definition_Template_Description__c, cgcloud__Done__c, cgcloud__Value__c, cgcloud__Display_Value__c, cgcloud__Product__r.Name, cgcloud__Promotion__r.Name FROM cgcloud__Visit_Job__c WHERE cgcloud__Visit__c = :visitId';
                    if (resolvedType == 'question' || resolvedType == 'questions') {
                        jobQueryStr += ' AND cgcloud__Job_Definition_Template__r.cgcloud__Job_Template__r.Name = \'Question\'';
                    } else if (resolvedType == 'survey' || resolvedType == 'surveys') {
                        jobQueryStr += ' AND cgcloud__Job_Definition_Template__r.cgcloud__Job_Template__r.Name = \'Survey\'';
                    }
                    List<cgcloud__Visit_Job__c> actualJobs = Database.query(jobQueryStr);

                    Set<Id> actualJdtIds = new Set<Id>();
                    Integer answeredCount = 0;
                    Integer pendingCount = 0;

                    List<String> questionRows = new List<String>();
                    List<String> surveyRows = new List<String>();

                    for (cgcloud__Visit_Job__c job : actualJobs) {
                        if (job.cgcloud__Job_Definition_Template__c != null) {
                            actualJdtIds.add(job.cgcloud__Job_Definition_Template__c);
                        }
                        Boolean isDone = (job.cgcloud__Done__c == true || String.isNotBlank(job.cgcloud__Value__c));
                        if (isDone) {
                            answeredCount++;
                        } else {
                            pendingCount++;
                        }

                        String jName = job.cgcloud__Job_Definition_Template__r != null ? job.cgcloud__Job_Definition_Template__r.Name : job.Name;
                        String descText = String.isNotBlank(job.cgcloud__Job_Definition_Template_Description__c) ? job.cgcloud__Job_Definition_Template_Description__c : '-';
                        String valText = String.isNotBlank(job.cgcloud__Display_Value__c) ? job.cgcloud__Display_Value__c : (String.isNotBlank(job.cgcloud__Value__c) ? job.cgcloud__Value__c : (isDone ? 'Completed' : 'Pending'));
                        String jType = (job.cgcloud__Job_Definition_Template__r != null && job.cgcloud__Job_Definition_Template__r.cgcloud__Job_Template__r != null) ? job.cgcloud__Job_Definition_Template__r.cgcloud__Job_Template__r.Name : 'Question';

                        if (jType == 'Survey') {
                            surveyRows.add('| ' + jName + ' | ' + (isDone ? '1 / 1' : '0 / 1') + ' | ' + (isDone ? '100%' : '0%') + ' |');
                        } else {
                            questionRows.add('| ' + jName + ' | ' + descText + ' | ' + (isDone ? 'Yes' : 'No') + ' | ' + valText + ' |');
                        }
                    }

                    // Add planned template questions that have not yet been answered as pending
                    for (Id tId : plannedMap.keySet()) {
                        if (!actualJdtIds.contains(tId)) {
                            pendingCount++;
                            cgcloud__Job_DL_Job_Definition_Template__c planned = plannedMap.get(tId);
                            String qName = planned.cgcloud__Job_Definition_Template__r != null ? planned.cgcloud__Job_Definition_Template__r.Name : planned.Name;
                            String descText = planned.cgcloud__Job_Definition_Template__r != null && String.isNotBlank(planned.cgcloud__Job_Definition_Template__r.cgcloud__Description__c) ? planned.cgcloud__Job_Definition_Template__r.cgcloud__Description__c : '-';
                            String jType = (planned.cgcloud__Job_Definition_Template__r != null && planned.cgcloud__Job_Definition_Template__r.cgcloud__Job_Template__r != null) ? planned.cgcloud__Job_Definition_Template__r.cgcloud__Job_Template__r.Name : 'Question';

                            if (jType == 'Survey') {
                                surveyRows.add('| ' + qName + ' | 0 / 1 | 0% |');
                            } else {
                                questionRows.add('| ' + qName + ' | ' + descText + ' | No | Pending |');
                            }
                        }
                    }

                    Integer totalCount = answeredCount + pendingCount;
                    if (totalCount > 0) {
                        String sb = '### 📝 Questions & Surveys Status for ' + (v.Account != null ? v.Account.Name : 'Visit') + ':\n\n';

                        if (!questionRows.isEmpty()) {
                            sb += '#### Questions Status\n';
                            sb += '| 📝 Question | 🏷️ Description | ✅ Answered? | 💬 Value / Answer |\n';
                            sb += '|---|---|---|---|\n';
                            for (String r : questionRows) {
                                sb += r + '\n';
                            }
                            sb += '\n';
                        }

                        if (!surveyRows.isEmpty()) {
                            sb += '#### Surveys Status\n';
                            sb += '| 📝 Survey | 📦 Products Checked / Total | 📊 Progress |\n';
                            sb += '|---|---|---|\n';
                            for (String r : surveyRows) {
                                sb += r + '\n';
                            }
                            sb += '\n';
                        }

                        sb += 'Summary:\n';
                        sb += '- Total Questions: ' + totalCount + '\n';
                        sb += '- ✅ Answered: ' + answeredCount + '\n';
                        sb += '- ⏳ Pending: ' + pendingCount + '\n';

                        res.totalTasks = totalCount;
                        res.completedTasks = answeredCount;
                        res.pendingTasks = pendingCount;
                        res.success = true;
                        res.message = 'Retrieved status for ' + totalCount + ' question(s) and survey(s).';
                        res.summary = sb;
                        return res;
                    }
                }
            } catch (Exception e) {
                // fall through
            }
        }

        // Fallback: Standard AssessmentTask status
        return handleGetAssessmentTasks(visitId, statusFilter);
    }

    private static Response handleGetAssessmentTasks(String visitId, String statusFilter) {
        Response res = new Response();
        if (String.isBlank(visitId)) {
            res.success = false;
            res.message = 'Visit ID is required.';
            res.summary = 'Please provide a valid Visit ID to view assessment tasks.';
            return res;
        }

        Boolean hasAssessmentTask = Schema.getGlobalDescribe().containsKey('assessmenttask');
        if (!hasAssessmentTask) {
            res.success = true;
            res.message = 'No AssessmentTask schema installed.';
            res.summary = 'There are no planned activities, questions, or surveys for this visit.';
            return res;
        }

        String soql = 'SELECT Id, Name, TaskType, Status, Description, StartTime, EndTime FROM AssessmentTask WHERE ParentId = :visitId';
        if (String.isNotBlank(statusFilter)) {
            soql += ' AND Status = :statusFilter';
        }
        soql += ' ORDER BY CreatedDate ASC LIMIT 25';

        List<SObject> taskList = Database.query(soql);
        res.totalTasks = taskList.size();

        Integer completed = 0;
        Integer pending = 0;

        String sb = '### Visit Assessment Tasks (' + taskList.size() + ' found):\n\n';
        for (SObject t : taskList) {
            String tId = (String) t.get('Id');
            String tName = (String) t.get('Name');
            String taskType = (String) t.get('TaskType');
            String status = (String) t.get('Status');

            if (status == 'Completed') {
                completed++;
                sb += '* ✅ **[' + tName + '](/lightning/r/AssessmentTask/' + tId + '/view)** | Type: ' + (taskType != null ? taskType : 'General') + ' | Status: Completed\n';
            } else {
                pending++;
                sb += '* ⏳ **[' + tName + '](/lightning/r/AssessmentTask/' + tId + '/view)** | Type: ' + (taskType != null ? taskType : 'General') + ' | Status: ' + (status != null ? status : 'Pending') + '\n';
            }
        }

        if (taskList.isEmpty()) {
            sb = 'There are no planned activities, questions, or surveys for this visit.';
        }

        res.completedTasks = completed;
        res.pendingTasks = pending;
        res.success = true;
        res.message = 'Retrieved ' + taskList.size() + ' Assessment Task(s). Completed: ' + completed + ', Pending: ' + pending;
        res.summary = sb;
        return res;
    }

    private static Response handleGetDeliveryActivities(String visitId) {
        Response res = new Response();
        if (String.isBlank(visitId)) {
            res.success = false;
            res.message = 'Visit ID is required.';
            res.summary = 'Please provide a Visit ID to check delivery activities.';
            return res;
        }

        Boolean hasDelivery = Schema.getGlobalDescribe().containsKey('cgcloud__delivery_task__c');
        if (!hasDelivery) {
            res.success = true;
            res.message = 'No delivery tasks found.';
            res.summary = 'No special delivery tasks are logged for this Visit.';
            return res;
        }

        String soql = 'SELECT Id, Name, cgcloud__Status__c, cgcloud__Delivery_Note__c FROM cgcloud__Delivery_Task__c WHERE cgcloud__Visit__c = :visitId LIMIT 10';
        List<SObject> delList = Database.query(soql);

        if (delList.isEmpty()) {
            res.success = true;
            res.message = 'No delivery tasks for this visit.';
            res.summary = 'No scheduled delivery tasks found for this Visit.';
            return res;
        }

        String sb = '### Scheduled Delivery Tasks (' + delList.size() + ' found):\n\n';
        for (SObject d : delList) {
            String dId = (String) d.get('Id');
            String dName = (String) d.get('Name');
            String st = (String) d.get('cgcloud__Status__c');
            sb += '* **[' + dName + '](/lightning/r/cgcloud__Delivery_Task__c/' + dId + '/view)** | Status: ' + (st != null ? st : 'Pending') + '\n';
        }

        res.success = true;
        res.message = 'Found ' + delList.size() + ' delivery task(s).';
        res.summary = sb;
        return res;
    }

    private static Response handleGetNextSteps(String visitId) {
        Response res = new Response();
        String sb = '### Recommended Next Actions:\n\n';
        sb += '1. **Execute In-Store Audit**: Complete pending shelf inspections and price compliance checks.\n';
        sb += '2. **Review Replenishment Recommendations**: Check recommended order quantities with the store manager.\n';
        sb += '3. **Log Notes & Wrap Up**: Record any customer feedback and update visit status to Completed.\n';

        res.success = true;
        res.message = 'Generated recommended next steps.';
        res.summary = sb;
        return res;
    }
}
