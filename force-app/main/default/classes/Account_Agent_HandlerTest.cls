@IsTest
private class Account_Agent_HandlerTest {

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

        Account_Agent_Handler.Request req = new Account_Agent_Handler.Request();
        req.actionType = 'getAccountSummary';
        req.accountId = acc.Id;

        Test.startTest();
        List<Account_Agent_Handler.Response> resList = Account_Agent_Handler.execute(
            new List<Account_Agent_Handler.Request>{ req }
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

        Account_Agent_Handler.Request rCounts = new Account_Agent_Handler.Request();
        rCounts.actionType = 'getCounts';
        rCounts.accountId = acc.Id;

        Account_Agent_Handler.Request rRecContacts = new Account_Agent_Handler.Request();
        rRecContacts.actionType = 'getRecords';
        rRecContacts.accountId = acc.Id;
        rRecContacts.category = 'contacts';

        Account_Agent_Handler.Request rRecOpps = new Account_Agent_Handler.Request();
        rRecOpps.actionType = 'getRecords';
        rRecOpps.accountId = acc.Id;
        rRecOpps.category = 'opportunities';

        Account_Agent_Handler.Request rRecCases = new Account_Agent_Handler.Request();
        rRecCases.actionType = 'getRecords';
        rRecCases.accountId = acc.Id;
        rRecCases.category = 'cases';

        Account_Agent_Handler.Request rRecProducts = new Account_Agent_Handler.Request();
        rRecProducts.actionType = 'getRecords';
        rRecProducts.accountId = acc.Id;
        rRecProducts.category = 'products';

        Account_Agent_Handler.Request rProducts = new Account_Agent_Handler.Request();
        rProducts.actionType = 'getProducts';
        rProducts.accountId = acc.Id;

        Account_Agent_Handler.Request rPromos = new Account_Agent_Handler.Request();
        rPromos.actionType = 'getPromotions';
        rPromos.accountId = acc.Id;

        Account_Agent_Handler.Request rBrief = new Account_Agent_Handler.Request();
        rBrief.actionType = 'getStoreBrief';
        rBrief.accountId = acc.Id;

        Account_Agent_Handler.Request rRecInv = new Account_Agent_Handler.Request();
        rRecInv.actionType = 'getRecords';
        rRecInv.accountId = acc.Id;
        rRecInv.category = 'inventory';

        Account_Agent_Handler.Request rRecVisits = new Account_Agent_Handler.Request();
        rRecVisits.actionType = 'getRecords';
        rRecVisits.accountId = acc.Id;
        rRecVisits.category = 'visits';

        Account_Agent_Handler.Request rEligible = new Account_Agent_Handler.Request();
        rEligible.actionType = 'getEligibleProducts';
        rEligible.accountId = acc.Id;
        rEligible.promotionId = '1';

        Account_Agent_Handler.Request rDefault = new Account_Agent_Handler.Request();
        rDefault.actionType = 'unknownAction';
        rDefault.accountId = acc.Id;

        Test.startTest();
        List<Account_Agent_Handler.Response> resList = Account_Agent_Handler.execute(
            new List<Account_Agent_Handler.Request>{ rCounts, rRecContacts, rRecOpps, rRecCases, rRecProducts, rProducts, rPromos, rBrief, rRecInv, rRecVisits, rEligible, rDefault }
        );
        Test.stopTest();

        Assert.areEqual(12, resList.size(), 'Expected 12 responses');
        for (Account_Agent_Handler.Response r : resList) {
            Assert.isTrue(r.success, 'Expected action to succeed');
        }
        Assert.isNotNull(resList[0].accountPhone, 'Phone link expected');
        Assert.isNotNull(resList[0].locationNavigateLink, 'Location link expected');
    }

    @IsTest
    static void testGetAccountContactsOpportunitiesCasesVisits() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Account_Agent_Handler.Request reqCon = new Account_Agent_Handler.Request();
        reqCon.actionType = 'getAccountContacts';
        reqCon.accountId = acc.Id;

