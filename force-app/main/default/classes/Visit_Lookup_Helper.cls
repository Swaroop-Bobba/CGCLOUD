/**
 * @description Helper class for AuraEnabled lookup, search, and metadata queries used by Lightning Web Components.
 */
@SuppressWarnings(
  'PMD.AvoidDebugStatements, PMD.CognitiveComplexity, PMD.CyclomaticComplexity, PMD.NcssMethodCount, PMD.ExcessiveClassLength, PMD.StdCyclomaticComplexity'
)
public with sharing class Visit_Lookup_Helper {
  /**
   * @description Gets picklist options for Visit Status.
   * @return List<Map<String, String>> Options list.
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
      System.debug(LoggingLevel.ERROR, e.getMessage());
    }
    return options;
  }

  /**
   * @description Gets active users.
   * @return List<Map<String, String>> Options list.
   */
  @AuraEnabled(cacheable=true)
  public static List<Map<String, String>> getActiveUsers() {
    return searchUsers('');
  }

  /**
   * @description Searches active users.
   * @param searchTerm Search query string.
   * @return List<Map<String, String>> Options list.
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
      System.debug(LoggingLevel.ERROR, e.getMessage());
    }
    return options;
  }

  /**
   * @description Gets user name by ID.
   * @param userId User ID.
   * @return String User name.
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
   * @param searchTerm Search query string.
   * @return List<Map<String, String>> Options list.
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
      System.debug(LoggingLevel.ERROR, e.getMessage());
    }
    return options;
  }

  /**
   * @description Gets account name by ID.
   * @param accountId Account ID.
   * @return String Account name.
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
   * @description Searches places (RetailStore and Location).
   * @param searchTerm Search query string.
   * @return List<Map<String, String>> Options list.
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
      System.debug(LoggingLevel.ERROR, e.getMessage());
    }
    return options;
  }

  /**
   * @description Gets place name by ID.
   * @param placeId Place ID.
   * @return String Place name.
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
      System.debug(LoggingLevel.ERROR, e.getMessage());
    }
    return '';
  }

  /**
   * @description Searches visit templates.
   * @param searchTerm Search query string.
   * @return List<Map<String, String>> Options list.
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
      System.debug(LoggingLevel.ERROR, e.getMessage());
    }
    return options;
  }

  /**
   * @description Gets template name by ID.
   * @param templateId Template ID.
   * @return String Template name.
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
   * @description Gets visit details to pre-populate LWC editor form.
   * @param visitId Visit ID.
   * @return CreateVisitWrapper Wrapper object with visit details.
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
   * @description Gets responsible user context.
   * @return Map<String, Object> Context map.
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
   * @param visitId Visit ID.
   * @return Map<String, Object> Field values map.
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
      System.debug(LoggingLevel.ERROR, e.getMessage());
    }
    return result;
  }
}