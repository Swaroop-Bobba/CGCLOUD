/**
 * Supplies visit details, status options, and user assignment lists
 * for the interactive visit update wizard component.
 */
public with sharing class VisitUpdaterLwcController {
  @AuraEnabled(cacheable=true)
  public static List<VisitOptionWrapper> getAvailableVisits() {
    List<VisitOptionWrapper> results = new List<VisitOptionWrapper>();
    try {
      Boolean hasVisit = Schema.getGlobalDescribe().containsKey('visit');
      if (!hasVisit) {
        return results;
      }
      Boolean hasResponsible = Schema.getGlobalDescribe().get('visit').getDescribe().fields.getMap()
        .containsKey('cgcloud__responsible__c');
      Boolean hasAccountable = Schema.getGlobalDescribe().get('visit').getDescribe().fields.getMap()
        .containsKey('cgcloud__accountable__c');

      String query = 'SELECT Id, Name, Status, PlannedVisitStartTime, PlannedVisitEndTime, Account.Name';
      if (hasResponsible) {
        query += ', cgcloud__Responsible__c, cgcloud__Responsible__r.Name';
      }
      if (hasAccountable) {
        query += ', cgcloud__Accountable__c, cgcloud__Accountable__r.Name';
      }
      query += ' FROM Visit ORDER BY PlannedVisitStartTime DESC LIMIT 50';

      List<SObject> visits = Database.query(query);
      for (SObject v : visits) {
        results.add(buildWrapper(v, hasResponsible, hasAccountable));
      }
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
    return results;
  }

  @AuraEnabled(cacheable=true)
  public static VisitOptionWrapper getVisitDetails(Id visitId) {
    try {
      if (visitId == null)
        return null;

      Boolean hasVisit = Schema.getGlobalDescribe().containsKey('visit');
      if (!hasVisit) {
        return null;
      }
      Boolean hasResponsible = Schema.getGlobalDescribe().get('visit').getDescribe().fields.getMap()
        .containsKey('cgcloud__responsible__c');
      Boolean hasAccountable = Schema.getGlobalDescribe().get('visit').getDescribe().fields.getMap()
        .containsKey('cgcloud__accountable__c');

      String query = 'SELECT Id, Name, Status, PlannedVisitStartTime, PlannedVisitEndTime, Account.Name';
      if (hasResponsible) {
        query += ', cgcloud__Responsible__c, cgcloud__Responsible__r.Name';
      }
      if (hasAccountable) {
        query += ', cgcloud__Accountable__c, cgcloud__Accountable__r.Name';
      }
      query += ' FROM Visit WHERE Id = :visitId LIMIT 1 FOR VIEW';

      List<SObject> visits = Database.query(query);
      if (!visits.isEmpty()) {
        return buildWrapper(visits[0], hasResponsible, hasAccountable);
      }
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
    return null;
  }

  @AuraEnabled(cacheable=true)
  public static String getMostRecentVisitId() {
    try {
      List<RecentlyViewed> rv = [
        SELECT Id
        FROM RecentlyViewed
        WHERE Type = 'Visit'
        ORDER BY LastViewedDate DESC
        LIMIT 1
      ];
      if (!rv.isEmpty()) {
        return (String) rv[0].Id;
      }
    } catch (Exception e) {
      // Ignore exception and return null
    }
    return null;
  }

  private static VisitOptionWrapper buildWrapper(
    SObject v,
    Boolean hasResponsible,
    Boolean hasAccountable
  ) {
    VisitOptionWrapper wrap = new VisitOptionWrapper();
    wrap.visitId = (String) v.get('Id');
    wrap.visitName = v.get('Name') != null ? (String) v.get('Name') : (String) v.get('Id');
    SObject accRef = v.getSObject('Account');
    wrap.accountName = accRef != null ? (String) accRef.get('Name') : '';
    wrap.status = (String) v.get('Status');
    DateTime startTime = (DateTime) v.get('PlannedVisitStartTime');
    DateTime endTime = (DateTime) v.get('PlannedVisitEndTime');
    wrap.plannedStartTime = startTime != null
      ? startTime.format(
          'yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'',
          'UTC'
        )
      : '';
    wrap.plannedEndTime = endTime != null
      ? endTime.format('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'', 'UTC')
      : '';

    if (hasResponsible && v.getSObject('cgcloud__Responsible__r') != null) {
      wrap.responsibleUserId = (Id) v.get('cgcloud__Responsible__c');
      wrap.responsibleUserName = (String) v.getSObject(
          'cgcloud__Responsible__r'
        )
        .get('Name');
    } else {
      wrap.responsibleUserId = null;
      wrap.responsibleUserName = '';
    }

    if (hasAccountable && v.getSObject('cgcloud__Accountable__r') != null) {
      wrap.accountableUserId = (Id) v.get('cgcloud__Accountable__c');
      wrap.accountableUserName = (String) v.getSObject(
          'cgcloud__Accountable__r'
        )
        .get('Name');
    } else {
      wrap.accountableUserId = null;
      wrap.accountableUserName = '';
    }
    return wrap;
  }

  @AuraEnabled
  public static void updateVisitRecord(Id visitId, String updatesJson) {
    try {
      if (visitId == null || String.isBlank(updatesJson) || updatesJson.trim() == '{}') {
        return;
      }
      Map<String, Object> updates = (Map<String, Object>) JSON.deserializeUntyped(
        updatesJson
      );
      if (updates.isEmpty()) {
        return;
      }

      Boolean hasVisit = Schema.getGlobalDescribe().containsKey('visit');
      if (!hasVisit) {
        return;
      }

      SObject v = Schema.getGlobalDescribe().get('Visit').newSObject(visitId);
      Map<String, Schema.SObjectField> fMap = Schema.getGlobalDescribe().get('Visit').getDescribe().fields.getMap();

      for (String fieldName : updates.keySet()) {
        Object val = updates.get(fieldName);
        String lowerF = fieldName.toLowerCase();
        if (lowerF == 'status' && fMap.containsKey('status')) {
          v.put('Status', (String) val);
        } else if (lowerF == 'plannedvisitstarttime' && fMap.containsKey('plannedvisitstarttime')) {
          v.put('PlannedVisitStartTime', val != null
            ? (DateTime) JSON.deserialize(
                '"' + (String) val + '"',
                DateTime.class
              )
            : null);
        } else if (lowerF == 'plannedvisitendtime' && fMap.containsKey('plannedvisitendtime')) {
          v.put('PlannedVisitEndTime', val != null
            ? (DateTime) JSON.deserialize(
                '"' + (String) val + '"',
                DateTime.class
              )
            : null);
        } else if (lowerF == 'cgcloud__responsible__c' && fMap.containsKey('cgcloud__responsible__c')) {
          v.put('cgcloud__Responsible__c', (String) val);
        } else if (lowerF == 'cgcloud__accountable__c' && fMap.containsKey('cgcloud__accountable__c')) {
          v.put('cgcloud__Accountable__c', (String) val);
        } else if (lowerF == 'cgcloud__subject__c' && fMap.containsKey('cgcloud__subject__c')) {
          v.put('cgcloud__Subject__c', (String) val);
        } else if (lowerF == 'cgcloud__note__c' && fMap.containsKey('cgcloud__note__c')) {
          v.put('cgcloud__Note__c', (String) val);
        }
      }
      Database.update(v, AccessLevel.USER_MODE);
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled(cacheable=true)
  public static List<UserOption> getActiveUsers() {
    List<UserOption> results = new List<UserOption>();
    try {
      for (User u : [
        SELECT Id, Name
        FROM User
        WHERE IsActive = TRUE
        ORDER BY Name ASC
        LIMIT 100
      ]) {
        results.add(new UserOption(u.Id, u.Name));
      }
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
    return results;
  }

  public class VisitOptionWrapper {
    @AuraEnabled
    public String visitId;
    @AuraEnabled
    public String visitName;
    @AuraEnabled
    public String accountName;
    @AuraEnabled
    public String status;
    @AuraEnabled
    public String plannedStartTime;
    @AuraEnabled
    public String plannedEndTime;
    @AuraEnabled
    public String subject;
    @AuraEnabled
    public String notes;
    @AuraEnabled
    public String responsibleUserId;
    @AuraEnabled
    public String responsibleUserName;
    @AuraEnabled
    public String accountableUserId;
    @AuraEnabled
    public String accountableUserName;
  }

  public class UserOption {
    @AuraEnabled
    public String value;
    @AuraEnabled
    public String label;
    public UserOption(String val, String lbl) {
      this.value = val;
      this.label = lbl;
    }
  }
}