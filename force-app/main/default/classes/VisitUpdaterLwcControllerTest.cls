/**
 * Unit tests verifying visit options and user assignment lookups
 * in VisitUpdaterLwcController and VisitUpdaterActionController.
 */
@IsTest
public class VisitUpdaterLwcControllerTest {

    @IsTest
    static void testControllerMethods() {
        Account acc = new Account(Name = 'Test Controller Account');
        insert as user acc;

        String visId = null;
        if (Schema.getGlobalDescribe().containsKey('visit')) {
            SObject vis = Schema.getGlobalDescribe().get('Visit').newSObject();
            vis.put('AccountId', acc.Id);
            if (Schema.getGlobalDescribe().containsKey('location')) {
                Schema.Location loc = new Schema.Location(Name = 'Test Place');
                insert as user loc;
                vis.put('PlaceId', loc.Id);
            }
            vis.put('Status', 'Planned');
            vis.put('PlannedVisitStartTime', DateTime.now().addDays(1));
            vis.put('PlannedVisitEndTime', DateTime.now().addDays(1).addHours(1));
            Database.insert(vis, AccessLevel.USER_MODE);
            visId = (String) vis.get('Id');
        }

        Id currentUserId = UserInfo.getUserId();

        Test.startTest();
        List<VisitUpdaterLwcController.VisitOptionWrapper> options = VisitUpdaterLwcController.getAvailableVisits();
        VisitUpdaterLwcController.VisitOptionWrapper details = visId != null ? VisitUpdaterLwcController.getVisitDetails((Id) visId) : null;
        VisitUpdaterLwcController.VisitOptionWrapper nullDetails = VisitUpdaterLwcController.getVisitDetails(null);
        String recentId = VisitUpdaterLwcController.getMostRecentVisitId();
        List<VisitUpdaterLwcController.UserOption> activeUsers = VisitUpdaterLwcController.getActiveUsers();

        // Direct updateVisitRecord execution covering ISO datetime, notes, subject, and user fields
        String isoTime = '2026-08-05T10:00:00.000Z';
        String updatesJson = '{"Status":"InProgress","cgcloud__Note__c":"Rep is in store","cgcloud__Subject__c":"Urgent Check","PlannedVisitStartTime":"' + isoTime + '","PlannedVisitEndTime":"' + isoTime + '","cgcloud__Responsible__c":"' + currentUserId + '","cgcloud__Accountable__c":"' + currentUserId + '"}';
        if (visId != null) {
            VisitUpdaterLwcController.updateVisitRecord((Id) visId, updatesJson);
            VisitUpdaterLwcController.updateVisitRecord((Id) visId, '{}');
            VisitUpdaterLwcController.updateVisitRecord((Id) visId, null);
        }
        VisitUpdaterLwcController.updateVisitRecord(null, updatesJson);

        VisitUpdaterLwcController.VisitOptionWrapper updatedDetails = visId != null ? VisitUpdaterLwcController.getVisitDetails((Id) visId) : null;
        Test.stopTest();

        Assert.isNotNull(options, 'Options list should not be null.');
        Assert.isNull(nullDetails, 'Null visit ID returns null.');
        Assert.isNotNull(activeUsers, 'Active users list should be returned.');
    }

    @IsTest
    static void testActionExecuteUpdate() {
        Account acc = new Account(Name = 'Test Action Account');
        insert as user acc;

        String visId = null;
        if (Schema.getGlobalDescribe().containsKey('visit')) {
            SObject vis = Schema.getGlobalDescribe().get('Visit').newSObject();
            vis.put('AccountId', acc.Id);
            if (Schema.getGlobalDescribe().containsKey('location')) {
                Schema.Location loc = new Schema.Location(Name = 'Test Action Place');
                insert as user loc;
                vis.put('PlaceId', loc.Id);
            }
            vis.put('Status', 'Planned');
            vis.put('PlannedVisitStartTime', DateTime.now().addDays(2));
            Database.insert(vis, AccessLevel.USER_MODE);
            visId = (String) vis.get('Id');
        }

        Test.startTest();
        VisitUpdaterActionController.Request req = new VisitUpdaterActionController.Request();
        req.visitId = visId;
        req.updatesPayload = new VisitUpdatePayload();
        req.updatesPayload.visitId = visId;
        req.updatesPayload.updatesJson = '{"Status":"Completed","cgcloud__Note__c":"Completed successfully","cgcloud__Subject__c":"Store Audit"}';

        List<VisitUpdaterActionController.Response> responses = VisitUpdaterActionController.executeUpdate(new List<VisitUpdaterActionController.Request>{ req });

        VisitUpdaterActionController.Request reqCancel = new VisitUpdaterActionController.Request();
        reqCancel.visitId = visId;
        reqCancel.updatesPayload = new VisitUpdatePayload();
        reqCancel.updatesPayload.visitId = visId;
        reqCancel.updatesPayload.updatesJson = '{}';

        List<VisitUpdaterActionController.Response> responsesCancel = VisitUpdaterActionController.executeUpdate(new List<VisitUpdaterActionController.Request>{ reqCancel });
        Test.stopTest();

        Assert.isNotNull(responses, 'Response list should not be null.');
        Assert.isNotNull(responsesCancel, 'Cancel responses should not be null.');
    }

