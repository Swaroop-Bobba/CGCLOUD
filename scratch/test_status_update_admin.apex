Visit v = [SELECT Id, Status, ActualVisitStartTime FROM Visit WHERE Name = '00001309' LIMIT 1];
System.debug('Admin Test - Before Update: ' + v.Status + ' | Start Time: ' + v.ActualVisitStartTime);

v.Status = 'InProgress';
v.ActualVisitStartTime = DateTime.now();

try {
    Database.SaveResult sr = Database.update(v, false);
    if (sr.isSuccess()) {
        System.debug('Admin Test - DML Success!');
    } else {
        for (Database.Error err : sr.getErrors()) {
            System.debug('Admin Test - DML Error: ' + err.getStatusCode() + ' - ' + err.getMessage());
        }
    }
} catch (Exception e) {
    System.debug('Admin Test - Exception: ' + e.getMessage());
}

Visit vAfter = [SELECT Id, Status, ActualVisitStartTime FROM Visit WHERE Id = :v.Id];
System.debug('Admin Test - After Update: ' + vAfter.Status + ' | Start Time: ' + vAfter.ActualVisitStartTime);
