# Workspace Rules

## CLI Commands Presentation Rule
After modifying or analyzing an agent, always provide the exact Salesforce CLI (`sf`) commands for:
1. **Agent Validation:**
   ```bash
   sf agent validate authoring-bundle --json --api-name <AgentApiName>
   ```
2. **Metadata Deployment:**
   ```bash
   sf project deploy start --json --metadata AiAuthoringBundle:<AgentApiName>
   ```
3. **Agent Publishing:**
   ```bash
   sf agent publish authoring-bundle --json --api-name <AgentApiName>
   ```
4. **Agent Activation:**
   ```bash
   sf agent activate --json --api-name <AgentApiName>
   ```
