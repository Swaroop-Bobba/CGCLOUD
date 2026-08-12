/**
 * @description Unit test class for Visit_Search_Helper.
 */
@IsTest(SeeAllData=true)
public class Visit_Search_HelperTest {
  @IsTest
  static void testSearchVisitsAndDateParsing() {
    Account acc = new Account(Name = 'Search Helper Store Account');
    insert acc;

    Schema.Location loc = new Schema.Location(Name = 'Search Helper Location');
    insert loc;

    Visit v = new Visit(
      AccountId = acc.Id,
      PlaceId = loc.Id,
      Status = 'Planned',
      PlannedVisitStartTime = System.now()
    );
    insert v;

    Test.startTest();
    List<Agent_Response.VisitOption> avail = Visit_Search_Helper.getAvailableVisits();
    List<Agent_Response.VisitOption> accVis = Visit_Search_Helper.getAccountVisits(acc.Id, '0');
    List<Agent_Response.VisitOption> oosVis = Visit_Search_Helper.getOosVisits(acc.Id, '0');
    List<Agent_Response.VisitOption> searchAll = Visit_Search_Helper.searchVisits('all', '0');
    List<Agent_Response.VisitOption> searchToday = Visit_Search_Helper.searchVisits('today', '0');
    List<Agent_Response.VisitOption> searchThisWeek = Visit_Search_Helper.searchVisits('this week', '0');
    Visit_Search_Helper.ParsedQuery pq = Visit_Search_Helper.parseSearchQuery('today');
    Date explicitDate = Visit_Search_Helper.tryParseExplicitDate('2026-08-05');
    Date monthDate = Visit_Search_Helper.tryParseMonthNameDate('15 Jan 2026');
    String formatted = Visit_Search_Helper.formatDate(System.now());
    Test.stopTest();

    Assert.isNotNull(avail, 'Available visits should not be null');
    Assert.isNotNull(accVis, 'Account visits should not be null');
    Assert.isNotNull(searchAll, 'Search results should not be null');
    Assert.isNotNull(pq, 'Parsed query should not be null');
    Assert.isNotNull(formatted, 'Formatted date should not be null');
  }
}