/**
 * @description Master unit test class for AgentMockDataSeeder targeting 100% code coverage.
 */
@IsTest
public class AgentMockDataSeederTest {

    @IsTest
    static void testSeedAllDataFirstAndSecondRun() {
        Test.startTest();
        Map<String, Integer> countsFirst = AgentMockDataSeeder.seedAllData();
        List<String> invocableResults = AgentMockDataSeeder.seedDataInvocable();

        // Second run exercises existing Account/Location detection branch
        Map<String, Integer> countsSecond = AgentMockDataSeeder.seedAllData();
        Test.stopTest();

        Assert.isNotNull(countsFirst, 'Counts map should be populated.');
        Assert.areEqual(5, countsFirst.get('Account'), '5 Accounts created on first run.');
        Assert.areEqual(5, countsSecond.get('Account'), '5 Accounts retrieved on second run.');
        Assert.isNotNull(invocableResults, 'Invocable result list should not be null.');
    }

    @IsTest
    static void testSeedAllDataExceptions() {
        AgentMockDataSeeder.forceException = true;

        Test.startTest();
        Map<String, Integer> counts = AgentMockDataSeeder.seedAllData();
        Test.stopTest();

        Assert.isNotNull(counts, 'Counts map should be populated.');
        AgentMockDataSeeder.forceException = false;
    }
}
