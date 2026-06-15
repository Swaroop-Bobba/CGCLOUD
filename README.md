# Consumer Goods Cloud (CGC) Agentforce Agents

This repository contains the Agentforce agents designed to assist internal users (supervisors and field reps) with analysis of Account, Order, and Visit records within Consumer Goods Cloud. 

These agents leverage Agentforce Employee Agents to provide contextual, data-driven insights directly within Salesforce records.

## 🤖 Available Agents

### 1. CGC Intelligence Agent (`CGC_Intelligence`)
Operates globally or within specific Account, Visit, or Order contexts. It automatically identifies the user's current record page context and loads the relevant data to provide immediate assistance.

**Key Capabilities:**
- **Context Awareness:** Automatically detects if opened from a Visit, Account, or Order record page and loads relevant details.
- **Search & Discovery:** Search for Accounts, Visits, and Orders, or list "Today's Visits", recently viewed, owned, and scheduled visits.
- **Account Summary:** Summarize account status, providing counts for Contacts, Visits, Tasks, Promotions, Out-of-Stock, Retail Stores, Assortments, etc.
- **Order Insights:** Retrieve order history summaries, buying insights, phase breakdowns, recent orders, and specific line items.
- **Store Briefs & Recommendations:** Generate comprehensive pre-visit store briefs and suggest/recommend products based on catalog gaps and order history.
- **Visit Execution:** Generate visit summaries/reports, update visit statuses (InProgress, Completed), add notes, set start/end times, and assign visits to other users.

**Subagents:**
- `agent_router`: Routes users to the correct subagent and initializes context.
- `cgc_intelligence`: Main workspace for analyzing Accounts, Visits, Orders, and related records.
- `off_topic` & `ambiguous_question`: Utility subagents to steer the conversation back to supported capabilities.
- `clear_context`: Utility to reset the conversation and switch context.

### 2. Visit Intelligence Agent (`Visit_Intelligence`)
A specialized agent that operates primarily within a Visit context, retrieving related Account context to help users execute and analyze their store visits.

**Key Capabilities:**
- **Visit Context:** Automatically detects the current Visit record and loads the associated Account details.
- **Visit Management:** Search for specific visits by account/store name, list upcoming/recent visits, and switch between visits.
- **Contextual Data Retrieval:** Fetch detailed records for contacts, promotions, inventory, out-of-stock items, and assortments related to the current visit's account.
- **Order Management within Visits:** Get order history specifically associated with the current Visit, view order items, and update delivery/invoice notes.
- **Store Execution:** Generate pre-visit store briefs, suggest products to order, and generate post-visit summaries.
- **Visit Updates:** Update the active Visit record (status, notes, timing, owner).

**Subagents:**
- `agent_router`: Initializes visit context and routes the user.
- `visit_intelligence`: Core subagent for analyzing the Visit and its related Account data.
- `off_topic` & `ambiguous_question`: Conversation guardrails.
- `clear_context`: Utility to clear active Visit/Account context before selecting another.

## 🛠️ Architecture & Actions

Both agents utilize standard and custom Salesforce Actions (Apex and Flows) to interact with the org's data:
- **Flows:** E.g., `Get_Visit_Details` to retrieve standard record information.
- **Apex Actions:** A suite of custom Apex classes (e.g., `GetAccountRelatedCounts`, `GetAccountOrderSummaryForAgent`, `SuggestProductsForStore`, `GenerateVisitSummary`) exposed as invocable actions for the agents.
- **LLM Configuration:** Both agents are configured to use Anthropic Claude models (e.g., `sfdc_ai__DefaultBedrockAnthropicClaude45Sonnet`).

## 🚀 Usage

To interact with these agents, open the Agentforce panel within the Salesforce UI while on a supported record page (Account, Visit, or Order) or globally. The agents will greet you based on your current context and prompt you with available actions.
