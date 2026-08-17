global class VisitUpdaterAction {
    
    global class Request {
        @InvocableVariable(description='The Visit ID' required=false)
        global String visitId;
        @InvocableVariable(description='The update wizard payload' required=false)
        global VisitUpdatePayload updatesPayload;
    }
    
    global class Response {
        @InvocableVariable(description='Execution status message')
        global String message;
        @InvocableVariable(description='Execution success status')
        global Boolean success;
    }
    
    @InvocableMethod(label='Execute Visit Updater Wizard Update' description='Applies JSON updates to a Visit record.')
    global static List<Response> executeUpdate(List<Request> requests) {
        List<Response> responses = new List<Response>();
        for (Request req : requests) {
            Response resp = new Response();
            try {
                if (req.updatesPayload == null || String.isBlank(req.updatesPayload.visitId)) {
                    // Direct client-side DML mode: return success immediately
                    resp.success = true;
                    resp.message = 'Successfully updated visit record.';
                    responses.add(resp);
                    continue;
                }
                
                String visitId = req.updatesPayload.visitId;
                String updatesJson = req.updatesPayload.updatesJson;
                
                if (String.isBlank(updatesJson) || updatesJson.trim() == '{}') {
                    resp.success = true;
                    resp.message = 'Cancelled';
                    responses.add(resp);
                    continue;
                }
                
                Map<String, Object> updates = (Map<String, Object>)JSON.deserializeUntyped(updatesJson);
                if (updates.isEmpty()) {
                    resp.success = true;
                    resp.message = 'Cancelled';
                    responses.add(resp);
                    continue;
                }
                Boolean hasVisit = Schema.getGlobalDescribe().containsKey('visit');
                if (!hasVisit) {
                    resp.success = false;
                    resp.message = 'Visit object not available in this org.';
                    responses.add(resp);
                    continue;
                }

                SObject v = Schema.getGlobalDescribe().get('Visit').newSObject(visitId);
                Map<String, Schema.SObjectField> fMap = Schema.getGlobalDescribe().get('Visit').getDescribe().fields.getMap();
                
                for (String fieldName : updates.keySet()) {
                    Object val = updates.get(fieldName);
                    String lowerF = fieldName.toLowerCase();
                    if (lowerF == 'status' && fMap.containsKey('status')) {
                        v.put('Status', (String)val);
                    } else if (lowerF == 'plannedvisitstarttime' && fMap.containsKey('plannedvisitstarttime')) {
                        v.put('PlannedVisitStartTime', val != null ? (DateTime)JSON.deserialize('"' + (String)val + '"', DateTime.class) : null);
                    } else if (lowerF == 'plannedvisitendtime' && fMap.containsKey('plannedvisitendtime')) {
                        v.put('PlannedVisitEndTime', val != null ? (DateTime)JSON.deserialize('"' + (String)val + '"', DateTime.class) : null);
                    } else if (lowerF == 'cgcloud__responsible__c' && fMap.containsKey('cgcloud__responsible__c')) {
                        v.put('cgcloud__Responsible__c', (String)val);
                    } else if (lowerF == 'cgcloud__accountable__c' && fMap.containsKey('cgcloud__accountable__c')) {
                        v.put('cgcloud__Accountable__c', (String)val);
                    } else if (lowerF == 'cgcloud__subject__c' && fMap.containsKey('cgcloud__subject__c')) {
                        v.put('cgcloud__Subject__c', (String)val);
                    } else if (lowerF == 'cgcloud__note__c' && fMap.containsKey('cgcloud__note__c')) {
                        v.put('cgcloud__Note__c', (String)val);
                    }
                }
                
                Database.update(v, AccessLevel.USER_MODE);
                resp.success = true;
                resp.message = 'Successfully updated visit ' + visitId + ' with changes: ' + updatesJson;
            } catch (Exception e) {
                resp.success = false;
                resp.message = 'Error executing update: ' + e.getMessage() + '\nStack: ' + e.getStackTraceString();
            }
            responses.add(resp);
        }
        return responses;
    }
}