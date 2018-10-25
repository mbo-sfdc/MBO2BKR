@isTest
private class BookerOpportunityFromBookerEndpointTest {
    static List<Opportunity> opportunities;
    static List<Contact> contacts;
    static List<OpportunityContactRole> opportunityContactRoles;
    static final Integer BULK_COUNT_CONTACT_ROLES = 2;// Limits.getLimitQueries() + 1;

    static void setup(){
        Account theAccount = (Account)new sObjectBuilder(Account.sObjectType)
            .put(Account.MindBodyId__c, new sObjectFieldProviders.DummyIdProvider(Account.sObjectType))
            .create()
            .getRecord();

        opportunities = (List<Opportunity>)new sObjectBuilder(Opportunity.sObjectType)
            .put(Opportunity.MindBodyId__c, new sObjectFieldProviders.DummyIdProvider(Opportunity.sObjectType))
            .put(Opportunity.AccountId, theAccount.Id)
            .count(BULK_COUNT_CONTACT_ROLES)
            .create()
            .getRecords();

        Opportunity opportunityWithContactRoles = opportunities[0];

        contacts = (List<Contact>)new sObjectBuilder(Contact.sObjectType)
            .put(Contact.MindBodyId__c, new sObjectFieldProviders.DummyIdProvider(Contact.sObjectType))
            .put(Contact.AccountId, theAccount.Id)
            .count(BULK_COUNT_CONTACT_ROLES)
            .create()
            .getRecords();

        opportunityContactRoles = (List<OpportunityContactRole>)new sObjectBuilder(OpportunityContactRole.sObjectType)
            .put(OpportunityContactRole.OpportunityId, opportunityWithContactRoles)
            .put(OpportunityContactRole.ContactId, contacts)
            .count(BULK_COUNT_CONTACT_ROLES)
            .create()
            .getRecords();

        opportunityContactRoles = [SELECT Id, Contact.Account.MindBodyId__c,Opportunity.MindBodyId__c,
                                            Contact.FirstName, Contact.LastName, Contact.MindBodyId__c,
                                            Role
                                    FROM OpportunityContactRole];

        opportunities = [SELECT Name, StageName, Account.MindBodyId__c, Account.Name,
                            CloseDate, MindBodyId__c
                        FROM Opportunity];

        delete opportunityContactRoles;
        delete opportunities;
        delete contacts;
        delete theAccount;

        for(Opportunity opportunity : opportunities){
            opportunity.Id = null;
            opportunity.Account.Id = null;
        }
        for(OpportunityContactRole contactRole : opportunityContactRoles){
            contactRole.Contact.Id = null;
            contactRole.Id = null;
            contactRole.ContactId = null;
        }
    }

    @isTest
    static void testOpportunityContactRoleCreation(){
        setup();

        BookerOpportunityFromBookerEndpoint.OpportunityAndContactRoles pocSetup = new BookerOpportunityFromBookerEndpoint.OpportunityAndContactRoles();
        pocSetup.opportunities = opportunities;
        pocSetup.contactRoles = opportunityContactRoles;

        Test.startTest();
            BookerOpportunityFromBookerEndpoint.createOpportunityStructure(pocSetup);
        Test.stopTest();

        Account theNewAccount = [Select Id, MindBodyId__c from Account];
        List<Opportunity> theNewOpportunities = [Select Id, AccountId from Opportunity];
        System.assertEquals(BULK_COUNT_CONTACT_ROLES, theNewOpportunities.size(), 'Each of the opportunities in OpportunityAndContactRoles should have been created');
        List<Contact> theContacts = [Select Id, AccountId from Contact];
        System.assertEquals(BULK_COUNT_CONTACT_ROLES, theContacts.size(), 'Each of the contacts in contactRoles should have been created into Contacts');
        List<OpportunityContactRole> contactRoles = [Select Id, ContactId, OpportunityId from OpportunityContactRole];
        System.assertEquals(BULK_COUNT_CONTACT_ROLES, contactRoles.size(), 'Each of contactRoles in OpportunityAndContactRoles should have been created into OpportunityContactRoles');
    }

    @isTest
    static void testMultipleCallouts(){
        setup();

        BookerOpportunityFromBookerEndpoint.OpportunityAndContactRoles pocSetup = new BookerOpportunityFromBookerEndpoint.OpportunityAndContactRoles();
        pocSetup.opportunities = opportunities;
        pocSetup.contactRoles = opportunityContactRoles;

        String serialized = JSON.serialize(pocSetup);


        RestContext.request = new RestRequest();
        RestContext.request.requestBody = Blob.valueOf(serialized);

        Test.startTest();
            BookerOpportunityFromBookerEndpoint.createOpportunityStructure();
            BookerOpportunityFromBookerEndpoint.createOpportunityStructure();
        Test.stopTest();

        Account theNewAccount = [Select Id, MindBodyId__c from Account];
        List<Opportunity> theNewOpportunities = [Select Id, AccountId from Opportunity];
        System.assertEquals(BULK_COUNT_CONTACT_ROLES, theNewOpportunities.size(), 'Opportunities should be upserted based on the MindbodyID');
        List<Contact> theContact = [Select Id, AccountId from Contact];
        System.assertEquals(BULK_COUNT_CONTACT_ROLES, theContact.size(), 'Contacts should be upserted based on the MindbodyId');
        List<OpportunityContactRole> contactRoles = [Select Id, ContactId, OpportunityId from OpportunityContactRole];
        System.assertEquals(BULK_COUNT_CONTACT_ROLES, contactRoles.size(), 'Duplicate calls to createOpportunityStructure should not create duplicate Opportunity Contact Roles');
    }

