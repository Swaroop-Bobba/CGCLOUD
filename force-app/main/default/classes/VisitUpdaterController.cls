public with sharing class VisitUpdaterController {
  @AuraEnabled(cacheable=true)
  public static List<VisitOptionWrapper> getAvailableVisits() {
    List<VisitOptionWrapper> results = new List<VisitOptionWrapper>();
    try {
      Boolean hasResponsible = Schema.sObjectType.Visit.fields.getMap()
        .containsKey('cgcloud__Responsible__c');
      Boolean hasAccountable = Schema.sObjectType.Visit.fields.getMap()
        .containsKey('cgcloud__Accountable__c');

      String query = 'SELECT Id, Name, Status, PlannedVisitStartTime, PlannedVisitEndTime, Account.Name, cgcloud__Subject__c, cgcloud__Note__c';
      if (hasResponsible) {
        query += ', cgcloud__Responsible__c, cgcloud__Responsible__r.Name';
      }
      if (hasAccountable) {
        query += ', cgcloud__Accountable__c, cgcloud__Accountable__r.Name';
      }
      query += ' FROM Visit ORDER BY PlannedVisitStartTime DESC LIMIT 50';

      List<Visit> visits = Database.query(query);
      for (Visit v : visits) {
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

      Boolean hasResponsible = Schema.sObjectType.Visit.fields.getMap()
        .containsKey('cgcloud__Responsible__c');
      Boolean hasAccountable = Schema.sObjectType.Visit.fields.getMap()
        .containsKey('cgcloud__Accountable__c');

      String query = 'SELECT Id, Name, Status, PlannedVisitStartTime, PlannedVisitEndTime, Account.Name, cgcloud__Subject__c, cgcloud__Note__c';
      if (hasResponsible) {
        query += ', cgcloud__Responsible__c, cgcloud__Responsible__r.Name';
      }
      if (hasAccountable) {
        query += ', cgcloud__Accountable__c, cgcloud__Accountable__r.Name';
      }
      query += ' FROM Visit WHERE Id = :visitId LIMIT 1 FOR VIEW';

      List<Visit> visits = Database.query(query);
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
    Visit v,
    Boolean hasResponsible,
    Boolean hasAccountable
  ) {
    VisitOptionWrapper wrap = new VisitOptionWrapper();
    wrap.visitId = v.Id;
    wrap.visitName = v.Name != null ? v.Name : v.Id;
    wrap.accountName = v.Account != null ? v.Account.Name : '';
    wrap.status = v.Status;
    wrap.plannedStartTime = v.PlannedVisitStartTime != null
      ? v.PlannedVisitStartTime.format(
          'yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'',
          'UTC'
        )
      : '';
    wrap.plannedEndTime = v.PlannedVisitEndTime != null
      ? v.PlannedVisitEndTime.format('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'', 'UTC')
      : '';
    wrap.subject = v.cgcloud__Subject__c;
    wrap.notes = v.cgcloud__Note__c;

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
      Visit v = new Visit(Id = visitId);

      Boolean hasResponsible = Schema.sObjectType.Visit.fields.getMap()
        .containsKey('cgcloud__Responsible__c');
      Boolean hasAccountable = Schema.sObjectType.Visit.fields.getMap()
        .containsKey('cgcloud__Accountable__c');

      for (String fieldName : updates.keySet()) {
        Object val = updates.get(fieldName);
        if (fieldName == 'Status') {
          v.Status = (String) val;
        } else if (fieldName == 'PlannedVisitStartTime') {
          v.PlannedVisitStartTime = val != null
            ? (DateTime) JSON.deserialize(
                '"' + (String) val + '"',
                DateTime.class
              )
            : null;
        } else if (fieldName == 'PlannedVisitEndTime') {
          v.PlannedVisitEndTime = val != null
            ? (DateTime) JSON.deserialize(
                '"' + (String) val + '"',
                DateTime.class
              )
            : null;
        } else if (fieldName == 'cgcloud__Responsible__c' && hasResponsible) {
          v.put('cgcloud__Responsible__c', (String) val);
        } else if (fieldName == 'cgcloud__Accountable__c' && hasAccountable) {
          v.put('cgcloud__Accountable__c', (String) val);
        } else if (fieldName == 'cgcloud__Subject__c') {
          v.cgcloud__Subject__c = (String) val;
        } else if (fieldName == 'cgcloud__Note__c') {
          v.cgcloud__Note__c = (String) val;
        }
      }
      update v;
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
