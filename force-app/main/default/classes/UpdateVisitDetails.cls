public with sharing class UpdateVisitDetails {
    public class Request {
        @InvocableVariable(required=true description='The active Visit record ID.')
        public String visitId;

        @InvocableVariable(description='New status value (e.g. InProgress, Completed, Canceled).')
        public String status;

        @InvocableVariable(description='Representative notes to append to the visit.')
        public String notes;

        @InvocableVariable(description='Actual start date/time.')
        public DateTime startTime;

        @InvocableVariable(description='Actual end date/time.')
        public DateTime endTime;

        @InvocableVariable(description='Name of the user to assign the visit.')
        public String ownerName;

        @InvocableVariable(description='Record ID of the user to assign the visit. Optional.')
        public String ownerId;

        @InvocableVariable(description='Alias of the user to assign the visit. Optional.')
        public String ownerAlias;

        @InvocableVariable(description='Profile Name of the user to assign the visit. Optional.')
        public String ownerProfileName;

        @InvocableVariable(description='New planned start date/time.')
        public DateTime plannedStartTime;

        @InvocableVariable(description='New planned end date/time.')
        public DateTime plannedEndTime;
    }

    public class Result {
        @InvocableVariable(description='True if the visit was successfully updated.')
        public Boolean success;

        @InvocableVariable(description='Result status message.')
        public String message;
    }

    @InvocableMethod(
        label='Update Visit Details'
        description='Update fields on the current Visit record. Requires user confirmation.'
    )
    public static List<Result> execute(List<Request> requests) {
        List<Result> results = new List<Result>();
        for (Request req : requests) {
            Result res = new Result();
            res.success = false;
            
            try {
                String visitId = req.visitId;
                if (String.isBlank(visitId)) {
                    res.message = 'Visit ID cannot be empty.';
                    results.add(res);
                    continue;
                }

                // Query existing visit record
                List<Visit> visits = [
                    SELECT Id, Status, ActualVisitStartTime, ActualVisitEndTime, PlannedVisitStartTime, PlannedVisitEndTime, cgcloud__Note__c, OwnerId, cgcloud__Responsible__c 
                    FROM Visit 
                    WHERE Id = :visitId 
                    WITH USER_MODE 
                    LIMIT 1
                ];
                if (visits.isEmpty()) {
                    res.message = 'Visit record not found with ID: ' + visitId;
                    results.add(res);
                    continue;
                }
                
                Visit v = visits[0];
                Boolean changed = false;
                
                // 1. Process Status Command
                if (String.isNotBlank(req.status)) {
                    String statusCmd = req.status.toLowerCase().trim();
                    if (statusCmd.contains('in progress') || statusCmd.contains('inprogress') || statusCmd == 'start') {
                        v.Status = 'InProgress';
                        v.ActualVisitStartTime = DateTime.now();
                        changed = true;
                    } else if (statusCmd.contains('complete') || statusCmd == 'end') {
                        v.Status = 'Completed';
                        v.ActualVisitEndTime = DateTime.now();
                        changed = true;
                    } else if (statusCmd.contains('cancel')) {
                        v.Status = 'Canceled';
                        changed = true;
                    } else {
                        v.Status = req.status;
                        changed = true;
                    }
                }
                
                // 2. Process Notes
                if (String.isNotBlank(req.notes)) {
                    String currentNotes = String.isNotBlank(v.cgcloud__Note__c) ? v.cgcloud__Note__c : '';
                    if (String.isNotBlank(currentNotes)) {
                        v.cgcloud__Note__c = currentNotes + '\n' + req.notes;
                    } else {
                        v.cgcloud__Note__c = req.notes;
                    }
                    changed = true;
                }
                
                // 3. Process Start Time
                if (req.startTime != null) {
                    v.ActualVisitStartTime = req.startTime;
                    changed = true;
                }
                
                // 4. Process End Time
                if (req.endTime != null) {
                    v.ActualVisitEndTime = req.endTime;
                    changed = true;
                }
                
                // 4.5. Process Planned Times
                if (req.plannedStartTime != null) {
                    v.PlannedVisitStartTime = req.plannedStartTime;
                    changed = true;
                }
                if (req.plannedEndTime != null) {
                    v.PlannedVisitEndTime = req.plannedEndTime;
                    changed = true;
                }
                
                // 5. Process Owner Assignment
                if (String.isNotBlank(req.ownerId) || String.isNotBlank(req.ownerName)) {
                    List<User> users = new List<User>();
                    if (String.isNotBlank(req.ownerId)) {
                        String cleanId = req.ownerId.trim();
                        users = [SELECT Id FROM User WHERE Id = :cleanId AND IsActive = true WITH USER_MODE LIMIT 1];
                    } else if (String.isNotBlank(req.ownerName)) {
                        String cleanName = req.ownerName.trim();
                        users = [SELECT Id FROM User WHERE (Name = :cleanName OR Username = :cleanName) AND IsActive = true WITH USER_MODE LIMIT 1];
                    }
                    
                    if (!users.isEmpty()) {
                        v.OwnerId = users[0].Id;
                        try {
                            v.cgcloud__Responsible__c = users[0].Id;
                        } catch(Exception e) {
                            // Fallback if field is not writable in this context
                        }
                        changed = true;
                    } else {
                        res.message = 'User not found. ';
                    }
                }
                
                if (changed) {
                    Database.update(v, AccessLevel.USER_MODE);
                    res.success = true;
                    res.message = (String.isNotBlank(res.message) ? res.message : '') + 'Visit updated successfully.';
                } else {
                    res.success = true;
                    res.message = 'No updates were made to the Visit record.';
                }
                
            } catch (Exception e) {
                res.success = false;
                res.message = 'Error updating visit: ' + e.getMessage();
            }
            
            results.add(res);
        }
        return results;
    }
}