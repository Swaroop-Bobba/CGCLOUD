/**
 * Unit tests verifying account summaries, contacts, opportunities,
 * store briefs, and search functionality in AccountAgentController.
 */
@IsTest
private class AccountAgentControllerTest {

    @TestSetup
    static void setupData() {
        Account acc = new Account(
            Name = 'CGC Metro Market',
            Industry = 'Retail',
            Phone = '555-4321',
            AnnualRevenue = 2500000,
            NumberOfEmployees = 150,
            BillingStreet = '123 Market St',
            BillingCity = 'San Francisco',
            BillingState = 'CA',
            BillingPostalCode = '94105',
            BillingCountry = 'USA'
        );
        insert acc;

        Contact con = new Contact(
            FirstName = 'Sarah',
            LastName = 'Connor',
            Title = 'Store Manager',
            cgcloud__Job_Title__c = 'Store Manager',
            Email = 'sarah.connor@example.com',
            Phone = '555-1122',
            MobilePhone = '555-9988',
            AccountId = acc.Id
        );
        insert con;

        Opportunity opp = new Opportunity(
            Name = 'Q3 Inventory Order',
            StageName = 'Prospecting',
            Amount = 50000,
            CloseDate = Date.today().addDays(30),
            AccountId = acc.Id
        );
        insert opp;

        Case cs = new Case(
            Subject = 'Cooler Display Issue',
            Status = 'New',
            Priority = 'High',
            AccountId = acc.Id
        );
        insert cs;

        if (Schema.getGlobalDescribe().containsKey('visit')) {
            SObject v = Schema.getGlobalDescribe().get('Visit').newSObject();
            v.put('AccountId', acc.Id);
            if (Schema.getGlobalDescribe().containsKey('location')) {
                Schema.Location loc = new Schema.Location(Name = 'Test Account Location');
                insert loc;
                v.put('PlaceId', loc.Id);
            }
            v.put('PlannedVisitStartTime', Datetime.now());
            v.put('Status', 'Planned');
            Database.insert(v, AccessLevel.USER_MODE);
        }
    }

    @IsTest
    static void testGetAccountDetailsAndSummary() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        AccountAgentController.Request req = new AccountAgentController.Request();
        req.actionType = 'getAccountSummary';
        req.accountId = acc.Id;

        Test.startTest();
        List<AccountAgentController.Response> resList = AccountAgentController.execute(
            new List<AccountAgentController.Request>{ req }
        );
        Test.stopTest();

