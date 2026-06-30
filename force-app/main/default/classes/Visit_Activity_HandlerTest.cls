@isTest
public class Visit_Activity_HandlerTest {

    @isTest
    static void testAllVisitActivityActions() {
        // Create test Account Template
        cgcloud__Account_Template__c at = new cgcloud__Account_Template__c(
            Name = 'Test Account Template',
            cgcloud__Sales_Org__c = '0001'
        );
        insert at;

        // Create test Account
        Account acc = new Account(
            Name = 'Test Account',
            cgcloud__Account_Template__c = at.Id
        );
        insert acc;

        // Create test Retail Store
        RetailStore store = new RetailStore(
            Name = 'Test Store',
            AccountId = acc.Id
        );
        insert store;

        // Create test Visit Template
        cgcloud__Visit_Template__c vt = new cgcloud__Visit_Template__c(
            Name = 'Test Visit Template',
            cgcloud__Sales_Org__c = '0001'
        );
        insert vt;

        // Create test Visit
        Visit v = new Visit(
            AccountId = acc.Id,
            PlaceId = store.Id,
            cgcloud__Visit_Template__c = vt.Id,
            PlannedVisitStartTime = Datetime.now(),
            Status = 'Planned'
        );
        insert v;

        // Create test Job Definition List Template
        cgcloud__Job_Definition_List_Template__c jdlt = new cgcloud__Job_Definition_List_Template__c(
            Name = 'Test JDL Template',
            cgcloud__Sales_Org__c = '0001'
        );
        insert jdlt;

        // Create test Job Definition List
        cgcloud__Job_Definition_List__c jdl = new cgcloud__Job_Definition_List__c(
            Name = 'Test JDL',
            cgcloud__Visit_Template__c = vt.Id,
            cgcloud__Job_Definition_List_Template__c = jdlt.Id,
            cgcloud__Active__c = true,
            cgcloud__Sales_Org__c = '0001'
        );
        insert jdl;

        // Create Data Type
        cgcloud__Data_Type__c dt = new cgcloud__Data_Type__c(
            Name = 'Toggle',
            cgcloud__Sales_Org__c = '0001'
        );
        insert dt;

        // Create Job Template
        cgcloud__Job_Template__c jt = new cgcloud__Job_Template__c(
            Name = 'Question',
            cgcloud__Sales_Org__c = '0001'
        );
        insert jt;

        // Create Job Definition Template
        cgcloud__Job_Definition_Template__c jdt = new cgcloud__Job_Definition_Template__c(
            Name = 'Test JDT Question',
            cgcloud__Description_Language_1__c = 'Test Description',
            cgcloud__Data_Type__c = dt.Id,
            cgcloud__Job_Template__c = jt.Id,
            cgcloud__Sales_Org__c = '0001'
        );
        insert jdt;

        // Create Link (JDL to JDT)
        cgcloud__Job_DL_Job_Definition_Template__c link = new cgcloud__Job_DL_Job_Definition_Template__c(
            cgcloud__Job_Definition_List__c = jdl.Id,
            cgcloud__Job_Definition_Template__c = jdt.Id,
            cgcloud__Mandatory__c = true,
            cgcloud__Job_Action_Success__c = 'Validation',
            cgcloud__Sales_Org__c = '0001'
        );
        insert link;

        // Create an actual Visit Job record
        cgcloud__Visit_Job__c vj = new cgcloud__Visit_Job__c(
            cgcloud__Visit__c = v.Id,
            cgcloud__Job_Definition_Template__c = jdt.Id,
            cgcloud__Done__c = true,
            cgcloud__Value__c = 'Yes'
        );
        insert vj;

        Test.startTest();

        // 1. Test getAvailable
        Visit_Activity_Handler.Request reqAvailable = new Visit_Activity_Handler.Request();
        reqAvailable.agentName = 'Visit_Activity_Agent';
        reqAvailable.actionType = 'getAvailable';
        List<Visit_Activity_Handler.Result> resAvailable = Visit_Activity_Handler.execute(new List<Visit_Activity_Handler.Request>{reqAvailable});
        System.assert(!resAvailable.isEmpty());

        // 2. Test search
        Visit_Activity_Handler.Request reqSearch = new Visit_Activity_Handler.Request();
        reqSearch.agentName = 'Visit_Activity_Agent';
        reqSearch.actionType = 'search';
        reqSearch.searchQuery = 'Test Store today';
        List<Visit_Activity_Handler.Result> resSearch = Visit_Activity_Handler.execute(new List<Visit_Activity_Handler.Request>{reqSearch});
        System.assert(!resSearch.isEmpty());

        // 3. Test getActivities
        Visit_Activity_Handler.Request reqAct = new Visit_Activity_Handler.Request();
        reqAct.agentName = 'Visit_Activity_Agent';
        reqAct.actionType = 'getActivities';
        reqAct.visitId = v.Id;
        List<Visit_Activity_Handler.Result> resAct = Visit_Activity_Handler.execute(new List<Visit_Activity_Handler.Request>{reqAct});
        System.assertEquals(1, resAct.size());
        System.assertEquals(1, resAct[0].activities.size());
        System.assertEquals('Question', resAct[0].activities[0].questions[0].jobType);

        // 4. Test getJobsStatus
        Visit_Activity_Handler.Request reqJobs = new Visit_Activity_Handler.Request();
        reqJobs.agentName = 'Visit_Activity_Agent';
        reqJobs.actionType = 'getJobsStatus';
        reqJobs.visitId = v.Id;
        reqJobs.statusFilter = 'all';
        List<Visit_Activity_Handler.Result> resJobs = Visit_Activity_Handler.execute(new List<Visit_Activity_Handler.Request>{reqJobs});
        System.assertEquals(1, resJobs.size());
        System.assert(resJobs[0].jobs.size() >= 1);

        // 5. Test getNextSteps
        Visit_Activity_Handler.Request reqSteps = new Visit_Activity_Handler.Request();
        reqSteps.agentName = 'Visit_Activity_Agent';
        reqSteps.actionType = 'getNextSteps';
        reqSteps.excludeOption = 'Switch to another visit';
        List<Visit_Activity_Handler.Result> resSteps = Visit_Activity_Handler.execute(new List<Visit_Activity_Handler.Request>{reqSteps});
        System.assertEquals(1, resSteps.size());
        System.assert(resSteps[0].itemDetails.size() > 0);

        Test.stopTest();
    }
}
