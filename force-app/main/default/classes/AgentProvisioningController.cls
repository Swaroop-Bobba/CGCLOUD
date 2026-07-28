global with sharing class AgentProvisioningController {

    @AuraEnabled
    global static String provisionAgents() {
        try {
            return provisionAgentsFromZip();
        } catch (Exception e) {
            return 'ERROR: ' + e.getMessage() + '\nStack Trace: ' + e.getStackTraceString();
        }
    }

    public static String provisionAgentsFromZip() {
        String sessionId = UserInfo.getSessionId();
        if (String.isBlank(sessionId)) {
            return 'ERROR: Active Session ID not available. Please run System.debug(VisitIntel.AgentProvisioningController.provisionAgents()); in Developer Console.';
        }

        List<StaticResource> srList = [
            SELECT Body FROM StaticResource 
            WHERE Name = 'VisitIntelAgentsZip' OR Name = 'VisitIntel__VisitIntelAgentsZip' 
            LIMIT 1
        ];
        
        if (srList.isEmpty() || srList[0].Body == null) {
            return 'ERROR: VisitIntelAgentsZip static resource not found in org.';
        }

        String base64Zip = EncodingUtil.base64Encode(srList[0].Body);

        String xmlBody = '<?xml version="1.0" encoding="utf-8"?>' +
        '<env:Envelope xmlns:env="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">' +
        '  <env:Header>' +
        '    <SessionHeader xmlns="http://soap.sforce.com/2006/04/metadata">' +
        '      <sessionId>' + sessionId + '</sessionId>' +
        '    </SessionHeader>' +
        '  </env:Header>' +
        '  <env:Body>' +
        '    <deploy xmlns="http://soap.sforce.com/2006/04/metadata">' +
        '      <ZipFile>' + base64Zip + '</ZipFile>' +
        '      <DeployOptions>' +
        '        <performRetrieve>false</performRetrieve>' +
        '        <rollbackOnError>true</rollbackOnError>' +
        '        <singlePackage>true</singlePackage>' +
        '      </DeployOptions>' +
        '    </deploy>' +
        '  </env:Body>' +
        '</env:Envelope>';

        HttpRequest req = new HttpRequest();
        String domainUrl = Url.getOrgDomainUrl().toExternalForm();
        req.setEndpoint(domainUrl + '/services/Soap/m/66.0');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'text/xml');
        req.setHeader('SOAPAction', 'deploy');
        req.setBody(xmlBody);

        Http http = new Http();
        HttpResponse res;
        try {
            res = http.send(req);
        } catch (System.CalloutException ce) {
            return 'CALLOUT_ERROR: Unauthorized Endpoint (' + domainUrl + '). Please add Remote Site Setting for ' + domainUrl + ' in Setup -> Remote Site Settings.\nDetails: ' + ce.getMessage();
        }

        System.debug(LoggingLevel.INFO, 'Agent Zip Deploy Response: ' + res.getStatusCode() + ' Body: ' + res.getBody());
        
        return 'HTTP_STATUS: ' + res.getStatusCode() + '\nRESPONSE_BODY:\n' + res.getBody();
    }

    @AuraEnabled
    global static String checkDeployStatus(String deployId) {
        String sessionId = UserInfo.getSessionId();
        if (String.isBlank(sessionId) || String.isBlank(deployId)) {
            return 'ERROR: SessionId or DeployId missing.';
        }

        String xmlBody = '<?xml version="1.0" encoding="utf-8"?>' +
        '<env:Envelope xmlns:env="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">' +
        '  <env:Header>' +
        '    <SessionHeader xmlns="http://soap.sforce.com/2006/04/metadata">' +
        '      <sessionId>' + sessionId + '</sessionId>' +
        '    </SessionHeader>' +
        '  </env:Header>' +
        '  <env:Body>' +
        '    <checkDeployStatus xmlns="http://soap.sforce.com/2006/04/metadata">' +
        '      <asyncProcessId>' + deployId + '</asyncProcessId>' +
        '      <includeDetails>true</includeDetails>' +
        '    </checkDeployStatus>' +
        '  </env:Body>' +
        '</env:Envelope>';

        HttpRequest req = new HttpRequest();
        String domainUrl = Url.getOrgDomainUrl().toExternalForm();
        req.setEndpoint(domainUrl + '/services/Soap/m/66.0');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'text/xml');
        req.setHeader('SOAPAction', 'checkDeployStatus');
        req.setBody(xmlBody);

        Http http = new Http();
        HttpResponse res;
        try {
            res = http.send(req);
        } catch (System.CalloutException ce) {
            return 'CALLOUT_ERROR: Unauthorized Endpoint (' + domainUrl + '). Please add Remote Site Setting for ' + domainUrl + ' in Setup -> Remote Site Settings.\nDetails: ' + ce.getMessage();
        }
        return 'STATUS_CODE: ' + res.getStatusCode() + '\nBODY:\n' + res.getBody();
    }
}
