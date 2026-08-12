/**
 * @description Master unit test class for VisitUpdaterController and VisitUpdaterAction targeting 100% code coverage.
 */
@IsTest
public class VisitUpdaterControllerTest {

    @IsTest
    static void testControllerMethods() {
        Account acc = new Account(Name = 'Test Controller Account');
        insert as user acc;

        Schema.Location loc = new Schema.Location(Name = 'Test Place');
        insert as user loc;

        Id currentUserId = UserInfo.getUserId();

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
        VisitUpdaterController.VisitOptionWrapper nullDetails = VisitUpdaterController.getVisitDetails(null);
        String recentId = VisitUpdaterController.getMostRecentVisitId();
        List<VisitUpdaterController.UserOption> activeUsers = VisitUpdaterController.getActiveUsers();

        // Direct updateVisitRecord execution covering ISO datetime, notes, subject, and user fields
        String isoTime = '2026-08-05T10:00:00.000Z';
        String updatesJson = '{"Status":"InProgress","cgcloud__Note__c":"Rep is in store","cgcloud__Subject__c":"Urgent Check","PlannedVisitStartTime":"' + isoTime + '","PlannedVisitEndTime":"' + isoTime + '","cgcloud__Responsible__c":"' + currentUserId + '","cgcloud__Accountable__c":"' + currentUserId + '"}';
        VisitUpdaterController.updateVisitRecord(vis.Id, updatesJson);

        // Edge case updates
        VisitUpdaterController.updateVisitRecord(vis.Id, '{}');
        VisitUpdaterController.updateVisitRecord(vis.Id, null);
        VisitUpdaterController.updateVisitRecord(null, updatesJson);

        VisitUpdaterController.VisitOptionWrapper updatedDetails = VisitUpdaterController.getVisitDetails(vis.Id);
        Test.stopTest();

        Assert.isNotNull(options, 'Options list should not be null.');
        Assert.isNotNull(details, 'Details wrapper should be returned.');
        Assert.isNull(nullDetails, 'Null visit ID returns null.');
        Assert.isNotNull(activeUsers, 'Active users list should be returned.');
        Assert.isNotNull(updatedDetails, 'Updated details wrapper should not be null.');
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
        req.updatesPayload.updatesJson = '{"Status":"Completed","cgcloud__Note__c":"Completed successfully","cgcloud__Subject__c":"Store Audit"}';

        List<VisitUpdaterAction.Response> responses = VisitUpdaterAction.executeUpdate(new List<VisitUpdaterAction.Request>{ req });

        VisitUpdaterAction.Request reqCancel = new VisitUpdaterAction.Request();
        reqCancel.visitId = vis.Id;
        reqCancel.updatesPayload = new VisitUpdatePayload();
        reqCancel.updatesPayload.visitId = vis.Id;
        reqCancel.updatesPayload.updatesJson = '{}';

        List<VisitUpdaterAction.Response> responsesCancel = VisitUpdaterAction.executeUpdate(new List<VisitUpdaterAction.Request>{ reqCancel });
        Test.stopTest();

        Assert.isNotNull(responses, 'Response list should not be null.');
        Assert.isTrue(responses[0].success, 'Keep success flag check.');
        Assert.isTrue(responsesCancel[0].success, 'Success flag check.');
    }

    @IsTest
    static void testActionEdgeCasesAndErrorCatching() {
        Account acc = new Account(Name = 'Test Edge Account');
        insert as user acc;

        Schema.Location loc = new Schema.Location(Name = 'Test Edge Place');
        insert as user loc;

        Visit vis = new Visit(
            AccountId = acc.Id,
            PlaceId = loc.Id,
            Status = 'Planned',
            PlannedVisitStartTime = DateTime.now().addDays(3)
        );
        insert as user vis;

        Id userId = UserInfo.getUserId();
        String isoTime = '2026-08-05T10:00:00.000Z';

        Test.startTest();
        // 1. Test null updatesPayload
        VisitUpdaterAction.Request reqNullPayload = new VisitUpdaterAction.Request();
        reqNullPayload.updatesPayload = null;
        List<VisitUpdaterAction.Response> respNull = VisitUpdaterAction.executeUpdate(new List<VisitUpdaterAction.Request>{ reqNullPayload });

        // 2. Test datetime, subject, note, and user fields
        VisitUpdaterAction.Request reqFields = new VisitUpdaterAction.Request();
        reqFields.visitId = vis.Id;
        reqFields.updatesPayload = new VisitUpdatePayload();
        reqFields.updatesPayload.visitId = vis.Id;
        reqFields.updatesPayload.updatesJson = '{"PlannedVisitStartTime":"' + isoTime + '","PlannedVisitEndTime":"' + isoTime + '","cgcloud__Responsible__c":"' + userId + '","cgcloud__Accountable__c":"' + userId + '","cgcloud__Subject__c":"Audit Check","cgcloud__Note__c":"All good"}';
        List<VisitUpdaterAction.Response> respFields = VisitUpdaterAction.executeUpdate(new List<VisitUpdaterAction.Request>{ reqFields });

        // 3. Test invalid JSON error handling
        VisitUpdaterAction.Request reqErr = new VisitUpdaterAction.Request();
        reqErr.updatesPayload = new VisitUpdatePayload();
        reqErr.updatesPayload.visitId = vis.Id;
        reqErr.updatesPayload.updatesJson = 'invalid_json_string';
        List<VisitUpdaterAction.Response> respErr = VisitUpdaterAction.executeUpdate(new List<VisitUpdaterAction.Request>{ reqErr });

        // 4. Controller Exception handling
        try {
            VisitUpdaterController.updateVisitRecord(vis.Id, 'invalid_json');
        } catch (Exception e) {
            Assert.isNotNull(e.getMessage(), 'AuraHandledException caught for invalid JSON update.');
        }
        Test.stopTest();

        Assert.isTrue(respNull[0].success, 'Null payload returns success for client-side DML.');
        Assert.isTrue(respFields[0].success, 'Field updates succeed.');
        Assert.isFalse(respErr[0].success, 'Invalid JSON fails gracefully.');
    }
}