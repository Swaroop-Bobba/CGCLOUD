/**
 * @description Test class for VisitUpdaterController and VisitUpdaterAction.
 */
@IsTest
public class VisitUpdaterControllerTest {

    @IsTest
    static void testControllerMethods() {
        // Setup Account and Visit
        Account acc = new Account(Name = 'Test Controller Account');
        insert as user acc;

        Schema.Location loc = new Schema.Location(Name = 'Test Place');
        insert as user loc;

        Visit vis = new Visit(
            AccountId = acc.Id,
            PlaceId = loc.Id,
            Status = 'Planned',
            PlannedVisitStartTime = DateTime.now().addDays(1),
            PlannedVisitEndTime = DateTime.now().addDays(1).addHours(1)
        );
        insert as user vis;

        Test.startTest();
        List<VisitUpdaterController.VisitOptionWrapper> options = VisitUpdaterController.getAvailableVisits();
        VisitUpdaterController.VisitOptionWrapper details = VisitUpdaterController.getVisitDetails(vis.Id);
        String recentId = VisitUpdaterController.getMostRecentVisitId();
        List<VisitUpdaterController.UserOption> activeUsers = VisitUpdaterController.getActiveUsers();
        
        // Execute JSON update
        String updatesJson = '{"Status":"InProgress","cgcloud__Note__c":"Rep is in store","cgcloud__Subject__c":"Urgent Check"}';
        VisitUpdaterController.updateVisitRecord(vis.Id, updatesJson);
        
        // Load details again to assert changes
        VisitUpdaterController.VisitOptionWrapper updatedDetails = VisitUpdaterController.getVisitDetails(vis.Id);
        Test.stopTest();

        Assert.isNotNull(options, 'Options list should not be null.');
        Assert.isNotNull(details, 'Details wrapper should be returned.');
        Assert.areEqual(vis.Id, details.visitId, 'Correct visit loaded.');
        Assert.isNotNull(activeUsers, 'Active users list should be returned.');
        
        Assert.isNotNull(updatedDetails, 'Updated details wrapper should not be null.');
        Assert.areEqual('InProgress', updatedDetails.status, 'Status changed to InProgress.');
        Assert.areEqual('Rep is in store', updatedDetails.notes, 'Notes updated.');
        Assert.areEqual('Urgent Check', updatedDetails.subject, 'Subject updated.');
    }

    @IsTest
    static void testActionExecuteUpdate() {
        Account acc = new Account(Name = 'Test Action Account');
        insert as user acc;

        Schema.Location loc = new Schema.Location(Name = 'Test Action Place');
        insert as user loc;

        Visit vis = new Visit(
            AccountId = acc.Id,
            PlaceId = loc.Id,
            Status = 'Planned',
            PlannedVisitStartTime = DateTime.now().addDays(2)
        );
        insert as user vis;

        Test.startTest();
        VisitUpdaterAction.Request req = new VisitUpdaterAction.Request();
        req.visitId = vis.Id;
        req.updatesPayload = new VisitUpdatePayload();
        req.updatesPayload.visitId = vis.Id;
        req.updatesPayload.updatesJson = '{"Status":"Completed","cgcloud__Note__c":"Completed successfully"}';
        
        List<VisitUpdaterAction.Response> responses = VisitUpdaterAction.executeUpdate(new List<VisitUpdaterAction.Request>{ req });
        
        // Test empty/cancelled updatesJson
        VisitUpdaterAction.Request reqCancel = new VisitUpdaterAction.Request();
        reqCancel.visitId = vis.Id;
        reqCancel.updatesPayload = new VisitUpdatePayload();
        reqCancel.updatesPayload.visitId = vis.Id;
        reqCancel.updatesPayload.updatesJson = '{}';
        
        List<VisitUpdaterAction.Response> responsesCancel = VisitUpdaterAction.executeUpdate(new List<VisitUpdaterAction.Request>{ reqCancel });
        Test.stopTest();

        Assert.isNotNull(responses, 'Response list should not be null.');
        Assert.areEqual(1, responses.size(), 'Response list size is 1.');
        Assert.isTrue(responses[0].success, 'Keep success flag check.');
        Assert.isTrue(responses[0].message.contains('Successfully updated visit'), 'Success message contains confirmation.');

        Visit verifiedVis = [SELECT Status, cgcloud__Note__c FROM Visit WHERE Id = :vis.Id LIMIT 1];
        Assert.areEqual('Completed', verifiedVis.Status, 'Visit status was updated to Completed via action.');
        Assert.areEqual('Completed successfully', verifiedVis.cgcloud__Note__c, 'Notes were updated.');

        Assert.isNotNull(responsesCancel, 'Cancelled response list should not be null.');
        Assert.isTrue(responsesCancel[0].success, 'Success flag check.');
        Assert.areEqual('Cancelled', responsesCancel[0].message, 'Message is Cancelled.');
    }
}
