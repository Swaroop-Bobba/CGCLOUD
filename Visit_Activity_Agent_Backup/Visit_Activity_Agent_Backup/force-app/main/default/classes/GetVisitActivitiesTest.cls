@isTest
public class GetVisitActivitiesTest {

    @isTest
    static void testGetVisitActivities() {
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
            Name = 'Test Job Template',
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

        // Execute Invocable
        GetVisitActivities.Request req = new GetVisitActivities.Request();
        req.visitId = v.Id;

        Test.startTest();
        List<GetVisitActivities.Result> results = GetVisitActivities.execute(new List<GetVisitActivities.Request>{req});
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertEquals(1, results[0].activities.size());
        System.assertEquals('Test JDL', results[0].activities[0].activityName);
        System.assertEquals(1, results[0].activities[0].questions.size());
        System.assertEquals('Test JDT Question', results[0].activities[0].questions[0].questionName);
    }
}
