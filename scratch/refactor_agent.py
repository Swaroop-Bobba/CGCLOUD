import os

filepath = 'force-app/main/default/aiAuthoringBundles/VisitIntelligence/VisitIntelligence.agent'
if not os.path.exists(filepath):
    print("Agent file not found.")
    exit(1)

content = open(filepath, 'r', encoding='utf-8').read()

# Normalize newlines
content = content.replace('\r\n', '\n')

# 1. Extract and remove LWC and Mobile custom actions from global block
lwc_schemas = content[62819:69185]
mobile_schemas = content[69185:74313]

content = content[:62819] + content[74313:]
print("Extracted and removed schemas from global block.")

# 2. Update routing inside subagent agent_router
target_routing = """            if @variables.accountId != "" and @variables.activeSubagent == "visit_intelligence":
                transition to @subagent.visit_intelligence"""

replacement_routing = """            if @variables.accountId != "" and @variables.activeSubagent == "visit_intelligence":
                transition to @subagent.visit_intelligence

            if @variables.accountId != "" and @variables.activeSubagent == "update_visit_lwc":
                transition to @subagent.update_visit_lwc

            if @variables.accountId != "" and @variables.activeSubagent == "update_visit_text":
                transition to @subagent.update_visit_text"""

if target_routing in content:
    content = content.replace(target_routing, replacement_routing, 1)
    print("1. Routing updated successfully.")
else:
    print("ERROR: Target routing not found.")

# 3. Add top-level actions transitions under go_to_create_visit_mobile
target_tla = '''            go_to_create_visit_mobile: @utils.transition to @subagent.create_visit_mobile
                description: "Route the user to the Create Visit Mobile Agent (conversational) when they request to create, plan, schedule, or add a new visit. Mobile channel only."
                available when @variables.channelType == "mobile"
                set @variables.visitId = ""
                set @variables.accountId = ""
                set @variables.tempAccountId = ""
                set @variables.tempAccountName = ""
                set @variables.tempPlaceId = ""
                set @variables.tempPlaceName = ""
                set @variables.tempTemplateId = ""
                set @variables.tempTemplateName = ""
                set @variables.tempResponsibleUserId = ""
                set @variables.tempResponsibleUserName = ""
                set @variables.tempSubject = ""
                set @variables.tempPlannedStartTime = ""
                set @variables.tempPlannedStartTimeWrapper = None
                set @variables.isDateTimeSelected = False
                set @variables.tempAccountSuggestions = ""
                set @variables.tempPlaceSuggestions = ""
                set @variables.tempTemplateSuggestions = ""
                set @variables.tempOwnerSuggestions = ""'''

replacement_tla = '''            go_to_create_visit_mobile: @utils.transition to @subagent.create_visit_mobile
                description: "Route the user to the Create Visit Mobile Agent (conversational) when they request to create, plan, schedule, or add a new visit. Mobile channel only."
                available when @variables.channelType == "mobile"
                set @variables.visitId = ""
                set @variables.accountId = ""
                set @variables.tempAccountId = ""
                set @variables.tempAccountName = ""
                set @variables.tempPlaceId = ""
                set @variables.tempPlaceName = ""
                set @variables.tempTemplateId = ""
                set @variables.tempTemplateName = ""
                set @variables.tempResponsibleUserId = ""
                set @variables.tempResponsibleUserName = ""
                set @variables.tempSubject = ""
                set @variables.tempPlannedStartTime = ""
                set @variables.tempPlannedStartTimeWrapper = None
                set @variables.isDateTimeSelected = False
                set @variables.tempAccountSuggestions = ""
                set @variables.tempPlaceSuggestions = ""
                set @variables.tempTemplateSuggestions = ""
                set @variables.tempOwnerSuggestions = ""

            go_to_update_visit_lwc: @utils.transition to @subagent.update_visit_lwc
                description: "Route the user to the Update Visit LWC Agent (forms) when they request to update, change, edit, or modify visit details (status, owner, notes, timings) and are NOT a CGCloud_User_Profile user."
                available when @variables.userProfileName != "CGCloud_User_Profile"

            go_to_update_visit_text: @utils.transition to @subagent.update_visit_text
                description: "Route the user to the Update Visit Text Agent (conversational text) when they request to update, change, edit, or modify visit details (status, owner, notes, timings)."

            go_to_intelligence: @utils.transition to @subagent.visit_intelligence
                description: "Return to the main Visit Intelligence subagent dashboard."'''

