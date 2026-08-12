/**
 * @description Master unit test class for MobileAgentUtility covering all natural language, fuzzy matching, and SObject type branches.
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

        Assert.isNotNull(dtTomorrow, 'Tomorrow DateTime should be parsed.');
        Assert.areEqual(Date.today().addDays(1), dtTomorrow.date(), 'Parsed tomorrow date should match.');

        Assert.isNotNull(dtYesterday, 'Yesterday DateTime should be parsed.');
        Assert.areEqual(Date.today().addDays(-1), dtYesterday.date(), 'Parsed yesterday date should match.');

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

        Assert.isNotNull(dtShort, 'Short date should be parsed.');
        Assert.areEqual(2026, dtShort.year(), 'Year should be 2026.');

        Assert.isNotNull(dtSpace, 'Space formatted datetime should be parsed.');
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

        Assert.isNotNull(dtDayMonthName, '6 July date should be parsed.');
        Assert.isNotNull(dtNumericSlashes, 'Numeric slashes date should be parsed.');
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
    static void testMatchRecordAccountAndLocation() {
        Account acc = new Account(Name = 'Fuzzy Mobile Target Store');
        insert as user acc;

        Schema.Location loc = new Schema.Location(Name = 'Fuzzy Mobile Location');
        insert as user loc;

        Test.startTest();
        // 1. Account exact match
        MobileAgentUtility.MatchResult mrExactAcc = MobileAgentUtility.matchRecord('Fuzzy Mobile Target Store', 'Account', '');
        // 2. Account index match
        MobileAgentUtility.MatchResult mrIndexAcc = MobileAgentUtility.matchRecord('1', 'Account', acc.Id);
        // 3. Account ID match
        MobileAgentUtility.MatchResult mrIdAcc = MobileAgentUtility.matchRecord(acc.Id, 'Account', '');
        // 4. Location exact match
        MobileAgentUtility.MatchResult mrExactLoc = MobileAgentUtility.matchRecord('Fuzzy Mobile Location', 'Location', '');
        // 5. Location index match
        MobileAgentUtility.MatchResult mrIndexLoc = MobileAgentUtility.matchRecord('1', 'Location', loc.Id);
        // 6. Location ID match
        MobileAgentUtility.MatchResult mrIdLoc = MobileAgentUtility.matchRecord(loc.Id, 'Location', '');
        // 7. Schema.Location match
        MobileAgentUtility.MatchResult mrSchemaLoc = MobileAgentUtility.matchRecord('Fuzzy Mobile Location', 'Schema.Location', '');
        // 8. Unsupported SObject type
        MobileAgentUtility.MatchResult mrInvalidObj = MobileAgentUtility.matchRecord('Test', 'Opportunity', '');
        Test.stopTest();

        Assert.isTrue(mrExactAcc.success, 'Account exact match should succeed.');
        Assert.areEqual(acc.Id, mrExactAcc.matchedId, 'ID matches.');

        Assert.isTrue(mrIndexAcc.success, 'Account index match should succeed.');
        Assert.isTrue(mrIdAcc.success, 'Account direct ID match should succeed.');

        Assert.isTrue(mrExactLoc.success, 'Location exact match should succeed.');
        Assert.areEqual(loc.Id, mrExactLoc.matchedId, 'Location ID matches.');

        Assert.isTrue(mrIndexLoc.success, 'Location index match should succeed.');
        Assert.isTrue(mrIdLoc.success, 'Location direct ID match should succeed.');
        Assert.isTrue(mrSchemaLoc.success, 'Schema.Location match should succeed.');

        Assert.isFalse(mrInvalidObj.success, 'Unsupported SObject type fails validation gracefully.');
    }

    @IsTest
    static void testScoredCandidateSorting() {
        Account acc1 = new Account(Name = 'Alpha');
        Account acc2 = new Account(Name = 'Beta');

        Double d80 = 80.0;
        Double d95 = 95.0;

        MobileAgentUtility.ScoredCandidate sc1 = new MobileAgentUtility.ScoredCandidate(acc1, d80);
        MobileAgentUtility.ScoredCandidate sc2 = new MobileAgentUtility.ScoredCandidate(acc2, d95);
        MobileAgentUtility.ScoredCandidate sc3 = new MobileAgentUtility.ScoredCandidate(acc1, d80);

        Test.startTest();
        Integer cmpHigh = sc1.compareTo(sc2);
        Integer cmpEqual = sc1.compareTo(sc3);
        Test.stopTest();

        Assert.areEqual(1, cmpHigh, 'Lower score returns positive comparison for descending sort.');
        Assert.areEqual(0, cmpEqual, 'Equal score returns 0.');
    }
}