    @isTest
    static void testContactRoleRemoval(){
        setup();

        BookerOpportunityFromBookerEndpoint.OpportunityAndContactRoles pocSetup = new BookerOpportunityFromBookerEndpoint.OpportunityAndContactRoles();
        pocSetup.opportunities = opportunities;
        pocSetup.contactRoles = opportunityContactRoles;

        String serialized = JSON.serialize(pocSetup);
        RestContext.request = new RestRequest();
        RestContext.request.requestBody = Blob.valueOf(serialized);
        BookerOpportunityFromBookerEndpoint.createOpportunityStructure();

        // Now the Opportunity only has one Contact, the other OpportunityContacts should be deleted
        pocSetup.contactRoles = new List<OpportunityContactRole>{opportunityContactRoles[0]};
        serialized = JSON.serialize(pocSetup);
        RestContext.request = new RestRequest();
        RestContext.request.requestBody = Blob.valueOf(serialized);
        Test.startTest();
            BookerOpportunityFromBookerEndpoint.createOpportunityStructure();
        Test.stopTest();

        List<OpportunityContactRole> contactRoles = [Select Id, ContactId, OpportunityId from OpportunityContactRole];
        System.assertEquals(pocSetup.contactRoles.size(), contactRoles.size(), 'When a contact role has been removed from the request, we expect the missing contact role to be deleted');
    }

    @isTest
    static void testResponse(){
        setup();

        BookerOpportunityFromBookerEndpoint.OpportunityAndContactRoles pocSetup = new BookerOpportunityFromBookerEndpoint.OpportunityAndContactRoles();
        pocSetup.opportunities = opportunities;
        pocSetup.contactRoles = opportunityContactRoles;

        Test.startTest();
          BookerOpportunityFromBookerEndpoint.OpportunityResponse results = BookerOpportunityFromBookerEndpoint.createOpportunityStructure(pocSetup);
        Test.stopTest();

    System.debug('the response is..'+results);

        Map<Id, Opportunity> opportunitiesCreated = new Map<Id, Opportunity>([SELECT Account.MindBodyId__c, Account.Id,
            (Select Id, Contact.Id, Contact.MindbodyId__c from OpportunityContactRoles)
        from Opportunity]);
        //Map<Id, Account> accountsCreated = new Map<Id, Account>([SELECT Id, MindbodyId from Account]);
        System.assertEquals(opportunities.size(), results.opportunities.size(), 'There should be a response for each opportunity');
        for(BookerOpportunityFromBookerEndpoint.ReponseOpportunityWrapper result : results.opportunities){
            System.assert(result.isSuccess == true,'The isSuccess field should have value true for success cases');
            System.assert(result.errorDetails == null ,'The errorDetails field shouldnot have error message for success cases');
            System.assertNotEquals(null,result.bookerId,'The booker Id should be available for success cases');

            Opportunity relatedOpportunity = opportunitiesCreated.get(result.bookerId);
            Account opportunitiesAccount = relatedOpportunity.Account;
            System.assertNotEquals(null, relatedOpportunity, 'A Booker Opportunity should belong to one of the records created in Booker');
            if(relatedOpportunity.OpportunityContactRoles != null && result.ocrList != null){
                for(BookerOpportunityFromBookerEndpoint.OCRWrapper ocrObj : result.ocrList){
                System.debug('the ocr contact is.. '+ocrObj.contact.bookerId);
                    System.assertNotEquals(null,
                                ocrObj.contact.bookerId,
                                'The booker Id send in response should no be null');
                }
                System.assertEquals(relatedOpportunity.OpportunityContactRoles.size(),
                                    result.ocrList.size(), 
                                    'We expect that each of the Opportunity Contact Roles for this Contact are returned');
            
            }
            System.assertEquals(opportunitiesAccount.Id,
                                result.account.bookerId,
                                'We expect the Opportunities account to be returned');

            System.assertNotEquals(null,opportunitiesAccount.MindbodyId__c, 'Opportunity Mindbody');
            
            
            // Assert Id=bookerId, MindbodyId & MindbodyIdAndAccountId__c on Contacts


        }
  }

}