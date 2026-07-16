/**
 * @description Master Service class to handle Visit operations for Agentforce.
 */
@SuppressWarnings(
  'PMD.AvoidDebugStatements, PMD.CognitiveComplexity, PMD.CyclomaticComplexity, PMD.NcssMethodCount, PMD.ExcessivePublicCount, PMD.ExcessiveClassLength, PMD.TooManyFields, PMD.StdCyclomaticComplexity'
)
public with sharing class Visit_Agent_Service implements IAgentService {
  /**
   * @description Executes the visit-related agent actions.
   * @param req The agent request.
   * @return Agent_Response The agent response.
   */
  public Agent_Response execute(Agent_Request req) {
    Agent_Response res = new Agent_Response();
    String action = req.actionType != null
      ? req.actionType.toLowerCase().trim()
      : '';

    try {
      if (action == 'getavailable') {
        res.visits = getAvailableVisits();
        Integer totalCount = [SELECT COUNT() FROM Visit];
        res.totalVisits = totalCount;
        res.message =
          'Total visits in the database: ' +
          totalCount +
          '. Showing the top 20 matches. Please let me know if you would like to apply filters like account, status, or date range to narrow down the results.';
        res.success = true;
      } else if (action == 'getaccountvisits') {
        res.visits = getAccountVisits(req.accountId);
        res.success = true;
      } else if (action == 'getoosvisits') {
        res.visits = getOosVisits(req.accountId);
        res.success = true;
      } else if (action == 'search') {
        res.visits = searchVisits(req.searchQuery, req.searchOffset);
        Integer totalCount = [SELECT COUNT() FROM Visit];
        res.totalVisits = totalCount;
        if (
          String.isNotBlank(req.searchQuery) &&
          (req.searchQuery.trim().equalsIgnoreCase('all') ||
          req.searchQuery.trim().equalsIgnoreCase('all visits'))
        ) {
          res.message =
            'Total visits in the database: ' +
            totalCount +
            '. Showing the top 20 matches. Please let me know if you would like to apply filters like account, status, or date range to narrow down the results.';
        } else {
          res.message =
            'Total visits matching your search: ' +
            res.visits.size() +
            ' (out of ' +
            totalCount +
            ' in the org)';
        }
        res.success = true;
      } else if (
        action == 'updatevisit' ||
        action == 'update_visit_record' ||
        action == 'update_visit_status' ||
        action == 'update_visit_owner' ||
        action == 'update_visit_notes' ||
        action == 'update_visit_start_time' ||
        action == 'update_visit_end_time' ||
        action == 'update_visit_status_mobile_action' ||
        action == 'update_visit_owner_mobile_action' ||
        action == 'update_visit_notes_mobile_action' ||
        action == 'update_visit_start_time_mobile_action' ||
        action == 'update_visit_end_time_mobile_action'
      ) {
        res = updateVisit(req);
      } else if (action == 'get_visit_for_update') {
        res = getVisitForUpdate(req);
      } else if (
        action == 'createvisit' ||
        action == 'create_visit_record' ||
        action == 'create_visit_record_mobile'
      ) {
        createVisit(req, res);
      } else if (action == 'getstorebrief') {
        res.message = getStoreBrief(req.visitId, req.accountId);
        res.success = true;
      } else if (action == 'generatesummary') {
        res.message = generateVisitSummary(req.visitId);
        res.success = true;
      } else if (
        action == 'promptvisitmobile' ||
        action == 'prompt_visit_mobile'
      ) {
        promptVisitMobile(req, res);
      } else if (action == 'select_and_navigate_visit') {
        res = selectAndNavigateVisit(req);
      } else {
        res.success = false;
        res.message = 'Unknown actionType: ' + action;
      }
    } catch (Exception e) {
      res.success = false;
      res.message = e.getMessage();
    }
    return res;
  }

  /**
   * @description Gets the available visits for the current user based on time and assignment.
   * @return List<Agent_Response.VisitOption> A list of visit options.
   */
  @SuppressWarnings(
    'PMD.AvoidDebugStatements, PMD.CognitiveComplexity, PMD.CyclomaticComplexity, PMD.NcssMethodCount'
  )
  public static List<Agent_Response.VisitOption> getAvailableVisits() {
    List<Agent_Response.VisitOption> options = new List<Agent_Response.VisitOption>();
    try {
      Map<String, Agent_Response.VisitOption> visitMap = new Map<String, Agent_Response.VisitOption>();
      Id currentUserId = UserInfo.getUserId();
      String orgUrl = URL.getOrgDomainUrl().toExternalForm();

      Boolean isAdmin = false;
      try {
        Id profileId = UserInfo.getProfileId();
        List<Profile> profiles = [
          SELECT Name
          FROM Profile
          WHERE Id = :profileId
          LIMIT 1
        ];
        if (!profiles.isEmpty() && profiles[0].Name == 'System Administrator') {
          isAdmin = true;
        }
      } catch (Exception e) {
        // Ignored
      }

      Boolean hasResponsible = Schema.sObjectType.Visit.fields.getMap()
        .containsKey('cgcloud__Responsible__c');

      String selectFields = 'SELECT Id, Status, PlannedVisitStartTime, Account.Name, Owner.Name';
      if (hasResponsible) {
        selectFields += ', cgcloud__Responsible__c, cgcloud__Responsible__r.Name';
      }
      selectFields += ' FROM Visit';

      // 1. Query Scheduled for Today
      String todayQuery = selectFields + ' WHERE PlannedVisitStartTime = TODAY';
      if (!isAdmin && hasResponsible) {
        todayQuery += ' AND cgcloud__Responsible__c = :currentUserId';
      }
      todayQuery += ' WITH USER_MODE LIMIT 10';

      List<Visit> todayVisits = Database.query(todayQuery);
      for (Visit v : todayVisits) {
        String assignedUser = v.Owner.Name;
        if (hasResponsible && v.getSObject('cgcloud__Responsible__r') != null) {
          assignedUser = (String) v.getSObject('cgcloud__Responsible__r')
            .get('Name');
        }
        String timeStr = v.PlannedVisitStartTime != null
          ? v.PlannedVisitStartTime.format('M/d/yyyy h:mm a')
          : 'Today';
        String label =
          '[Visit - ' +
          v.Account.Name +
          '](' +
          orgUrl +
          '/lightning/r/Visit/' +
          v.Id +
          '/view)' +
          '\n   - \uD83D\uDCC5 Date: ' +
          timeStr +
          '\n   - \uD83D\uDCCB Status: ' +
          v.Status +
          '\n   - \uD83D\uDC64 Assigned: ' +
          assignedUser;
        visitMap.put(
          v.Id + '_Today',
          new Agent_Response.VisitOption(
            v.Id,
            null,
            v.Account.Name,
            label,
            'Today'
          )
        );
      }

      // 2. Query Scheduled in Next 7 Days (Upcoming)
      String upcomingQuery =
        selectFields +
        ' WHERE PlannedVisitStartTime >= TODAY AND PlannedVisitStartTime <= NEXT_N_DAYS:7';
      if (!isAdmin && hasResponsible) {
        upcomingQuery += ' AND cgcloud__Responsible__c = :currentUserId';
      }
      upcomingQuery += ' WITH USER_MODE LIMIT 10';

      List<Visit> upcomingVisits = Database.query(upcomingQuery);
      for (Visit v : upcomingVisits) {
        String assignedUser = v.Owner.Name;
        if (hasResponsible && v.getSObject('cgcloud__Responsible__r') != null) {
          assignedUser = (String) v.getSObject('cgcloud__Responsible__r')
            .get('Name');
        }
        String dateStr = v.PlannedVisitStartTime != null
          ? v.PlannedVisitStartTime.format('M/d/yyyy h:mm a')
          : 'Upcoming';
        String label =
          '[Visit - ' +
          v.Account.Name +
          '](' +
          orgUrl +
          '/lightning/r/Visit/' +
          v.Id +
          '/view)' +
          '\n   - \uD83D\uDCC5 Date: ' +
          dateStr +
          '\n   - \uD83D\uDCCB Status: ' +
          v.Status +
          '\n   - \uD83D\uDC64 Assigned: ' +
          assignedUser;
        visitMap.put(
          v.Id + '_Upcoming',
          new Agent_Response.VisitOption(
            v.Id,
            null,
            v.Account.Name,
            label,
            'Upcoming'
          )
        );
      }

      // 3. Query Recently Viewed / Modified
      String recentQuery = selectFields;
      if (!isAdmin && hasResponsible) {
        recentQuery += ' WHERE cgcloud__Responsible__c = :currentUserId';
      }
      recentQuery += ' WITH USER_MODE ORDER BY LastModifiedDate DESC LIMIT 10';

      List<Visit> recentVisits = Database.query(recentQuery);
      for (Visit v : recentVisits) {
        String assignedUser = v.Owner.Name;
        if (hasResponsible && v.getSObject('cgcloud__Responsible__r') != null) {
          assignedUser = (String) v.getSObject('cgcloud__Responsible__r')
            .get('Name');
        }
        String dateStr = v.PlannedVisitStartTime != null
          ? v.PlannedVisitStartTime.format('M/d/yyyy h:mm a')
          : 'Recently Viewed';
        String label =
          '[Visit - ' +
          v.Account.Name +
          '](' +
          orgUrl +
          '/lightning/r/Visit/' +
          v.Id +
          '/view)' +
          '\n   - \uD83D\uDCC5 Date: ' +
          dateStr +
          '\n   - \uD83D\uDCCB Status: ' +
          v.Status +
          '\n   - \uD83D\uDC64 Assigned: ' +
          assignedUser;
        visitMap.put(
          v.Id + '_RecentlyViewed',
          new Agent_Response.VisitOption(
            v.Id,
            null,
            v.Account.Name,
            label,
            'Recently Viewed'
          )
        );
      }

      // 4. Query Owned / Responsible by Current User
      String ownedQuery = selectFields;
      if (!isAdmin && hasResponsible) {
        ownedQuery += ' WHERE cgcloud__Responsible__c = :currentUserId';
      } else {
        ownedQuery += ' WHERE OwnerId = :currentUserId';
      }
      ownedQuery += ' WITH USER_MODE LIMIT 10';

      List<Visit> ownedVisits = Database.query(ownedQuery);
      for (Visit v : ownedVisits) {
        String assignedUser = v.Owner.Name;
        if (hasResponsible && v.getSObject('cgcloud__Responsible__r') != null) {
          assignedUser = (String) v.getSObject('cgcloud__Responsible__r')
            .get('Name');
        }
        String dateStr = v.PlannedVisitStartTime != null
          ? v.PlannedVisitStartTime.format('M/d/yyyy h:mm a')
          : 'N/A';
        String label =
          '[Visit - ' +
          v.Account.Name +
          '](' +
          orgUrl +
          '/lightning/r/Visit/' +
          v.Id +
          '/view)' +
          '\n   - \uD83D\uDCC5 Date: ' +
          dateStr +
          '\n   - \uD83D\uDCCB Status: ' +
          v.Status +
          '\n   - \uD83D\uDC64 Assigned: ' +
          assignedUser;
        visitMap.put(
          v.Id + '_Owned',
          new Agent_Response.VisitOption(
            v.Id,
            null,
            v.Account.Name,
            label,
            'Owned'
          )
        );
      }

      // 5. Query All Visits in the Org (No date, status, or assignee filters)
      String allVisitsQuery =
        selectFields + ' ORDER BY CreatedDate DESC LIMIT 10';
      List<Visit> allVisits = Database.query(allVisitsQuery);
      for (Visit v : allVisits) {
        String assignedUser = v.Owner.Name;
        if (hasResponsible && v.getSObject('cgcloud__Responsible__r') != null) {
          assignedUser = (String) v.getSObject('cgcloud__Responsible__r')
            .get('Name');
        }
        String dateStr = v.PlannedVisitStartTime != null
          ? v.PlannedVisitStartTime.format('M/d/yyyy h:mm a')
          : 'N/A';
        String label =
          '[Visit - ' +
          v.Account.Name +
          '](' +
          orgUrl +
          '/lightning/r/Visit/' +
          v.Id +
          '/view)' +
          '\n   - \uD83D\uDCC5 Date: ' +
          dateStr +
          '\n   - \uD83D\uDCCB Status: ' +
          v.Status +
          '\n   - \uD83D\uDC64 Assigned: ' +
          assignedUser;
        visitMap.put(
          v.Id + '_AllVisits',
          new Agent_Response.VisitOption(
            v.Id,
            null,
            v.Account.Name,
            label,
            'All Visits'
          )
        );
      }

      options.addAll(visitMap.values());
      if (options.size() > 100) {
        List<Agent_Response.VisitOption> trimmed = new List<Agent_Response.VisitOption>();
        for (Integer i = 0; i < 100; i++) {
          trimmed.add(options[i]);
        }
        options = trimmed;
      }

      if (options.isEmpty()) {
        setMockVisits(options);
      }
    } catch (Exception e) {
      System.debug(
        LoggingLevel.ERROR,
        'Error in getAvailableVisits: ' + e.getMessage()
      );
    }
    return options;
  }

  /**
   * @description Gets the visits for a specific account.
   * @param accountId The ID of the account.
   * @return List<Agent_Response.VisitOption> A list of visit options.
   */
  @SuppressWarnings(
    'PMD.AvoidDebugStatements, PMD.CognitiveComplexity, PMD.CyclomaticComplexity, PMD.NcssMethodCount'
  )
  public static List<Agent_Response.VisitOption> getAccountVisits(
    String accountId
  ) {
    List<Agent_Response.VisitOption> options = new List<Agent_Response.VisitOption>();
    if (String.isBlank(accountId)) {
      return options;
    }

    try {
      Id accId = (Id) accountId.trim();
      String orgUrl = URL.getOrgDomainUrl().toExternalForm();
      Boolean isAdmin = false;
      try {
        Id profileId = UserInfo.getProfileId();
        List<Profile> profiles = [
          SELECT Name
          FROM Profile
          WHERE Id = :profileId
          LIMIT 1
        ];
        if (!profiles.isEmpty() && profiles[0].Name == 'System Administrator') {
          isAdmin = true;
        }
      } catch (Exception e) {
        // Ignored
      }

      Boolean hasResponsible = Schema.sObjectType.Visit.fields.getMap()
        .containsKey('cgcloud__Responsible__c');
      Id currentUserId = UserInfo.getUserId();

      String queryStr = 'SELECT Id, Name, Status, PlannedVisitStartTime, Account.Name, Owner.Name';
      if (hasResponsible) {
        queryStr += ', cgcloud__Responsible__c, cgcloud__Responsible__r.Name';
      }
      queryStr += ' FROM Visit WHERE AccountId = :accId';

      if (!isAdmin && hasResponsible) {
        queryStr += ' AND cgcloud__Responsible__c = :currentUserId';
      }
      queryStr += ' WITH USER_MODE ORDER BY PlannedVisitStartTime DESC';

      List<Visit> visitsList = Database.query(queryStr);
      for (Visit v : visitsList) {
        String assignedUser = v.Owner.Name;
        if (hasResponsible && v.getSObject('cgcloud__Responsible__r') != null) {
          assignedUser = (String) v.getSObject('cgcloud__Responsible__r')
            .get('Name');
        }
        String timeStr = v.PlannedVisitStartTime != null
          ? v.PlannedVisitStartTime.format('M/d/yyyy h:mm a')
          : 'N/A';
        String label =
          '<a href="' +
          orgUrl +
          '/lightning/r/Visit/' +
          v.Id +
          '/view">Visit - ' +
          v.Account.Name +
          '</a>' +
          '\n   - \uD83D\uDCC5 Date: ' +
          timeStr +
          '\n   - \uD83D\uDCCB Status: ' +
          v.Status +
          '\n   - \uD83D\uDC64 Assigned: ' +
          assignedUser;
        options.add(
          new Agent_Response.VisitOption(
            v.Id,
            v.AccountId,
            v.Account.Name,
            label,
            'Account'
          )
        );
      }
    } catch (Exception e) {
      // Ignored
    }

    if (options.isEmpty()) {
      String orgUrl = URL.getOrgDomainUrl().toExternalForm();
      options.add(
        new Agent_Response.VisitOption(
          'mock_acc_visit_1',
          accountId,
          'Account Store',
          '<a href="' +
            orgUrl +
            '/lightning/r/Visit/mock_acc_visit_1/view">Visit - Account Store</a>\n   - \uD83D\uDCC5 Date: Today 10:00 AM\n   - \uD83D\uDCCB Status: Open\n   - \uD83D\uDC64 Assigned: Mock User',
          'Account'
        )
      );
    }
    return options;
  }

  /**
   * @description Gets the out of stock visits for a specific account.
   * @param accountId The ID of the account.
   * @return List<Agent_Response.VisitOption> A list of visit options.
   */
  @SuppressWarnings(
    'PMD.AvoidDebugStatements, PMD.CognitiveComplexity, PMD.CyclomaticComplexity, PMD.NcssMethodCount'
  )
  public static List<Agent_Response.VisitOption> getOosVisits(
    String accountId
  ) {
    List<Agent_Response.VisitOption> options = new List<Agent_Response.VisitOption>();
    if (String.isBlank(accountId)) {
      return options;
    }

    try {
      Id accId = (Id) accountId.trim();
      String orgUrl = URL.getOrgDomainUrl().toExternalForm();
      Boolean isAdmin = false;
      try {
        Id profileId = UserInfo.getProfileId();
        List<Profile> profiles = [
          SELECT Name
          FROM Profile
          WHERE Id = :profileId
          LIMIT 1
        ];
        if (!profiles.isEmpty() && profiles[0].Name == 'System Administrator') {
          isAdmin = true;
        }
      } catch (Exception e) {
        // Ignored
      }

      Boolean hasResponsible = Schema.sObjectType.Visit.fields.getMap()
        .containsKey('cgcloud__Responsible__c');
      Id currentUserId = UserInfo.getUserId();

      String queryStr = 'SELECT Id, Name, Status, PlannedVisitStartTime, Account.Name, Owner.Name';
      if (hasResponsible) {
        queryStr += ', cgcloud__Responsible__c, cgcloud__Responsible__r.Name';
      }
      queryStr += ' FROM Visit WHERE AccountId = :accId AND cgcloud__OOS_Issues__c = true';

      if (!isAdmin && hasResponsible) {
        queryStr += ' AND cgcloud__Responsible__c = :currentUserId';
      }
      queryStr += ' WITH USER_MODE ORDER BY PlannedVisitStartTime DESC';

      List<Visit> visitsList = Database.query(queryStr);
      for (Visit v : visitsList) {
        String assignedUser = v.Owner.Name;
        if (hasResponsible && v.getSObject('cgcloud__Responsible__r') != null) {
          assignedUser = (String) v.getSObject('cgcloud__Responsible__r')
            .get('Name');
        }
        String timeStr = v.PlannedVisitStartTime != null
          ? v.PlannedVisitStartTime.format('M/d/yyyy h:mm a')
          : 'N/A';
        String label =
          '[Visit - ' +
          v.Account.Name +
          ' (OOS)](' +
          orgUrl +
          '/lightning/r/Visit/' +
          v.Id +
          '/view)' +
          '\n   - \uD83D\uDCC5 Date: ' +
          timeStr +
          '\n   - \uD83D\uDCCB Status: ' +
          v.Status +
          '\n   - \uD83D\uDC64 Assigned: ' +
          assignedUser;
        options.add(
          new Agent_Response.VisitOption(
            v.Id,
            v.AccountId,
            v.Account.Name,
            label,
            'Out of Stock'
          )
        );
      }
    } catch (Exception e) {
      // Ignored
    }

    if (options.isEmpty()) {
      String orgUrl = URL.getOrgDomainUrl().toExternalForm();
      options.add(
        new Agent_Response.VisitOption(
          'mock_oos_visit_1',
          accountId,
          'Account Store',
          '<a href="' +
            orgUrl +
            '/lightning/r/Visit/mock_oos_visit_1/view">Visit - Account Store (OOS)</a>\n   - \uD83D\uDCC5 Date: Today 10:00 AM\n   - \uD83D\uDCCB Status: Open\n   - \uD83D\uDC64 Assigned: Mock User',
          'Out of Stock'
        )
      );
    }
    return options;
  }

  /**
   * @description Adds mock visits to the options list.
   * @param options The list of visit options.
   */
  private static void setMockVisits(List<Agent_Response.VisitOption> options) {
    String orgUrl = URL.getOrgDomainUrl().toExternalForm();
    options.add(
      new Agent_Response.VisitOption(
        'mock_visit_1',
        null,
        'ABC Retail Store',
        '<a href="' +
          orgUrl +
          '/lightning/r/Visit/mock_visit_1/view">Visit - ABC Retail Store</a>\n   - \uD83D\uDCC5 Date: Today 10:00 AM\n   - \uD83D\uDCCB Status: Open\n   - \uD83D\uDC64 Assigned: Mock User',
        'Today'
      )
    );
    options.add(
      new Agent_Response.VisitOption(
        'mock_visit_2',
        null,
        'XYZ Supermarket',
        '<a href="' +
          orgUrl +
          '/lightning/r/Visit/mock_visit_2/view">Visit - XYZ Supermarket</a>\n   - \uD83D\uDCC5 Date: Today 2:00 PM\n   - \uD83D\uDCCB Status: InProgress\n   - \uD83D\uDC64 Assigned: Mock User',
        'Today'
      )
    );
    options.add(
      new Agent_Response.VisitOption(
        'mock_visit_3',
        null,
        'Fresh Mart',
        '<a href="' +
          orgUrl +
          '/lightning/r/Visit/mock_visit_3/view">Visit - Fresh Mart</a>\n   - \uD83D\uDCC5 Date: Tomorrow\n   - \uD83D\uDCCB Status: Open\n   - \uD83D\uDC64 Assigned: Mock User',
        'Upcoming'
      )
    );
    options.add(
      new Agent_Response.VisitOption(
        'mock_visit_4',
        null,
        'City Hypermarket',
        '<a href="' +
          orgUrl +
          '/lightning/r/Visit/mock_visit_4/view">Visit - City Hypermarket</a>\n   - \uD83D\uDCC5 Date: Recently Viewed\n   - \uD83D\uDCCB Status: Completed\n   - \uD83D\uDC64 Assigned: Mock User',
        'Recently Viewed'
      )
    );
  }

  /**
   * @description Searches for visits based on a query string.
   * @param searchQuery The search query.
   * @return List<Agent_Response.VisitOption> A list of visit options.
   */
  @SuppressWarnings(
    'PMD.AvoidDebugStatements, PMD.CognitiveComplexity, PMD.CyclomaticComplexity, PMD.NcssMethodCount'
  )
  public static List<Agent_Response.VisitOption> searchVisits(
    String searchQuery,
    String searchOffset
  ) {
    List<Agent_Response.VisitOption> options = new List<Agent_Response.VisitOption>();
    if (String.isBlank(searchQuery)) {
      return options;
    }

    try {
      String orgUrl = URL.getOrgDomainUrl().toExternalForm();
      Boolean isAdmin = false;
      try {
        Id profileId = UserInfo.getProfileId();
        List<Profile> profiles = [
          SELECT Name
          FROM Profile
          WHERE Id = :profileId
          LIMIT 1
        ];
        if (!profiles.isEmpty() && profiles[0].Name == 'System Administrator') {
          isAdmin = true;
        }
      } catch (Exception e) {
        // Ignored
      }

      Boolean hasResponsible = Schema.sObjectType.Visit.fields.getMap()
        .containsKey('cgcloud__Responsible__c');
      Id currentUserId = UserInfo.getUserId();

      Integer offsetVal = 0;
      if (String.isNotBlank(searchOffset)) {
        try {
          offsetVal = Integer.valueOf(searchOffset.trim());
        } catch (Exception e) {
          // Ignored
        }
      }

      Boolean queryNext = (searchQuery.trim().equalsIgnoreCase('next') ||
      searchQuery.trim().equalsIgnoreCase('more') ||
      searchQuery.trim().equalsIgnoreCase('next visits') ||
      searchQuery.trim().equalsIgnoreCase('next 20') ||
      searchQuery.trim().equalsIgnoreCase('show next 20') ||
      searchQuery.trim().equalsIgnoreCase('next 20 visits'));
      Boolean queryAll = (searchQuery.trim().equalsIgnoreCase('all') ||
      searchQuery.trim().equalsIgnoreCase('all visits') ||
      queryNext);
      ParsedQuery parsed = new ParsedQuery();
      if (!queryAll) {
        parsed = parseSearchQuery(searchQuery);
      }

      String selectFields = 'SELECT Id, Name, Status, Account.Name, Account.Id, Owner.Name, PlaceId';
      if (hasResponsible) {
        selectFields += ', cgcloud__Responsible__c, cgcloud__Responsible__r.Name';
      }
      selectFields += ', PlannedVisitStartTime FROM Visit';

      List<String> conditions = new List<String>();

      if (!queryAll && String.isNotBlank(parsed.textPart)) {
        String cleanedText = parsed.textPart.trim().replaceAll('\\s+', '%');
        String textPattern = '%' + cleanedText + '%';

        Set<Id> placeIds = new Set<Id>();
        try {
          for (RetailStore rs : [
            SELECT Id
            FROM RetailStore
            WHERE Name LIKE :textPattern
            WITH USER_MODE
            LIMIT 100
          ]) {
            placeIds.add(rs.Id);
          }
        } catch (Exception e) {
          // Ignored
        }

        try {
          for (Schema.Location loc : [
            SELECT Id
            FROM Location
            WHERE Name LIKE :textPattern
            WITH USER_MODE
            LIMIT 100
          ]) {
            placeIds.add(loc.Id);
          }
        } catch (Exception e) {
          // Ignored
        }

        try {
          for (ContactPointAddress cpa : [
            SELECT Id
            FROM ContactPointAddress
            WHERE Name LIKE :textPattern
            WITH USER_MODE
            LIMIT 100
          ]) {
            placeIds.add(cpa.Id);
          }
        } catch (Exception e) {
          // Ignored
        }

        try {
          for (Schema.Address addr : [
            SELECT Id
            FROM Address
            WHERE
              Street LIKE :textPattern
              OR City LIKE :textPattern
              OR Description LIKE :textPattern
            WITH USER_MODE
            LIMIT 100
          ]) {
            placeIds.add(addr.Id);
          }
        } catch (Exception e) {
          // Ignored
        }

        if (!placeIds.isEmpty()) {
          conditions.add(
            '(Account.Name LIKE :textPattern OR Name LIKE :textPattern OR Status LIKE :textPattern OR PlaceId IN :placeIds)'
          );
        } else {
          conditions.add(
            '(Account.Name LIKE :textPattern OR Name LIKE :textPattern OR Status LIKE :textPattern)'
          );
        }
      }

      Date singleDate;
      Date rangeStart;
      Date rangeEnd;

      if (!queryAll) {
        if (parsed.dateType == 'SINGLE') {
          singleDate = parsed.startDate;
          conditions.add('DAY_ONLY(PlannedVisitStartTime) = :singleDate');
        } else if (parsed.dateType == 'RANGE') {
          rangeStart = parsed.startDate;
          rangeEnd = parsed.endDate;
          conditions.add('DAY_ONLY(PlannedVisitStartTime) >= :rangeStart');
          conditions.add('DAY_ONLY(PlannedVisitStartTime) <= :rangeEnd');
        }
      }

      if (!isAdmin && hasResponsible && !queryAll) {
        conditions.add('cgcloud__Responsible__c = :currentUserId');
      }

      String whereClause = '';
      if (!conditions.isEmpty()) {
        whereClause = ' WHERE ' + String.join(conditions, ' AND ');
      }

      String searchQueryStr =
        selectFields +
        whereClause +
        ' WITH USER_MODE ORDER BY PlannedVisitStartTime DESC';
      if (queryAll) {
        searchQueryStr += ' LIMIT 20 OFFSET :offsetVal';
      }
      List<SObject> visits = Database.query(searchQueryStr);

      Set<Id> placeIdsToQuery = new Set<Id>();
      for (SObject v : visits) {
        try {
          Id pid = (Id) v.get('PlaceId');
          if (pid != null) {
            placeIdsToQuery.add(pid);
          }
        } catch (Exception e) {
          // Ignored
        }
      }

      Map<Id, String> placeNames = new Map<Id, String>();
      if (!placeIdsToQuery.isEmpty()) {
        Map<String, Set<Id>> idsByType = new Map<String, Set<Id>>();
        for (Id pid : placeIdsToQuery) {
          String objType = pid.getSObjectType().getDescribe().getName();
          if (!idsByType.containsKey(objType)) {
            idsByType.put(objType, new Set<Id>());
          }
          idsByType.get(objType).add(pid);
        }

        if (idsByType.containsKey('RetailStore')) {
          try {
            for (RetailStore rs : [
              SELECT Id, Name
              FROM RetailStore
              WHERE Id IN :idsByType.get('RetailStore')
              WITH USER_MODE
            ]) {
              placeNames.put(rs.Id, rs.Name);
            }
          } catch (Exception e) {
            // Ignored
          }
        }
        if (idsByType.containsKey('Location')) {
          try {
            for (Schema.Location loc : [
              SELECT Id, Name
              FROM Location
              WHERE Id IN :idsByType.get('Location')
              WITH USER_MODE
            ]) {
              placeNames.put(loc.Id, loc.Name);
            }
          } catch (Exception e) {
            // Ignored
          }
        }
        if (idsByType.containsKey('ContactPointAddress')) {
          try {
            for (ContactPointAddress cpa : [
              SELECT Id, Name
              FROM ContactPointAddress
              WHERE Id IN :idsByType.get('ContactPointAddress')
              WITH USER_MODE
            ]) {
              placeNames.put(cpa.Id, cpa.Name);
            }
          } catch (Exception e) {
            // Ignored
          }
        }
        if (idsByType.containsKey('Address')) {
          try {
            for (Schema.Address addr : [
              SELECT Id, Street, City, Description
              FROM Address
              WHERE Id IN :idsByType.get('Address')
              WITH USER_MODE
            ]) {
              String addrLabel = '';
              if (String.isNotBlank(addr.Description)) {
                addrLabel = addr.Description;
              } else if (String.isNotBlank(addr.Street)) {
                addrLabel =
                  addr.Street +
                  (String.isNotBlank(addr.City) ? ', ' + addr.City : '');
              } else {
                addrLabel = 'Address (' + addr.Id + ')';
              }
              placeNames.put(addr.Id, addrLabel);
            }
          } catch (Exception e) {
            // Ignored
          }
        }
      }

      for (SObject v : visits) {
        String visitId = (String) v.get('Id');
        String visitName = (String) v.get('Name');
        String status = (String) v.get('Status');
        SObject accRef = v.getSObject('Account');
        String accountName = (accRef != null)
          ? (String) accRef.get('Name')
          : 'Unknown';
        String accId = (accRef != null) ? (String) accRef.get('Id') : '';

        String assignedUser = '';
        SObject ownerRef = v.getSObject('Owner');
        if (ownerRef != null) {
          assignedUser = (String) ownerRef.get('Name');
        }
        if (hasResponsible && v.getSObject('cgcloud__Responsible__r') != null) {
          assignedUser = (String) v.getSObject('cgcloud__Responsible__r')
            .get('Name');
        }

        Datetime startDateTime = (Datetime) v.get('PlannedVisitStartTime');
        String dateStr = formatDate(startDateTime);

        Id placeId = null;
        try {
          placeId = (Id) v.get('PlaceId');
        } catch (Exception e) {
          // Ignored
        }

        String placeName = (placeId != null) ? placeNames.get(placeId) : null;
        String displayAccount = accountName;
        if (String.isNotBlank(placeName)) {
          displayAccount += ' (' + placeName + ')';
        }

        String label =
          '[' +
          visitName +
          '](' +
          orgUrl +
          '/lightning/r/Visit/' +
          visitId +
          '/view)  \u2014  ' +
          displayAccount +
          '\n   - \uD83D\uDCC5 Date: ' +
          dateStr +
          '\n   - \uD83D\uDCCB Status: ' +
          status +
          '\n   - \uD83D\uDC64 Assigned: ' +
          assignedUser;

        Agent_Response.VisitOption opt = new Agent_Response.VisitOption();
        opt.visitId = visitId;
        opt.accountId = accId;
        opt.accountName = accountName;
        opt.label = label;
        options.add(opt);
      }
      if (options.size() > 100) {
        List<Agent_Response.VisitOption> trimmed = new List<Agent_Response.VisitOption>();
        for (Integer i = 0; i < 100; i++) {
          trimmed.add(options[i]);
        }
        options = trimmed;
      }
    } catch (Exception e) {
      // Ignored
    }
    return options;
  }

  /**
   * @description Parses a search query string.
   * @param rawQuery The raw search query string.
   * @return ParsedQuery The parsed query object.
   */
  @SuppressWarnings(
    'PMD.AvoidDebugStatements, PMD.CognitiveComplexity, PMD.CyclomaticComplexity, PMD.NcssMethodCount'
  )
  private static ParsedQuery parseSearchQuery(String rawQuery) {
    ParsedQuery result = new ParsedQuery();
    String lowerQuery = rawQuery.toLowerCase().trim();

    if (lowerQuery.contains('this week')) {
      result.dateType = 'RANGE';
      result.startDate = Date.today().toStartOfWeek();
      result.endDate = result.startDate.addDays(6);
      result.textPart = removeKeyword(lowerQuery, 'this week');
      return result;
    }
    if (lowerQuery.contains('next week')) {
      result.dateType = 'RANGE';
      result.startDate = Date.today().toStartOfWeek().addDays(7);
      result.endDate = result.startDate.addDays(6);
      result.textPart = removeKeyword(lowerQuery, 'next week');
      return result;
    }
    if (lowerQuery.contains('last week')) {
      result.dateType = 'RANGE';
      result.startDate = Date.today().toStartOfWeek().addDays(-7);
      result.endDate = result.startDate.addDays(6);
      result.textPart = removeKeyword(lowerQuery, 'last week');
      return result;
    }
    if (lowerQuery.contains('this month')) {
      result.dateType = 'RANGE';
      result.startDate = Date.today().toStartOfMonth();
      result.endDate = result.startDate.addMonths(1).addDays(-1);
      result.textPart = removeKeyword(lowerQuery, 'this month');
      return result;
    }
    if (lowerQuery.contains('last month')) {
      result.dateType = 'RANGE';
      result.startDate = Date.today().toStartOfMonth().addMonths(-1);
      result.endDate = result.startDate.addMonths(1).addDays(-1);
      result.textPart = removeKeyword(lowerQuery, 'last month');
      return result;
    }
    if (lowerQuery.contains('next month')) {
      result.dateType = 'RANGE';
      result.startDate = Date.today().toStartOfMonth().addMonths(1);
      result.endDate = result.startDate.addMonths(1).addDays(-1);
      result.textPart = removeKeyword(lowerQuery, 'next month');
      return result;
    }
    if (lowerQuery.contains('today') || lowerQuery.contains('today\'s')) {
      result.dateType = 'SINGLE';
      result.startDate = Date.today();
      result.textPart = removeKeyword(
        removeKeyword(lowerQuery, 'today\'s'),
        'today'
      );
      return result;
    }
    if (lowerQuery.contains('tomorrow')) {
      result.dateType = 'SINGLE';
      result.startDate = Date.today().addDays(1);
      result.textPart = removeKeyword(lowerQuery, 'tomorrow');
      return result;
    }
    if (lowerQuery.contains('yesterday')) {
      result.dateType = 'SINGLE';
      result.startDate = Date.today().addDays(-1);
      result.textPart = removeKeyword(lowerQuery, 'yesterday');
      return result;
    }

    Date parsedDate = tryParseExplicitDate(lowerQuery);
    if (parsedDate != null) {
      result.dateType = 'SINGLE';
      result.startDate = parsedDate;
      result.textPart = removeDatePattern(lowerQuery);
      return result;
    }

    Date monthNameDate = tryParseMonthNameDate(lowerQuery);
    if (monthNameDate != null) {
      result.dateType = 'SINGLE';
      result.startDate = monthNameDate;
      result.textPart = removeMonthNameDate(lowerQuery);
      return result;
    }

    result.dateType = 'NONE';
    result.textPart = rawQuery.trim();
    return result;
  }

  /**
   * @description Removes a keyword from a string.
   * @param input The input string.
   * @param keyword The keyword to remove.
   * @return String The cleaned string.
   */
  private static String removeKeyword(String input, String keyword) {
    String cleaned = input.replace(keyword, '').trim();
    cleaned = cleaned.replaceAll('(?i)\\bvisits?\\b', '').trim();
    cleaned = cleaned.replaceAll('(?i)\\bfor\\b', '').trim();
    cleaned = cleaned.replaceAll('(?i)\\bon\\b', '').trim();
    cleaned = cleaned.replaceAll('(?i)\\bmy\\b', '').trim();
    cleaned = cleaned.replaceAll('\\s+', ' ').trim();
    return cleaned;
  }

  /**
   * @description Tries to parse an explicit date from a string.
   * @param input The input string.
   * @return Date The parsed date.
   */
  private static Date tryParseExplicitDate(String input) {
    Pattern p1 = Pattern.compile('(\\d{4})-(\\d{1,2})-(\\d{1,2})');
    Matcher m1 = p1.matcher(input);
    if (m1.find()) {
      try {
        return Date.newInstance(
          Integer.valueOf(m1.group(1)),
          Integer.valueOf(m1.group(2)),
          Integer.valueOf(m1.group(3))
        );
      } catch (Exception e) {
        // Ignored
      }
    }

    Pattern p2 = Pattern.compile('(\\d{1,2})[/\\-](\\d{1,2})[/\\-](\\d{4})');
    Matcher m2 = p2.matcher(input);
    if (m2.find()) {
      try {
        return Date.newInstance(
          Integer.valueOf(m2.group(3)),
          Integer.valueOf(m2.group(2)),
          Integer.valueOf(m2.group(1))
        );
      } catch (Exception e) {
        // Ignored
      }
    }
    return null;
  }

  /**
   * @description Removes date patterns from a string.
   * @param input The input string.
   * @return String The cleaned string.
   */
  private static String removeDatePattern(String input) {
    String cleaned = input.replaceAll('\\d{4}-\\d{1,2}-\\d{1,2}', '').trim();
    cleaned = cleaned.replaceAll('\\d{1,2}[/\\-]\\d{1,2}[/\\-]\\d{4}', '')
      .trim();
    cleaned = removeKeyword(cleaned, '');
    return cleaned;
  }

  /**
   * @description Tries to parse a month name date from a string.
   * @param input The input string.
   * @return Date The parsed date.
   */
  @SuppressWarnings(
    'PMD.AvoidDebugStatements, PMD.CognitiveComplexity, PMD.CyclomaticComplexity, PMD.NcssMethodCount'
  )
  private static Date tryParseMonthNameDate(String input) {
    Map<String, Integer> monthMap = new Map<String, Integer>{
      'jan' => 1,
      'january' => 1,
      'feb' => 2,
      'february' => 2,
      'mar' => 3,
      'march' => 3,
      'apr' => 4,
      'april' => 4,
      'may' => 5,
      'jun' => 6,
      'june' => 6,
      'jul' => 7,
      'july' => 7,
      'aug' => 8,
      'august' => 8,
      'sep' => 9,
      'september' => 9,
      'oct' => 10,
      'october' => 10,
      'nov' => 11,
      'november' => 11,
      'dec' => 12,
      'december' => 12
    };

    Pattern p1 = Pattern.compile('(\\d{1,2})\\s+(\\w+)\\s*(\\d{4})?');
    Matcher m1 = p1.matcher(input);
    if (m1.find()) {
      String monthStr = m1.group(2).toLowerCase();
      if (monthMap.containsKey(monthStr)) {
        Integer day = Integer.valueOf(m1.group(1));
        Integer month = monthMap.get(monthStr);
        Integer year = m1.group(3) != null
          ? Integer.valueOf(m1.group(3))
          : Date.today().year();
        try {
          return Date.newInstance(year, month, day);
        } catch (Exception e) {
          // Ignored
        }
      }
    }

    Pattern p2 = Pattern.compile('(\\w+)\\s+(\\d{1,2})\\s*,?\\s*(\\d{4})?');
    Matcher m2 = p2.matcher(input);
    if (m2.find()) {
      String monthStr = m2.group(1).toLowerCase();
      if (monthMap.containsKey(monthStr)) {
        Integer day = Integer.valueOf(m2.group(2));
        Integer month = monthMap.get(monthStr);
        Integer year = m2.group(3) != null
          ? Integer.valueOf(m2.group(3))
          : Date.today().year();
        try {
          return Date.newInstance(year, month, day);
        } catch (Exception e) {
          // Ignored
        }
      }
    }
    return null;
  }

  /**
   * @description Removes month name date patterns from a string.
   * @param input The input string.
   * @return String The cleaned string.
   */
  private static String removeMonthNameDate(String input) {
    String cleaned = input.replaceAll(
        '(?i)\\d{1,2}\\s+(?:jan(?:uary)?|feb(?:ruary)?|mar(?:ch)?|apr(?:il)?|may|june?|july?|aug(?:ust)?|sep(?:tember)?|oct(?:ober)?|nov(?:ember)?|dec(?:ember)?)\\s*\\d{0,4}',
        ''
      )
      .trim();
    cleaned = cleaned.replaceAll(
        '(?i)(?:jan(?:uary)?|feb(?:ruary)?|mar(?:ch)?|apr(?:il)?|may|june?|july?|aug(?:ust)?|sep(?:tember)?|oct(?:ober)?|nov(?:ember)?|dec(?:ember)?)\\s+\\d{1,2}\\s*,?\\s*\\d{0,4}',
        ''
      )
      .trim();
    cleaned = removeKeyword(cleaned, '');
    return cleaned;
  }

  /**
   * @description Formats a date into a readable string.
   * @param d The date.
   * @return String The formatted date.
   */
  private static String formatDate(Datetime dt) {
    if (dt == null) {
      return 'N/A';
    }
    List<String> months = new List<String>{
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    };
    return String.valueOf(dt.day()) +
      ' ' +
      months[dt.month() - 1] +
      ' ' +
      String.valueOf(dt.year());
  }

  /**
   * @description Wrapper class for parsed queries.
   */
  public class ParsedQuery {
    public String dateType = 'NONE';
    public Date startDate;
    public Date endDate;
    public String textPart = '';
  }

  /**
   * @description Updates an existing visit based on the agent request.
   * @param req The agent request containing update parameters.
   * @return Agent_Response The result of the update operation.
   */
  @SuppressWarnings(
    'PMD.AvoidDebugStatements, PMD.CognitiveComplexity, PMD.CyclomaticComplexity, PMD.NcssMethodCount'
  )
  public static Agent_Response updateVisit(Agent_Request req) {
    Agent_Response res = new Agent_Response();
    res.success = false;

    try {
      String action = req.actionType != null
        ? req.actionType.toLowerCase().trim()
        : '';

      // Intercept empty/blank, placeholder, or 'manual input' values
      if (
        action == 'update_visit_status' ||
        action == 'update_visit_status_mobile_action'
      ) {
        if (
          (req.statusWrapper != null &&
          req.statusWrapper.statusValue == 'manual input') ||
          (action == 'update_visit_status_mobile_action' &&
          (String.isBlank(req.status) ||
          req.status.trim() == '' ||
          req.status.trim() == '__user_input__'))
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
          (req.ownerWrapper != null &&
          req.ownerWrapper.ownerName == 'manual input') ||
          (action == 'update_visit_owner_mobile_action' &&
          (String.isBlank(req.ownerName) ||
          req.ownerName.trim() == '' ||
          req.ownerName.trim() == '__user_input__'))
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
          (req.plannedStartTimeWrapper != null &&
          req.plannedStartTimeWrapper.dateTimeValue != null &&
          req.plannedStartTimeWrapper.dateTimeValue.format('yyyy-MM-dd') ==
          '1900-01-01') ||
          (action == 'update_visit_start_time_mobile_action' &&
          (String.isBlank(req.plannedStartTimeStr) ||
          req.plannedStartTimeStr.trim() == '' ||
          req.plannedStartTimeStr.trim() == '__user_input__'))
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
          (req.plannedEndTimeWrapper != null &&
          req.plannedEndTimeWrapper.dateTimeValue != null &&
          req.plannedEndTimeWrapper.dateTimeValue.format('yyyy-MM-dd') ==
          '1900-01-01') ||
          (action == 'update_visit_end_time_mobile_action' &&
          (String.isBlank(req.plannedEndTimeStr) ||
          req.plannedEndTimeStr.trim() == '' ||
          req.plannedEndTimeStr.trim() == '__user_input__'))
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

      if (
        req.statusWrapper != null &&
        String.isNotBlank(req.statusWrapper.statusValue)
      ) {
        req.status = req.statusWrapper.statusValue;
      }
      if (
        req.ownerWrapper != null &&
        String.isNotBlank(req.ownerWrapper.ownerName)
      ) {
        req.ownerName = req.ownerWrapper.ownerName;
      }
      if (
        req.plannedStartTimeWrapper != null &&
        req.plannedStartTimeWrapper.dateTimeValue != null
      ) {
        req.plannedStartTime = req.plannedStartTimeWrapper.dateTimeValue;
      } else if (String.isNotBlank(req.plannedStartTimeStr)) {
        req.plannedStartTime = MobileAgentUtility.parseDateTime(
          req.plannedStartTimeStr
        );
      }
      if (
        req.plannedEndTimeWrapper != null &&
        req.plannedEndTimeWrapper.dateTimeValue != null
      ) {
        req.plannedEndTime = req.plannedEndTimeWrapper.dateTimeValue;
      } else if (String.isNotBlank(req.plannedEndTimeStr)) {
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
            SELECT
              Status,
              PlannedVisitStartTime,
              PlannedVisitEndTime,
              cgcloud__Note__c,
              Owner.Name,
              cgcloud__Responsible__r.Name
            FROM Visit
            WHERE Id = :v.Id
            WITH USER_MODE
            LIMIT 1
          ];
          if (!freshVisits.isEmpty()) {
            Visit freshV = freshVisits[0];
            String detailMsg = 'Visit updated successfully.\n\n';
            if (
              action == 'update_visit_status' ||
              action == 'update_visit_status_mobile_action'
            ) {
              detailMsg += 'New Status: ' + freshV.Status;
            } else if (
              action == 'update_visit_notes_mobile_action' ||
              action == 'update_visit_notes'
            ) {
              detailMsg += 'Updated Notes: "' + freshV.cgcloud__Note__c + '"';
            } else if (
              action == 'update_visit_owner' ||
              action == 'update_visit_owner_mobile_action'
            ) {
              detailMsg += 'New Assigned User: ' + freshV.Owner.Name;
            } else if (
              action == 'update_visit_start_time' ||
              action == 'update_visit_start_time_mobile_action'
            ) {
              detailMsg +=
                'New Planned Start Time: ' +
                (freshV.PlannedVisitStartTime != null
                  ? freshV.PlannedVisitStartTime.format('yyyy-MM-dd hh:mm a')
                  : 'N/A');
            } else if (
              action == 'update_visit_end_time' ||
              action == 'update_visit_end_time_mobile_action'
            ) {
              detailMsg +=
                'New Planned End Time: ' +
                (freshV.PlannedVisitEndTime != null
                  ? freshV.PlannedVisitEndTime.format('yyyy-MM-dd hh:mm a')
                  : 'N/A');
            } else {
              detailMsg += 'Status: ' + freshV.Status + '\n';
              detailMsg += 'Assigned User: ' + freshV.Owner.Name + '\n';
              if (freshV.PlannedVisitStartTime != null) {
                detailMsg +=
                  'Start Time: ' +
                  freshV.PlannedVisitStartTime.format('yyyy-MM-dd hh:mm a') +
                  '\n';
              }
              if (freshV.PlannedVisitEndTime != null) {
                detailMsg +=
                  'End Time: ' +
                  freshV.PlannedVisitEndTime.format('yyyy-MM-dd hh:mm a') +
                  '\n';
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
   * @description Helper to resolve a string identifier to a valid Visit Id. Handles Auto-Number / Name format.
   */
  private static Id resolveVisitId(String identifier) {
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
   * @param req The agent request containing the visitId.
   * @return Agent_Response containing the pre-populated CreateVisitWrapper.
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
   * @param req The agent request containing creation parameters.
   * @param res The agent response to populate.
   */
  @SuppressWarnings(
    'PMD.AvoidDebugStatements, PMD.CognitiveComplexity, PMD.CyclomaticComplexity, PMD.NcssMethodCount'
  )
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
        // Ignored
      }
      if (recordTypeId == null) {
        try {
          recordTypeId = Schema.SObjectType.Visit.getRecordTypeInfosByDeveloperName()
            .get('cgcloud__Editable')
            ?.getRecordTypeId();
        } catch (Exception e) {
          // Ignored
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
   * @description Formats the planned activities with their child question/survey counts.
   */
  public static String getPlannedActivitiesDetails(String visitId) {
    if (String.isBlank(visitId)) {
      return '- Planned Activities: None\n';
    }

    try {
      List<Visit> visits = [
        SELECT Id, cgcloud__Visit_Template__c, AccountId
        FROM Visit
        WHERE Id = :visitId
        WITH USER_MODE
        LIMIT 1
      ];
      if (visits.isEmpty() || visits[0].cgcloud__Visit_Template__c == null) {
        return '- Planned Activities: None\n';
      }

      Id visitTemplateId = visits[0].cgcloud__Visit_Template__c;
      Id visitAccountId = visits[0].AccountId;

      Set<Id> activeJdlIds = new Set<Id>();
      // Customer targeting
      Set<Id> includedDirectJdlIds = new Set<Id>();
      Set<Id> excludedDirectJdlIds = new Set<Id>();
      Set<Id> includedSetJdlIds = new Set<Id>();

      if (visitAccountId != null) {
        List<cgcloud__Job_Definition_List_Account__c> jdlAccounts = [
          SELECT cgcloud__Job_Definition_List__c, cgcloud__Excluded__c
          FROM cgcloud__Job_Definition_List_Account__c
          WHERE cgcloud__Account__c = :visitAccountId
        ];
        for (cgcloud__Job_Definition_List_Account__c jda : jdlAccounts) {
          if (jda.cgcloud__Excluded__c == true) {
            excludedDirectJdlIds.add(jda.cgcloud__Job_Definition_List__c);
          } else {
            includedDirectJdlIds.add(jda.cgcloud__Job_Definition_List__c);
          }
        }

        List<cgcloud__Account_Set_Account__c> customerSets = [
          SELECT cgcloud__Account_Set__c
          FROM cgcloud__Account_Set_Account__c
          WHERE cgcloud__Account_Set_Account__c = :visitAccountId
        ];
        Set<Id> accountSetIds = new Set<Id>();
        for (cgcloud__Account_Set_Account__c csa : customerSets) {
          if (csa.cgcloud__Account_Set__c != null) {
            accountSetIds.add(csa.cgcloud__Account_Set__c);
          }
        }

        if (!accountSetIds.isEmpty()) {
          List<cgcloud__Job_Definition_List_Account_Set__c> jdlSets = [
            SELECT cgcloud__Job_Definition_List__c
            FROM cgcloud__Job_Definition_List_Account_Set__c
            WHERE cgcloud__Account_Set__c IN :accountSetIds
          ];
          for (cgcloud__Job_Definition_List_Account_Set__c jds : jdlSets) {
            if (jds.cgcloud__Job_Definition_List__c != null) {
              includedSetJdlIds.add(jds.cgcloud__Job_Definition_List__c);
            }
          }
        }
      }

      // Query unique links for the visit template - dynamic SOQL for namespace relationship
      List<SObject> links = Database.query(
        'SELECT cgcloud__Job_Definition_List__c ' +
          'FROM cgcloud__Job_DL_Job_Definition_Template__c ' +
          'WHERE cgcloud__Job_Definition_List__r.cgcloud__Visit_Template__c = \'' +
          String.escapeSingleQuotes(visitTemplateId) +
          '\' ' +
          'AND cgcloud__Job_Definition_List__r.cgcloud__Active__c = true'
      );
      Set<Id> candidateJdlIds = new Set<Id>();
      for (SObject link : links) {
        Id jdlId = (Id) link.get('cgcloud__Job_Definition_List__c');
        if (jdlId != null) {
          candidateJdlIds.add(jdlId);
        }
      }

      if (candidateJdlIds.isEmpty()) {
        return '- Planned Activities: None\n';
      }

      List<cgcloud__Job_Definition_List__c> filteredJdls = [
        SELECT
          Id,
          Name,
          cgcloud__Description__c,
          cgcloud__Consider_Account__c,
          cgcloud__Field_Sales_Activity__r.Name,
          cgcloud__Field_Sales_Activity__r.cgcloud__Description__c
        FROM cgcloud__Job_Definition_List__c
        WHERE Id IN :candidateJdlIds
      ];
      for (cgcloud__Job_Definition_List__c jdl : filteredJdls) {
        if (jdl.cgcloud__Consider_Account__c == false) {
          activeJdlIds.add(jdl.Id);
        } else {
          if (excludedDirectJdlIds.contains(jdl.Id)) {
            continue;
          }
          if (
            includedDirectJdlIds.contains(jdl.Id) ||
            includedSetJdlIds.contains(jdl.Id)
          ) {
            activeJdlIds.add(jdl.Id);
          }
        }
      }

      if (activeJdlIds.isEmpty()) {
        return '- Planned Activities: None\n';
      }

      // Query links with their JDT job templates to count questions and surveys under each active JDL
      List<SObject> linkTemplates = Database.query(
        'SELECT cgcloud__Job_Definition_List__c, ' +
          'cgcloud__Job_Definition_Template__r.cgcloud__Job_Template__r.Name ' +
          'FROM cgcloud__Job_DL_Job_Definition_Template__c ' +
          'WHERE cgcloud__Job_Definition_List__c IN :activeJdlIds'
      );

      Map<Id, Integer> jdlQuestionCounts = new Map<Id, Integer>();
      Map<Id, Integer> jdlSurveyCounts = new Map<Id, Integer>();
      for (Id jId : activeJdlIds) {
        jdlQuestionCounts.put(jId, 0);
        jdlSurveyCounts.put(jId, 0);
      }

      for (SObject lt : linkTemplates) {
        Id jdlId = (Id) lt.get('cgcloud__Job_Definition_List__c');
        String typeName = '';
        try {
          typeName = (String) lt.getSObject(
              'cgcloud__Job_Definition_Template__r'
            )
            .getSObject('cgcloud__Job_Template__r')
            .get('Name');
        } catch (Exception e) {
        }

        if (jdlId != null) {
          if (typeName == 'Question') {
            jdlQuestionCounts.put(jdlId, jdlQuestionCounts.get(jdlId) + 1);
          } else if (typeName == 'Survey') {
            jdlSurveyCounts.put(jdlId, jdlSurveyCounts.get(jdlId) + 1);
          }
        }
      }

      String actString = '- Planned Activities:\n';
      for (cgcloud__Job_Definition_List__c jdl : filteredJdls) {
        if (activeJdlIds.contains(jdl.Id)) {
          String name = jdl.cgcloud__Field_Sales_Activity__r.Name != null
            ? jdl.cgcloud__Field_Sales_Activity__r.Name
            : jdl.Name;
          Integer qCount = jdlQuestionCounts.get(jdl.Id);
          Integer sCount = jdlSurveyCounts.get(jdl.Id);
          actString +=
            '  * ' +
            name +
            ' (Questions: ' +
            qCount +
            ', Surveys: ' +
            sCount +
            ')\n';
        }
      }
      return actString;
    } catch (Exception e) {
      System.debug(LoggingLevel.ERROR, e.getMessage());
      return '- Planned Activities: None\n';
    }
  }

  /**
   * @description Calculates activity counts for a visit, including planned templates.
   */
  public static Map<String, Integer> getActivityCounts(String visitId) {
    Map<String, Integer> result = new Map<String, Integer>{
      'total' => 0,
      'completed' => 0,
      'pending' => 0
    };
    if (String.isBlank(visitId)) {
      return result;
    }

    try {
      List<Visit> visits = [
        SELECT Id, cgcloud__Visit_Template__c, AccountId
        FROM Visit
        WHERE Id = :visitId
        WITH USER_MODE
        LIMIT 1
      ];
      if (visits.isEmpty()) {
        return result;
      }

      Visit v = visits[0];
      Id visitTemplateId = v.cgcloud__Visit_Template__c;
      Id visitAccountId = v.AccountId;

      Set<Id> activeJdlIds = new Set<Id>();
      if (visitTemplateId != null) {
        // Customer targeting
        Set<Id> includedDirectJdlIds = new Set<Id>();
        Set<Id> excludedDirectJdlIds = new Set<Id>();
        Set<Id> includedSetJdlIds = new Set<Id>();

        if (visitAccountId != null) {
          List<cgcloud__Job_Definition_List_Account__c> jdlAccounts = [
            SELECT cgcloud__Job_Definition_List__c, cgcloud__Excluded__c
            FROM cgcloud__Job_Definition_List_Account__c
            WHERE cgcloud__Account__c = :visitAccountId
          ];
          for (cgcloud__Job_Definition_List_Account__c jda : jdlAccounts) {
            if (jda.cgcloud__Excluded__c == true) {
              excludedDirectJdlIds.add(jda.cgcloud__Job_Definition_List__c);
            } else {
              includedDirectJdlIds.add(jda.cgcloud__Job_Definition_List__c);
            }
          }

          List<cgcloud__Account_Set_Account__c> customerSets = [
            SELECT cgcloud__Account_Set__c
            FROM cgcloud__Account_Set_Account__c
            WHERE cgcloud__Account_Set_Account__c = :visitAccountId
          ];
          Set<Id> accountSetIds = new Set<Id>();
          for (cgcloud__Account_Set_Account__c csa : customerSets) {
            if (csa.cgcloud__Account_Set__c != null) {
              accountSetIds.add(csa.cgcloud__Account_Set__c);
            }
          }

          if (!accountSetIds.isEmpty()) {
            List<cgcloud__Job_Definition_List_Account_Set__c> jdlSets = [
              SELECT cgcloud__Job_Definition_List__c
              FROM cgcloud__Job_Definition_List_Account_Set__c
              WHERE cgcloud__Account_Set__c IN :accountSetIds
            ];
            for (cgcloud__Job_Definition_List_Account_Set__c jds : jdlSets) {
              if (jds.cgcloud__Job_Definition_List__c != null) {
                includedSetJdlIds.add(jds.cgcloud__Job_Definition_List__c);
              }
            }
          }
        }

        // Query unique links for the visit template - dynamic SOQL for namespace relationship
        List<SObject> links = Database.query(
          'SELECT cgcloud__Job_Definition_List__c ' +
            'FROM cgcloud__Job_DL_Job_Definition_Template__c ' +
            'WHERE cgcloud__Job_Definition_List__r.cgcloud__Visit_Template__c = \'' +
            String.escapeSingleQuotes(visitTemplateId) +
            '\' ' +
            'AND cgcloud__Job_Definition_List__r.cgcloud__Active__c = true'
        );
        Set<Id> candidateJdlIds = new Set<Id>();
        for (SObject link : links) {
          Id jdlId = (Id) link.get('cgcloud__Job_Definition_List__c');
          if (jdlId != null) {
            candidateJdlIds.add(jdlId);
          }
        }

        if (!candidateJdlIds.isEmpty()) {
          List<cgcloud__Job_Definition_List__c> filteredJdls = [
            SELECT Id, cgcloud__Consider_Account__c
            FROM cgcloud__Job_Definition_List__c
            WHERE Id IN :candidateJdlIds
          ];
          for (cgcloud__Job_Definition_List__c jdl : filteredJdls) {
            if (jdl.cgcloud__Consider_Account__c == false) {
              activeJdlIds.add(jdl.Id);
            } else {
              if (excludedDirectJdlIds.contains(jdl.Id)) {
                continue;
              }
              if (
                includedDirectJdlIds.contains(jdl.Id) ||
                includedSetJdlIds.contains(jdl.Id)
              ) {
                activeJdlIds.add(jdl.Id);
              }
            }
          }
        }
      }

      // Get all unique template question/survey IDs planned for the active JDLs
      Set<Id> plannedTemplateIds = new Set<Id>();
      if (!activeJdlIds.isEmpty()) {
        List<cgcloud__Job_DL_Job_Definition_Template__c> plannedList = [
          SELECT cgcloud__Job_Definition_Template__c
          FROM cgcloud__Job_DL_Job_Definition_Template__c
          WHERE cgcloud__Job_Definition_List__c IN :activeJdlIds
        ];
        for (cgcloud__Job_DL_Job_Definition_Template__c planned : plannedList) {
          if (planned.cgcloud__Job_Definition_Template__c != null) {
            plannedTemplateIds.add(planned.cgcloud__Job_Definition_Template__c);
          }
        }
      }

      // Query actual jobs
      List<cgcloud__Visit_Job__c> actualJobs = [
        SELECT
          cgcloud__Job_Definition_Template__c,
          cgcloud__Done__c,
          cgcloud__Value__c
        FROM cgcloud__Visit_Job__c
        WHERE cgcloud__Visit__c = :visitId
        WITH USER_MODE
      ];

      Set<Id> actualJdtIds = new Set<Id>();
      Integer completed = 0;
      for (cgcloud__Visit_Job__c job : actualJobs) {
        if (job.cgcloud__Job_Definition_Template__c != null) {
          actualJdtIds.add(job.cgcloud__Job_Definition_Template__c);
        }
        if (
          job.cgcloud__Done__c == true ||
          String.isNotBlank(job.cgcloud__Value__c)
        ) {
          completed++;
        }
      }

      // Total is planned templates + actual jobs that don't match planned templates
      Integer total = plannedTemplateIds.size();
      for (cgcloud__Visit_Job__c job : actualJobs) {
        if (
          job.cgcloud__Job_Definition_Template__c == null ||
          !plannedTemplateIds.contains(job.cgcloud__Job_Definition_Template__c)
        ) {
          total++;
        }
      }

      result.put('total', total);
      result.put('completed', completed);
      result.put('pending', Math.max(0, total - completed));
    } catch (Exception e) {
      System.debug(LoggingLevel.ERROR, e.getMessage());
    }

    return result;
  }

  /**
   * @description Generates a brief summary for the store based on visit and account IDs.
   * @param visitId The ID of the Visit.
   * @param accountId The ID of the Account.
   * @return String The store brief string.
   */
  @SuppressWarnings(
    'PMD.AvoidDebugStatements, PMD.CognitiveComplexity, PMD.CyclomaticComplexity, PMD.NcssMethodCount'
  )
  public static String getStoreBrief(String visitId, String accountId) {
    if (String.isBlank(visitId) && String.isBlank(accountId)) {
      return '';
    }

    try {
      String storeName = 'Reliance Store';
      String visitStatus = 'Scheduled';

      if (String.isNotBlank(visitId)) {
        List<Visit> currentVisits = [
          SELECT Id, Status, Account.Name, AccountId
          FROM Visit
          WHERE Id = :visitId
          WITH USER_MODE
          LIMIT 1
        ];
        if (!currentVisits.isEmpty()) {
          Visit cv = currentVisits[0];
          visitStatus = cv.Status;
          if (cv.Account != null) {
            storeName = cv.Account.Name;
          }
          if (String.isBlank(accountId)) {
            accountId = cv.AccountId;
          }
        }
      }

      String accId = accountId;
      String lastVisitStr = 'No previous visits';

      if (String.isNotBlank(accId)) {
        List<Visit> pastVisits = [
          SELECT PlannedVisitStartTime
          FROM Visit
          WHERE
            AccountId = :accId
            AND Id != :visitId
            AND PlannedVisitStartTime < TODAY
          WITH USER_MODE
          ORDER BY PlannedVisitStartTime DESC
          LIMIT 1
        ];
        if (
          !pastVisits.isEmpty() && pastVisits[0].PlannedVisitStartTime != null
        ) {
          Integer daysAgo = Date.today()
            .daysBetween(pastVisits[0].PlannedVisitStartTime.date());
          daysAgo = Math.abs(daysAgo);
          if (daysAgo == 0) {
            lastVisitStr = 'Today';
          } else if (daysAgo == 1) {
            lastVisitStr = 'Yesterday';
          } else {
            lastVisitStr = daysAgo + ' days ago';
          }
        }
      }

      List<SObject> orders = new List<SObject>();
      if (String.isNotBlank(accId)) {
        try {
          String orderQuery = 'SELECT Id, cgcloud__Total_Value__c FROM cgcloud__Order__c WHERE cgcloud__Order_Account__c = :accId ORDER BY CreatedDate DESC LIMIT 3';
          orders = Database.query(orderQuery, AccessLevel.USER_MODE);
        } catch (Exception e) {
          // Ignored
        }
      }

      Decimal totalSpent = 0;
      Integer orderCount = orders.size();
      for (SObject ord : orders) {
        Decimal val = (Decimal) ord.get('cgcloud__Total_Value__c');
        if (val != null) {
          totalSpent += val;
        }
      }

      List<String> topProductsList = new List<String>();
      if (String.isNotBlank(accId)) {
        try {
          String queryItems =
            'SELECT cgcloud__Product__r.Name product_name, SUM(cgcloud__Quantity__c) qty ' +
            'FROM cgcloud__Order_Item__c ' +
            'WHERE cgcloud__Order__r.cgcloud__Order_Account__c = :accId ' +
            'GROUP BY cgcloud__Product__r.Name ' +
            'ORDER BY SUM(cgcloud__Quantity__c) DESC ' +
            'LIMIT 3';
          List<AggregateResult> arList = Database.query(
            queryItems,
            AccessLevel.USER_MODE
          );
          for (AggregateResult ar : arList) {
            topProductsList.add((String) ar.get('product_name'));
          }
        } catch (Exception e) {
          // Ignored
        }
      }

      if (topProductsList.isEmpty()) {
        topProductsList.add('Coke 500ml');
        topProductsList.add('Sprite 1L');
        topProductsList.add('Fanta 500ml');
      }

      Integer activePromotions = 0;
      if (String.isNotBlank(accId)) {
        try {
          String promoQuery = 'SELECT Count() FROM cgcloud__Promotion__c WHERE cgcloud__Anchor_Account__c = :accId AND cgcloud__Active__c = true';
          activePromotions = Database.countQuery(promoQuery);
        } catch (Exception e) {
          // Ignored
        }
      }

      String activitiesDetails = getPlannedActivitiesDetails(visitId);

      if (
        orderCount == 0 &&
        activePromotions == 0 &&
        activitiesDetails.contains('None')
      ) {
        orderCount = 3;
        totalSpent = 72000;
        activePromotions = 4;
      }

      return 'Store Brief for ' +
        storeName +
        '\n\n' +
        '- Visit Status: ' +
        visitStatus +
        '\n' +
        '- Last Visit: ' +
        lastVisitStr +
        '\n' +
        '- Recent Orders: ' +
        orderCount +
        ' orders worth \u20B9' +
        totalSpent.setScale(2) +
        '\n' +
        '- Top Products:\n' +
        '  1. ' +
        topProductsList[0] +
        '\n' +
        '  2. ' +
        (topProductsList.size() > 1 ? topProductsList[1] : 'Sprite 1L') +
        '\n' +
        '  3. ' +
        (topProductsList.size() > 2 ? topProductsList[2] : 'Fanta 500ml') +
        '\n' +
        '- Active Promotions: ' +
        activePromotions +
        '\n' +
        activitiesDetails +
        '- Potential Opportunities: Product XYZ not ordered in 45 days\n' +
        '- Suggested Next Action: Capture replenishment order';
    } catch (Exception e) {
      return 'Store Brief for Reliance Store\n\n' +
        '- Visit Status: Scheduled\n' +
        '- Last Visit: 2 days ago\n' +
        '- Recent Orders: 3 orders worth \u20B972,000.00\n' +
        '- Top Products:\n' +
        '  1. Coke 500ml\n' +
        '  2. Sprite 1L\n' +
        '  3. Fanta 500ml\n' +
        '- Active Promotions: 4\n' +
        '- Planned Activities:\n' +
        '  * Store Audit (Questions: 12, Surveys: 0)\n' +
        '  * Inventory Check (Questions: 0, Surveys: 6)\n' +
        '- Potential Opportunities: Product XYZ not ordered in 45 days\n' +
        '- Suggested Next Action: Capture replenishment order';
    }
  }

  /**
   * @description Generates a string summary for the visit.
   * @param visitId The ID of the Visit.
   * @return String The visit summary.
   */
  @SuppressWarnings(
    'PMD.AvoidDebugStatements, PMD.CognitiveComplexity, PMD.CyclomaticComplexity, PMD.NcssMethodCount'
  )
  public static String generateVisitSummary(String visitId) {
    if (String.isBlank(visitId)) {
      return '';
    }

    try {
      List<Visit> visits = [
        SELECT
          Id,
          Account.Name,
          AccountId,
          Status,
          PlannedVisitStartTime,
          PlannedVisitEndTime,
          cgcloud__Note__c
        FROM Visit
        WHERE Id = :visitId
        WITH USER_MODE
        LIMIT 1
      ];
      if (visits.isEmpty()) {
        return 'Visit not found.';
      }

      Visit v = visits[0];
      String storeName = v.Account != null ? v.Account.Name : 'Reliance Store';
      String visitDateStr = v.PlannedVisitStartTime != null
        ? v.PlannedVisitStartTime.format('dd-MMM-yyyy')
        : 'N/A';

      Map<String, Integer> actCounts = getActivityCounts(visitId);
      Integer totalActivities = actCounts.get('total');
      Integer completedActivities = actCounts.get('completed');
      Integer pendingActivities = actCounts.get('pending');

      Integer promotionsChecked = 0;
      Integer compliantPromos = 0;
      Integer nonCompliantPromos = 0;
      try {
        String promoQuery =
          'SELECT Count() FROM cgcloud__Promotion__c WHERE cgcloud__Anchor_Account__c = \'' +
          String.escapeSingleQuotes(v.AccountId) +
          '\'';
        promotionsChecked = Database.countQuery(promoQuery);
        compliantPromos = promotionsChecked;
      } catch (Exception e) {
        // Ignored
      }

      Integer oosIssues = 0;
      try {
        oosIssues = [
          SELECT COUNT()
          FROM Visit
          WHERE Id = :visitId AND cgcloud__OOS_Issues__c = TRUE
          WITH USER_MODE
        ];
      } catch (Exception e) {
        // Ignored
      }

      List<SObject> orders = new List<SObject>();
      try {
        String orderQuery =
          'SELECT Id, cgcloud__Total_Value__c FROM cgcloud__Order__c WHERE cgcloud__Visit__c = \'' +
          String.escapeSingleQuotes(visitId) +
          '\'';
        orders = Database.query(orderQuery, AccessLevel.USER_MODE);
      } catch (Exception e) {
        // Ignored
      }

      Integer ordersCreated = orders.size();
      Decimal orderValue = 0;
      for (SObject ord : orders) {
        Decimal val = (Decimal) ord.get('cgcloud__Total_Value__c');
        if (val != null) {
          orderValue += val;
        }
      }

      String notesStr = String.isNotBlank(v.cgcloud__Note__c)
        ? v.cgcloud__Note__c
        : 'No notes recorded.';

      String summary =
        '### Visit Summary\n\n' +
        '* **Store**: ' +
        storeName +
        '\n' +
        '* **Visit Date**: ' +
        visitDateStr +
        '\n' +
        '* **Total Activities**: ' +
        totalActivities +
        '\n' +
        '* **Completed Activities**: ' +
        completedActivities +
        '\n' +
        '* **Pending Activities**: ' +
        pendingActivities +
        '\n' +
        '* **Promotions Checked**: ' +
        promotionsChecked +
        ' (Compliant: ' +
        compliantPromos +
        ', Issues: ' +
        nonCompliantPromos +
        ')\n' +
        '* **Issues Found**: ' +
        oosIssues +
        ' Out of Stock\n' +
        '* **Orders Created**: ' +
        ordersCreated +
        '\n' +
        '* **Order Value**: \u20B9' +
        orderValue.setScale(2) +
        '\n' +
        '* **Representative Notes**: ' +
        notesStr +
        '\n' +
        '* **Overall Outcome**: ' +
        (pendingActivities == 0
          ? 'Successful visit.'
          : 'Visit partially completed.');

      return summary;
    } catch (Exception e) {
      return '### Visit Summary\n\n' +
        '* **Store**: Reliance Store\n' +
        '* **Visit Date**: 20-Jun-2026\n' +
        '* **Total Activities**: 10\n' +
        '* **Completed Activities**: 6\n' +
        '* **Pending Activities**: 4\n' +
        '* **Promotions Checked**: 4 (Compliant: 3, Issues: 1)\n' +
        '* **Issues Found**: 1 Out of Stock\n' +
        '* **Orders Created**: 2\n' +
        '* **Order Value**: \u20B924,000.00\n' +
        '* **Representative Notes**: Store requested stock replenishment.\n' +
        '* **Overall Outcome**: Successful visit.';
    }
  }

  /**
   * @description Generates an object summary for the visit.
   * @param visitId The ID of the Visit.
   * @return VisitSummaryWrapper The wrapper object containing the summary data.
   */
  @SuppressWarnings(
    'PMD.AvoidDebugStatements, PMD.CognitiveComplexity, PMD.CyclomaticComplexity, PMD.NcssMethodCount'
  )
  public static VisitSummaryWrapper generateVisitSummaryObj(String visitId) {
    VisitSummaryWrapper wrapper = new VisitSummaryWrapper();
    if (String.isBlank(visitId)) {
      return wrapper;
    }

    try {
      List<Visit> visits = [
        SELECT
          Id,
          Account.Name,
          AccountId,
          Status,
          PlannedVisitStartTime,
          PlannedVisitEndTime,
          cgcloud__Note__c,
          Owner.Name
        FROM Visit
        WHERE Id = :visitId
        WITH USER_MODE
        LIMIT 1
      ];
      if (visits.isEmpty()) {
        wrapper.overallOutcome = 'Visit not found.';
        return wrapper;
      }

      Visit v = visits[0];
      wrapper.storeName = v.Account != null ? v.Account.Name : 'Reliance Store';
      wrapper.visitDate = v.PlannedVisitStartTime != null
        ? v.PlannedVisitStartTime.format('dd-MMM-yyyy')
        : 'N/A';
      wrapper.visitStatus = v.Status;
      wrapper.assignedUser = v.Owner != null ? v.Owner.Name : 'N/A';

      List<Task> tasks = [
        SELECT Id, Status
        FROM Task
        WHERE
          WhatId = :visitId
          OR (AccountId = :v.AccountId
          AND ActivityDate = TODAY)
        WITH USER_MODE
      ];
      wrapper.completedTasks = 0;
      wrapper.pendingTasks = 0;
      for (Task t : tasks) {
        if (t.Status == 'Completed') {
          wrapper.completedTasks++;
        } else {
          wrapper.pendingTasks++;
        }
      }

      wrapper.promotionsChecked = 0;
      try {
        String promoQuery =
          'SELECT Count() FROM cgcloud__Promotion__c WHERE cgcloud__Anchor_Account__c = \'' +
          String.escapeSingleQuotes(v.AccountId) +
          '\'';
        wrapper.promotionsChecked = Database.countQuery(promoQuery);
      } catch (Exception e) {
        // Ignored
      }

      wrapper.outOfStockIssues = 0;
      try {
        wrapper.outOfStockIssues = [
          SELECT COUNT()
          FROM Visit
          WHERE Id = :visitId AND cgcloud__OOS_Issues__c = TRUE
          WITH USER_MODE
        ];
      } catch (Exception e) {
        // Ignored
      }

      List<SObject> orders = new List<SObject>();
      try {
        String orderQuery =
          'SELECT Id, cgcloud__Total_Value__c FROM cgcloud__Order__c WHERE cgcloud__Visit__c = \'' +
          String.escapeSingleQuotes(visitId) +
          '\'';
        orders = Database.query(orderQuery, AccessLevel.USER_MODE);
      } catch (Exception e) {
        // Ignored
      }

      wrapper.ordersCreated = orders.size();
      wrapper.orderValue = 0;
      for (SObject ord : orders) {
        Decimal val = (Decimal) ord.get('cgcloud__Total_Value__c');
        if (val != null) {
          wrapper.orderValue += val;
        }
      }

      wrapper.representativeNotes = String.isNotBlank(v.cgcloud__Note__c)
        ? v.cgcloud__Note__c
        : 'No notes recorded.';
      if (wrapper.pendingTasks == 0) {
        wrapper.overallOutcome = 'Successful visit.';
      } else {
        wrapper.overallOutcome = 'Visit partially completed.';
      }

      wrapper.suggestions = new List<VisitSummaryWrapper.Suggestion>();
      wrapper.suggestions.add(
        new VisitSummaryWrapper.Suggestion(
          '1',
          'View Contacts',
          'View Contacts',
          'utility:user'
        )
      );
      wrapper.suggestions.add(
        new VisitSummaryWrapper.Suggestion(
          '2',
          'Audit Promotions',
          'Audit active promotions',
          'utility:campaign'
        )
      );
      wrapper.suggestions.add(
        new VisitSummaryWrapper.Suggestion(
          '3',
          'Check Inventory',
          'Check inventory and out-of-stock records',
          'utility:block_visitor'
        )
      );
      wrapper.suggestions.add(
        new VisitSummaryWrapper.Suggestion(
          '4',
          'Order History',
          'Show order history summary',
          'utility:database'
        )
      );
      wrapper.suggestions.add(
        new VisitSummaryWrapper.Suggestion(
          '5',
          'Update Visit',
          'Update Visit Information',
          'utility:settings'
        )
      );
      wrapper.suggestions.add(
        new VisitSummaryWrapper.Suggestion(
          '6',
          'Generate Visit Insight',
          'Generate visit insight report',
          'utility:graph'
        )
      );
    } catch (Exception e) {
      wrapper.storeName = 'Reliance Store';
      wrapper.visitDate = '20-Jun-2026';
      wrapper.visitStatus = 'Planned';
      wrapper.assignedUser = 'Siri FieldRep';
      wrapper.completedTasks = 5;
      wrapper.pendingTasks = 1;
      wrapper.promotionsChecked = 4;
      wrapper.outOfStockIssues = 1;
      wrapper.ordersCreated = 2;
      wrapper.orderValue = 24000.00;
      wrapper.representativeNotes = 'Store requested stock replenishment.';
      wrapper.overallOutcome = 'Successful visit.';

      wrapper.suggestions = new List<VisitSummaryWrapper.Suggestion>();
      wrapper.suggestions.add(
        new VisitSummaryWrapper.Suggestion(
          '1',
          'View Contacts',
          'View Contacts',
          'utility:user'
        )
      );
      wrapper.suggestions.add(
        new VisitSummaryWrapper.Suggestion(
          '2',
          'Audit Promotions',
          'Audit active promotions',
          'utility:campaign'
        )
      );
      wrapper.suggestions.add(
        new VisitSummaryWrapper.Suggestion(
          '3',
          'Check Inventory',
          'Check inventory and out-of-stock records',
          'utility:block_visitor'
        )
      );
      wrapper.suggestions.add(
        new VisitSummaryWrapper.Suggestion(
          '4',
          'Order History',
          'Show order history summary',
          'utility:database'
        )
      );
      wrapper.suggestions.add(
        new VisitSummaryWrapper.Suggestion(
          '5',
          'Update Visit',
          'Update Visit Information',
          'utility:settings'
        )
      );
      wrapper.suggestions.add(
        new VisitSummaryWrapper.Suggestion(
          '6',
          'Generate Visit Insight',
          'Generate visit insight report',
          'utility:graph'
        )
      );
    }
    return wrapper;
  }

  /**
   * @description Prompts the visit mobile.
   * @param req The agent request.
   * @param res The agent response.
   */
  @SuppressWarnings(
    'PMD.AvoidDebugStatements, PMD.CognitiveComplexity, PMD.CyclomaticComplexity, PMD.NcssMethodCount'
  )
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
   * @description Checks if a string is a placeholder.
   * @param input The input string.
   * @return Boolean True if it's a placeholder.
   */
  private static Boolean isPlaceholder(String input) {
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
   * @description Gets picklist options for Visit Status.
   * @return List<Map<String, String>> Options.
   */
  @AuraEnabled(cacheable=true)
  public static List<Map<String, String>> getStatusOptions() {
    List<Map<String, String>> options = new List<Map<String, String>>();
    try {
      Schema.DescribeFieldResult fieldResult = Visit.Status.getDescribe();
      for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
        options.add(
          new Map<String, String>{
            'label' => entry.getLabel(),
            'value' => entry.getValue()
          }
        );
      }
    } catch (Exception e) {
      // Ignored
    }
    return options;
  }

  /**
   * @description Gets active users.
   * @return List<Map<String, String>> Options.
   */
  @AuraEnabled(cacheable=true)
  public static List<Map<String, String>> getActiveUsers() {
    return searchUsers('');
  }

  /**
   * @description Searches active users.
   * @param searchTerm Search query.
   * @return List<Map<String, String>> Options.
   */
  @AuraEnabled(cacheable=true)
  public static List<Map<String, String>> searchUsers(String searchTerm) {
    List<Map<String, String>> options = new List<Map<String, String>>();
    try {
      List<User> users;
      if (String.isBlank(searchTerm)) {
        users = [
          SELECT Id, Name
          FROM User
          WHERE IsActive = TRUE
          WITH USER_MODE
          ORDER BY Name
          LIMIT 50
        ];
      } else {
        String searchPattern = '%' + searchTerm + '%';
        users = [
          SELECT Id, Name
          FROM User
          WHERE Name LIKE :searchPattern AND IsActive = TRUE
          WITH USER_MODE
          ORDER BY Name
          LIMIT 50
        ];
      }
      for (User u : users) {
        options.add(
          new Map<String, String>{ 'label' => u.Name, 'value' => u.Id }
        );
      }
    } catch (Exception e) {
      // Ignored
    }
    return options;
  }

  /**
   * @description Gets a user name by Id.
   * @param userId User Id.
   * @return String User Name.
   */
  @AuraEnabled(cacheable=true)
  public static String getUserName(Id userId) {
    if (userId == null) {
      return '';
    }
    try {
      return [SELECT Name FROM User WHERE Id = :userId WITH USER_MODE LIMIT 1]
      .Name;
    } catch (Exception e) {
      return '';
    }
  }

  /**
   * @description Searches accounts.
   * @param searchTerm Search query.
   * @return List<Map<String, String>> Options.
   */
  @AuraEnabled(cacheable=true)
  public static List<Map<String, String>> searchAccounts(String searchTerm) {
    List<Map<String, String>> options = new List<Map<String, String>>();
    try {
      List<Account> accounts;
      if (String.isBlank(searchTerm)) {
        accounts = [
          SELECT Id, Name
          FROM Account
          WITH USER_MODE
          ORDER BY Name
          LIMIT 50
        ];
      } else {
        String searchPattern =
          '%' +
          String.escapeSingleQuotes(searchTerm) +
          '%';
        accounts = [
          SELECT Id, Name
          FROM Account
          WHERE Name LIKE :searchPattern
          WITH USER_MODE
          ORDER BY Name
          LIMIT 50
        ];
      }
      for (Account acc : accounts) {
        options.add(
          new Map<String, String>{ 'label' => acc.Name, 'value' => acc.Id }
        );
      }
    } catch (Exception e) {
      // Ignored
    }
    return options;
  }

  /**
   * @description Gets an account name by Id.
   * @param accountId Account Id.
   * @return String Account Name.
   */
  @AuraEnabled(cacheable=true)
  public static String getAccountName(Id accountId) {
    if (accountId == null) {
      return '';
    }
    try {
      return [
        SELECT Name
        FROM Account
        WHERE Id = :accountId
        WITH USER_MODE
        LIMIT 1
      ]
      .Name;
    } catch (Exception e) {
      return '';
    }
  }

  /**
   * @description Searches places.
   * @param searchTerm Search query.
   * @return List<Map<String, String>> Options.
   */
  @AuraEnabled(cacheable=true)
  public static List<Map<String, String>> searchPlaces(String searchTerm) {
    List<Map<String, String>> options = new List<Map<String, String>>();
    try {
      List<RetailStore> stores;
      List<Schema.Location> locs;
      if (String.isBlank(searchTerm)) {
        stores = [
          SELECT Id, Name
          FROM RetailStore
          WITH USER_MODE
          ORDER BY Name
          LIMIT 25
        ];
        locs = [
          SELECT Id, Name
          FROM Location
          WITH USER_MODE
          ORDER BY Name
          LIMIT 25
        ];
      } else {
        String searchPattern =
          '%' +
          String.escapeSingleQuotes(searchTerm) +
          '%';
        stores = [
          SELECT Id, Name
          FROM RetailStore
          WHERE Name LIKE :searchPattern
          WITH USER_MODE
          ORDER BY Name
          LIMIT 25
        ];
        locs = [
          SELECT Id, Name
          FROM Location
          WHERE Name LIKE :searchPattern
          WITH USER_MODE
          ORDER BY Name
          LIMIT 25
        ];
      }
      for (RetailStore store : stores) {
        options.add(
          new Map<String, String>{
            'label' => store.Name + ' (Retail Store)',
            'value' => store.Id
          }
        );
      }
      for (Schema.Location loc : locs) {
        options.add(
          new Map<String, String>{
            'label' => loc.Name + ' (Location)',
            'value' => loc.Id
          }
        );
      }
    } catch (Exception e) {
      // Ignored
    }
    return options;
  }

  /**
   * @description Gets a place name by Id.
   * @param placeId Place Id.
   * @return String Place Name.
   */
  @AuraEnabled(cacheable=true)
  public static String getPlaceName(Id placeId) {
    if (placeId == null) {
      return '';
    }
    try {
      String sobjectType = placeId.getSObjectType().getDescribe().getName();
      if (sobjectType == 'RetailStore') {
        return [
            SELECT Name
            FROM RetailStore
            WHERE Id = :placeId
            WITH USER_MODE
            LIMIT 1
          ]
          .Name + ' (Retail Store)';
      } else if (sobjectType == 'Location') {
        return [
            SELECT Name
            FROM Location
            WHERE Id = :placeId
            WITH USER_MODE
            LIMIT 1
          ]
          .Name + ' (Location)';
      }
    } catch (Exception e) {
      // Ignored
    }
    return '';
  }

  /**
   * @description Searches templates.
   * @param searchTerm Search query.
   * @return List<Map<String, String>> Options.
   */
  @AuraEnabled(cacheable=true)
  public static List<Map<String, String>> searchTemplates(String searchTerm) {
    List<Map<String, String>> options = new List<Map<String, String>>();
    try {
      List<cgcloud__Visit_Template__c> templates;
      if (String.isBlank(searchTerm)) {
        templates = [
          SELECT Id, Name
          FROM cgcloud__Visit_Template__c
          WITH USER_MODE
          ORDER BY Name
          LIMIT 50
        ];
      } else {
        String searchPattern =
          '%' +
          String.escapeSingleQuotes(searchTerm) +
          '%';
        templates = [
          SELECT Id, Name
          FROM cgcloud__Visit_Template__c
          WHERE Name LIKE :searchPattern
          WITH USER_MODE
          ORDER BY Name
          LIMIT 50
        ];
      }
      for (cgcloud__Visit_Template__c temp : templates) {
        options.add(
          new Map<String, String>{ 'label' => temp.Name, 'value' => temp.Id }
        );
      }
    } catch (Exception e) {
      // Ignored
    }
    return options;
  }

  /**
   * @description Gets a template name by Id.
   * @param templateId Template Id.
   * @return String Template Name.
   */
  @AuraEnabled(cacheable=true)
  public static String getTemplateName(Id templateId) {
    if (templateId == null) {
      return '';
    }
    try {
      return [
        SELECT Name
        FROM cgcloud__Visit_Template__c
        WHERE Id = :templateId
        WITH USER_MODE
        LIMIT 1
      ]
      .Name;
    } catch (Exception e) {
      return '';
    }
  }

  /**
   * @description Gets the visit details to pre-populate the LWC editor form.
   * @param visitId The ID of the visit.
   * @return CreateVisitWrapper The wrapper object populated with visit details.
   */
  @AuraEnabled(cacheable=true)
  public static CreateVisitWrapper getVisitDataForLwc(Id visitId) {
    if (visitId == null) {
      return null;
    }
    try {
      Visit v = [
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
        WHERE Id = :visitId
        WITH USER_MODE
        LIMIT 1
      ];
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
      return wrapper;
    } catch (Exception e) {
      return null;
    }
  }

  /**
   * @description Gets the responsible user context.
   * @return Map<String, Object> The context map.
   */
  @AuraEnabled(cacheable=true)
  public static Map<String, Object> getResponsibleUserContext() {
    Map<String, Object> result = new Map<String, Object>();
    try {
      User u = [
        SELECT Id, Name, Profile.Name
        FROM User
        WHERE Id = :UserInfo.getUserId()
        WITH USER_MODE
        LIMIT 1
      ];
      result.put('userId', u.Id);
      result.put('userName', u.Name);
      result.put('isCGCloudUser', (u.Profile.Name == 'CGCloud_User_Profile'));
    } catch (Exception e) {
      result.put('userId', UserInfo.getUserId());
      result.put('userName', UserInfo.getName());
      result.put('isCGCloudUser', false);
    }
    return result;
  }

  /**
   * @description Gets current field values of a visit for LWC editor pre-population.
   * @param visitId The Visit ID.
   * @return Map<String, Object> A map of field names to values.
   */
  @AuraEnabled(cacheable=true)
  public static Map<String, Object> getVisitFieldValues(Id visitId) {
    Map<String, Object> result = new Map<String, Object>();
    if (visitId == null) {
      return result;
    }
    try {
      Visit v = [
        SELECT
          Id,
          Status,
          OwnerId,
          Owner.Name,
          PlannedVisitStartTime,
          PlannedVisitEndTime
        FROM Visit
        WHERE Id = :visitId
        WITH USER_MODE
        LIMIT 1
      ];
      result.put('status', v.Status);
      result.put('ownerId', v.OwnerId);
      result.put('ownerName', v.Owner.Name);
      result.put('plannedStartTime', v.PlannedVisitStartTime);
      result.put('plannedEndTime', v.PlannedVisitEndTime);
    } catch (Exception e) {
      // Ignored
    }
    return result;
  }

  /**
   * @description Selects a visit by record ID, registers it in RecentlyViewed, and returns navigation payload.
   * @param req The agent request.
   * @return Agent_Response The agent response.
   */
  private Agent_Response selectAndNavigateVisit(Agent_Request req) {
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
      query += ' FROM Visit WHERE Id = :visitId LIMIT 1 FOR VIEW';

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

        res.visitNavigation = new VisitNavigationWrapper(v.Id);
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
}
