/**
 * @description Helper class to handle Visit search, filtering, available visit options, and natural language date query parsing.
 */
@SuppressWarnings(
  'PMD.AvoidDebugStatements, PMD.CognitiveComplexity, PMD.CyclomaticComplexity, PMD.NcssMethodCount, PMD.ExcessiveClassLength, PMD.StdCyclomaticComplexity'
)
public with sharing class Visit_Search_Helper {
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
   * @description Gets available visits for the current user.
   * @return List<Agent_Response.VisitOption> List of visit options.
   */
  public static List<Agent_Response.VisitOption> getAvailableVisits() {
    List<Agent_Response.VisitOption> options = new List<Agent_Response.VisitOption>();
    try {
      Id currentUserId = UserInfo.getUserId();
      String orgUrl = URL.getOrgDomainUrl().toExternalForm();

      Boolean isAdmin = false;
      try {
        Id profileId = UserInfo.getProfileId();
        List<Profile> profiles = [
          SELECT Name
          FROM Profile
          WHERE Id = :profileId
          WITH USER_MODE
          LIMIT 1
        ];
        if (!profiles.isEmpty() && profiles[0].Name == 'System Administrator') {
          isAdmin = true;
        }
      } catch (Exception e) {
        System.debug(LoggingLevel.WARN, 'Error fetching user profile: ' + e.getMessage());
      }

      Boolean hasResponsible = Schema.sObjectType.Visit.fields.getMap()
        .containsKey('cgcloud__Responsible__c');

      String selectFields = 'SELECT Id, Status, PlannedVisitStartTime, Account.Name, Owner.Name';
      if (hasResponsible) {
        selectFields += ', cgcloud__Responsible__c, cgcloud__Responsible__r.Name';
      }
      selectFields += ' FROM Visit';

      String recentQuery = selectFields;
      if (!isAdmin && hasResponsible) {
        recentQuery += ' WHERE cgcloud__Responsible__c = :currentUserId';
      }
      recentQuery += ' WITH USER_MODE ORDER BY CreatedDate DESC LIMIT 20';

      List<Visit> recentVisits = Database.query(recentQuery);
      for (Visit v : recentVisits) {
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
          '](' +
          orgUrl +
          '/lightning/r/Visit/' +
          v.Id +
          '/view)' +
          '\n   - 📅 Date: ' +
          timeStr +
          '\n   - 📋 Status: ' +
          v.Status +
          '\n   - 👤 Assigned: ' +
          assignedUser;
        options.add(
          new Agent_Response.VisitOption(
            v.Id,
            null,
            v.Account.Name,
            label,
            'Recent Visits'
          )
        );
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
   * @description Gets visits for a specific account.
   * @param accountId Account ID.
   * @param searchOffset Query offset string.
   * @return List<Agent_Response.VisitOption> List of visit options.
   */
  public static List<Agent_Response.VisitOption> getAccountVisits(
    String accountId,
    String searchOffset
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
          WITH USER_MODE
          LIMIT 1
        ];
        if (!profiles.isEmpty() && profiles[0].Name == 'System Administrator') {
          isAdmin = true;
        }
      } catch (Exception e) {
        System.debug(LoggingLevel.ERROR, e.getMessage());
      }

      Boolean hasResponsible = Schema.sObjectType.Visit.fields.getMap()
        .containsKey('cgcloud__Responsible__c');
      Id currentUserId = UserInfo.getUserId();

      Integer offsetVal = 0;
      if (String.isNotBlank(searchOffset)) {
        try {
          offsetVal = Integer.valueOf(searchOffset.trim());
        } catch (Exception e) {
          System.debug(LoggingLevel.ERROR, e.getMessage());
        }
      }

      String queryStr = 'SELECT Id, Name, Status, PlannedVisitStartTime, Account.Name, Owner.Name';
      if (hasResponsible) {
        queryStr += ', cgcloud__Responsible__c, cgcloud__Responsible__r.Name';
      }
      queryStr += ' FROM Visit WHERE AccountId = :accId';

      if (!isAdmin && hasResponsible) {
        queryStr += ' AND cgcloud__Responsible__c = :currentUserId';
      }
      queryStr += ' WITH USER_MODE ORDER BY PlannedVisitStartTime DESC LIMIT 20 OFFSET :offsetVal';

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
          '\n   - 📅 Date: ' +
          timeStr +
          '\n   - 📋 Status: ' +
          v.Status +
          '\n   - 👤 Assigned: ' +
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
      System.debug(LoggingLevel.ERROR, e.getMessage());
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
            '/lightning/r/Visit/mock_acc_visit_1/view">Visit - Account Store</a>\n   - 📅 Date: Today 10:00 AM\n   - 📋 Status: Open\n   - 👤 Assigned: Mock User',
          'Account'
        )
      );
    }
    return options;
  }

  /**
   * @description Gets out-of-stock visits for a specific account.
   * @param accountId Account ID.
   * @param searchOffset Search offset string.
   * @return List<Agent_Response.VisitOption> List of visit options.
   */
  public static List<Agent_Response.VisitOption> getOosVisits(
    String accountId,
    String searchOffset
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
          WITH USER_MODE
          LIMIT 1
        ];
        if (!profiles.isEmpty() && profiles[0].Name == 'System Administrator') {
          isAdmin = true;
        }
      } catch (Exception e) {
        System.debug(LoggingLevel.ERROR, e.getMessage());
      }

      Boolean hasResponsible = Schema.sObjectType.Visit.fields.getMap()
        .containsKey('cgcloud__Responsible__c');
      Id currentUserId = UserInfo.getUserId();

      Integer offsetVal = 0;
      if (String.isNotBlank(searchOffset)) {
        try {
          offsetVal = Integer.valueOf(searchOffset.trim());
        } catch (Exception e) {
          System.debug(LoggingLevel.ERROR, e.getMessage());
        }
      }

      String queryStr = 'SELECT Id, Name, Status, PlannedVisitStartTime, Account.Name, Owner.Name';
      if (hasResponsible) {
        queryStr += ', cgcloud__Responsible__c, cgcloud__Responsible__r.Name';
      }
      queryStr += ' FROM Visit WHERE AccountId = :accId AND cgcloud__OOS_Issues__c = true';

      if (!isAdmin && hasResponsible) {
        queryStr += ' AND cgcloud__Responsible__c = :currentUserId';
      }
      queryStr += ' WITH USER_MODE ORDER BY PlannedVisitStartTime DESC LIMIT 20 OFFSET :offsetVal';

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
          '\n   - 📅 Date: ' +
          timeStr +
          '\n   - 📋 Status: ' +
          v.Status +
          '\n   - 👤 Assigned: ' +
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
      System.debug(LoggingLevel.ERROR, e.getMessage());
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
            '/lightning/r/Visit/mock_oos_visit_1/view">Visit - Account Store (OOS)</a>\n   - 📅 Date: Today 10:00 AM\n   - 📋 Status: Open\n   - 👤 Assigned: Mock User',
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
  public static void setMockVisits(List<Agent_Response.VisitOption> options) {
    String orgUrl = URL.getOrgDomainUrl().toExternalForm();
    options.add(
      new Agent_Response.VisitOption(
        'mock_visit_1',
        null,
        'ABC Retail Store',
        '<a href="' +
          orgUrl +
          '/lightning/r/Visit/mock_visit_1/view">Visit - ABC Retail Store</a>\n   - 📅 Date: Today 10:00 AM\n   - 📋 Status: Open\n   - 👤 Assigned: Mock User',
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
          '/lightning/r/Visit/mock_visit_2/view">Visit - XYZ Supermarket</a>\n   - 📅 Date: Today 2:00 PM\n   - 📋 Status: InProgress\n   - 👤 Assigned: Mock User',
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
          '/lightning/r/Visit/mock_visit_3/view">Visit - Fresh Mart</a>\n   - 📅 Date: Tomorrow\n   - 📋 Status: Open\n   - 👤 Assigned: Mock User',
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
          '/lightning/r/Visit/mock_visit_4/view">Visit - City Hypermarket</a>\n   - 📅 Date: Recently Viewed\n   - 📋 Status: Completed\n   - 👤 Assigned: Mock User',
        'Recently Viewed'
      )
    );
  }

  /**
   * @description Searches visits based on a query string and offset.
   * @param searchQuery The search query string.
   * @param searchOffset Search offset.
   * @return List<Agent_Response.VisitOption> List of matching visit options.
   */
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
          WITH USER_MODE
          LIMIT 1
        ];
        if (!profiles.isEmpty() && profiles[0].Name == 'System Administrator') {
          isAdmin = true;
        }
      } catch (Exception e) {
        System.debug(LoggingLevel.ERROR, e.getMessage());
      }

      Boolean hasResponsible = Schema.sObjectType.Visit.fields.getMap()
        .containsKey('cgcloud__Responsible__c');
      Id currentUserId = UserInfo.getUserId();

      Integer offsetVal = 0;
      if (String.isNotBlank(searchOffset)) {
        try {
          offsetVal = Integer.valueOf(searchOffset.trim());
        } catch (Exception e) {
          System.debug(LoggingLevel.ERROR, e.getMessage());
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
          System.debug(LoggingLevel.ERROR, e.getMessage());
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
          System.debug(LoggingLevel.ERROR, e.getMessage());
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
          System.debug(LoggingLevel.ERROR, e.getMessage());
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
          System.debug(LoggingLevel.ERROR, e.getMessage());
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
        ' WITH USER_MODE ORDER BY PlannedVisitStartTime DESC LIMIT 20 OFFSET :offsetVal';
      List<SObject> visits = Database.query(searchQueryStr);

      Set<Id> placeIdsToQuery = new Set<Id>();
      for (SObject v : visits) {
        try {
          Id pid = (Id) v.get('PlaceId');
          if (pid != null) {
            placeIdsToQuery.add(pid);
          }
        } catch (Exception e) {
          System.debug(LoggingLevel.ERROR, e.getMessage());
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
            System.debug(LoggingLevel.ERROR, e.getMessage());
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
            System.debug(LoggingLevel.ERROR, e.getMessage());
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
            System.debug(LoggingLevel.ERROR, e.getMessage());
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
            System.debug(LoggingLevel.ERROR, e.getMessage());
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
          System.debug(LoggingLevel.ERROR, e.getMessage());
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
          '/view)  —  ' +
          displayAccount +
          '\n   - 📅 Date: ' +
          dateStr +
          '\n   - 📋 Status: ' +
          status +
          '\n   - 👤 Assigned: ' +
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
      System.debug(LoggingLevel.ERROR, e.getMessage());
    }
    return options;
  }

  /**
   * @description Parses a search query string into date components and text query.
   * @param rawQuery The raw search query string.
   * @return ParsedQuery The parsed query result object.
   */
  public static ParsedQuery parseSearchQuery(String rawQuery) {
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
   * @return String Cleaned string.
   */
  public static String removeKeyword(String input, String keyword) {
    String cleaned = input.replace(keyword, '').trim();
    cleaned = cleaned.replaceAll('(?i)\\bvisits?\\b', '').trim();
    cleaned = cleaned.replaceAll('(?i)\\bfor\\b', '').trim();
    cleaned = cleaned.replaceAll('(?i)\\bon\\b', '').trim();
    cleaned = cleaned.replaceAll('(?i)\\bmy\\b', '').trim();
    cleaned = cleaned.replaceAll('\\s+', ' ').trim();
    return cleaned;
  }

  /**
   * @description Tries to parse explicit date format (YYYY-MM-DD or DD/MM/YYYY).
   * @param input Input string.
   * @return Date Parsed date or null.
   */
  public static Date tryParseExplicitDate(String input) {
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
        System.debug(LoggingLevel.ERROR, e.getMessage());
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
        System.debug(LoggingLevel.ERROR, e.getMessage());
      }
    }
    return null;
  }

  /**
   * @description Removes date pattern strings from query.
   * @param input Input string.
   * @return String Cleaned string.
   */
  public static String removeDatePattern(String input) {
    String cleaned = input.replaceAll('\\d{4}-\\d{1,2}-\\d{1,2}', '').trim();
    cleaned = cleaned.replaceAll('\\d{1,2}[/\\-]\\d{1,2}[/\\-]\\d{4}', '')
      .trim();
    cleaned = removeKeyword(cleaned, '');
    return cleaned;
  }

  /**
   * @description Tries to parse month name dates.
   * @param input Input string.
   * @return Date Parsed date or null.
   */
  public static Date tryParseMonthNameDate(String input) {
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
          System.debug(LoggingLevel.ERROR, e.getMessage());
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
          System.debug(LoggingLevel.ERROR, e.getMessage());
        }
      }
    }
    return null;
  }

  /**
   * @description Removes month name date patterns from query string.
   * @param input Input string.
   * @return String Cleaned string.
   */
  public static String removeMonthNameDate(String input) {
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
   * @description Formats datetime into readable date string.
   * @param dt Datetime object.
   * @return String Formatted date string.
   */
  public static String formatDate(Datetime dt) {
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
}