if target_tla in content:
    content = content.replace(target_tla, replacement_tla, 1)
    print("2. Top-level transition actions added successfully.")
else:
    print("ERROR: Target top-level actions block not found.")

# 4. Update instructions of visit_intelligence
target_inst_sec1 = '                |   * "Update" / "change visit" / "assign visit" -> Prompt the user: "What would you like to update? Please select a field to update:" and present the Update Menu (described in Section 3).'
replacement_inst_sec1 = '                |   * "Update" / "change visit" / "assign visit" / "update status" / "reassign visit" / "change owner" / "add notes" / "update start time" / "update end time" -> Transition immediately to the @subagent.update_visit_lwc subagent (using go_to_update_visit_lwc) if userProfileName != "CGCloud_User_Profile", or the @subagent.update_visit_text subagent (using go_to_update_visit_text) if userProfileName == "CGCloud_User_Profile".'

if target_inst_sec1 in content:
    content = content.replace(target_inst_sec1, replacement_inst_sec1, 1)
    print("3a. Section 1 instruction updated.")
else:
    print("ERROR: target_inst_sec1 not found.")

target_inst_sec3a = """                |         * Update Visit / Update Visit Information -> Present the Update Menu:
                |           What would you like to update? Please select a field to update:
                |           * Status
                |           * Owner
                |           * Notes
                |           * Start Time
                |           * End Time"""

replacement_inst_sec3a = """                |         * Update Visit / Update Visit Information -> Transition immediately to:
                |           - The @subagent.update_visit_lwc subagent (using go_to_update_visit_lwc) if userProfileName != "CGCloud_User_Profile".
                |           - The @subagent.update_visit_text subagent (using go_to_update_visit_text) if userProfileName == "CGCloud_User_Profile"."""

if target_inst_sec3a in content:
    content = content.replace(target_inst_sec3a, replacement_inst_sec3a, 1)
    print("3b. Section 3a instruction updated.")
else:
    print("ERROR: target_inst_sec3a not found.")

target_inst_sec3b = """                |   B. IF THE UPDATE MENU WAS PRESENTED:
                |      - If channelType is "web":
                |        * Option 1 or "Status" -> Call @actions.update_visit_status immediately with only visitId.
                |        * Option 2 or "Owner" / "Assign" -> Call @actions.update_visit_owner immediately with only visitId.
                |        * Option 3 or "Notes" -> Call @actions.update_visit_notes immediately with only visitId.
                |        * Option 4 or "Start Time" -> Call @actions.update_visit_start_time immediately with only visitId.
                |        * Option 5 or "End Time" -> Call @actions.update_visit_end_time immediately with only visitId.
                |      - If channelType is "mobile":
                |        * Option 1 or "Status" -> Call @actions.update_visit_status_mobile immediately with only visitId.
                |        * Option 2 or "Owner" / "Assign" -> Call @actions.update_visit_owner_mobile immediately with only visitId.
                |        * Option 3 or "Notes" -> Call @actions.update_visit_notes_mobile immediately with only visitId.
                |        * Option 4 or "Start Time" -> Call @actions.update_visit_start_time_mobile immediately with only visitId.
                |        * Option 5 or "End Time" -> Call @actions.update_visit_end_time_mobile immediately with only visitId.
                |
                |   C. FALLBACK MAPPING:"""

replacement_inst_sec3b = """                |   B. FALLBACK MAPPING:"""

if target_inst_sec3b in content:
    content = content.replace(target_inst_sec3b, replacement_inst_sec3b, 1)
    print("3c. Section 3b instruction removed.")
else:
    print("ERROR: target_inst_sec3b not found.")

# Remove LWC/mobile slot filling lines
target_sf_web = '                | - Slot Filling (Web): For update actions (Section 3-B), invoke the action with only the visitId parameter. Do not ask for fields/values in your response; let the system\'s slot-filling UI render the forms.\n'
if target_sf_web in content:
    content = content.replace(target_sf_web, '')
    print("3d. Slot Filling (Web) removed.")
else:
    print("Warning: target_sf_web not found.")

