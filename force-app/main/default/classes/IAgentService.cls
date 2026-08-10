/**
 * @description Interface for all Agent services.
 */
global interface IAgentService {
    
    /**
     * @description Executes the agent request.
     * @param req The agent request object.
     * @return Agent_Response The agent response object.
     */
    Agent_Response execute(Agent_Request req);
}