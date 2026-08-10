@IsTest
private class Agent_RequestTest {
    @IsTest
    static void testAgentRequestFields() {
        Agent_Request req = new Agent_Request();
        req.domain = 'Visit';
        req.actionType = 'search';
        req.agentName = 'VisitIntelDesktop';
        req.matchedTemplate = 'SearchVisits';
        req.searchQuery = 'Test Store';
        req.accountId = '001000000000000AAA';
        req.visitId = '0ZE000000000000AAA';
        req.visitIds = new List<String>{'0ZE000000000000AAA'};
        req.orderId = '801000000000000AAA';
        req.placeId = '131000000000000AAA';
        req.createVisitWrapper = new CreateVisitWrapper();
        req.status = 'Planned';
        req.notes = 'Sample notes';
        req.ownerName = 'Test User';
        req.ownerId = '005000000000000AAA';
        req.ownerAlias = 'tuser';
        req.ownerProfileName = 'System Administrator';
        req.startTime = System.now();
        req.endTime = System.now().addHours(1);
        req.plannedStartTime = System.now();
        req.plannedEndTime = System.now().addHours(1);
        req.accountInput = 'Test Account';
        req.placeInput = 'Test Place';
        req.templateInput = 'Test Template';
        req.plannedStartTimeStr = '2026-08-05T10:00:00.000Z';
        req.plannedEndTimeStr = '2026-08-05T11:00:00.000Z';
        req.subject = 'Test Subject';
        req.isAllDayEvent = false;
        req.accountableInput = 'Accountable User';
        req.responsibleInput = 'Responsible User';
        req.suggestions = 'Suggestion 1';
        req.orderIdentifier = 'ORD-001';
        req.deliveryNote = 'Delivery Note';
        req.invoiceNote = 'Invoice Note';
        req.recordType = 'contacts';
        req.statusFilter = 'all';
        req.excludeOption = 'Option 1';
        req.questionOrSurveyFilter = 'question';
        req.promotionId = '701000000000000AAA';
        req.searchOffset = '0';

        Assert.areEqual('Visit', req.domain, 'Domain property set successfully.');
        Assert.areEqual('search', req.actionType, 'ActionType property set successfully.');
        Assert.areEqual(1, req.visitIds.size(), 'VisitIds set successfully.');
    }
}