        Assert.areEqual(1, resList.size(), 'Expected 1 response');
        Assert.isTrue(resList[0].success, 'Expected summary to succeed');
        Assert.isNotNull(resList[0].googleMapsUrl, 'Google Maps URL should be populated');
        Assert.areEqual(1, resList[0].totalContacts, 'Expected 1 contact');
        Assert.areEqual(1, resList[0].openOpportunities, 'Expected 1 opp');
        Assert.areEqual(1, resList[0].openCases, 'Expected 1 case');
        Assert.isNotNull(resList[0].totalVisits, 'Expected total visits populated');
    }

    @IsTest
    static void testCountsRecordsProductsPromotionsStoreBrief() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        AccountAgentController.Request rCounts = new AccountAgentController.Request();
        rCounts.actionType = 'getCounts';
        rCounts.accountId = acc.Id;

        AccountAgentController.Request rRecContacts = new AccountAgentController.Request();
        rRecContacts.actionType = 'getRecords';
        rRecContacts.accountId = acc.Id;
        rRecContacts.category = 'contacts';

        AccountAgentController.Request rRecOpps = new AccountAgentController.Request();
        rRecOpps.actionType = 'getRecords';
        rRecOpps.accountId = acc.Id;
        rRecOpps.category = 'opportunities';

        AccountAgentController.Request rRecCases = new AccountAgentController.Request();
        rRecCases.actionType = 'getRecords';
        rRecCases.accountId = acc.Id;
        rRecCases.category = 'cases';

        AccountAgentController.Request rRecProducts = new AccountAgentController.Request();
        rRecProducts.actionType = 'getRecords';
        rRecProducts.accountId = acc.Id;
        rRecProducts.category = 'products';

        AccountAgentController.Request rProducts = new AccountAgentController.Request();
        rProducts.actionType = 'getProducts';
        rProducts.accountId = acc.Id;

        AccountAgentController.Request rPromos = new AccountAgentController.Request();
        rPromos.actionType = 'getPromotions';
        rPromos.accountId = acc.Id;

        AccountAgentController.Request rBrief = new AccountAgentController.Request();
        rBrief.actionType = 'getStoreBrief';
        rBrief.accountId = acc.Id;

        AccountAgentController.Request rRecInv = new AccountAgentController.Request();
        rRecInv.actionType = 'getRecords';
        rRecInv.accountId = acc.Id;
        rRecInv.category = 'inventory';

        AccountAgentController.Request rRecVisits = new AccountAgentController.Request();
        rRecVisits.actionType = 'getRecords';
        rRecVisits.accountId = acc.Id;
        rRecVisits.category = 'visits';

        AccountAgentController.Request rEligible = new AccountAgentController.Request();
        rEligible.actionType = 'getEligibleProducts';
        rEligible.accountId = acc.Id;
        rEligible.promotionId = '1';

        AccountAgentController.Request rDefault = new AccountAgentController.Request();
        rDefault.actionType = 'unknownAction';
        rDefault.accountId = acc.Id;

        Test.startTest();
        List<AccountAgentController.Response> resList = AccountAgentController.execute(
            new List<AccountAgentController.Request>{ rCounts, rRecContacts, rRecOpps, rRecCases, rRecProducts, rProducts, rPromos, rBrief, rRecInv, rRecVisits, rEligible, rDefault }
        );
        Test.stopTest();

        Assert.areEqual(12, resList.size(), 'Expected 12 responses');
        for (AccountAgentController.Response r : resList) {
            Assert.isTrue(r.success, 'Expected action to succeed');
        }
        Assert.isNotNull(resList[0].accountPhone, 'Phone link expected');
        Assert.isNotNull(resList[0].locationNavigateLink, 'Location link expected');
    }

    @IsTest
    static void testGetAccountContactsOpportunitiesCasesVisits() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        AccountAgentController.Request reqCon = new AccountAgentController.Request();
        reqCon.actionType = 'getAccountContacts';
        reqCon.accountId = acc.Id;

        AccountAgentController.Request reqOpp = new AccountAgentController.Request();
        reqOpp.actionType = 'getAccountOpportunities';
        reqOpp.accountId = acc.Id;

        AccountAgentController.Request reqCs = new AccountAgentController.Request();
        reqCs.actionType = 'getAccountCases';
        reqCs.accountId = acc.Id;

        AccountAgentController.Request reqVis = new AccountAgentController.Request();
        reqVis.actionType = 'getAccountVisits';
        reqVis.accountId = acc.Id;

        Test.startTest();
        List<AccountAgentController.Response> resList = AccountAgentController.execute(
            new List<AccountAgentController.Request>{ reqCon, reqOpp, reqCs, reqVis }
        );
        Test.stopTest();

        Assert.areEqual(4, resList.size(), 'Expected 4 responses');
        Assert.isTrue(resList[0].success, 'Contacts retrieval succeeded');
        Assert.isTrue(resList[1].success, 'Opportunities retrieval succeeded');
        Assert.isTrue(resList[2].success, 'Cases retrieval succeeded');
        Assert.isTrue(resList[3].success, 'Visits retrieval succeeded');
    }

    @IsTest
    static void testSearchAccounts() {
        AccountAgentController.Request reqMatch = new AccountAgentController.Request();
        reqMatch.actionType = 'searchAccounts';
        reqMatch.searchQuery = 'Metro Market';

        AccountAgentController.Request reqNoMatch = new AccountAgentController.Request();
        reqNoMatch.actionType = 'search';
        reqNoMatch.searchQuery = 'NonExistentStoreName999';

        Test.startTest();
        List<AccountAgentController.Response> resList = AccountAgentController.execute(
            new List<AccountAgentController.Request>{ reqMatch, reqNoMatch }
        );
        Test.stopTest();

        Assert.areEqual(2, resList.size(), 'Expected 2 responses');
        Assert.isTrue(resList[0].success, 'Search match succeeded');
        Assert.isTrue(resList[1].success, 'Search no-match handled gracefully');
    }

    @IsTest
    static void testErrorCases() {
        AccountAgentController.Request reqBlankId = new AccountAgentController.Request();
        reqBlankId.actionType = 'getAccountDetails';
        reqBlankId.accountId = '';

        AccountAgentController.Request reqNotFound = new AccountAgentController.Request();
        reqNotFound.actionType = 'getAccountDetails';
        reqNotFound.accountId = '001000000000000AAA';

        AccountAgentController.Request reqConBlank = new AccountAgentController.Request();
        reqConBlank.actionType = 'getAccountContacts';
        reqConBlank.accountId = '';

        AccountAgentController.Request reqOppBlank = new AccountAgentController.Request();
        reqOppBlank.actionType = 'getAccountOpportunities';
        reqOppBlank.accountId = '';

        AccountAgentController.Request reqCsBlank = new AccountAgentController.Request();
        reqCsBlank.actionType = 'getAccountCases';
        reqCsBlank.accountId = '';

        AccountAgentController.Request reqVisBlank = new AccountAgentController.Request();
        reqVisBlank.actionType = 'getAccountVisits';
        reqVisBlank.accountId = '';

        Test.startTest();
        List<AccountAgentController.Response> resList = AccountAgentController.execute(
            new List<AccountAgentController.Request>{ reqBlankId, reqNotFound, reqConBlank, reqOppBlank, reqCsBlank, reqVisBlank }
        );
        Test.stopTest();

        Assert.areEqual(6, resList.size(), 'Expected 6 responses');
        for (AccountAgentController.Response r : resList) {
            Assert.isFalse(r.success, 'Blank IDs should fail gracefully');
        }
    }

    @IsTest
    static void testShippingAddressFallback() {
        Account accShip = new Account(
            Name = 'CGC Shipping Only Store',
            ShippingStreet = '456 Ocean Ave',
            ShippingCity = 'Miami',
            ShippingState = 'FL',
            ShippingPostalCode = '33139',
            ShippingCountry = 'USA'
        );
        insert accShip;

        AccountAgentController.Request req = new AccountAgentController.Request();
        req.actionType = 'getAccountSummary';
        req.accountId = accShip.Id;

        Test.startTest();
        List<AccountAgentController.Response> resList = AccountAgentController.execute(
            new List<AccountAgentController.Request>{ req }
        );
        Test.stopTest();

        Assert.areEqual(1, resList.size(), 'Expected 1 response');
        Assert.isTrue(resList[0].success, 'Expected summary to succeed');
        Assert.isTrue(resList[0].summary.contains('456 Ocean Ave'), 'Expected shipping street in summary');
    }
}
