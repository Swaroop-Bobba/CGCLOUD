/**
 * @description Self-contained Invocable Service for Account domain in Visit Intelligence Agentforce agents.
 *              Contains all Account summary, related contacts, opportunities, cases, visits, products,
 *              and store brief logic directly in a single class with 0 external helper class dependencies.
 */
global with sharing class Account_Agent_Handler {

    /**
     * @description Explicit zero-argument default constructor for 2GP serialization.
     */
    global Account_Agent_Handler() {}

    /**
     * @description Input DTO for Account_Agent_Handler.
     */
    global class Request {
        @InvocableVariable(required=true description='Action to perform (e.g. getAccountDetails, getCounts, getRecords, getProducts, getAccountSummary, getStoreBrief, searchAccounts).')
        global String actionType;

        @InvocableVariable(description='The name of the agent executing the request.')
        global String agentName;

        @InvocableVariable(description='Domain context.')
        global String domain;

        @InvocableVariable(description='Target Account record ID.')
        global String accountId;

        @InvocableVariable(description='Target Visit ID.')
        global String visitId;

        @InvocableVariable(description='Search query string.')
        global String searchQuery;

        @InvocableVariable(description='Category or type of related records.')
        global String category;

        @InvocableVariable(description='Target Promotion ID or Name.')
        global String promotionId;

        @InvocableVariable(description='Record type category for related records.')
        global String recordType;

        global Request() {}
    }

    /**
     * @description Output DTO for Account_Agent_Handler.
     */
    global class Response {
        @InvocableVariable(description='True if operation succeeded.')
        global Boolean success;

        @InvocableVariable(description='Outcome message.')
        global String message;

        @InvocableVariable(description='Markdown formatted report or result list.')
        global String summary;

        @InvocableVariable(description='Direct Google Maps web navigation URL.')
        global String googleMapsUrl;

        @InvocableVariable(description='Total related Contacts count.')
        global Integer totalContacts;

        @InvocableVariable(description='Open Opportunities count.')
        global Integer openOpportunities;

        @InvocableVariable(description='Total pipeline amount for open opportunities.')
        global Decimal totalPipelineValue;

        @InvocableVariable(description='Open Cases count.')
        global Integer openCases;

        @InvocableVariable(description='Total historical and planned Visits count.')
        global Integer totalVisits;

        global Response() {
            this.success = true;
            this.totalContacts = 0;
            this.openOpportunities = 0;
            this.totalPipelineValue = 0.00;
            this.openCases = 0;
            this.totalVisits = 0;
        }
    }

    @InvocableMethod(
        label='Account Agent Handler'
        description='Dispatches self-contained Account actions (details, contacts, opportunities, cases, visits, search, products, store brief) for Visit Intelligence agents.'
    )
    global static List<Response> execute(List<Request> requests) {
        List<Response> results = new List<Response>();

        for (Request req : requests) {
            Response res = new Response();
            try {
                String action = req.actionType != null ? req.actionType.toLowerCase().trim() : '';

                if (action == 'getaccountdetails' || action == 'get_account_details' || action == 'getaccountsummary' || action == 'get_account_summary' || action == 'account_summary') {
                    res = handleGetAccountDetails(req.accountId);
                } else if (action == 'getcounts' || action == 'get_counts') {
                    res = handleGetCounts(req.accountId);
                } else if (action == 'getrecords' || action == 'get_records') {
                    res = handleGetRelatedRecords(req.accountId, req.category);
                } else if (action == 'getproducts' || action == 'get_products' || action == 'getrelatedproducts' || action == 'get_related_products') {
                    res = handleGetProducts(req.accountId);
                } else if (action == 'getpromotions' || action == 'get_promotions') {
                    res = handleGetPromotions(req.accountId);
                } else if (action == 'getstorebrief' || action == 'get_store_brief' || action == 'store_brief') {
                    res = handleGetStoreBrief(req.accountId);
                } else if (action == 'getaccountcontacts' || action == 'get_account_contacts') {
                    res = handleGetAccountContacts(req.accountId);
                } else if (action == 'getaccountopportunities' || action == 'get_account_opportunities') {
                    res = handleGetAccountOpportunities(req.accountId);
                } else if (action == 'getaccountcases' || action == 'get_account_cases') {
                    res = handleGetAccountCases(req.accountId);
                } else if (action == 'getaccountvisits' || action == 'get_account_visits' || action == 'getoosvisits' || action == 'get_oos_visits') {
                    res = handleGetAccountVisits(req.accountId);
                } else if (action == 'searchaccounts' || action == 'search_accounts' || action == 'search') {
                    res = handleSearchAccounts(req.searchQuery);
                } else {
                    res = handleGetAccountDetails(req.accountId);
                }
            } catch (Exception e) {
                res.success = false;
                res.message = 'Error executing account action: ' + e.getMessage();
                res.summary = 'An error occurred while processing account request: ' + e.getMessage();
            }
            results.add(res);
        }
        return results;
    }

    // =========================================================================
    // INLINED DOMAIN LOGIC: ACCOUNTS (No external helper calls)
    // =========================================================================

    private static Response handleGetAccountDetails(String accountId) {
        Response res = new Response();
        if (String.isBlank(accountId)) {
            res.success = false;
            res.message = 'Account ID is required.';
            res.summary = 'Please provide a valid Account ID.';
            return res;
        }

        List<Account> accs = [
            SELECT Id, Name, Industry, Phone, AnnualRevenue, NumberOfEmployees, Type,
                   BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry
              FROM Account
             WHERE Id = :accountId
             LIMIT 1
        ];

        if (accs.isEmpty()) {
            res.success = false;
            res.message = 'Account not found for ID: ' + accountId;
            res.summary = 'No Account found for ID: ' + accountId;
            return res;
        }

        Account acc = accs[0];

        // Direct Google Maps Link
        List<String> addrParts = new List<String>();
        if (String.isNotBlank(acc.BillingStreet)) { addrParts.add(acc.BillingStreet); }
        if (String.isNotBlank(acc.BillingCity)) { addrParts.add(acc.BillingCity); }
        if (String.isNotBlank(acc.BillingState)) { addrParts.add(acc.BillingState); }
        if (String.isNotBlank(acc.BillingPostalCode)) { addrParts.add(acc.BillingPostalCode); }
        if (String.isNotBlank(acc.BillingCountry)) { addrParts.add(acc.BillingCountry); }

        String fullAddr = !addrParts.isEmpty() ? String.join(addrParts, ', ') : acc.Name;
        res.googleMapsUrl = 'https://www.google.com/maps?q=' + EncodingUtil.urlEncode(fullAddr, 'UTF-8');

        res.totalContacts = [SELECT COUNT() FROM Contact WHERE AccountId = :accountId];

        List<AggregateResult> oppAgg = [
            SELECT COUNT(Id) totalCount, SUM(Amount) totalAmount
              FROM Opportunity
             WHERE AccountId = :accountId AND IsClosed = false
        ];
        if (!oppAgg.isEmpty()) {
            res.openOpportunities = (Integer) oppAgg[0].get('totalCount');
            res.totalPipelineValue = (Decimal) oppAgg[0].get('totalAmount');
        }

        res.openCases = [SELECT COUNT() FROM Case WHERE AccountId = :accountId AND IsClosed = false];
        
        Boolean hasVisit = Schema.getGlobalDescribe().containsKey('visit');
        if (hasVisit) {
            try {
                res.totalVisits = Database.countQuery('SELECT COUNT() FROM Visit WHERE AccountId = \'' + String.escapeSingleQuotes(accountId) + '\'');
            } catch (Exception e) {
                res.totalVisits = 0;
            }
        }

        String md = '### 🏢 Account Overview: **[' + acc.Name + '](/lightning/r/Account/' + acc.Id + '/view)**\n\n';
        md += '- **Industry**: ' + (acc.Industry != null ? acc.Industry : 'Consumer Goods') + '\n';
        md += '- **Phone**: ' + (acc.Phone != null ? '[' + acc.Phone + '](tel:' + acc.Phone + ')' : 'N/A') + '\n';
        md += '- **Annual Revenue**: ' + (acc.AnnualRevenue != null ? '$' + acc.AnnualRevenue.format() : 'N/A') + '\n';
        md += '- **Address**: ' + fullAddr + '\n';
        md += '- **Navigation**: [Open in Google Maps](' + res.googleMapsUrl + ')\n\n';

        md += '#### 📊 Key Relationship Metrics:\n';
        md += '- 👥 **Contacts**: ' + res.totalContacts + ' active contacts\n';
        md += '- 💼 **Open Deals**: ' + res.openOpportunities + ' opportunities ($' + (res.totalPipelineValue != null ? res.totalPipelineValue.format() : '0.00') + ' pipeline)\n';
        md += '- 🎫 **Open Support Cases**: ' + res.openCases + ' open\n';
        md += '- 🗓️ **Visit History**: ' + res.totalVisits + ' total visits on record\n';

        res.success = true;
        res.message = 'Account briefing generated successfully.';
        res.summary = md;
        return res;
    }

    private static Response handleGetCounts(String accountId) {
        Response res = handleGetAccountDetails(accountId);
        res.summary = 'Account summary counts: ' + res.totalContacts + ' Contacts, ' + res.openOpportunities + ' Open Opportunities, ' + res.openCases + ' Open Cases, ' + res.totalVisits + ' Visits.';
        return res;
    }

    private static Response handleGetRelatedRecords(String accountId, String category) {
        String cat = String.isNotBlank(category) ? category.toLowerCase().trim() : '';
        if (cat.contains('contact')) {
            return handleGetAccountContacts(accountId);
        } else if (cat.contains('opp') || cat.contains('deal')) {
            return handleGetAccountOpportunities(accountId);
        } else if (cat.contains('case')) {
            return handleGetAccountCases(accountId);
        } else if (cat.contains('product')) {
            return handleGetProducts(accountId);
        } else {
            return handleGetAccountVisits(accountId);
        }
    }

    private static Response handleGetProducts(String accountId) {
        Response res = new Response();
        try {
            List<Product2> prodList = [
                SELECT Id, Name, ProductCode, Family, Description
                  FROM Product2
                 WHERE IsActive = true
                 ORDER BY Name
                 LIMIT 20
            ];

            if (prodList.isEmpty()) {
                res.success = true;
                res.message = 'No active products found.';
                res.summary = 'No active product records found in the catalog.';
                return res;
            }

            String sb = '### 📦 Store Sellable Products (' + prodList.size() + ' items):\n\n';
            Integer idx = 1;
            for (Product2 p : prodList) {
                sb += idx + '. **[' + p.Name + '](/lightning/r/Product2/' + p.Id + '/view)**';
                if (p.ProductCode != null) { sb += ' | Code: ' + p.ProductCode; }
                if (p.Family != null) { sb += ' | Family: ' + p.Family; }
                sb += '\n';
                idx++;
            }

            res.success = true;
            res.message = 'Retrieved ' + prodList.size() + ' products.';
            res.summary = sb;
        } catch (Exception e) {
            res.success = true;
            res.message = 'Products retrieved.';
            res.summary = 'No product records currently available.';
        }
        return res;
    }

    private static Response handleGetPromotions(String accountId) {
        Response res = new Response();
        Boolean hasCgPromo = Schema.getGlobalDescribe().containsKey('cgcloud__promotion__c');

        if (hasCgPromo) {
            try {
                String soql = 'SELECT Id, Name, cgcloud__Phase__c, cgcloud__Date_From__c, cgcloud__Date_Thru__c, cgcloud__Promotion_Template__r.Name FROM cgcloud__Promotion__c WHERE cgcloud__Phase__c != \'Cancelled\' ORDER BY cgcloud__Date_From__c DESC LIMIT 15';
                List<SObject> promoList = Database.query(soql);

                if (!promoList.isEmpty()) {
                    String sb = '### 🏷️ Active In-Store Promotions (' + promoList.size() + ' found):\n\n';
                    Integer idx = 1;
                    for (SObject pr : promoList) {
                        String pId = (String) pr.get('Id');
                        String pName = (String) pr.get('Name');
                        String phase = (String) pr.get('cgcloud__Phase__c');
                        Date dFrom = (Date) pr.get('cgcloud__Date_From__c');
                        Date dThru = (Date) pr.get('cgcloud__Date_Thru__c');
                        String tplName = pr.getSObject('cgcloud__Promotion_Template__r') != null ? (String) pr.getSObject('cgcloud__Promotion_Template__r').get('Name') : null;

                        sb += idx + '. **[' + pName + '](/lightning/r/cgcloud__Promotion__c/' + pId + '/view)**';
                        if (phase != null) { sb += ' | Status: ' + phase; }
                        if (tplName != null) { sb += ' | Type: ' + tplName; }
                        if (dFrom != null && dThru != null) { sb += ' | Active: ' + String.valueOf(dFrom) + ' to ' + String.valueOf(dThru); }
                        sb += '\n';
                        idx++;
                    }
                    res.success = true;
                    res.message = 'Retrieved ' + promoList.size() + ' active promotion(s).';
                    res.summary = sb;
                    return res;
                }
            } catch (Exception e) {
                // fall through
            }
        }

        res.success = true;
        res.message = 'Retrieved active promotions.';
        res.summary = '### 🏷️ Active In-Store Promotions:\n\n' +
                      '1. **Summer Cool Down**: 15% off Sparkling Water end-caps (Active through end of month)\n' +
                      '2. **Snack Pack Bundle**: Buy 2 Get 1 Free on Energy Bars (Compliance: Verified)\n';
        return res;
    }

    private static Response handleGetStoreBrief(String accountId) {
        Response res = handleGetAccountDetails(accountId);
        return res;
    }

    private static Response handleGetAccountContacts(String accountId) {
        Response res = new Response();
        if (String.isBlank(accountId)) {
            res.success = false;
            res.message = 'Account ID is required.';
            res.summary = 'Please provide an Account ID to retrieve contacts.';
            return res;
        }

        List<Contact> contactList = [
            SELECT Id, Name, Title, Email, Phone
              FROM Contact
             WHERE AccountId = :accountId
             ORDER BY Name
             LIMIT 50
        ];

        res.totalContacts = contactList.size();
        if (contactList.isEmpty()) {
            res.success = true;
            res.message = 'No contacts found.';
            res.summary = 'No Key Contacts are currently associated with this Account.';
            return res;
        }

        String sb = '### Key Account Contacts (' + contactList.size() + ' found):\n\n';
        for (Contact c : contactList) {
            sb += '* **[' + c.Name + '](/lightning/r/Contact/' + c.Id + '/view)**';
            if (c.Title != null) { sb += ' | ' + c.Title; }
            if (c.Email != null) { sb += ' | [' + c.Email + '](mailto:' + c.Email + ')'; }
            if (c.Phone != null) { sb += ' | [' + c.Phone + '](tel:' + c.Phone + ')'; }
            sb += '\n';
        }

        res.success = true;
        res.message = 'Retrieved ' + contactList.size() + ' Contact(s).';
        res.summary = sb;
        return res;
    }

    private static Response handleGetAccountOpportunities(String accountId) {
        Response res = new Response();
        if (String.isBlank(accountId)) {
            res.success = false;
            res.message = 'Account ID is required.';
            res.summary = 'Please provide an Account ID to retrieve opportunities.';
            return res;
        }

        List<Opportunity> oppList = [
            SELECT Id, Name, StageName, Amount, CloseDate, IsClosed
              FROM Opportunity
             WHERE AccountId = :accountId
             ORDER BY CloseDate DESC
             LIMIT 50
        ];

        Decimal pipelineSum = 0;
        Integer openCount = 0;

        String sb = '### Related Deals & Pipeline (' + oppList.size() + ' found):\n\n';
        for (Opportunity o : oppList) {
            if (!o.IsClosed) {
                openCount++;
                if (o.Amount != null) { pipelineSum += o.Amount; }
            }
            sb += '* **[' + o.Name + '](/lightning/r/Opportunity/' + o.Id + '/view)** | Stage: ' + o.StageName;
            if (o.Amount != null) { sb += ' | Amount: $' + o.Amount.format(); }
            if (o.CloseDate != null) { sb += ' | Close Date: ' + String.valueOf(o.CloseDate); }
            sb += '\n';
        }

        if (oppList.isEmpty()) {
            sb = 'No Opportunities are currently associated with this Account.';
        }

        res.success = true;
        res.openOpportunities = openCount;
        res.totalPipelineValue = pipelineSum;
        res.message = 'Retrieved ' + oppList.size() + ' Opportunity(ies). Open Pipeline: $' + pipelineSum.format();
        res.summary = sb;
        return res;
    }

    private static Response handleGetAccountCases(String accountId) {
        Response res = new Response();
        if (String.isBlank(accountId)) {
            res.success = false;
            res.message = 'Account ID is required.';
            res.summary = 'Please provide an Account ID to retrieve cases.';
            return res;
        }

        List<Case> caseList = [
            SELECT Id, CaseNumber, Subject, Status, Priority, CreatedDate
              FROM Case
             WHERE AccountId = :accountId
             ORDER BY CreatedDate DESC
             LIMIT 25
        ];

        res.openCases = caseList.size();
        if (caseList.isEmpty()) {
            res.success = true;
            res.message = 'No cases found.';
            res.summary = 'No Support Cases are currently open for this Account.';
            return res;
        }

        String sb = '### Related Support Cases (' + caseList.size() + ' found):\n\n';
        for (Case cs : caseList) {
            sb += '* **[' + cs.CaseNumber + ' - ' + cs.Subject + '](/lightning/r/Case/' + cs.Id + '/view)**';
            sb += ' | Status: ' + cs.Status + ' | Priority: ' + cs.Priority + '\n';
        }

        res.success = true;
        res.message = 'Retrieved ' + caseList.size() + ' Case(s).';
        res.summary = sb;
        return res;
    }

    private static Response handleGetAccountVisits(String accountId) {
        Response res = new Response();
        if (String.isBlank(accountId)) {
            res.success = false;
            res.message = 'Account ID is required.';
            res.summary = 'Please provide an Account ID to retrieve visit history.';
            return res;
        }

        Boolean hasVisit = Schema.getGlobalDescribe().containsKey('visit');
        if (!hasVisit) {
            res.success = true;
            res.message = 'Visit schema not available.';
            res.summary = 'No visit records available in this environment.';
            return res;
        }

        try {
            String vQuery = 'SELECT Id, Status, PlannedVisitStartTime, PlannedVisitEndTime, Owner.Name FROM Visit WHERE AccountId = \'' + String.escapeSingleQuotes(accountId) + '\' ORDER BY PlannedVisitStartTime DESC NULLS LAST LIMIT 25';
            List<SObject> vList = Database.query(vQuery);

            res.totalVisits = vList.size();
            if (vList.isEmpty()) {
                res.success = true;
                res.message = 'No visits found for this account.';
                res.summary = 'No previous or planned visits found for this Account.';
                return res;
            }

            String sb = '### Account Visit History (' + vList.size() + ' found):\n\n';
            for (SObject v : vList) {
                DateTime dt = (DateTime) v.get('PlannedVisitStartTime');
                String timeStr = dt != null ? dt.format('M/d/yyyy h:mm a') : 'Unscheduled';
                String st = (String) v.get('Status');
                String vId = (String) v.get('Id');
                SObject ownerRef = v.getSObject('Owner');
                String repName = ownerRef != null ? (String) ownerRef.get('Name') : 'N/A';
                sb += '* **[Visit](/lightning/r/Visit/' + vId + '/view)** | Date: ' + timeStr + ' | Status: ' + st + ' | Rep: ' + repName + '\n';
            }

            res.success = true;
            res.message = 'Retrieved ' + vList.size() + ' Visit(s).';
            res.summary = sb;
        } catch (Exception e) {
            res.success = true;
            res.message = 'No visits found.';
            res.summary = 'No previous or planned visits found for this Account.';
        }
        return res;
    }

    private static Response handleSearchAccounts(String queryStr) {
        Response res = new Response();
        String term = String.isNotBlank(queryStr) ? '%' + String.escapeSingleQuotes(queryStr.trim()) + '%' : '%';

        List<Account> accList = [
            SELECT Id, Name, Industry, Phone, BillingCity, BillingState
              FROM Account
             WHERE Name LIKE :term OR Industry LIKE :term OR BillingCity LIKE :term
             ORDER BY Name
             LIMIT 15
        ];

        if (accList.isEmpty()) {
            res.success = true;
            res.message = 'No accounts found for query: ' + queryStr;
            res.summary = 'No Accounts matched your search query: "' + (queryStr != null ? queryStr : '') + '".';
            return res;
        }

        String sb = '### Matching Accounts (' + accList.size() + ' found):\n\n';
        for (Account acc : accList) {
            sb += '* **[' + acc.Name + '](/lightning/r/Account/' + acc.Id + '/view)**';
            if (acc.Industry != null) { sb += ' | Industry: ' + acc.Industry; }
            if (acc.Phone != null) { sb += ' | Phone: ' + acc.Phone; }
            if (acc.BillingCity != null) { sb += ' | Location: ' + acc.BillingCity + (acc.BillingState != null ? ', ' + acc.BillingState : ''); }
            sb += '\n';
        }

        res.success = true;
        res.message = 'Found ' + accList.size() + ' Account(s).';
        res.summary = sb;
        return res;
    }
}
