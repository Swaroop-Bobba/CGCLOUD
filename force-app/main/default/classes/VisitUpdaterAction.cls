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
                Visit v = new Visit(Id = visitId);
                
                Boolean hasResponsible = Schema.sObjectType.Visit.fields.getMap().containsKey('cgcloud__Responsible__c');
                Boolean hasAccountable = Schema.sObjectType.Visit.fields.getMap().containsKey('cgcloud__Accountable__c');
                
                for (String fieldName : updates.keySet()) {
                    Object val = updates.get(fieldName);
                    if (fieldName == 'Status') {
                        v.Status = (String)val;
                    } else if (fieldName == 'PlannedVisitStartTime') {
                        v.PlannedVisitStartTime = val != null ? (DateTime)JSON.deserialize('"' + (String)val + '"', DateTime.class) : null;
                    } else if (fieldName == 'PlannedVisitEndTime') {
                        v.PlannedVisitEndTime = val != null ? (DateTime)JSON.deserialize('"' + (String)val + '"', DateTime.class) : null;
                    } else if (fieldName == 'cgcloud__Responsible__c' && hasResponsible) {
                        v.put('cgcloud__Responsible__c', (String)val);
                    } else if (fieldName == 'cgcloud__Accountable__c' && hasAccountable) {
                        v.put('cgcloud__Accountable__c', (String)val);
                    } else if (fieldName == 'cgcloud__Subject__c') {
                        v.cgcloud__Subject__c = (String)val;
                    } else if (fieldName == 'cgcloud__Note__c') {
                        v.cgcloud__Note__c = (String)val;
                    }
                }
                
                update v;
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