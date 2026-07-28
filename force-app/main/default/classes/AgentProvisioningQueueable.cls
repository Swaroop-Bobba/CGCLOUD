public class AgentProvisioningQueueable implements Queueable, Database.AllowsCallouts {

    public void execute(QueueableContext context) {
        try {
            AgentProvisioningController.provisionAgentsFromZip();
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'AgentProvisioningQueueable Exception: ' + e.getMessage());
        }
    }
}
