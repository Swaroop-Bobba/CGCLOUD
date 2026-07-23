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

## Permission Set Management Rule
Always update the `Visit_Intel_Access` permission set (`Visit_Intel_Access.permissionset-meta.xml`) with the required accesses (e.g. Apex classes, wrappers, handlers, or flows) whenever custom Apex classes, actions, or flows are added, updated, or created for the Agent.

## Account Summary Direct Google Maps Link Rule
For Account Summary features across all agents (including `VisitIntelDesktop` and `VisitIntelMobile`), Google Maps navigation links MUST be generated directly as web URLs (`https://www.google.com/maps?q=...`) without routing through Visualforce pages (`/apex/GoogleMapRedirect?q=...`), matching direct protocol behavior like `mailto:` and `tel:`.