target_sf_mob = '                | - Slot Filling (Mobile): Slot-filling UI cards and forms are NOT used. All field updates are requested and verified conversationally in plain text chat.\n'
if target_sf_mob in content:
    content = content.replace(target_sf_mob, '')
    print("3e. Slot Filling (Mobile) removed.")
else:
    print("Warning: target_sf_mob not found.")

target_failures = """                | - Update Action Failures and Successes:
                |   * If any update action (e.g., update_visit, update_visit_status, update_visit_owner, update_visit_notes, update_visit_start_time, update_visit_end_time) returns success = False, you MUST print the error message returned in the output message field verbatim (e.g., "Failed to update visit: [message]") so the user knows exactly why the update failed. Do NOT print a success message and do NOT show the updated Visit Details table.
                |   * If the update action returns success = True, print a success message (e.g., "Perfect! I've updated the visit status to InProgress ✅") and show the updated Visit Details table.\n"""

if target_failures in content:
    content = content.replace(target_failures, '')
    print("3f. Failure/Success messages formatting rules removed.")
else:
    target_failures_nonl = target_failures.rstrip('\n')
    if target_failures_nonl in content:
        content = content.replace(target_failures_nonl, '')
        print("3f. Failure/Success messages formatting rules removed (no nl).")
    else:
        print("ERROR: target_failures not found.")

# 5. Replace 11 update actions in visit_intelligence actions block using start/end indices
start_str = '            update_visit: @actions.update_visit'
end_str = '            search_users: @actions.search_users'

# Find indices in the modified content (since we removed the global actions above, start/end indices are now smaller)
start_idx = content.find(start_str)
end_idx = content.find(end_str)

replacement_actions = """            go_to_update_visit_lwc: @utils.transition to @subagent.update_visit_lwc
                available when @variables.userProfileName != "CGCloud_User_Profile"

            go_to_update_visit_text: @utils.transition to @subagent.update_visit_text

"""

if start_idx != -1 and end_idx != -1:
    content = content[:start_idx] + replacement_actions + content[end_idx:]
    print("4. Action block replaced via index lookup successfully.")
else:
    print(f"ERROR: start_idx={start_idx}, end_idx={end_idx}")

