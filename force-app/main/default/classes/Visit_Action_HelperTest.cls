/**
 * @description Unit test class for Visit_Action_Helper.
 */
@IsTest(SeeAllData=true)
public class Visit_Action_HelperTest {
  @IsTest
  static void testVisitActionOperations() {
    Account acc = new Account(Name = 'Action Helper Store Account');
    insert acc;

    Schema.Location loc = new Schema.Location(Name = 'Action Helper Location');
    insert loc;

    Visit v = new Visit(
      AccountId = acc.Id,
      PlaceId = loc.Id,
      Status = 'Planned',
      PlannedVisitStartTime = System.now()
    );
    insert v;

    Test.startTest();
    Agent_Request reqUpdate = new Agent_Request();
    reqUpdate.actionType = 'update_visit_status';
    reqUpdate.visitId = v.Id;
    reqUpdate.status = 'InProgress';
    Agent_Response resUpdate = Visit_Action_Helper.updateVisit(reqUpdate);

    Agent_Request reqNav = new Agent_Request();
    reqNav.visitId = v.Id;
    Agent_Response resNav = Visit_Action_Helper.selectAndNavigateVisit(reqNav);

    Agent_Request reqForUpdate = new Agent_Request();
    reqForUpdate.visitId = v.Id;
    Agent_Response resForUpdate = Visit_Action_Helper.getVisitForUpdate(reqForUpdate);

    List<Agent_Response.StaleVisitInfo> stales = Visit_Action_Helper.getStaleVisits(acc.Id, '0');
    Agent_Response resAlerts = Visit_Action_Helper.sendVisitAlerts(new List<String>{ v.Id });
    Test.stopTest();

    Assert.isNotNull(resUpdate, 'Update response should not be null');
    Assert.isNotNull(resNav, 'Navigation response should not be null');
    Assert.isNotNull(resForUpdate, 'Visit for update response should not be null');
    Assert.isNotNull(stales, 'Stale visits should not be null');
  }
}