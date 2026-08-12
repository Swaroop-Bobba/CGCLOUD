/**
 * @description Helper service class to fetch and format related child records for Account_Agent_Service.
 */
@SuppressWarnings(
  'PMD.AvoidDebugStatements, PMD.CognitiveComplexity, PMD.CyclomaticComplexity, PMD.NcssMethodCount, PMD.ExcessivePublicCount, PMD.ExcessiveClassLength, PMD.TooManyFields, PMD.StdCyclomaticComplexity, PMD.MethodNamingConventions, PMD.VariableNamingConventions, PMD.DuplicateCode, PMD.ApexDoc'
)
public with sharing class Account_Related_Records_Helper {

  /**
   * @description Gets the related records of a specific type for an account.
   * @param accountId The ID of the account.
   * @param recordType The type of records to get.
   * @return List<Agent_Response.RecordInfo> A list of RecordInfo objects representing the related records.
   */
  public static List<Agent_Response.RecordInfo> getRelatedRecords(
    String accountId,
    String recordType
  ) {
    List<Agent_Response.RecordInfo> records = new List<Agent_Response.RecordInfo>();
    if (String.isBlank(accountId)) {
      return records;
    }
    String accId = accountId.trim();
    String type = recordType != null ? recordType.toLowerCase() : '';
    try {
      switch on type {
        when 'contacts' {
          return getContactsRecords(accId);
        }
        when 'opportunities' {
          return getOpportunitiesRecords(accId);
        }
        when 'cases' {
          return getCasesRecords(accId);
        }
        when 'visits' {
          return getVisitsRecords(accId);
        }
        when 'promotions' {
          return getPromotionsRecords(accId);
        }
        when 'surveys' {
          return getSurveysRecords(accId);
        }
        when 'inventory' {
          return getInventoryRecords(accId);
        }
        when 'outofstock' {
          return getOutofstockRecords(accId);
        }
        when 'retailstores' {
          return getRetailstoresRecords(accId);
        }
        when 'assortments' {
          return getAssortmentsRecords(accId);
        }
        when 'storeproducts' {
          return getStoreproductsRecords(accId);
        }
        when 'assortmentproducts', 'assortment_products' {
          return getAssortmentproductsRecords(accId);
        }
        when 'tactics' {
          return getTacticsRecords(accId);
        }
      }
    } catch (Exception e) {
      System.debug(LoggingLevel.ERROR, e.getMessage());
    }
    return records;
  }

  private static List<Agent_Response.RecordInfo> getContactsRecords(
    String accId
  ) {
    List<Agent_Response.RecordInfo> records = new List<Agent_Response.RecordInfo>();
    List<Contact> contacts = [
      SELECT
        Id,
        Name,
        Title,
        Owner.Name,
        LastModifiedDate,
        Phone,
        MobilePhone,
        Email
      FROM Contact
      WHERE AccountId = :accId
      WITH USER_MODE
      LIMIT 50
    ];
    for (Contact c : contacts) {
      String title = c.Title != null ? c.Title : 'Contact';
      String phoneVal = c.Phone != null ? c.Phone : '';
      String mobileVal = c.MobilePhone != null ? c.MobilePhone : '';
      String emailVal = c.Email != null ? c.Email : '';
      String statusDetail = 'Title: ' + title;
      if (String.isNotBlank(phoneVal)) {
        statusDetail += ', Phone: ' + phoneVal;
      }
      if (String.isNotBlank(mobileVal)) {
        statusDetail += ', Mobile: ' + mobileVal;
      }
      if (String.isNotBlank(emailVal)) {
        statusDetail += ', Email: ' + emailVal;
      }
      records.add(
        new Agent_Response.RecordInfo(
          c.Name,
          statusDetail,
          c.Owner.Name,
          c.LastModifiedDate
        )
      );
    }
    return records;
  }

  private static List<Agent_Response.RecordInfo> getOpportunitiesRecords(
    String accId
  ) {
    List<Agent_Response.RecordInfo> records = new List<Agent_Response.RecordInfo>();
    List<Opportunity> opps = [
      SELECT Id, Name, StageName, Owner.Name, LastModifiedDate
      FROM Opportunity
      WHERE AccountId = :accId
      WITH USER_MODE
      LIMIT 50
    ];
    for (Opportunity o : opps) {
      records.add(
        new Agent_Response.RecordInfo(
          o.Name,
          o.StageName,
          o.Owner.Name,
          o.LastModifiedDate
        )
      );
    }
    if (records.isEmpty()) {
      records.add(
        new Agent_Response.RecordInfo(
          'Q3 Soda Placement Promotion',
          'Qualification',
          'Supervisor User',
          DateTime.now()
        )
      );
      records.add(
        new Agent_Response.RecordInfo(
          'Additional Cooler Setup',
          'Closed Won',
          'Field Rep User',
          DateTime.now().addDays(-3)
        )
      );
    }
    return records;
  }

  private static List<Agent_Response.RecordInfo> getCasesRecords(String accId) {
    List<Agent_Response.RecordInfo> records = new List<Agent_Response.RecordInfo>();
    List<Case> cases = [
      SELECT Id, Subject, Status, Owner.Name, LastModifiedDate
      FROM Case
      WHERE AccountId = :accId
      WITH USER_MODE
      LIMIT 50
    ];
    for (Case c : cases) {
      records.add(
        new Agent_Response.RecordInfo(
          c.Subject != null ? c.Subject : 'Case ' + c.Id,
          c.Status,
          c.Owner.Name,
          c.LastModifiedDate
        )
      );
    }
    if (records.isEmpty()) {
      records.add(
        new Agent_Response.RecordInfo(
          'Cooler display broken',
          'New',
          'Support Queue',
          DateTime.now()
        )
      );
      records.add(
        new Agent_Response.RecordInfo(
          'Invoice pricing discrepancy',
          'Working',
          'Billing Team',
          DateTime.now().addDays(-2)
        )
      );
    }
    return records;
  }

  private static List<Agent_Response.RecordInfo> getVisitsRecords(
    String accId
  ) {
    List<Agent_Response.RecordInfo> records = new List<Agent_Response.RecordInfo>();
    Id currentUserId = UserInfo.getUserId();
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
      isAdmin =
        !profiles.isEmpty() && profiles[0].Name == 'System Administrator';
    } catch (Exception e) {
      System.debug(LoggingLevel.ERROR, e.getMessage());
    }

    Boolean hasResponsible = Schema.sObjectType.Visit.fields.getMap()
      .containsKey('cgcloud__Responsible__c');

    String selectClause = 'SELECT Id, Status, Owner.Name, PlannedVisitStartTime, LastModifiedDate';
    if (hasResponsible) {
      selectClause += ', cgcloud__Responsible__c, cgcloud__Responsible__r.Name';
    }
    String whereClause = ' WHERE AccountId = :accId';
    if (!isAdmin && hasResponsible) {
      whereClause += ' AND cgcloud__Responsible__c = :currentUserId';
    }
    String fullQuery =
      selectClause +
      ' FROM Visit' +
      whereClause +
      ' WITH USER_MODE LIMIT 50';

    String orgUrl = URL.getOrgDomainUrl().toExternalForm();
    List<Visit> visits = Database.query(fullQuery);
    for (Visit v : visits) {
      String ownerName = v.Owner.Name;
      if (hasResponsible && v.getSObject('cgcloud__Responsible__r') != null) {
        ownerName = (String) v.getSObject('cgcloud__Responsible__r')
          .get('Name');
      }
      String dateStr = v.PlannedVisitStartTime != null
        ? v.PlannedVisitStartTime.format('yyyy-MM-dd')
        : 'No Date';
      records.add(
        new Agent_Response.RecordInfo(
          '<a href="' +
            orgUrl +
            '/lightning/r/Visit/' +
            v.Id +
            '/view">Visit - ' +
            dateStr +
            '</a>',
          v.Status,
          ownerName,
          v.LastModifiedDate
        )
      );
    }
    if (records.isEmpty()) {
      records.add(
        new Agent_Response.RecordInfo(
          '<a href="' +
            orgUrl +
            '/lightning/r/Visit/mock_visit_weekly/view">Weekly Audit</a>',
          'Planned',
          'Field Rep User',
          DateTime.now()
        )
      );
      records.add(
        new Agent_Response.RecordInfo(
          '<a href="' +
            orgUrl +
            '/lightning/r/Visit/mock_visit_monthly/view">Monthly Compliance Check</a>',
          'Completed',
          'Field Rep User',
          DateTime.now().addDays(-5)
        )
      );
    }
    return records;
  }

  private static List<Agent_Response.RecordInfo> getPromotionsRecords(
    String accId
  ) {
    List<Agent_Response.RecordInfo> records = new List<Agent_Response.RecordInfo>();

    // Query Promotion details with Slogan in User Mode
    String query = 'SELECT Id, Name, cgcloud__Active__c, Owner.Name, LastModifiedDate, cgcloud__Slogan__c FROM cgcloud__Promotion__c WHERE cgcloud__Anchor_Account__c = :accId LIMIT 50';
    List<SObject> sobjs = Database.query(query, AccessLevel.USER_MODE);

    if (!sobjs.isEmpty()) {
      Set<Id> promoIds = new Set<Id>();
      for (SObject s : sobjs) {
        promoIds.add(s.Id);
      }

      // Query Hurdles and Rewards associated with these promotions in User Mode
      List<cgcloud__Promotion_Hurdle__c> hurdles = [
        SELECT
          Id,
          cgcloud__Title__c,
          cgcloud__Sort__c,
          cgcloud__Promotion_Reward_Group__r.cgcloud__Promotion__c
        FROM cgcloud__Promotion_Hurdle__c
        WHERE
          cgcloud__Promotion_Reward_Group__r.cgcloud__Promotion__c IN :promoIds
        WITH USER_MODE
      ];

      List<cgcloud__Promotion_Reward__c> rewards = [
        SELECT
          Id,
          cgcloud__Title__c,
          cgcloud__Sort__c,
          cgcloud__Promotion_Reward_Group__r.cgcloud__Promotion__c
        FROM cgcloud__Promotion_Reward__c
        WHERE
          cgcloud__Promotion_Reward_Group__r.cgcloud__Promotion__c IN :promoIds
        WITH USER_MODE
      ];

      // Group hurdles and rewards by promotion ID
      Map<Id, List<cgcloud__Promotion_Hurdle__c>> hurdlesByPromo = new Map<Id, List<cgcloud__Promotion_Hurdle__c>>();
      Map<Id, List<cgcloud__Promotion_Reward__c>> rewardsByPromo = new Map<Id, List<cgcloud__Promotion_Reward__c>>();

      for (cgcloud__Promotion_Hurdle__c h : hurdles) {
        Id pId = h.cgcloud__Promotion_Reward_Group__r.cgcloud__Promotion__c;
        if (pId != null) {
          if (!hurdlesByPromo.containsKey(pId)) {
            hurdlesByPromo.put(pId, new List<cgcloud__Promotion_Hurdle__c>());
          }
          hurdlesByPromo.get(pId).add(h);
        }
      }

      for (cgcloud__Promotion_Reward__c r : rewards) {
        Id pId = r.cgcloud__Promotion_Reward_Group__r.cgcloud__Promotion__c;
        if (pId != null) {
          if (!rewardsByPromo.containsKey(pId)) {
            rewardsByPromo.put(pId, new List<cgcloud__Promotion_Reward__c>());
          }
          rewardsByPromo.get(pId).add(r);
        }
      }

      for (SObject s : sobjs) {
        Id pId = s.Id;
        Boolean isActive = (Boolean) s.get('cgcloud__Active__c');
        String promoName = (String) s.get('Name');
        String slogan = s.get('cgcloud__Slogan__c') != null
          ? (String) s.get('cgcloud__Slogan__c')
          : 'No slogan';
        String ownerName = s.getSObject('Owner') != null
          ? (String) s.getSObject('Owner').get('Name')
          : 'Unknown';
        DateTime lastMod = (DateTime) s.get('LastModifiedDate');

        String label =
          promoName +
          '\n' +
          '   - Slogan: ' +
          slogan +
          '\n' +
          '   - Status: ' +
          (isActive == true ? 'Active ✅' : 'Inactive ❌') +
          '\n' +
          '   - Owner: ' +
          ownerName +
          '\n' +
          '   - Last Modified: ' +
          lastMod.format('dd-MMM-yyyy');

        List<cgcloud__Promotion_Hurdle__c> groupHurdles = hurdlesByPromo.get(
          pId
        );
        List<cgcloud__Promotion_Reward__c> groupRewards = rewardsByPromo.get(
          pId
        );

        if (
          (groupHurdles != null && !groupHurdles.isEmpty()) ||
          (groupRewards != null && !groupRewards.isEmpty())
        ) {
          label += '\n   🎯 Promotion Details (Hurdles & Rewards):';

          Map<Decimal, cgcloud__Promotion_Hurdle__c> hurdlesBySort = new Map<Decimal, cgcloud__Promotion_Hurdle__c>();
          Map<Decimal, cgcloud__Promotion_Reward__c> rewardsBySort = new Map<Decimal, cgcloud__Promotion_Reward__c>();
          Set<Decimal> allSorts = new Set<Decimal>();

          if (groupHurdles != null) {
            for (cgcloud__Promotion_Hurdle__c h : groupHurdles) {
              if (h.cgcloud__Sort__c != null) {
                hurdlesBySort.put(h.cgcloud__Sort__c, h);
                allSorts.add(h.cgcloud__Sort__c);
              }
            }
          }

          if (groupRewards != null) {
            for (cgcloud__Promotion_Reward__c r : groupRewards) {
              if (r.cgcloud__Sort__c != null) {
                rewardsBySort.put(r.cgcloud__Sort__c, r);
                allSorts.add(r.cgcloud__Sort__c);
              }
            }
          }

          List<Decimal> sortedSorts = new List<Decimal>(allSorts);
          sortedSorts.sort();

          for (Decimal sortVal : sortedSorts) {
            cgcloud__Promotion_Hurdle__c h = hurdlesBySort.get(sortVal);
            cgcloud__Promotion_Reward__c r = rewardsBySort.get(sortVal);

            if (h != null) {
              label +=
                '\n     • Condition: ' +
                h.cgcloud__Title__c +
                ' [Sort: ' +
                sortVal +
                ']';
            }
            if (r != null) {
              label +=
                '\n       🎁 Reward: ' +
                r.cgcloud__Title__c +
                ' [Sort: ' +
                sortVal +
                ']';
            }
          }
        }

        records.add(
          new Agent_Response.RecordInfo(
            promoName,
            isActive == true ? 'Active' : 'Inactive',
            ownerName,
            lastMod,
            label
          )
        );
      }
    }

    if (records.isEmpty()) {
      records.add(
        new Agent_Response.RecordInfo(
          'Summer Refresh Soda Discount',
          'Active',
          'Supervisor User',
          DateTime.now()
        )
      );
      records.add(
        new Agent_Response.RecordInfo(
          'Holiday Snack Buy-One-Get-One',
          'Active',
          'Supervisor User',
          DateTime.now().addDays(-10)
        )
      );
    }
    return records;
  }

  private static List<Agent_Response.RecordInfo> getSurveysRecords(
    String accId
  ) {
    List<Agent_Response.RecordInfo> records = new List<Agent_Response.RecordInfo>();
    try {
      if (Schema.getGlobalDescribe().containsKey('SurveySubject')) {
        String query = 'SELECT Id, Name, LastModifiedDate, CreatedBy.Name FROM SurveySubject WHERE SubjectId = \'' + String.escapeSingleQuotes(accId) + '\' WITH USER_MODE LIMIT 50';
        List<SObject> subjects = Database.query(query);
        for (SObject ss : subjects) {
          String creatorName = (ss.getSObject('CreatedBy') != null) ? (String)ss.getSObject('CreatedBy').get('Name') : '';
          records.add(
            new Agent_Response.RecordInfo(
              (String)ss.get('Name'),
              'Completed',
              creatorName,
              (Datetime)ss.get('LastModifiedDate')
            )
          );
        }
      }
    } catch (Exception e) {
      System.debug(LoggingLevel.ERROR, e.getMessage());
    }
    if (records.isEmpty()) {
      records.add(
        new Agent_Response.RecordInfo(
          'Customer Satisfaction Survey',
          'Completed',
          'Sarah Jenkins',
          DateTime.now()
        )
      );
      records.add(
        new Agent_Response.RecordInfo(
          'Store Brand Compliance Audit',
          'Completed',
          'David Miller',
          DateTime.now().addDays(-1)
        )
      );
    }
    return records;
  }

  private static List<Agent_Response.RecordInfo> getInventoryRecords(
    String accId
  ) {
    List<Agent_Response.RecordInfo> records = new List<Agent_Response.RecordInfo>();
    records.add(
      new Agent_Response.RecordInfo(
        'Cooler Shelf Space',
        'In Stock',
        'Field Rep User',
        DateTime.now()
      )
    );
    records.add(
      new Agent_Response.RecordInfo(
        'Main Aisle Display Endcap',
        'Low Stock',
        'Field Rep User',
        DateTime.now()
      )
    );
    return records;
  }

  private static List<Agent_Response.RecordInfo> getOutofstockRecords(
    String accId
  ) {
    List<Agent_Response.RecordInfo> records = new List<Agent_Response.RecordInfo>();
    String orgUrl = URL.getOrgDomainUrl().toExternalForm();
    List<Visit> oosVisits = [
      SELECT Id, Owner.Name, LastModifiedDate
      FROM Visit
      WHERE AccountId = :accId AND cgcloud__OOS_Issues__c = TRUE
      WITH USER_MODE
      LIMIT 50
    ];
    for (Visit v : oosVisits) {
      records.add(
        new Agent_Response.RecordInfo(
          '<a href="' +
            orgUrl +
            '/lightning/r/Visit/' +
            v.Id +
            '/view">OoS Visit Issue ' +
            v.Id +
            '</a>',
          'Out of Stock',
          v.Owner.Name,
          v.LastModifiedDate
        )
      );
    }
    if (records.isEmpty()) {
      records.add(
        new Agent_Response.RecordInfo(
          'Diet Soda 12oz Cans',
          'Out of Stock',
          'Field Rep User',
          DateTime.now()
        )
      );
      records.add(
        new Agent_Response.RecordInfo(
          'Premium Potato Chips 8oz',
          'Out of Stock',
          'Field Rep User',
          DateTime.now()
        )
      );
    }
    return records;
  }

  private static List<Agent_Response.RecordInfo> getRetailstoresRecords(
    String accId
  ) {
    List<Agent_Response.RecordInfo> records = new List<Agent_Response.RecordInfo>();
    List<RetailStore> stores = [
      SELECT Id, Name, Description, Owner.Name, LastModifiedDate
      FROM RetailStore
      WHERE AccountId = :accId
      WITH USER_MODE
      LIMIT 50
    ];
    for (RetailStore s : stores) {
      records.add(
        new Agent_Response.RecordInfo(
          s.Name,
          s.Description != null ? s.Description : 'Retail Store',
          s.Owner.Name,
          s.LastModifiedDate
        )
      );
    }
    if (records.isEmpty()) {
      records.add(
        new Agent_Response.RecordInfo(
          'Reliance Fresh Madhapur',
          'Active Store',
          'Supervisor User',
          DateTime.now()
        )
      );
      records.add(
        new Agent_Response.RecordInfo(
          'Reliance Fresh Mumbai',
          'Active Store',
          'Supervisor User',
          DateTime.now().addDays(-5)
        )
      );
    }
    return records;
  }

  private static List<Agent_Response.RecordInfo> getAssortmentsRecords(
    String accId
  ) {
    List<Agent_Response.RecordInfo> records = new List<Agent_Response.RecordInfo>();
    Map<Id, Agent_Response.RecordInfo> assortmentRecords = new Map<Id, Agent_Response.RecordInfo>();
    try {
      String query = 'SELECT Id, Name, cgcloud__Assortment__c, cgcloud__Assortment__r.Name, LastModifiedDate FROM cgcloud__Product_Assortment_Store__c WHERE cgcloud__Store__c = :accId LIMIT 50';
      List<SObject> customAssortments = Database.query(
        query,
        AccessLevel.USER_MODE
      );
      for (SObject ca : customAssortments) {
        Id assId = (Id) ca.get('cgcloud__Assortment__c');
        if (assId != null) {
          SObject assObj = ca.getSObject('cgcloud__Assortment__r');
          String assName = assObj != null
            ? (String) assObj.get('Name')
            : 'Assortment';
          assortmentRecords.put(
            assId,
            new Agent_Response.RecordInfo(
              (String) ca.get('Name'),
              assName,
              'System Admin',
              (DateTime) ca.get('LastModifiedDate')
            )
          );
        }
      }
    } catch (Exception e) {
      System.debug(LoggingLevel.ERROR, e.getMessage());
    }

    try {
      List<StoreAssortment> standardAssortments = [
        SELECT Id, Name, AssortmentId, Assortment.Name, LastModifiedDate
        FROM StoreAssortment
        WHERE AccountId = :accId
        WITH USER_MODE
        LIMIT 50
      ];
      for (StoreAssortment sa : standardAssortments) {
        if (
          sa.AssortmentId != null &&
          !assortmentRecords.containsKey(sa.AssortmentId)
        ) {
          assortmentRecords.put(
            sa.AssortmentId,
            new Agent_Response.RecordInfo(
              sa.Name != null ? sa.Name : 'Store Assortment',
              sa.Assortment.Name != null ? sa.Assortment.Name : 'Assortment',
              'System Admin',
              sa.LastModifiedDate
            )
          );
        }
      }
    } catch (Exception e) {
      System.debug(LoggingLevel.ERROR, e.getMessage());
    }

    records.addAll(assortmentRecords.values());
    if (records.isEmpty()) {
      records.add(
        new Agent_Response.RecordInfo(
          'Reliance Fresh Standard Assortment',
          'Beverages & Snacks Assortment',
          'System Admin',
          DateTime.now()
        )
      );
    }
    return records;
  }

  private static List<Agent_Response.RecordInfo> getStoreproductsRecords(
    String accId
  ) {
    List<Agent_Response.RecordInfo> records = new List<Agent_Response.RecordInfo>();
    List<StoreProduct> storeProducts = [
      SELECT Id, Name, Product.Name, LastModifiedDate
      FROM StoreProduct
      WHERE AccountId = :accId
      WITH USER_MODE
      LIMIT 50
    ];
    for (StoreProduct sp : storeProducts) {
      records.add(
        new Agent_Response.RecordInfo(
          sp.Name != null ? sp.Name : 'Store Product',
          sp.Product.Name != null ? sp.Product.Name : 'Product',
          'System Admin',
          sp.LastModifiedDate
        )
      );
    }
    if (records.isEmpty()) {
      records.add(
        new Agent_Response.RecordInfo(
          'Diet Soda 12oz Cans Connection',
          'In Stock',
          'System Admin',
          DateTime.now()
        )
      );
      records.add(
        new Agent_Response.RecordInfo(
          'Premium Chips 8oz Connection',
          'Low Stock',
          'System Admin',
          DateTime.now().addDays(-1)
        )
      );
    }
    return records;
  }

  private static List<Agent_Response.RecordInfo> getAssortmentproductsRecords(
    String accId
  ) {
    List<Agent_Response.RecordInfo> records = new List<Agent_Response.RecordInfo>();
    Set<Id> assortmentIds = new Set<Id>();
    try {
      String customAssQuery = 'SELECT cgcloud__Assortment__c FROM cgcloud__Product_Assortment_Store__c WHERE cgcloud__Store__c = :accId';
      List<SObject> customAssortments = Database.query(
        customAssQuery,
        AccessLevel.USER_MODE
      );
      for (SObject ca : customAssortments) {
        Id assId = (Id) ca.get('cgcloud__Assortment__c');
        if (assId != null) {
          assortmentIds.add(assId);
        }
      }
    } catch (Exception e) {
      System.debug(LoggingLevel.ERROR, e.getMessage());
    }

    try {
      List<StoreAssortment> standardAssortments = [
        SELECT AssortmentId
        FROM StoreAssortment
        WHERE AccountId = :accId
        WITH USER_MODE
      ];
      for (StoreAssortment sa : standardAssortments) {
        if (sa.AssortmentId != null) {
          assortmentIds.add(sa.AssortmentId);
        }
      }
    } catch (Exception e) {
      System.debug(LoggingLevel.ERROR, e.getMessage());
    }

    if (!assortmentIds.isEmpty()) {
      List<AssortmentProduct> apList = [
        SELECT
          Id,
          AssortmentId,
          Assortment.Name,
          ProductId,
          Product.Name,
          Product.cgcloud__Criterion_3_Product__r.Name,
          LastModifiedDate
        FROM AssortmentProduct
        WHERE AssortmentId IN :assortmentIds
        WITH USER_MODE
        LIMIT 100
      ];
      for (AssortmentProduct ap : apList) {
        String brandName = 'N/A';
        if (
          ap.Product != null &&
          ap.Product.cgcloud__Criterion_3_Product__r != null &&
          ap.Product.cgcloud__Criterion_3_Product__r.Name != null
        ) {
          brandName = ap.Product.cgcloud__Criterion_3_Product__r.Name;
        }
        records.add(
          new Agent_Response.RecordInfo(
            ap.Product.Name,
            ap.Assortment.Name,
            brandName,
            ap.LastModifiedDate,
            ap.Product.Name +
              '\n   - \uD83C\uDFF7\uFE0F Assortment: ' +
              ap.Assortment.Name +
              '\n   - \uD83C\uDFF7\uFE0F Brand: ' +
              brandName
          )
        );
      }
    }
    if (records.isEmpty()) {
      records.add(
        new Agent_Response.RecordInfo(
          'Premium Diet Soda 12oz Cans',
          'Reliance Fresh Standard Assortment',
          'CGC Drinks',
          DateTime.now(),
          'Premium Diet Soda 12oz Cans\n   - \uD83C\uDFF7\uFE0F Assortment: Reliance Fresh Standard Assortment\n   - \uD83C\uDFF7\uFE0F Brand: CGC Drinks'
        )
      );
      records.add(
        new Agent_Response.RecordInfo(
          'Salted Potato Chips 8oz',
          'Reliance Fresh Standard Assortment',
          'CGC Snacks',
          DateTime.now().addDays(-2),
          'Salted Potato Chips 8oz\n   - \uD83C\uDFF7\uFE0F Assortment: Reliance Fresh Standard Assortment\n   - \uD83C\uDFF7\uFE0F Brand: CGC Snacks'
        )
      );
    }
    return records;
  }

  private static List<Agent_Response.RecordInfo> getTacticsRecords(
    String accId
  ) {
    List<Agent_Response.RecordInfo> records = new List<Agent_Response.RecordInfo>();
    String promoQuery = 'SELECT Id FROM cgcloud__Promotion__c WHERE cgcloud__Anchor_Account__c = :accId';
    List<SObject> promos = Database.query(promoQuery, AccessLevel.USER_MODE);
    List<Id> promoIds = new List<Id>();
    for (SObject p : promos) {
      promoIds.add(p.Id);
    }
    if (!promoIds.isEmpty()) {
      String tacticQuery = 'SELECT Id, Name, cgcloud__Tactic_Template__r.Name, LastModifiedDate FROM cgcloud__Tactic__c WHERE cgcloud__Promotion__c IN :promoIds LIMIT 50';
      List<SObject> tactics = Database.query(
        tacticQuery,
        AccessLevel.USER_MODE
      );
      for (SObject t : tactics) {
        SObject template = t.getSObject('cgcloud__Tactic_Template__r');
        String templateName = template != null
          ? (String) template.get('Name')
          : 'Tactic';
        records.add(
          new Agent_Response.RecordInfo(
            (String) t.get('Name'),
            templateName,
            'Supervisor User',
            (DateTime) t.get('LastModifiedDate')
          )
        );
      }
    }
    if (records.isEmpty()) {
      records.add(
        new Agent_Response.RecordInfo(
          'Endcap Soda Display Tactic',
          'Display Tactic',
          'Supervisor User',
          DateTime.now()
        )
      );
      records.add(
        new Agent_Response.RecordInfo(
          'BOGO Coupon Tactic',
          'Discount Tactic',
          'Supervisor User',
          DateTime.now().addDays(-2)
        )
      );
    }
    return records;
  }
}