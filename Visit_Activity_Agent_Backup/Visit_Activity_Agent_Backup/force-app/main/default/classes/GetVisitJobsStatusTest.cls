@isTest
public class GetVisitJobsStatusTest {

    @isTest
    static void testGetVisitJobsStatus() {
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

        // Create JDL and JDT to simulate planned templates
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
            Name = 'Test Job Template',
            cgcloud__Sales_Org__c = '0001'
        );
        insert jt;

        cgcloud__Job_Definition_Template__c jdtPlannedOnly = new cgcloud__Job_Definition_Template__c(
            Name = 'Planned Only Question',
            cgcloud__Description_Language_1__c = 'Planned Only Desc',
            cgcloud__Data_Type__c = dt.Id,
            cgcloud__Job_Template__c = jt.Id,
            cgcloud__Sales_Org__c = '0001'
        );
        insert jdtPlannedOnly;

        cgcloud__Job_DL_Job_Definition_Template__c linkPlannedOnly = new cgcloud__Job_DL_Job_Definition_Template__c(
            cgcloud__Job_Definition_List__c = jdl.Id,
            cgcloud__Job_Definition_Template__c = jdtPlannedOnly.Id,
            cgcloud__Sales_Org__c = '0001'
        );
        insert linkPlannedOnly;

        cgcloud__Job_Definition_Template__c jdtAnswered = new cgcloud__Job_Definition_Template__c(
            Name = 'Answered Question',
            cgcloud__Description_Language_1__c = 'Answered Desc',
            cgcloud__Data_Type__c = dt.Id,
            cgcloud__Job_Template__c = jt.Id,
            cgcloud__Sales_Org__c = '0001'
        );
        insert jdtAnswered;

        cgcloud__Job_DL_Job_Definition_Template__c linkAnswered = new cgcloud__Job_DL_Job_Definition_Template__c(
            cgcloud__Job_Definition_List__c = jdl.Id,
            cgcloud__Job_Definition_Template__c = jdtAnswered.Id,
            cgcloud__Sales_Org__c = '0001'
        );
        insert linkAnswered;

        // Create an answered Visit Job
        cgcloud__Visit_Job__c vjAnswered = new cgcloud__Visit_Job__c(
            cgcloud__Visit__c = v.Id,
            cgcloud__Job_Definition_Template__c = jdtAnswered.Id,
            cgcloud__Done__c = true,
            cgcloud__Value__c = 'Yes'
        );
        insert vjAnswered;

        // Create an unanswered/pending actual Visit Job
        cgcloud__Job_Definition_Template__c jdtPendingActual = new cgcloud__Job_Definition_Template__c(
            Name = 'Pending Actual Question',
            cgcloud__Description_Language_1__c = 'Pending Actual Desc',
            cgcloud__Data_Type__c = dt.Id,
            cgcloud__Job_Template__c = jt.Id,
            cgcloud__Sales_Org__c = '0001'
        );
        insert jdtPendingActual;

        cgcloud__Job_DL_Job_Definition_Template__c linkPendingActual = new cgcloud__Job_DL_Job_Definition_Template__c(
            cgcloud__Job_Definition_List__c = jdl.Id,
            cgcloud__Job_Definition_Template__c = jdtPendingActual.Id,
            cgcloud__Sales_Org__c = '0001'
        );
        insert linkPendingActual;

        cgcloud__Visit_Job__c vjPending = new cgcloud__Visit_Job__c(
            cgcloud__Visit__c = v.Id,
            cgcloud__Job_Definition_Template__c = jdtPendingActual.Id,
            cgcloud__Done__c = false,
            cgcloud__Value__c = ''
        );
        insert vjPending;

        // Test with Status Filter: answered
        GetVisitJobsStatus.Request reqAnswered = new GetVisitJobsStatus.Request();
        reqAnswered.visitId = v.Id;
        reqAnswered.statusFilter = 'answered';

        // Test with Status Filter: pending
        GetVisitJobsStatus.Request reqPending = new GetVisitJobsStatus.Request();
        reqPending.visitId = v.Id;
        reqPending.statusFilter = 'pending';

        // Test with Status Filter: all
        GetVisitJobsStatus.Request reqAll = new GetVisitJobsStatus.Request();
        reqAll.visitId = v.Id;
        reqAll.statusFilter = 'all';

        Test.startTest();
        List<GetVisitJobsStatus.Result> resAnsweredList = GetVisitJobsStatus.execute(new List<GetVisitJobsStatus.Request>{reqAnswered});
        List<GetVisitJobsStatus.Result> resPendingList = GetVisitJobsStatus.execute(new List<GetVisitJobsStatus.Request>{reqPending});
        List<GetVisitJobsStatus.Result> resAllList = GetVisitJobsStatus.execute(new List<GetVisitJobsStatus.Request>{reqAll});
        Test.stopTest();

        // Verify Answered
        System.assertEquals(1, resAnsweredList.size());
        System.assertEquals(1, resAnsweredList[0].jobs.size(), 'Should have 1 answered job');
        System.assertEquals('Answered Question', resAnsweredList[0].jobs[0].questionName);
        System.assertEquals(true, resAnsweredList[0].jobs[0].isDone);

        // Verify Pending
        System.assertEquals(1, resPendingList.size());
        // Should have 2 pending jobs: vjPending (pending actual job) and jdtPlannedOnly (planned template with no actual jobs)
        System.assertEquals(2, resPendingList[0].jobs.size(), 'Should have 2 pending jobs');
        
        Set<String> pendingNames = new Set<String>();
        for (GetVisitJobsStatus.JobStatusInfo info : resPendingList[0].jobs) {
            pendingNames.add(info.questionName);
            System.assertEquals(false, info.isDone);
        }
        System.assert(pendingNames.contains('Pending Actual Question'), 'Should contain Pending Actual Question');
        System.assert(pendingNames.contains('Planned Only Question'), 'Should contain Planned Only Question');

        // Verify All
        System.assertEquals(1, resAllList.size());
        System.assertEquals(3, resAllList[0].jobs.size(), 'Should have 3 total jobs');
    }
}