        Account_Agent_Handler.Request reqOpp = new Account_Agent_Handler.Request();
        reqOpp.actionType = 'getAccountOpportunities';
        reqOpp.accountId = acc.Id;

        Account_Agent_Handler.Request reqCs = new Account_Agent_Handler.Request();
        reqCs.actionType = 'getAccountCases';
        reqCs.accountId = acc.Id;

        Account_Agent_Handler.Request reqVis = new Account_Agent_Handler.Request();
        reqVis.actionType = 'getAccountVisits';
        reqVis.accountId = acc.Id;

        Test.startTest();
        List<Account_Agent_Handler.Response> resList = Account_Agent_Handler.execute(
            new List<Account_Agent_Handler.Request>{ reqCon, reqOpp, reqCs, reqVis }
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
        Account_Agent_Handler.Request reqMatch = new Account_Agent_Handler.Request();
        reqMatch.actionType = 'searchAccounts';
        reqMatch.searchQuery = 'Metro Market';

        Account_Agent_Handler.Request reqNoMatch = new Account_Agent_Handler.Request();
        reqNoMatch.actionType = 'search';
        reqNoMatch.searchQuery = 'NonExistentStoreName999';

        Test.startTest();
        List<Account_Agent_Handler.Response> resList = Account_Agent_Handler.execute(
            new List<Account_Agent_Handler.Request>{ reqMatch, reqNoMatch }
        );
        Test.stopTest();

        Assert.areEqual(2, resList.size(), 'Expected 2 responses');
        Assert.isTrue(resList[0].success, 'Search match succeeded');
        Assert.isTrue(resList[1].success, 'Search no-match handled gracefully');
    }

    @IsTest
    static void testErrorCases() {
        Account_Agent_Handler.Request reqBlankId = new Account_Agent_Handler.Request();
        reqBlankId.actionType = 'getAccountDetails';
        reqBlankId.accountId = '';

        Account_Agent_Handler.Request reqNotFound = new Account_Agent_Handler.Request();
        reqNotFound.actionType = 'getAccountDetails';
        reqNotFound.accountId = '001000000000000AAA';

        Account_Agent_Handler.Request reqConBlank = new Account_Agent_Handler.Request();
        reqConBlank.actionType = 'getAccountContacts';
        reqConBlank.accountId = '';

        Account_Agent_Handler.Request reqOppBlank = new Account_Agent_Handler.Request();
        reqOppBlank.actionType = 'getAccountOpportunities';
        reqOppBlank.accountId = '';

        Account_Agent_Handler.Request reqCsBlank = new Account_Agent_Handler.Request();
        reqCsBlank.actionType = 'getAccountCases';
        reqCsBlank.accountId = '';

        Account_Agent_Handler.Request reqVisBlank = new Account_Agent_Handler.Request();
        reqVisBlank.actionType = 'getAccountVisits';
        reqVisBlank.accountId = '';

        Test.startTest();
        List<Account_Agent_Handler.Response> resList = Account_Agent_Handler.execute(
            new List<Account_Agent_Handler.Request>{ reqBlankId, reqNotFound, reqConBlank, reqOppBlank, reqCsBlank, reqVisBlank }
        );
        Test.stopTest();

        Assert.areEqual(6, resList.size(), 'Expected 6 responses');
        for (Account_Agent_Handler.Response r : resList) {
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

        Account_Agent_Handler.Request req = new Account_Agent_Handler.Request();
        req.actionType = 'getAccountSummary';
        req.accountId = accShip.Id;

        Test.startTest();
        List<Account_Agent_Handler.Response> resList = Account_Agent_Handler.execute(
            new List<Account_Agent_Handler.Request>{ req }
        );
        Test.stopTest();

        Assert.areEqual(1, resList.size(), 'Expected 1 response');
        Assert.isTrue(resList[0].success, 'Expected summary to succeed');
        Assert.isTrue(resList[0].summary.contains('456 Ocean Ave'), 'Expected shipping street in summary');
    }
}