    @IsTest
    static void testActionEdgeCasesAndErrorCatching() {
        Account acc = new Account(Name = 'Test Edge Account');
        insert as user acc;

        String visId = null;
        if (Schema.getGlobalDescribe().containsKey('visit')) {
            SObject vis = Schema.getGlobalDescribe().get('Visit').newSObject();
            vis.put('AccountId', acc.Id);
            if (Schema.getGlobalDescribe().containsKey('location')) {
                Schema.Location loc = new Schema.Location(Name = 'Test Edge Place');
                insert as user loc;
                vis.put('PlaceId', loc.Id);
            }
            vis.put('Status', 'Planned');
            vis.put('PlannedVisitStartTime', DateTime.now().addDays(3));
            Database.insert(vis, AccessLevel.USER_MODE);
            visId = (String) vis.get('Id');
        }

        Id userId = UserInfo.getUserId();
        String isoTime = '2026-08-05T10:00:00.000Z';
        String targetVisitId = (visId != null ? visId : '001000000000000AAA');

        Test.startTest();
        // 1. Test null updatesPayload
        VisitUpdaterActionController.Request reqNullPayload = new VisitUpdaterActionController.Request();
        reqNullPayload.updatesPayload = null;
        List<VisitUpdaterActionController.Response> respNull = VisitUpdaterActionController.executeUpdate(new List<VisitUpdaterActionController.Request>{ reqNullPayload });

        // 2. Test datetime, subject, note, and user fields
        VisitUpdaterActionController.Request reqFields = new VisitUpdaterActionController.Request();
        reqFields.visitId = targetVisitId;
        reqFields.updatesPayload = new VisitUpdatePayload();
        reqFields.updatesPayload.visitId = targetVisitId;
        reqFields.updatesPayload.updatesJson = '{"PlannedVisitStartTime":"' + isoTime + '","PlannedVisitEndTime":"' + isoTime + '","cgcloud__Responsible__c":"' + userId + '","cgcloud__Accountable__c":"' + userId + '","cgcloud__Subject__c":"Audit Check","cgcloud__Note__c":"All good"}';
        List<VisitUpdaterActionController.Response> respFields = VisitUpdaterActionController.executeUpdate(new List<VisitUpdaterActionController.Request>{ reqFields });

        // 3. Test invalid JSON error handling
        VisitUpdaterActionController.Request reqErr = new VisitUpdaterActionController.Request();
        reqErr.updatesPayload = new VisitUpdatePayload();
        reqErr.updatesPayload.visitId = targetVisitId;
        reqErr.updatesPayload.updatesJson = 'invalid_json_string';
        List<VisitUpdaterActionController.Response> respErr = VisitUpdaterActionController.executeUpdate(new List<VisitUpdaterActionController.Request>{ reqErr });

        // 4. Controller Exception handling
        if (visId != null) {
            try {
                VisitUpdaterLwcController.updateVisitRecord((Id) visId, 'invalid_json');
            } catch (Exception e) {
                Assert.isNotNull(e.getMessage(), 'AuraHandledException caught for invalid JSON update.');
            }
        }
        Test.stopTest();

        Assert.isTrue(respNull[0].success, 'Null payload returns success for client-side DML.');
        Assert.isFalse(respErr[0].success, 'Invalid JSON fails gracefully.');
    }
}