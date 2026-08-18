/**
 * Unit tests verifying fuzzy text matching, scoring algorithms,
 * and natural language date parsing in AgentFuzzyMatchUtility.
 */
@IsTest
public class AgentFuzzyMatchUtilityTest {

    @IsTest
    static void testParseDateTimeRelative() {
        Test.startTest();
        DateTime dtToday = AgentFuzzyMatchUtility.parseDateTime('today at 2:30 pm');
        DateTime dtTomorrow = AgentFuzzyMatchUtility.parseDateTime('tomorrow at 10:00 am');
        DateTime dtYesterday = AgentFuzzyMatchUtility.parseDateTime('yesterday at 9 pm');
        DateTime dtInvalid = AgentFuzzyMatchUtility.parseDateTime('invalid date time string');
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
        DateTime dtIso = AgentFuzzyMatchUtility.parseDateTime('2026-07-23T10:20:30.000Z');
        DateTime dtShort = AgentFuzzyMatchUtility.parseDateTime('2026-07-23');
        DateTime dtSpace = AgentFuzzyMatchUtility.parseDateTime('2026-07-23 10:20');
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
        DateTime dtMonthName = AgentFuzzyMatchUtility.parseDateTime('July 6 2026 2pm');
        DateTime dtDayMonthName = AgentFuzzyMatchUtility.parseDateTime('6 July 2026 10am');
        DateTime dtNumericSlashes = AgentFuzzyMatchUtility.parseDateTime('15/07/2026 at 4:30 pm');
        Test.stopTest();

        Assert.isNotNull(dtMonthName, 'July 6 date should be parsed.');
        Assert.areEqual(2026, dtMonthName.year());

        Assert.isNotNull(dtDayMonthName, '6 July date should be parsed.');
        Assert.isNotNull(dtNumericSlashes, 'Numeric slashes date should be parsed.');
    }

    @IsTest
    static void testLevenshteinAndMatchScore() {
        Test.startTest();
        Integer dist1 = AgentFuzzyMatchUtility.getLevenshteinDistance('kitten', 'sitting');
        Integer distEqual = AgentFuzzyMatchUtility.getLevenshteinDistance('test', 'test');
        Integer distEmpty = AgentFuzzyMatchUtility.getLevenshteinDistance('', 'test');
        Double scoreExact = AgentFuzzyMatchUtility.getMatchScore('Reliance', 'Reliance');
        Double scoreStartsWith = AgentFuzzyMatchUtility.getMatchScore('Reli', 'Reliance');
        Double scoreContains = AgentFuzzyMatchUtility.getMatchScore('lian', 'Reliance');
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
        AgentFuzzyMatchUtility.MatchResult mrExactAcc = AgentFuzzyMatchUtility.matchRecord('Fuzzy Mobile Target Store', 'Account', '');
        // 2. Account index match
        AgentFuzzyMatchUtility.MatchResult mrIndexAcc = AgentFuzzyMatchUtility.matchRecord('1', 'Account', acc.Id);
        // 3. Account ID match
        AgentFuzzyMatchUtility.MatchResult mrIdAcc = AgentFuzzyMatchUtility.matchRecord(acc.Id, 'Account', '');
        // 4. Location exact match
        AgentFuzzyMatchUtility.MatchResult mrExactLoc = AgentFuzzyMatchUtility.matchRecord('Fuzzy Mobile Location', 'Location', '');
        // 5. Location index match
        AgentFuzzyMatchUtility.MatchResult mrIndexLoc = AgentFuzzyMatchUtility.matchRecord('1', 'Location', loc.Id);
        // 6. Location ID match
        AgentFuzzyMatchUtility.MatchResult mrIdLoc = AgentFuzzyMatchUtility.matchRecord(loc.Id, 'Location', '');
        // 7. Schema.Location match
        AgentFuzzyMatchUtility.MatchResult mrSchemaLoc = AgentFuzzyMatchUtility.matchRecord('Fuzzy Mobile Location', 'Schema.Location', '');
        // 8. Unsupported SObject type
        AgentFuzzyMatchUtility.MatchResult mrInvalidObj = AgentFuzzyMatchUtility.matchRecord('Test', 'Opportunity', '');
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

        AgentFuzzyMatchUtility.ScoredCandidate sc1 = new AgentFuzzyMatchUtility.ScoredCandidate(acc1, d80);
        AgentFuzzyMatchUtility.ScoredCandidate sc2 = new AgentFuzzyMatchUtility.ScoredCandidate(acc2, d95);
        AgentFuzzyMatchUtility.ScoredCandidate sc3 = new AgentFuzzyMatchUtility.ScoredCandidate(acc1, d80);

        Test.startTest();
        Integer cmpHigh = sc1.compareTo(sc2);
        Integer cmpEqual = sc1.compareTo(sc3);
        Test.stopTest();

        Assert.areEqual(1, cmpHigh, 'Lower score returns positive comparison for descending sort.');
        Assert.areEqual(0, cmpEqual, 'Equal score returns 0.');
    }
}