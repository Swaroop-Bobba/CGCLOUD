/**
 * @description Unit test class for Visit_Lookup_Helper.
 */
@IsTest(SeeAllData=true)
public class Visit_Lookup_HelperTest {
  @IsTest
  static void testLookupOperations() {
    Account acc = new Account(Name = 'Lookup Helper Store Account');
    insert acc;

    Schema.Location loc = new Schema.Location(Name = 'Lookup Helper Location');
    insert loc;

    Visit v = new Visit(
      AccountId = acc.Id,
      PlaceId = loc.Id,
      Status = 'Planned',
      PlannedVisitStartTime = System.now()
    );
    insert v;

    Test.startTest();
    List<Map<String, String>> statusOpts = Visit_Lookup_Helper.getStatusOptions();
    List<Map<String, String>> users = Visit_Lookup_Helper.getActiveUsers();
    List<Map<String, String>> searchedUsers = Visit_Lookup_Helper.searchUsers('Test');
    String uName = Visit_Lookup_Helper.getUserName(UserInfo.getUserId());
    List<Map<String, String>> accounts = Visit_Lookup_Helper.searchAccounts('Lookup');
    String accName = Visit_Lookup_Helper.getAccountName(acc.Id);
    List<Map<String, String>> places = Visit_Lookup_Helper.searchPlaces('Lookup');
    String placeName = Visit_Lookup_Helper.getPlaceName(loc.Id);
    List<Map<String, String>> tpls = Visit_Lookup_Helper.searchTemplates('');
    CreateVisitWrapper wrapper = Visit_Lookup_Helper.getVisitDataForLwc(v.Id);
    Map<String, Object> ctx = Visit_Lookup_Helper.getResponsibleUserContext();
    Map<String, Object> fVals = Visit_Lookup_Helper.getVisitFieldValues(v.Id);
    Test.stopTest();

    Assert.isNotNull(statusOpts, 'Status options should not be null');
    Assert.isNotNull(users, 'Users should not be null');
    Assert.isNotNull(accounts, 'Accounts should not be null');
    Assert.isNotNull(accName, 'Account name should not be null');
    Assert.isNotNull(wrapper, 'LWC visit wrapper should not be null');
    Assert.isNotNull(ctx, 'User context should not be null');
    Assert.isNotNull(fVals, 'Field values map should not be null');
  }
}