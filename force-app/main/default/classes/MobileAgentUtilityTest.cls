/**
 * @description Test class for MobileAgentUtility.
 */
@IsTest
public class MobileAgentUtilityTest {

    @IsTest
    static void testParseDateTimeRelative() {
        Test.startTest();
        DateTime dtToday = MobileAgentUtility.parseDateTime('today at 2:30 pm');
        DateTime dtTomorrow = MobileAgentUtility.parseDateTime('tomorrow at 10:00 am');
        DateTime dtYesterday = MobileAgentUtility.parseDateTime('yesterday at 9 pm');
        DateTime dtInvalid = MobileAgentUtility.parseDateTime('invalid date time string');
        Test.stopTest();

        Assert.isNotNull(dtToday, 'Today DateTime should be parsed.');
        Assert.areEqual(Date.today(), dtToday.date(), 'Parsed today date should match system date.');
        Assert.areEqual(14, dtToday.hour(), 'Parsed time hour should be 14 (2 PM).');
        Assert.areEqual(30, dtToday.minute(), 'Parsed time minute should be 30.');

        Assert.isNotNull(dtTomorrow, 'Tomorrow DateTime should be parsed.');
        Assert.areEqual(Date.today().addDays(1), dtTomorrow.date(), 'Parsed tomorrow date should match.');
        Assert.areEqual(10, dtTomorrow.hour(), 'Hour should be 10.');

        Assert.isNotNull(dtYesterday, 'Yesterday DateTime should be parsed.');
        Assert.areEqual(Date.today().addDays(-1), dtYesterday.date(), 'Parsed yesterday date should match.');
        Assert.areEqual(21, dtYesterday.hour(), 'Hour should be 21 (9 PM).');

        Assert.isNull(dtInvalid, 'Invalid dates should return null.');
    }

    @IsTest
    static void testParseDateTimeStandardFormats() {
        Test.startTest();
        DateTime dtIso = MobileAgentUtility.parseDateTime('2026-07-23T10:20:30.000Z');
        DateTime dtShort = MobileAgentUtility.parseDateTime('2026-07-23');
        DateTime dtSpace = MobileAgentUtility.parseDateTime('2026-07-23 10:20');
        Test.stopTest();

        Assert.isNotNull(dtIso, 'ISO date should be parsed.');
        Assert.areEqual(2026, dtIso.year(), 'Year should be 2026.');
        Assert.areEqual(7, dtIso.month(), 'Month should be 7.');
        Assert.areEqual(23, dtIso.day(), 'Day should be 23.');

        Assert.isNotNull(dtShort, 'Short date should be parsed.');
        Assert.areEqual(2026, dtShort.year(), 'Year should be 2026.');

        Assert.isNotNull(dtSpace, 'Space formatted datetime should be parsed.');
        Assert.areEqual(10, dtSpace.hourGmt(), 'Hour should match.');
    }

    @IsTest
    static void testParseDateTimeNaturalLanguage() {
        Test.startTest();
        DateTime dtMonthName = MobileAgentUtility.parseDateTime('July 6 2026 2pm');
        DateTime dtDayMonthName = MobileAgentUtility.parseDateTime('6 July 2026 10am');
        DateTime dtNumericSlashes = MobileAgentUtility.parseDateTime('15/07/2026 at 4:30 pm');
        Test.stopTest();

        Assert.isNotNull(dtMonthName, 'July 6 date should be parsed.');
        Assert.areEqual(2026, dtMonthName.year());
        Assert.areEqual(7, dtMonthName.month());
        Assert.areEqual(6, dtMonthName.day());

        Assert.isNotNull(dtDayMonthName, '6 July date should be parsed.');
        Assert.areEqual(6, dtDayMonthName.day());

        Assert.isNotNull(dtNumericSlashes, 'Numeric slashes date should be parsed.');
        Assert.areEqual(15, dtNumericSlashes.day());
        Assert.areEqual(7, dtNumericSlashes.month());
    }

    @IsTest
    static void testLevenshteinAndMatchScore() {
        Test.startTest();
        Integer dist1 = MobileAgentUtility.getLevenshteinDistance('kitten', 'sitting');
        Integer distEqual = MobileAgentUtility.getLevenshteinDistance('test', 'test');
        Integer distEmpty = MobileAgentUtility.getLevenshteinDistance('', 'test');
        Double scoreExact = MobileAgentUtility.getMatchScore('Reliance', 'Reliance');
        Double scoreStartsWith = MobileAgentUtility.getMatchScore('Reli', 'Reliance');
        Double scoreContains = MobileAgentUtility.getMatchScore('lian', 'Reliance');
        Test.stopTest();

        Assert.areEqual(3, dist1, 'Distance between kitten and sitting should be 3.');
        Assert.areEqual(0, distEqual, 'Distance for equal strings is 0.');
        Assert.areEqual(4, distEmpty, 'Distance with empty string is target length.');
        Assert.areEqual(100.0, scoreExact, 'Exact match score is 100.');
        Assert.isTrue(scoreStartsWith > 90.0, 'Starts with score is greater than 90.');
        Assert.isTrue(scoreContains > 80.0, 'Contains score is greater than 80.');
    }

    @IsTest
    static void testMatchRecordAccount() {
        Account acc = new Account(Name = 'Fuzzy Match Target Account');
        insert as user acc;

        Test.startTest();
        // 1. Exact match
        MobileAgentUtility.MatchResult mrExact = MobileAgentUtility.matchRecord('Fuzzy Match Target Account', 'Account', '');
        // 2. Index match
        MobileAgentUtility.MatchResult mrIndex = MobileAgentUtility.matchRecord('1', 'Account', acc.Id);
        // 3. ID match
        MobileAgentUtility.MatchResult mrId = MobileAgentUtility.matchRecord(acc.Id, 'Account', '');
        // 4. Fuzzy match
        MobileAgentUtility.MatchResult mrFuzzy = MobileAgentUtility.matchRecord('Fuzzy Match Target', 'Account', '');
        // 5. Empty input
        MobileAgentUtility.MatchResult mrEmpty = MobileAgentUtility.matchRecord('', 'Account', '');
        Test.stopTest();

        Assert.isTrue(mrExact.success, 'Exact match should succeed.');
        Assert.areEqual(acc.Id, mrExact.matchedId, 'ID matches.');

        Assert.isTrue(mrIndex.success, 'Index match should succeed.');
        Assert.areEqual(acc.Id, mrIndex.matchedId, 'Index ID matches.');

        Assert.isTrue(mrId.success, 'ID match should succeed.');
        Assert.areEqual(acc.Id, mrId.matchedId, 'Direct ID match matches.');

        Assert.isTrue(mrFuzzy.success, 'Fuzzy prefix match should succeed.');

        Assert.isFalse(mrEmpty.success, 'Empty match should fail.');
    }

    @IsTest
    static void testMatchRecordSuggestions() {
        // Create multiple similar accounts to test multiple suggestions flow
        List<Account> accounts = new List<Account>{
            new Account(Name = 'Fuzzy Match Alpha Account'),
            new Account(Name = 'Fuzzy Match Beta Account')
        };
        insert as user accounts;

        Test.startTest();
        MobileAgentUtility.MatchResult mrSuggestions = MobileAgentUtility.matchRecord('Match', 'Account', '');
        Test.stopTest();

        Assert.isFalse(mrSuggestions.success, 'Should not match uniquely due to multiple candidates.');
        Assert.isNotNull(mrSuggestions.suggestions, 'Suggestions list of IDs should be returned.');
        Assert.isTrue(mrSuggestions.message.contains('multiple matching records'), 'Message informs about multiple candidates.');
    }
}