# 6. Insert update_visit_lwc and update_visit_text subagents before subagent visit_activities
target_subagent = "\nsubagent visit_activities:"
new_subagents_code = f"""
subagent update_visit_lwc:
    label: "Update Visit LWC"
    description: "Update the status, owner, notes, start time, or end time of the current visit using Custom LWC forms for non-field reps."
    before_reasoning:
        set @variables.activeSubagent = "update_visit_lwc"
    reasoning:
        instructions: |
            You are now in the Update Visit LWC subagent.
            Your goal is to update details (status, owner, notes, start time, or end time) of the current Visit (ID: {{!@variables.visitId}}) using the appropriate LWC form.

            SECTION 1: DISPATCH UPDATE ACTION
            - If the user has just entered this subagent, or selects an update field from the menu, call the corresponding action immediately:
              * "Status" / Option 1 -> Call update_visit_status with only visitId.
              * "Owner" / Option 2 -> Call update_visit_owner with only visitId.
              * "Notes" / Option 3 -> Call update_visit_notes with only visitId.
              * "Start Time" / Option 4 -> Call update_visit_start_time with only visitId.
              * "End Time" / Option 5 -> Call update_visit_end_time with only visitId.
            - If the user's message does not specify a field to update, prompt them:
              "What would you like to update? Please select a field to update:
              1. Status
              2. Owner
              3. Notes
              4. Start Time
              5. End Time"

            SECTION 2: LWC SLOT-FILLING AND MANUAL INPUT TRANSITION
            - Since the LWC parameters (statusWrapper, ownerWrapper, plannedStartTimeWrapper, plannedEndTimeWrapper) are required, the platform will prompt the user to fill the form in the chat.
            - If the user types "manual input" in the chat box while they are viewing the LWC form:
              * Do NOT transition to another action or subagent.
              * Populate the required input wrapper parameter of the active action with the manual input dummy indicator:
                - If Status update -> set statusWrapper.statusValue = "manual input".
                - If Owner update -> set ownerWrapper.ownerName = "manual input".
                - If Start Time update -> set plannedStartTimeWrapper.dateTimeValue = "1900-01-01T00:00:00Z".
                - If End Time update -> set plannedEndTimeWrapper.dateTimeValue = "1900-01-01T00:00:00Z".
              * Once the action returns the conversational choices prompt text, immediately transition to the Update Visit Text subagent using go_to_update_visit_text.

            SECTION 3: RETURN ON SUCCESS
            - If any update action returns success = True:
              * Print a success message (e.g. "Perfect! I've updated the visit status to InProgress ✅").
              * Transition back to the main dashboard using go_to_intelligence.
            - If any update action returns success = False (other than the manual input fallback), print the returned message verbatim and prompt the user to try again or type "manual input".

        actions:
            update_visit_status: @actions.update_visit_status
                with visitId = @variables.visitId
                with statusWrapper = ...

            update_visit_owner: @actions.update_visit_owner
                with visitId = @variables.visitId
                with ownerWrapper = ...

            update_visit_notes: @actions.update_visit_notes
                with visitId = @variables.visitId
                with notes = ...

            update_visit_start_time: @actions.update_visit_start_time
                with visitId = @variables.visitId
                with plannedStartTimeWrapper = ...
                with plannedStartTimeStr = ...

            update_visit_end_time: @actions.update_visit_end_time
                with visitId = @variables.visitId
                with plannedEndTimeWrapper = ...
                with plannedEndTimeStr = ...

            go_to_update_visit_text: @utils.transition to @subagent.update_visit_text
            go_to_intelligence: @utils.transition to @subagent.visit_intelligence

    actions:
{lwc_schemas}

subagent update_visit_text:
    label: "Update Visit Text"
    description: "Update the status, owner, notes, start time, or end time of the current visit conversationally using plain text inputs."
    before_reasoning:
        set @variables.activeSubagent = "update_visit_text"
    reasoning:
        instructions: |
            You are now in the Update Visit Text subagent.
            Your goal is to update details (status, owner, notes, start time, or end time) of the current Visit (ID: {{!@variables.visitId}}) conversationally using text inputs.

            SECTION 1: DISPATCH UPDATE ACTION
            - If the user selects a field or option from the menu, call the corresponding conversational mobile action:
              * "Status" / Option 1 -> Call update_visit_status_mobile with only visitId.
              * "Owner" / Option 2 -> Call update_visit_owner_mobile with only visitId.
              * "Notes" / Option 3 -> Call update_visit_notes_mobile with only visitId.
              * "Start Time" / Option 4 -> Call update_visit_start_time_mobile with only visitId.
              * "End Time" / Option 5 -> Call update_visit_end_time_mobile with only visitId.
            - If the user has just transitioned here due to manual input, or if their message does not specify a field to update, prompt them:
              "What would you like to update? Please select a field to update:
              1. Status
              2. Owner
              3. Notes
              4. Start Time
              5. End Time"

            SECTION 2: RETURN ON SUCCESS
            - If any update action returns success = True:
              * Print a success message (e.g. "Perfect! I've updated the visit status to InProgress ✅").
              * Transition back to the main dashboard using go_to_intelligence.
            - If any update action returns success = False, print the returned message verbatim and capture their subsequent text input.

        actions:
            update_visit_status_mobile: @actions.update_visit_status_mobile_action
                with visitId = @variables.visitId
                with status = ...

            update_visit_owner_mobile: @actions.update_visit_owner_mobile_action
                with visitId = @variables.visitId
                with ownerName = ...
                with suggestions = @variables.tempOwnerSuggestions
                set @variables.tempOwnerSuggestions = @outputs.suggestions

            update_visit_notes_mobile: @actions.update_visit_notes_mobile_action
                with visitId = @variables.visitId
                with notes = ...

            update_visit_start_time_mobile: @actions.update_visit_start_time_mobile_action
                with visitId = @variables.visitId
                with plannedStartTimeStr = ...

            update_visit_end_time_mobile: @actions.update_visit_end_time_mobile_action
                with visitId = @variables.visitId
                with plannedEndTimeStr = ...

            go_to_intelligence: @utils.transition to @subagent.visit_intelligence

    actions:
{mobile_schemas}
""" + target_subagent

content = content.replace(target_subagent, new_subagents_code, 1)
print("5. Subagents code inserted successfully.")

# Write back to file
open(filepath, 'w', encoding='utf-8').write(content)
print("Refactoring complete.")
