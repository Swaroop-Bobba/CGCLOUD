/**
 * @description Unit test class for Agent_Response constructors, properties, and inner classes.
 */
@IsTest
public class Agent_ResponseTest {

    @IsTest
    static void testAgentResponseConstructorsAndInnerClasses() {
        Agent_Response res = new Agent_Response();
        res.success = true;
        res.message = 'Success';
        res.profileName = 'System Administrator';
        res.accountId = '001000000000000AAA';
        res.accountName = 'Test Account';
        res.visitId = '07VD00000000000AAA';
        res.orderId = 'a2M000000000000AAA';
        res.orderName = 'ORD-001';
        res.placeId = '13D000000000000AAA';
        res.placeName = 'Test Location';
        res.templateId = '01p000000000000AAA';
        res.templateName = 'Test Template';
        res.summary = 'Summary';
        res.visitSummary = 'Visit Summary';
        res.visitStatus = 'Planned';
        res.visitDate = '2026-08-05';
        res.visitEndDate = '2026-08-05';
        res.accountableUser = 'User A';
        res.assignedUser = 'User B';
        res.plannedStartTimeStr = '2026-08-05T10:00:00Z';
        res.suggestions = '[]';
        res.isSubmitted = true;
        res.ownerId = '005000000000000AAA';
        res.ownerName = 'Owner User';

        // Inner classes testing
        Agent_Response.UserOption uOpt = new Agent_Response.UserOption();
        uOpt.userId = '005000000000000AAA';
        uOpt.name = 'Test User';
        uOpt.alias = 'tuser';
        uOpt.profileName = 'Admin';

        Agent_Response.VisitOption vOpt1 = new Agent_Response.VisitOption();
        Agent_Response.VisitOption vOpt2 = new Agent_Response.VisitOption('vis1', 'acc1', 'Acc Name', 'Label');
        Agent_Response.VisitOption vOpt3 = new Agent_Response.VisitOption('vis1', 'acc1', 'Acc Name', 'Label', 'Category');

        Agent_Response.OrderOption oOpt1 = new Agent_Response.OrderOption();
        Agent_Response.OrderOption oOpt2 = new Agent_Response.OrderOption('ord1', 'ORD-1', 'acc1', 'Acc Name', 'Label');

        Agent_Response.AccountOption aOpt = new Agent_Response.AccountOption('acc1', 'Acc Name', 'Label');

        Agent_Response.OrderItem item = new Agent_Response.OrderItem();
        item.productName = 'Soda';
        item.quantity = 10;
        item.uom = 'PCE';

        Agent_Response.RecordInfo rec = new Agent_Response.RecordInfo('Title', 'Status', 'Owner', DateTime.now());
        Agent_Response.RecordInfo rec2 = new Agent_Response.RecordInfo('Title', 'Status', 'Owner', DateTime.now(), 'Label');

        Agent_Response.ActivityInfo act = new Agent_Response.ActivityInfo();
        act.activityId = 'act1';
        act.activityName = 'Title';
        act.description = 'Desc';

        Agent_Response.QuestionInfo qInfo = new Agent_Response.QuestionInfo();
        qInfo.questionId = 'q1';
        qInfo.questionName = 'Q Name';
        qInfo.description = 'Desc';
        qInfo.mandatory = true;
        qInfo.jobType = 'Question';
        act.questions = new List<Agent_Response.QuestionInfo>{ qInfo };

        Agent_Response.JobStatusInfo job = new Agent_Response.JobStatusInfo();
        job.jobId = 'job1';
        job.questionName = 'Title';
        job.questionDescription = 'Desc';
        job.isDone = true;
        job.value = 'Ans';
        job.displayValue = 'Ans Display';

        Agent_Response.ItemDetail det1 = new Agent_Response.ItemDetail();
        Agent_Response.ItemDetail det2 = new Agent_Response.ItemDetail('Item', 'Desc');
        det1.itemName = 'det1';
        det1.itemDescriptionText = 'Label';

        Agent_Response.StaleVisitInfo stale = new Agent_Response.StaleVisitInfo();
        stale.visitId = 'vis1';
        stale.visitName = 'V-001';
        stale.accountName = 'Acc';
        stale.status = 'Planned';
        stale.responsibleRepName = 'Rep';
        stale.responsibleRepId = '005000000000000AAA';
        stale.plannedStartTime = DateTime.now();
        stale.createdDate = DateTime.now();

        Assert.isTrue(res.success, 'Agent_Response properties initialized correctly.');
        Assert.isNotNull(vOpt3.visitId, 'VisitOption initialized correctly.');
        Assert.isNotNull(oOpt2.orderId, 'OrderOption initialized correctly.');
        Assert.isNotNull(item.productName, 'OrderItem initialized correctly.');
    }
}
