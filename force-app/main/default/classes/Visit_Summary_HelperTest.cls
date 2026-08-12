/**
 * @description Unit test class for Visit_Summary_Helper.
 */
@IsTest(SeeAllData=true)
public class Visit_Summary_HelperTest {
  @IsTest
  static void testVisitSummaryOperations() {
    Account acc = new Account(Name = 'Summary Helper Store Account');
    insert acc;

    Schema.Location loc = new Schema.Location(Name = 'Summary Helper Location');
    insert loc;

    Visit v = new Visit(
      AccountId = acc.Id,
      PlaceId = loc.Id,
      Status = 'Planned',
      PlannedVisitStartTime = System.now()
    );
    insert v;

    Test.startTest();
    Map<String, Integer> qCounts = Visit_Summary_Helper.getQuestionsSummaryCounts(v.Id);
    String actDetails = Visit_Summary_Helper.getPlannedActivitiesDetails(v.Id);
    Map<String, Integer> actCounts = Visit_Summary_Helper.getActivityCounts(v.Id);
    String storeBrief = Visit_Summary_Helper.getStoreBrief(v.Id, acc.Id);
    String summaryStr = Visit_Summary_Helper.generateVisitSummary(v.Id);
    VisitSummaryWrapper summaryObj = Visit_Summary_Helper.generateVisitSummaryObj(v.Id);
    Test.stopTest();

    Assert.isNotNull(qCounts, 'Question counts should not be null');
    Assert.isNotNull(actDetails, 'Planned activity details should not be null');
    Assert.isNotNull(actCounts, 'Activity counts should not be null');
    Assert.isNotNull(storeBrief, 'Store brief should not be null');
    Assert.isNotNull(summaryStr, 'Visit summary string should not be null');
    Assert.isNotNull(summaryObj, 'Visit summary wrapper should not be null');
  }
}