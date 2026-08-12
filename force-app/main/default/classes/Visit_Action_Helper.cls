/**
 * @description Helper class to handle Visit DML operations, creation, status/owner updates, mobile action prompting, navigation, stale visit queries, and alert processing.
 */
@SuppressWarnings(
  'PMD.AvoidDebugStatements, PMD.CognitiveComplexity, PMD.CyclomaticComplexity, PMD.NcssMethodCount, PMD.ExcessiveClassLength, PMD.StdCyclomaticComplexity'
)
public with sharing class Visit_Action_Helper {
  /**
   * @description Updates an existing visit based on agent request.
   * @param req Agent request containing update parameters.
   * @return Agent_Response Result of the update operation.
   */
  public static Agent_Response updateVisit(Agent_Request req) {
    Agent_Response res = new Agent_Response();
    res.success = false;

    try {
      String action = req.actionType != null
        ? req.actionType.toLowerCase().trim()
        : '';

      if (
        action == 'update_visit_status' ||
        action == 'update_visit_status_mobile_action'
      ) {
        if (
          String.isBlank(req.status) ||
          req.status.trim() == '' ||
          req.status.trim() == '__user_input__'
        ) {
          res.success = false;
          res.message = 'Please select the new status for the visit:\n1. InProgress\n2. Completed\n3. Canceled\n4. Abandoned';
          return res;
        }
      }
      if (
        action == 'update_visit_owner' ||
        action == 'update_visit_owner_mobile_action'
      ) {
        if (
          String.isBlank(req.ownerName) ||
          req.ownerName.trim() == '' ||
          req.ownerName.trim() == '__user_input__'
        ) {
          res.success = false;
          res.message = 'Please provide the name of the user you want to reassign this visit to.';
          return res;
        }
      }
      if (action == 'update_visit_notes_mobile_action') {
        if (
          String.isBlank(req.notes) ||
          req.notes.trim() == '' ||
          req.notes.trim() == '__user_input__'
        ) {
          res.success = false;
          res.message = 'Please enter the notes you want to add to this visit.';
          return res;
        }
      }
      if (
        action == 'update_visit_start_time' ||
        action == 'update_visit_start_time_mobile_action'
      ) {
        if (
          String.isBlank(req.plannedStartTimeStr) ||
          req.plannedStartTimeStr.trim() == '' ||
          req.plannedStartTimeStr.trim() == '__user_input__'
        ) {
          res.success = false;
          res.message = 'Please provide the new planned start date and time for the visit (e.g. "Tomorrow at 2 PM", "July 16, 2026 at 10:00 AM").';
          return res;
        }
      }
      if (
        action == 'update_visit_end_time' ||
        action == 'update_visit_end_time_mobile_action'
      ) {
        if (
          String.isBlank(req.plannedEndTimeStr) ||
          req.plannedEndTimeStr.trim() == '' ||
          req.plannedEndTimeStr.trim() == '__user_input__'
        ) {
          res.success = false;
          res.message = 'Please provide the new planned end date and time for the visit (e.g. "Tomorrow at 3 PM", "July 16, 2026 at 11:00 AM").';
          return res;
        }
      }

      if (
        action == 'update_visit_owner_mobile_action' &&
        String.isNotBlank(req.ownerName)
      ) {
        MobileAgentUtility.MatchResult mr = MobileAgentUtility.matchRecord(
          req.ownerName,
          'User',
          req.suggestions
        );
        if (mr.success) {
          req.ownerId = mr.matchedId;
        } else {
          res.success = false;
          res.message = mr.message;
          res.suggestions = mr.suggestions;
          return res;
        }
      }

      if (String.isNotBlank(req.plannedStartTimeStr)) {
        req.plannedStartTime = MobileAgentUtility.parseDateTime(
          req.plannedStartTimeStr
        );
      }
      if (String.isNotBlank(req.plannedEndTimeStr)) {
        req.plannedEndTime = MobileAgentUtility.parseDateTime(
          req.plannedEndTimeStr
        );
      }

      Id parsedVisitId = resolveVisitId(req.visitId);
      if (parsedVisitId == null) {
        res.message = 'Visit record not found for: ' + req.visitId;
        return res;
      }

      List<Visit> visits = [
        SELECT
          Id,
          Status,
          PlannedVisitStartTime,
          PlannedVisitEndTime,
          cgcloud__Note__c,
          OwnerId,
          cgcloud__Responsible__c,
          cgcloud__Subject__c,
          AccountId,
          PlaceId,
          cgcloud__Visit_Template__c,
          cgcloud__IsAllDayEvent__c,
          cgcloud__Accountable__c
        FROM Visit
        WHERE Id = :parsedVisitId
        WITH USER_MODE
        LIMIT 1
      ];
      if (visits.isEmpty()) {
        res.message = 'Visit record not found with ID: ' + req.visitId;
        return res;
      }

      Visit v = visits[0];
      DateTime targetPlannedStart = req.plannedStartTime != null
        ? req.plannedStartTime
        : req.startTime;
      DateTime targetPlannedEnd = req.plannedEndTime != null
        ? req.plannedEndTime
        : req.endTime;
      Boolean changed = false;

      if (action == 'update_visit_record' && req.createVisitWrapper != null) {
        v.cgcloud__Subject__c = req.createVisitWrapper.subject;
        v.AccountId = req.createVisitWrapper.accountId;
        v.PlaceId = req.createVisitWrapper.placeId;
        v.cgcloud__Visit_Template__c = req.createVisitWrapper.visitTemplateId;
        v.PlannedVisitStartTime = req.createVisitWrapper.plannedStartTime;
        v.PlannedVisitEndTime = req.createVisitWrapper.plannedEndTime;
        v.cgcloud__IsAllDayEvent__c = req.createVisitWrapper.isAllDayEvent !=
          null
          ? req.createVisitWrapper.isAllDayEvent
          : false;
        v.cgcloud__Responsible__c = req.createVisitWrapper.responsibleId;
        v.cgcloud__Accountable__c = req.createVisitWrapper.accountableId;

        if (req.createVisitWrapper.responsibleId != null) {
          v.OwnerId = req.createVisitWrapper.responsibleId;
        }
        changed = true;
      }

      if (String.isNotBlank(req.status)) {
        String statusCmd = req.status.toLowerCase().trim();
        if (
          statusCmd == '1' ||
          statusCmd.contains('in progress') ||
          statusCmd.contains('inprogress') ||
          statusCmd == 'start'
        ) {
          v.Status = 'InProgress';
          if (targetPlannedStart == null) {
            targetPlannedStart = DateTime.now();
          }
          changed = true;
        } else if (
          statusCmd == '2' ||
          statusCmd.contains('complete') ||
          statusCmd == 'end'
        ) {
          v.Status = 'Completed';
          if (targetPlannedEnd == null) {
            targetPlannedEnd = DateTime.now();
          }
          changed = true;
        } else if (statusCmd == '3' || statusCmd.contains('cancel')) {
          v.Status = 'Canceled';
          changed = true;
        } else if (statusCmd == '4' || statusCmd.contains('abandon')) {
          v.Status = 'Abandoned';
          changed = true;
        } else {
          v.Status = req.status;
          changed = true;
        }
      }

      if (String.isNotBlank(req.notes)) {
        String currentNotes = String.isNotBlank(v.cgcloud__Note__c)
          ? v.cgcloud__Note__c
          : '';
        if (String.isNotBlank(currentNotes)) {
          v.cgcloud__Note__c = currentNotes + '\n' + req.notes;
        } else {
          v.cgcloud__Note__c = req.notes;
        }
        changed = true;
      }

      if (targetPlannedStart != null) {
        v.PlannedVisitStartTime = targetPlannedStart;
        changed = true;
      }
      if (targetPlannedEnd != null) {
        v.PlannedVisitEndTime = targetPlannedEnd;
        changed = true;
      }

      if (String.isNotBlank(req.ownerId) || String.isNotBlank(req.ownerName)) {
        List<User> users = new List<User>();
        if (String.isNotBlank(req.ownerId)) {
          String cleanId = req.ownerId.trim();
          users = [
            SELECT Id
            FROM User
            WHERE Id = :cleanId AND IsActive = TRUE
            WITH USER_MODE
            LIMIT 1
          ];
        } else if (String.isNotBlank(req.ownerName)) {
          String cleanName = req.ownerName.trim();
          if (
            (cleanName.length() == 15 || cleanName.length() == 18) &&
            Pattern.matches('[a-zA-Z0-9]{15,18}', cleanName)
          ) {
            users = [
              SELECT Id
              FROM User
              WHERE Id = :cleanName AND IsActive = TRUE
              WITH USER_MODE
              LIMIT 1
            ];
          } else {
            users = [
              SELECT Id
              FROM User
              WHERE
                (Name = :cleanName
                OR Username = :cleanName)
                AND IsActive = TRUE
              WITH USER_MODE
              LIMIT 1
            ];
          }
        }

        if (!users.isEmpty()) {
          v.OwnerId = users[0].Id;
          v.cgcloud__Responsible__c = users[0].Id;
          changed = true;
        } else {
          res.message = 'User not found. ';
        }
      }

      if (changed) {
        Database.update(v, AccessLevel.USER_MODE);
        List<Visit> verifyList = [
          SELECT Status
          FROM Visit
          WHERE Id = :v.Id
          WITH USER_MODE
          LIMIT 1
        ];
        if (
          !verifyList.isEmpty() &&
          String.isNotBlank(req.status) &&
          verifyList[0].Status != v.Status
        ) {
          res.success = false;
          res.message =
            'Can\'t move from ' +
            verifyList[0].Status +
            ' to ' +
            req.status +
            ' manually.';
        } else {
          res.success = true;
          List<Visit> freshVisits = [
            SELECT Status, PlannedVisitStartTime, PlannedVisitEndTime, cgcloud__Note__c, Owner.Name, cgcloud__Responsible__r.Name
            FROM Visit
            WHERE Id = :v.Id
            WITH USER_MODE
            LIMIT 1
          ];
          if (!freshVisits.isEmpty()) {
            Visit freshV = freshVisits[0];
            String detailMsg = 'Visit updated successfully.\n\n';
            if (action == 'update_visit_status' || action == 'update_visit_status_mobile_action') {
              detailMsg += 'New Status: ' + freshV.Status;
            } else if (action == 'update_visit_notes_mobile_action' || action == 'update_visit_notes') {
              detailMsg += 'Updated Notes: "' + freshV.cgcloud__Note__c + '"';
            } else if (action == 'update_visit_owner' || action == 'update_visit_owner_mobile_action') {
              detailMsg += 'New Assigned User: ' + freshV.Owner.Name;
            } else if (action == 'update_visit_start_time' || action == 'update_visit_start_time_mobile_action') {
              detailMsg += 'New Planned Start Time: ' + (freshV.PlannedVisitStartTime != null ? freshV.PlannedVisitStartTime.format('yyyy-MM-dd hh:mm a') : 'N/A');
            } else if (action == 'update_visit_end_time' || action == 'update_visit_end_time_mobile_action') {
              detailMsg += 'New Planned End Time: ' + (freshV.PlannedVisitEndTime != null ? freshV.PlannedVisitEndTime.format('yyyy-MM-dd hh:mm a') : 'N/A');
            } else {
              detailMsg += 'Status: ' + freshV.Status + '\n';
              detailMsg += 'Assigned User: ' + freshV.Owner.Name + '\n';
              if (freshV.PlannedVisitStartTime != null) {
                detailMsg += 'Start Time: ' + freshV.PlannedVisitStartTime.format('yyyy-MM-dd hh:mm a') + '\n';
              }
              if (freshV.PlannedVisitEndTime != null) {
                detailMsg += 'End Time: ' + freshV.PlannedVisitEndTime.format('yyyy-MM-dd hh:mm a') + '\n';
              }
              if (String.isNotBlank(freshV.cgcloud__Note__c)) {
                detailMsg += 'Notes: ' + freshV.cgcloud__Note__c + '\n';
              }
            }
            res.message = detailMsg;
          } else {
            res.message = 'Visit updated successfully.';
          }
        }
      } else {
        res.success = true;
        res.message = 'No updates were made to the Visit record.';
      }
    } catch (Exception e) {
      res.success = false;
      res.message = 'Error updating visit: ' + e.getMessage();
    }
    return res;
  }

  /**
   * @description Resolves string identifier to valid Visit ID.
   * @param identifier Visit ID or Name.
   * @return Id Valid Visit ID or null.
   */
  public static Id resolveVisitId(String identifier) {
    if (String.isBlank(identifier)) {
      return null;
    }
    try {
      return (Id) identifier;
    } catch (Exception e) {
      List<Visit> matched = [
        SELECT Id
        FROM Visit
        WHERE Name = :identifier
        WITH USER_MODE
        LIMIT 1
      ];
      if (!matched.isEmpty()) {
        return matched[0].Id;
      }
    }
    return null;
  }

  /**
   * @description Retrieves current visit details formatted for full-form update.
   * @param req Agent request containing visitId.
   * @return Agent_Response Response with pre-populated CreateVisitWrapper.
   */
  public static Agent_Response getVisitForUpdate(Agent_Request req) {
    Agent_Response res = new Agent_Response();
    res.success = false;
    try {
      Id parsedVisitId = resolveVisitId(req.visitId);
      if (parsedVisitId == null) {
        res.message = 'Visit record not found for: ' + req.visitId;
        return res;
      }
      List<Visit> visits = [
        SELECT
          Id,
          cgcloud__Subject__c,
          AccountId,
          PlaceId,
          cgcloud__Visit_Template__c,
          PlannedVisitStartTime,
          PlannedVisitEndTime,
          cgcloud__IsAllDayEvent__c,
          cgcloud__Responsible__c,
          cgcloud__Accountable__c
        FROM Visit
        WHERE Id = :parsedVisitId
        WITH USER_MODE
        LIMIT 1
      ];
      if (visits.isEmpty()) {
        res.message = 'Visit record not found with ID: ' + req.visitId;
        return res;
      }
      Visit v = visits[0];
      CreateVisitWrapper wrapper = new CreateVisitWrapper();
      wrapper.subject = v.cgcloud__Subject__c;
      wrapper.accountId = v.AccountId;
      wrapper.placeId = v.PlaceId;
      wrapper.visitTemplateId = v.cgcloud__Visit_Template__c;
      wrapper.plannedStartTime = v.PlannedVisitStartTime;
      wrapper.plannedEndTime = v.PlannedVisitEndTime;
      wrapper.isAllDayEvent = v.cgcloud__IsAllDayEvent__c;
      wrapper.accountableId = v.cgcloud__Accountable__c;
      wrapper.responsibleId = v.cgcloud__Responsible__c;

      res.createVisitWrapper = wrapper;
      res.success = true;
      res.message = 'Loaded visit details successfully.';
    } catch (Exception e) {
      res.success = false;
      res.message = 'Error loading visit for update: ' + e.getMessage();
    }
    return res;
  }

  /**
   * @description Creates a new visit based on the agent request.
   * @param req Agent request.
   * @param res Agent response to populate.
   */
  public static void createVisit(Agent_Request req, Agent_Response res) {
    try {
      Visit newVisit = new Visit();

      if (req.createVisitWrapper != null) {
        newVisit.cgcloud__Subject__c = req.createVisitWrapper.subject;
        newVisit.AccountId = req.createVisitWrapper.accountId;
        newVisit.PlaceId = req.createVisitWrapper.placeId;
        if (req.createVisitWrapper.visitTemplateId != null) {
          newVisit.cgcloud__Visit_Template__c = req.createVisitWrapper.visitTemplateId;
        }
        newVisit.PlannedVisitStartTime = req.createVisitWrapper.plannedStartTime;
        if (req.createVisitWrapper.plannedEndTime != null) {
          newVisit.PlannedVisitEndTime = req.createVisitWrapper.plannedEndTime;
        }
        newVisit.cgcloud__IsAllDayEvent__c = req.createVisitWrapper.isAllDayEvent !=
          null
          ? req.createVisitWrapper.isAllDayEvent
          : false;

        Id respId = req.createVisitWrapper.responsibleId;
        if (respId == null) {
          List<User> runningUser = [
            SELECT Profile.Name
            FROM User
            WHERE Id = :UserInfo.getUserId()
            WITH USER_MODE
            LIMIT 1
          ];
          if (
            !runningUser.isEmpty() &&
            runningUser[0].Profile.Name == 'CGCloud_User_Profile'
          ) {
            respId = UserInfo.getUserId();
          } else {
            List<User> cgUsers = [
              SELECT Id
              FROM User
              WHERE Profile.Name = 'CGCloud_User_Profile' AND IsActive = TRUE
              WITH USER_MODE
              LIMIT 1
            ];
            respId = !cgUsers.isEmpty() ? cgUsers[0].Id : UserInfo.getUserId();
          }
        }
        newVisit.cgcloud__Responsible__c = respId;
        if (req.createVisitWrapper.accountableId != null) {
          newVisit.cgcloud__Accountable__c = req.createVisitWrapper.accountableId;
        } else {
          newVisit.cgcloud__Accountable__c = respId;
        }
      } else {
        newVisit.cgcloud__Subject__c = req.subject;
        newVisit.AccountId = req.accountInput != null
          ? req.accountInput
          : req.accountId;
        newVisit.PlaceId = req.placeInput != null
          ? req.placeInput
          : req.placeId;
        if (req.templateInput != null) {
          newVisit.cgcloud__Visit_Template__c = req.templateInput;
        }
        if (req.plannedStartTime != null) {
          newVisit.PlannedVisitStartTime = req.plannedStartTime;
        } else if (req.plannedStartTimeStr != null) {
          newVisit.PlannedVisitStartTime = MobileAgentUtility.parseDateTime(
            req.plannedStartTimeStr
          );
        }
        if (req.plannedEndTime != null) {
          newVisit.PlannedVisitEndTime = req.plannedEndTime;
        }
        newVisit.cgcloud__IsAllDayEvent__c = req.isAllDayEvent != null
          ? req.isAllDayEvent
          : false;

        Id respId = null;
        List<User> runningUser = [
          SELECT Profile.Name
          FROM User
          WHERE Id = :UserInfo.getUserId()
          WITH USER_MODE
          LIMIT 1
        ];
        if (
          !runningUser.isEmpty() &&
          runningUser[0].Profile.Name == 'CGCloud_User_Profile'
        ) {
          respId = UserInfo.getUserId();
        } else {
          List<User> cgUsers = [
            SELECT Id
            FROM User
            WHERE Profile.Name = 'CGCloud_User_Profile' AND IsActive = TRUE
            WITH USER_MODE
            LIMIT 1
          ];
          respId = !cgUsers.isEmpty() ? cgUsers[0].Id : UserInfo.getUserId();
        }
        newVisit.cgcloud__Responsible__c = respId;
        newVisit.cgcloud__Accountable__c = respId;
      }

      Id recordTypeId = null;
      try {
        recordTypeId = Schema.SObjectType.Visit.getRecordTypeInfosByDeveloperName()
          .get('cgcloud__Default')
          ?.getRecordTypeId();
      } catch (Exception e) {
        System.debug(LoggingLevel.ERROR, e.getMessage());
      }
      if (recordTypeId == null) {
        try {
          recordTypeId = Schema.SObjectType.Visit.getRecordTypeInfosByDeveloperName()
            .get('cgcloud__Editable')
            ?.getRecordTypeId();
        } catch (Exception e) {
          System.debug(LoggingLevel.ERROR, e.getMessage());
        }
      }
      if (recordTypeId != null) {
        newVisit.RecordTypeId = recordTypeId;
      }

      newVisit.Status = 'Planned';
      insert as user newVisit;

      Visit inserted = [
        SELECT Id, Status, PlannedVisitStartTime, Owner.Name
        FROM Visit
        WHERE Id = :newVisit.Id
        WITH USER_MODE
        LIMIT 1
      ];

      res.success = true;
      res.visitId = inserted.Id;
      res.visitStatus = inserted.Status;
      res.visitDate = inserted.PlannedVisitStartTime != null
        ? inserted.PlannedVisitStartTime.format('yyyy-MM-dd HH:mm:ss')
        : '';
      res.assignedUser = inserted.Owner != null ? inserted.Owner.Name : '';
      res.message = 'Visit successfully created!';
    } catch (Exception e) {
      res.success = false;
      res.message = 'Error creating Visit record: ' + e.getMessage();
    }
  }

  /**
   * @description Prompts the visit mobile.
   * @param req Agent request.
   * @param res Agent response.
   */
  public static void promptVisitMobile(Agent_Request req, Agent_Response res) {
    res.isSubmitted = false;
    res.suggestions = '';

    if (
      req.plannedStartTimeStr != null && !isPlaceholder(req.plannedStartTimeStr)
    ) {
      try {
        DateTime parsedDt = MobileAgentUtility.parseDateTime(
          req.plannedStartTimeStr
        );
        if (parsedDt != null) {
          res.success = true;
          res.isSubmitted = true;
          res.plannedStartTimeStr = parsedDt.formatGmt(
            'yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\''
          );
          res.message =
            'Excellent! I\'ve scheduled the visit for ' +
            parsedDt.format('dd-MMM-yyyy h:mm a') +
            ' .. Let me create it for you.';
        } else {
          res.success = false;
          res.isSubmitted = true;
          res.message =
            'Failed to parse date/time "' +
            req.plannedStartTimeStr +
            '". Please enter a valid date/time.';
        }
      } catch (Exception e) {
        res.message = 'Error parsing date/time: ' + e.getMessage();
      }
      return;
    }

    if (req.templateInput != null && !isPlaceholder(req.templateInput)) {
      try {
        MobileAgentUtility.MatchResult mr = MobileAgentUtility.matchRecord(
          req.templateInput,
          'cgcloud__Visit_Template__c',
          req.suggestions
        );
        res.success = mr.success;
        res.isSubmitted = true;
        res.message = mr.message;
        res.suggestions = mr.suggestions;
        if (mr.success) {
          res.templateId = mr.matchedId;
          res.templateName = mr.matchedName;
        }
      } catch (Exception e) {
        res.message = 'Error resolving Template: ' + e.getMessage();
      }
      return;
    }

    if (req.placeInput != null && !isPlaceholder(req.placeInput)) {
      try {
        MobileAgentUtility.MatchResult mr = MobileAgentUtility.matchRecord(
          req.placeInput,
          'RetailStore',
          req.suggestions
        );
        if (!mr.success && String.isBlank(req.suggestions)) {
          mr = MobileAgentUtility.matchRecord(
            req.placeInput,
            'Schema.Location',
            req.suggestions
          );
        }
        res.success = mr.success;
        res.isSubmitted = true;
        res.message = mr.message;
        res.suggestions = mr.suggestions;
        if (mr.success) {
          res.placeId = mr.matchedId;
          res.placeName = mr.matchedName;
        }
      } catch (Exception e) {
        res.message = 'Error resolving Place: ' + e.getMessage();
      }
      return;
    }

    if (req.accountInput != null && !isPlaceholder(req.accountInput)) {
      try {
        MobileAgentUtility.MatchResult mr = MobileAgentUtility.matchRecord(
          req.accountInput,
          'Account',
          req.suggestions
        );
        res.success = mr.success;
        res.isSubmitted = true;
        res.message = mr.message;
        res.suggestions = mr.suggestions;
        if (mr.success) {
          res.accountId = mr.matchedId;
          res.accountName = mr.matchedName;
        }
      } catch (Exception e) {
        res.message = 'Error resolving Account: ' + e.getMessage();
      }
      return;
    }

    res.message = 'No valid prompt input provided.';
  }

  /**
   * @description Checks if input string is placeholder string.
   * @param input Input string.
   * @return Boolean True if placeholder.
   */
  public static Boolean isPlaceholder(String input) {
    if (String.isBlank(input)) {
      return true;
    }
    String lower = input.toLowerCase();
    return lower.contains('user_input_required') ||
      lower.contains('__user_input_required__') ||
      lower.contains('user-input-required') ||
      (lower.contains('user') &&
      lower.contains('input') &&
      lower.contains('required'));
  }

  /**
   * @description Selects visit by ID and returns navigation payload.
   * @param req Agent request.
   * @return Agent_Response Agent response.
   */
  public static Agent_Response selectAndNavigateVisit(Agent_Request req) {
    Agent_Response res = new Agent_Response();
    try {
      if (String.isBlank(req.visitId)) {
        res.success = false;
        res.message = 'Visit ID (visitId) is required.';
        return res;
      }

      Id visitId = (Id) req.visitId.trim();
      Boolean hasResponsible = Schema.sObjectType.Visit.fields.getMap()
        .containsKey('cgcloud__Responsible__c');
      Boolean hasAccountable = Schema.sObjectType.Visit.fields.getMap()
        .containsKey('cgcloud__Accountable__c');

      String query = 'SELECT Id, Name, Status, PlannedVisitStartTime, PlannedVisitEndTime, AccountId, Account.Name';
      if (hasResponsible) {
        query += ', cgcloud__Responsible__c, cgcloud__Responsible__r.Name';
      }
      if (hasAccountable) {
        query += ', cgcloud__Accountable__c, cgcloud__Accountable__r.Name';
      }
      query += ' WITH USER_MODE LIMIT 1 FOR VIEW';

      List<Visit> visits = Database.query(query);
      if (!visits.isEmpty()) {
        Visit v = visits[0];
        res.visitId = v.Id;
        res.accountId = v.AccountId;
        res.accountName = v.Account != null ? v.Account.Name : '';
        res.visitStatus = v.Status;
        res.visitDate = v.PlannedVisitStartTime != null
          ? v.PlannedVisitStartTime.format(
              'yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'',
              'UTC'
            )
          : '';
        res.visitEndDate = v.PlannedVisitEndTime != null
          ? v.PlannedVisitEndTime.format(
              'yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'',
              'UTC'
            )
          : '';

        if (hasResponsible && v.getSObject('cgcloud__Responsible__r') != null) {
          res.assignedUser = (String) v.getSObject('cgcloud__Responsible__r')
            .get('Name');
        } else {
          res.assignedUser = '';
        }

        if (hasAccountable && v.getSObject('cgcloud__Accountable__r') != null) {
          res.accountableUser = (String) v.getSObject('cgcloud__Accountable__r')
            .get('Name');
        } else {
          res.accountableUser = '';
        }

        res.success = true;
        res.message = 'Visit selected successfully. Navigating you to the Visit record page...';
      } else {
        res.success = false;
        res.message = 'Visit record not found for ID: ' + req.visitId;
      }
    } catch (Exception e) {
      res.success = false;
      res.message = 'Error selecting and navigating visit: ' + e.getMessage();
    }
    return res;
  }

  /**
   * @description Retrieves stale visits.
   * @param accountId Account ID filter.
   * @param searchOffset Query offset.
   * @return List<Agent_Response.StaleVisitInfo> List of stale visits.
   */
  public static List<Agent_Response.StaleVisitInfo> getStaleVisits(String accountId, String searchOffset) {
    List<Agent_Response.StaleVisitInfo> results = new List<Agent_Response.StaleVisitInfo>();
    DateTime yesterday = System.now().addDays(-1);

    String query = 'SELECT Id, Name, Status, CreatedDate, ActualVisitStartTime, PlannedVisitStartTime, ' +
                   'AccountId, Account.Name, cgcloud__Responsible__c, cgcloud__Responsible__r.Name, ' +
                   'OwnerId, Owner.Name ' +
                   'FROM Visit ' +
                   'WHERE ((Status = \'Planned\' AND CreatedDate < :yesterday) ' +
                   'OR (Status = \'InProgress\' AND (ActualVisitStartTime < :yesterday OR (ActualVisitStartTime = null AND LastModifiedDate < :yesterday))))';

    if (String.isNotBlank(accountId)) {
      query += ' AND AccountId = \'' + String.escapeSingleQuotes(accountId) + '\'';
    }

    query += ' WITH USER_MODE ORDER BY CreatedDate DESC LIMIT 20';

    if (String.isNotBlank(searchOffset)) {
      try {
        Integer offsetVal = Integer.valueOf(searchOffset.trim());
        if (offsetVal > 0) {
          query += ' OFFSET ' + offsetVal;
        }
      } catch (Exception e) {
        System.debug(LoggingLevel.WARN, 'Invalid searchOffset passed to getStaleVisits: ' + searchOffset);
      }
    }

    List<Visit> visits = Database.query(query);

    for (Visit v : visits) {
      Agent_Response.StaleVisitInfo res = new Agent_Response.StaleVisitInfo();
      res.visitId = v.Id;
      res.visitName = v.Name;
      res.accountName = v.Account != null ? v.Account.Name : '';
      res.status = v.Status;
      res.responsibleRepId = v.cgcloud__Responsible__c != null ? v.cgcloud__Responsible__c : v.OwnerId;
      res.responsibleRepName = v.cgcloud__Responsible__c != null && v.getSObject('cgcloud__Responsible__r') != null ? (String) v.getSObject('cgcloud__Responsible__r').get('Name') : v.Owner.Name;
      res.plannedStartTime = v.PlannedVisitStartTime;
      res.createdDate = v.CreatedDate;
      results.add(res);
    }

    return results;
  }

  /**
   * @description Sends custom notifications and creates offline tasks for specified visits.
   * @param visitIds List of Visit IDs.
   * @return Agent_Response Result of sending alerts.
   */
  public static Agent_Response sendVisitAlerts(List<String> visitIds) {
    Agent_Response res = new Agent_Response();
    res.success = false;

    if (visitIds == null || visitIds.isEmpty()) {
      res.message = 'No Visit IDs provided.';
      return res;
    }

    Id notificationTypeId;
    try {
      CustomNotificationType notificationType = [
        SELECT Id 
        FROM CustomNotificationType 
        WHERE DeveloperName = 'User_Notifications'
        WITH USER_MODE
        LIMIT 1
      ];
      notificationTypeId = notificationType.Id;
    } catch (Exception e) {
      System.debug(LoggingLevel.WARN, 'Custom Notification Type "Visit Alerts" not found: ' + e.getMessage());
    }

    Id taskRecordTypeId;
    try {
      RecordType rt = [
        SELECT Id 
        FROM RecordType 
        WHERE SObjectType = 'Task' AND (DeveloperName = 'User_Notification' OR DeveloperName = 'cgcloud__User_Notification')
        WITH USER_MODE
        LIMIT 1
      ];
      taskRecordTypeId = rt.Id;
    } catch (Exception e) {
      System.debug(LoggingLevel.WARN, 'Task Record Type "User_Notification" not found: ' + e.getMessage());
    }

    List<Visit> visits = [
      SELECT Id, Name, Status, cgcloud__Responsible__c, OwnerId, Account.Name
      FROM Visit
      WHERE Id IN :visitIds
      WITH USER_MODE
    ];

    if (visits.isEmpty()) {
      res.message = 'No matching Visit records found.';
      return res;
    }

    Set<Id> visitsWithNotifications = new Set<Id>();
    if (taskRecordTypeId != null) {
      List<Task> existingTasks = [
        SELECT WhatId 
        FROM Task 
        WHERE WhatId IN :visitIds 
          AND RecordTypeId = :taskRecordTypeId 
          AND Status != 'Completed'
        WITH USER_MODE
      ];
      for (Task t : existingTasks) {
        visitsWithNotifications.add(t.WhatId);
      }
    }

    List<Task> tasksToInsert = new List<Task>();
    Integer sentCount = 0;

    for (Visit v : visits) {
      if (visitsWithNotifications.contains(v.Id)) {
        continue;
      }

      Id recipientId = v.cgcloud__Responsible__c != null ? v.cgcloud__Responsible__c : v.OwnerId;
      if (recipientId == null) {
        continue;
      }

      String storeName = v.Account != null ? v.Account.Name : 'Store';
      String alertMessage = '';
      if (v.Status == 'Planned') {
        alertMessage = 'Visit ' + v.Name + ' for store ' + storeName + ' has been in Planned state for more than one day from its creation date.';
      } else if (v.Status == 'InProgress') {
        alertMessage = 'Visit ' + v.Name + ' for store ' + storeName + ' has been in In Progress state for more than one day.';
      } else {
        alertMessage = 'Visit ' + v.Name + ' for store ' + storeName + ' requires your attention.';
      }

      if (taskRecordTypeId != null) {
        Task t = new Task();
        t.RecordTypeId = taskRecordTypeId;
        t.OwnerId = recipientId;
        t.Subject = 'Visit Alerts';
        t.Description = alertMessage;
        t.ActivityDate = Date.today();
        t.Status = 'Open';
        t.WhatId = v.Id;
        tasksToInsert.add(t);
      }

      if (notificationTypeId != null) {
        try {
          Messaging.CustomNotification notification = new Messaging.CustomNotification();
          notification.setNotificationTypeId(notificationTypeId);
          notification.setTargetId(v.Id);
          notification.setTitle('Visit Alert');
          notification.setBody(alertMessage);
          notification.send(new Set<String>{ recipientId });
          sentCount++;
        } catch (Exception e) {
          System.debug(LoggingLevel.ERROR, 'Error sending custom notification for Visit ' + v.Id + ': ' + e.getMessage());
        }
      }
    }

    try {
      if (!tasksToInsert.isEmpty()) {
        insert as user tasksToInsert;
      }
      res.success = true;
      res.message = 'Successfully sent ' + sentCount + ' notifications and created offline tasks.';
    } catch (Exception e) {
      res.success = false;
      res.message = 'Failed to create offline tasks: ' + e.getMessage();
    }

    return res;
  }
}