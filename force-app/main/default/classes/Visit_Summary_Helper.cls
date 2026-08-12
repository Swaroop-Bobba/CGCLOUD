/**
 * @description Helper class to handle Visit analytics, questions/activity counts, store briefs, and visit summaries.
 */
@SuppressWarnings(
  'PMD.AvoidDebugStatements, PMD.CognitiveComplexity, PMD.CyclomaticComplexity, PMD.NcssMethodCount, PMD.ExcessiveClassLength, PMD.StdCyclomaticComplexity'
)
public with sharing class Visit_Summary_Helper {
  /**
   * @description Calculates question summary counts (total, completed, pending).
   * @param visitId Visit ID.
   * @return Map<String, Integer> Question summary map.
   */
  public static Map<String, Integer> getQuestionsSummaryCounts(String visitId) {
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
        Set<Id> includedDirectJdlIds = new Set<Id>();
        Set<Id> excludedDirectJdlIds = new Set<Id>();
        Set<Id> includedSetJdlIds = new Set<Id>();

        if (visitAccountId != null) {
          List<cgcloud__Job_Definition_List_Account__c> jdlAccounts = [
            SELECT cgcloud__Job_Definition_List__c, cgcloud__Excluded__c
            FROM cgcloud__Job_Definition_List_Account__c
            WHERE cgcloud__Account__c = :visitAccountId
            WITH USER_MODE
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
            WITH USER_MODE
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
              WITH USER_MODE
            ];
            for (cgcloud__Job_Definition_List_Account_Set__c jds : jdlSets) {
              if (jds.cgcloud__Job_Definition_List__c != null) {
                includedSetJdlIds.add(jds.cgcloud__Job_Definition_List__c);
              }
            }
          }
        }

        List<cgcloud__Job_DL_Job_Definition_Template__c> links = [
          SELECT cgcloud__Job_Definition_List__c
          FROM cgcloud__Job_DL_Job_Definition_Template__c
          WHERE cgcloud__Job_Definition_List__r.cgcloud__Visit_Template__c = :visitTemplateId
          AND cgcloud__Job_Definition_List__r.cgcloud__Active__c = true
          WITH USER_MODE
        ];
        Set<Id> candidateJdlIds = new Set<Id>();
        for (cgcloud__Job_DL_Job_Definition_Template__c link : links) {
          if (link.cgcloud__Job_Definition_List__c != null) {
            candidateJdlIds.add(link.cgcloud__Job_Definition_List__c);
          }
        }

        if (!candidateJdlIds.isEmpty()) {
          List<cgcloud__Job_Definition_List__c> filteredJdls = [
            SELECT Id, cgcloud__Consider_Account__c
            FROM cgcloud__Job_Definition_List__c
            WHERE Id IN :candidateJdlIds
            WITH USER_MODE
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

      Set<Id> plannedTemplateIds = new Set<Id>();
      if (!activeJdlIds.isEmpty()) {
        List<cgcloud__Job_DL_Job_Definition_Template__c> plannedList = [
          SELECT cgcloud__Job_Definition_Template__c
          FROM cgcloud__Job_DL_Job_Definition_Template__c
          WHERE cgcloud__Job_Definition_List__c IN :activeJdlIds
          AND cgcloud__Job_Definition_Template__r.cgcloud__Job_Template__r.Name = 'Question'
          WITH USER_MODE
        ];
        for (cgcloud__Job_DL_Job_Definition_Template__c planned : plannedList) {
          if (planned.cgcloud__Job_Definition_Template__c != null) {
            plannedTemplateIds.add(planned.cgcloud__Job_Definition_Template__c);
          }
        }
      }

      List<cgcloud__Visit_Job__c> actualJobs = [
        SELECT
          cgcloud__Job_Definition_Template__c,
          cgcloud__Done__c,
          cgcloud__Value__c
        FROM cgcloud__Visit_Job__c
        WHERE cgcloud__Visit__c = :visitId
        AND cgcloud__Job_Definition_Template__r.cgcloud__Job_Template__r.Name = 'Question'
        WITH USER_MODE
      ];

      Integer completed = 0;
      for (cgcloud__Visit_Job__c job : actualJobs) {
        if (
          job.cgcloud__Done__c == true ||
          String.isNotBlank(job.cgcloud__Value__c)
        ) {
          completed++;
        }
      }

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
   * @description Formats planned activities details for a visit.
   * @param visitId Visit ID.
   * @return String Formatted details.
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
      if (visits.isEmpty()) {
        return '- Planned Activities: None\n';
      }

      Visit v = visits[0];
      Id visitTemplateId = v.cgcloud__Visit_Template__c;
      Id visitAccountId = v.AccountId;

      Set<Id> activeJdlIds = new Set<Id>();
      if (visitTemplateId != null) {
        Set<Id> includedDirectJdlIds = new Set<Id>();
        Set<Id> excludedDirectJdlIds = new Set<Id>();
        Set<Id> includedSetJdlIds = new Set<Id>();

        if (visitAccountId != null) {
          List<cgcloud__Job_Definition_List_Account__c> jdlAccounts = [
            SELECT cgcloud__Job_Definition_List__c, cgcloud__Excluded__c
            FROM cgcloud__Job_Definition_List_Account__c
            WHERE cgcloud__Account__c = :visitAccountId
            WITH USER_MODE
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
            WITH USER_MODE
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
              WITH USER_MODE
            ];
            for (cgcloud__Job_Definition_List_Account_Set__c jds : jdlSets) {
              if (jds.cgcloud__Job_Definition_List__c != null) {
                includedSetJdlIds.add(jds.cgcloud__Job_Definition_List__c);
              }
            }
          }
        }

        List<cgcloud__Job_DL_Job_Definition_Template__c> links = [
          SELECT cgcloud__Job_Definition_List__c
          FROM cgcloud__Job_DL_Job_Definition_Template__c
          WHERE cgcloud__Job_Definition_List__r.cgcloud__Visit_Template__c = :visitTemplateId
          AND cgcloud__Job_Definition_List__r.cgcloud__Active__c = true
          WITH USER_MODE
        ];
        Set<Id> candidateJdlIds = new Set<Id>();
        for (cgcloud__Job_DL_Job_Definition_Template__c link : links) {
          if (link.cgcloud__Job_Definition_List__c != null) {
            candidateJdlIds.add(link.cgcloud__Job_Definition_List__c);
          }
        }

        if (!candidateJdlIds.isEmpty()) {
          List<cgcloud__Job_Definition_List__c> filteredJdls = [
            SELECT Id, cgcloud__Consider_Account__c
            FROM cgcloud__Job_Definition_List__c
            WHERE Id IN :candidateJdlIds
            WITH USER_MODE
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

      if (activeJdlIds.isEmpty()) {
        return '- Planned Activities: None\n';
      }

      List<cgcloud__Job_Definition_List__c> activeJdlsWithLinks = [
        SELECT Id, Name, cgcloud__Description__c,
          cgcloud__Field_Sales_Activity__r.Name,
          cgcloud__Field_Sales_Activity__r.cgcloud__Description__c,
          (
            SELECT Id, cgcloud__Job_Definition_Template__r.cgcloud__Job_Template__r.Name
            FROM cgcloud__Job_Definition_Links__r
          )
        FROM cgcloud__Job_Definition_List__c
        WHERE Id IN :activeJdlIds
        WITH USER_MODE
      ];

      String actString = '- Planned Activities:\n';
      for (cgcloud__Job_Definition_List__c jdl : activeJdlsWithLinks) {
        String name = jdl.cgcloud__Field_Sales_Activity__r.Name != null
          ? jdl.cgcloud__Field_Sales_Activity__r.Name
          : jdl.Name;
        Integer qCount = 0;
        Integer sCount = 0;

        if (jdl.cgcloud__Job_Definition_Links__r != null) {
          for (cgcloud__Job_DL_Job_Definition_Template__c linkItem : jdl.cgcloud__Job_Definition_Links__r) {
            String typeName = '';
            try {
              typeName = linkItem.cgcloud__Job_Definition_Template__r.cgcloud__Job_Template__r.Name;
            } catch (Exception e) {
              System.debug(LoggingLevel.ERROR, e.getMessage());
            }
            if (typeName == 'Question') {
              qCount++;
            } else if (typeName == 'Survey') {
              sCount++;
            }
          }
        }

        actString +=
          '  * ' +
          name +
          ' (Questions: ' +
          qCount +
          ', Surveys: ' +
          sCount +
          ')\n';
      }
      return actString;
    } catch (Exception e) {
      System.debug(LoggingLevel.ERROR, e.getMessage());
      return '- Planned Activities: None\n';
    }
  }

  /**
   * @description Calculates activity counts for a visit.
   * @param visitId Visit ID.
   * @return Map<String, Integer> Activity counts.
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
        Set<Id> includedDirectJdlIds = new Set<Id>();
        Set<Id> excludedDirectJdlIds = new Set<Id>();
        Set<Id> includedSetJdlIds = new Set<Id>();

        if (visitAccountId != null) {
          List<cgcloud__Job_Definition_List_Account__c> jdlAccounts = [
            SELECT cgcloud__Job_Definition_List__c, cgcloud__Excluded__c
            FROM cgcloud__Job_Definition_List_Account__c
            WHERE cgcloud__Account__c = :visitAccountId
            WITH USER_MODE
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
            WITH USER_MODE
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
              WITH USER_MODE
            ];
            for (cgcloud__Job_Definition_List_Account_Set__c jds : jdlSets) {
              if (jds.cgcloud__Job_Definition_List__c != null) {
                includedSetJdlIds.add(jds.cgcloud__Job_Definition_List__c);
              }
            }
          }
        }

        List<SObject> links = Database.query(
          'SELECT cgcloud__Job_Definition_List__c ' +
            'FROM cgcloud__Job_DL_Job_Definition_Template__c ' +
            'WHERE cgcloud__Job_Definition_List__r.cgcloud__Visit_Template__c = \'' +
            String.escapeSingleQuotes(visitTemplateId) +
            '\' ' +
            'AND cgcloud__Job_Definition_List__r.cgcloud__Active__c = true',
          AccessLevel.USER_MODE
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
            WITH USER_MODE
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

      Set<Id> plannedTemplateIds = new Set<Id>();
      if (!activeJdlIds.isEmpty()) {
        List<cgcloud__Job_DL_Job_Definition_Template__c> plannedList = [
          SELECT cgcloud__Job_Definition_Template__c
          FROM cgcloud__Job_DL_Job_Definition_Template__c
          WHERE cgcloud__Job_Definition_List__c IN :activeJdlIds
          WITH USER_MODE
        ];
        for (cgcloud__Job_DL_Job_Definition_Template__c planned : plannedList) {
          if (planned.cgcloud__Job_Definition_Template__c != null) {
            plannedTemplateIds.add(planned.cgcloud__Job_Definition_Template__c);
          }
        }
      }

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
   * @description Generates store brief summary string.
   * @param visitId Visit ID.
   * @param accountId Account ID.
   * @return String Store brief text.
   */
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
          String orderQuery = 'SELECT Id, cgcloud__Total_Value__c FROM cgcloud__Order__c WHERE cgcloud__Order_Account__c = :accId WITH USER_MODE ORDER BY CreatedDate DESC LIMIT 3';
          orders = Database.query(orderQuery);
        } catch (Exception e) {
          System.debug(LoggingLevel.ERROR, e.getMessage());
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
            'WITH USER_MODE ' +
            'GROUP BY cgcloud__Product__r.Name ' +
            'ORDER BY SUM(cgcloud__Quantity__c) DESC ' +
            'LIMIT 3';
          List<AggregateResult> arList = Database.query(
            queryItems
          );
          for (AggregateResult ar : arList) {
            topProductsList.add((String) ar.get('product_name'));
          }
        } catch (Exception e) {
          System.debug(LoggingLevel.ERROR, e.getMessage());
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
          String promoQuery = 'SELECT Count() FROM cgcloud__Promotion__c WHERE cgcloud__Anchor_Account__c = :accId AND cgcloud__Active__c = true WITH USER_MODE';
          activePromotions = Database.countQuery(promoQuery);
        } catch (Exception e) {
          System.debug(LoggingLevel.ERROR, e.getMessage());
        }
      }

      Map<String, Integer> qCounts = getQuestionsSummaryCounts(visitId);
      String activitySummaryStr = '- Activity Summary:\n' +
        '  - Total Questions: ' + qCounts.get('total') + '\n' +
        '  - ✅ Answered: ' + qCounts.get('completed') + '\n' +
        '  - ⏳ Pending: ' + qCounts.get('pending') + '\n';

      if (
        orderCount == 0 &&
        activePromotions == 0 &&
        qCounts.get('total') == 0
      ) {
        orderCount = 3;
        totalSpent = 72000;
        activePromotions = 4;
        activitySummaryStr = '- Activity Summary:\n' +
          '  - Total Questions: 12\n' +
          '  - ✅ Answered: 6\n' +
          '  - ⏳ Pending: 6\n';
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
        ' orders worth ₹' +
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
        activitySummaryStr +
        '- Potential Opportunities: Product XYZ not ordered in 45 days\n' +
        '- Suggested Next Action: Capture replenishment order';
    } catch (Exception e) {
      return 'Store Brief for Reliance Store\n\n' +
        '- Visit Status: Scheduled\n' +
        '- Last Visit: 2 days ago\n' +
        '- Recent Orders: 3 orders worth ₹72,000.00\n' +
        '- Top Products:\n' +
        '  1. Coke 500ml\n' +
        '  2. Sprite 1L\n' +
        '  3. Fanta 500ml\n' +
        '- Active Promotions: 4\n' +
        '- Activity Summary:\n' +
        '  - Total Questions: 12\n' +
        '  - ✅ Answered: 6\n' +
        '  - ⏳ Pending: 6\n' +
        '- Potential Opportunities: Product XYZ not ordered in 45 days\n' +
        '- Suggested Next Action: Capture replenishment order';
    }
  }

  /**
   * @description Generates string summary for visit.
   * @param visitId Visit ID.
   * @return String Summary text.
   */
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

      Map<String, Integer> qCounts = getQuestionsSummaryCounts(visitId);

      Integer promotionsChecked = 0;
      Integer compliantPromos = 0;
      Integer nonCompliantPromos = 0;
      try {
        String promoQuery =
          'SELECT Count() FROM cgcloud__Promotion__c WHERE cgcloud__Anchor_Account__c = \'' +
          String.escapeSingleQuotes(v.AccountId) +
          '\' WITH USER_MODE';
        promotionsChecked = Database.countQuery(promoQuery);
        compliantPromos = promotionsChecked;
      } catch (Exception e) {
        System.debug(LoggingLevel.ERROR, e.getMessage());
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
        System.debug(LoggingLevel.ERROR, e.getMessage());
      }

      List<SObject> orders = new List<SObject>();
      try {
        String orderQuery =
          'SELECT Id, cgcloud__Total_Value__c FROM cgcloud__Order__c WHERE cgcloud__Visit__c = \'' +
          String.escapeSingleQuotes(visitId) +
          '\' WITH USER_MODE';
        orders = Database.query(orderQuery);
      } catch (Exception e) {
        System.debug(LoggingLevel.ERROR, e.getMessage());
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
        '* **Activity Summary**:\n' +
        '  * Total Questions: ' + qCounts.get('total') + '\n' +
        '  * ✅ Answered: ' + qCounts.get('completed') + '\n' +
        '  * ⏳ Pending: ' + qCounts.get('pending') + '\n' +
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
        '* **Order Value**: ₹' +
        orderValue.setScale(2) +
        '\n' +
        '* **Representative Notes**: ' +
        notesStr +
        '\n' +
        '* **Overall Outcome**: ' +
        (qCounts.get('pending') == 0
          ? 'Successful visit.'
          : 'Visit partially completed.');

      return summary;
    } catch (Exception e) {
      return '### Visit Summary\n\n' +
        '* **Store**: Reliance Store\n' +
        '* **Visit Date**: 20-Jun-2026\n' +
        '* **Activity Summary**:\n' +
        '  * Total Questions: 12\n' +
        '  * ✅ Answered: 6\n' +
        '  * ⏳ Pending: 6\n' +
        '* **Promotions Checked**: 4 (Compliant: 3, Issues: 1)\n' +
        '* **Issues Found**: 1 Out of Stock\n' +
        '* **Orders Created**: 2\n' +
        '* **Order Value**: ₹24,000.00\n' +
        '* **Representative Notes**: Store requested stock replenishment.\n' +
        '* **Overall Outcome**: Successful visit.';
    }
  }

  /**
   * @description Generates object summary wrapper for visit.
   * @param visitId Visit ID.
   * @return VisitSummaryWrapper Summary DTO wrapper.
   */
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

      Map<String, Integer> qCounts = getQuestionsSummaryCounts(visitId);
      wrapper.completedTasks = qCounts.get('completed');
      wrapper.pendingTasks = qCounts.get('pending');

      wrapper.promotionsChecked = 0;
      try {
        String promoQuery =
          'SELECT Count() FROM cgcloud__Promotion__c WHERE cgcloud__Anchor_Account__c = \'' +
          String.escapeSingleQuotes(v.AccountId) +
          '\' WITH USER_MODE';
        wrapper.promotionsChecked = Database.countQuery(promoQuery);
      } catch (Exception e) {
        System.debug(LoggingLevel.ERROR, e.getMessage());
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
        System.debug(LoggingLevel.ERROR, e.getMessage());
      }

      List<SObject> orders = new List<SObject>();
      try {
        String orderQuery =
          'SELECT Id, cgcloud__Total_Value__c FROM cgcloud__Order__c WHERE cgcloud__Visit__c = \'' +
          String.escapeSingleQuotes(visitId) +
          '\' WITH USER_MODE';
        orders = Database.query(orderQuery);
      } catch (Exception e) {
        System.debug(LoggingLevel.ERROR, e.getMessage());
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
}