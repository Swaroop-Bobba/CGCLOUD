try {
    // In Salesforce, BotDefinition/BotVersion are metadata sObjects. Let's see if DML delete is supported.
    List<SObject> bots = Database.query('SELECT Id FROM BotDefinition WHERE DeveloperName = \'CGC_Visit_Intelligence_Agent_4\'');
    if (!bots.isEmpty()) {
        delete bots;
        System.debug('Successfully deleted Agent 4');
    } else {
        System.debug('Agent 4 not found');
    }
} catch (Exception e) {
    System.debug('Error: ' + e.getMessage());
}