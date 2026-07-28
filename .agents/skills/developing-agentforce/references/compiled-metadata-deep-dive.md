# Compiled Metadata Deep Dive: Bots, BotVersions, and GenAiPlannerBundles

This document provides a deep dive into the compiled runtime metadata generated when publishing Agentforce agents. It details the relationship between the developer-owned Authoring Domain and the system-generated Runtime Domain, along with troubleshooting steps for local retrieval.

---

## 1. The Two-Domain Architectural Model

Salesforce splits Agentforce agents into two separate domains to decouple human-readable developer source code from machine-optimized execution graphs:

```
AUTHORING DOMAIN (Developer-Owned / Local Source)
  └── AiAuthoringBundle (.agent) ──> Where humans write instructions & actions.

              │
              │  [sf agent publish]  <-- Compiles code into machine metadata
              ▼

RUNTIME DOMAIN (Engine-Owned / Org-Generated)
  ├── Bot (.bot-meta.xml)           ──> The entry point / container for the agent.
  ├── BotVersion (.botVersion)      ──> The version controller (Active vs Inactive).
  └── GenAiPlannerBundle (.genAi)   ──> The compiled "brain" & JSON schemas of actions.
```

---

## 2. Detailed Breakdown of Runtime Metadata Types

### A. The Bot Container (`.bot-meta.xml`)
* **Purpose:** Represents the top-level container for the agent in the Salesforce database (`BotDefinition` SObject).
* **Metadata Type:** `Bot`
* **Local Location:** `force-app/main/default/bots/<AgentName>/<AgentName>.bot-meta.xml`
* **Contents:**
  * High-level metadata about the agent (Developer Name, Label, and Description).
  * Configurations linking the agent to specific profiles or system roles.
  * Channel bindings (e.g. Experience Cloud, Einstein Copilot).

### B. The Bot Version (`vXX.botVersion-meta.xml`)
* **Purpose:** Represents a specific historical version snapshot (e.g., version 1, 2, 13, 22). It handles version locking, allowing developers to work on drafts while production remains stable.
* **Metadata Type:** `BotVersion`
* **Local Location:** `force-app/main/default/bots/<AgentName>/v<VersionNumber>.botVersion-meta.xml`
* **Contents:**
  * The lifecycle status: `<status>Active</status>` or `<status>Inactive</status>`. Only one version can be active in the org at a time.
  * A reference pointing to the version-specific `GenAiPlannerBundle` containing the compiled logic.

### C. The GenAI Planner Bundle (`.genAiPlannerBundle` & `/localActions/`)
* **Purpose:** Serves as the actual compiled "reasoning engine" config for a specific version.
* **Metadata Type:** `GenAiPlannerBundle`
* **Local Location:** `force-app/main/default/genAiPlannerBundles/<AgentName>_v<VersionNumber>/`
* **Contents:**
  * **System Instructions:** Fully compiled prompts and subagent transition logic.
  * **Local Actions (`/localActions/` directory):** Scoped folders containing action schemas. For every Flow, Invocable Apex class, or Prompt Template registered to the agent, it contains:
    * `input/schema.json`: Schema defining parameters the LLM must collect to execute the action.
    * `output/schema.json`: Schema defining the response structure returned by the action to the LLM.

---

## 3. The `.forceignore` Retrieval Gotcha

By default, Salesforce projects include directories for compiled runtime assets in `.forceignore`:

```text
# Ignore compiled runtime domains to prevent publishing collisions
**/bots/**
**/genAiPlannerBundles/**
```

### Why they are ignored:
Because `AiAuthoringBundle` (`.agent`) is the single source of truth, committing the compiled `.bot` and `.genAiPlannerBundle` files locally and deploying them back to the org can overwrite versions or trigger schema conflicts.

### How to temporarily retrieve them:
If you need to inspect the generated JSON schemas or version files locally:
1. Open `.forceignore` and comment out the ignore rules:
   ```text
   # **/bots/**
   # **/genAiPlannerBundles/**
   ```
2. Retrieve the specific components:
   * **For Bots:** 
     ```bash
     sf project retrieve start --json --metadata Bot:Agent_API_Name
     ```
   * **For Planners (Version-specific):**
     ```bash
     sf project retrieve start --json --metadata GenAiPlannerBundle:Agent_API_Name_v<VersionNumber>
     ```
3. Re-uncomment the lines in `.forceignore` to prevent accidental deployments:
   ```text
   **/bots/**
   **/genAiPlannerBundles/**
   ```

---

## 4. Verification and Querying

Because `GenAiPlannerBundle` is not SOQL-queryable, you can verify your published versions using `BotVersion` queries:

```bash
sf data query --json -q "SELECT VersionNumber, Status, BotDefinition.DeveloperName FROM BotVersion WHERE BotDefinition.DeveloperName = 'Agent_API_Name' ORDER BY VersionNumber DESC"
```
