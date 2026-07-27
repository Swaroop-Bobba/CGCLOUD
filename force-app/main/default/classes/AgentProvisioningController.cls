global with sharing class AgentProvisioningController {

    @AuraEnabled
    global static String provisionAgents() {
        try {
            return provisionAgentsFromZip();
        } catch (Exception e) {
            return 'Error: ' + e.getMessage();
        }
    }

    public static String provisionAgentsFromZip() {
        String sessionId = UserInfo.getSessionId();
        if (String.isBlank(sessionId)) {
            return 'Error: Active Session ID not available. Please execute from Developer Console or Admin UI.';
        }

        List<StaticResource> srList = [
            SELECT Body FROM StaticResource 
            WHERE Name = 'VisitIntelAgentsZip' OR Name = 'VisitIntel__VisitIntelAgentsZip' 
            LIMIT 1
        ];
        
        if (srList.isEmpty() || srList[0].Body == null) {
            return 'Error: VisitIntelAgentsZip static resource not found.';
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
        HttpResponse res = http.send(req);
        System.debug(LoggingLevel.INFO, 'Agent Zip Deploy Response: ' + res.getStatusCode() + ' Body: ' + res.getBody());
        
        if (res.getStatusCode() == 200) {
            return 'Success: Agent Deployment Queued. Status Code: 200';
        } else {
            return 'Failed: Status Code ' + res.getStatusCode() + ' Body: ' + res.getBody();
        }
    }
}
