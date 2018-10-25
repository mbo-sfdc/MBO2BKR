@RestResource(urlMapping='/booker_opportunity')
global with sharing class BookerOpportunityFromBookerEndpoint {
    public static Map<String, ContactWrapper> conMindBodyIdVSconWrapper;
    public static Map<String, AccountWrapper> accMindBodyIdVSaccountWrapper;
    public static Map<String, ReponseOpportunityWrapper> oppMindBodyIdVSopportunityWrapper;
    public static  Map<String, List<OCRWrapper>> oppMindBodyIdVSocrWrapperList;

    @httpPost
    global static OpportunityResponse createOpportunityStructure(){
        RestRequest req = RestContext.request;
        String body = req.requestBody.toString();

        System.debug('####body....' + body);
        OpportunityAndContactRoles optyContactRoles = (OpportunityAndContactRoles)JSON.deserialize(body, OpportunityAndContactRoles.class);

        return createOpportunityStructure(optyContactRoles);
    }

    private static void createOpportunities(OpportunityAndContactRoles optyContactRoles){
        Set<Account> accounts = new Set<Account>();
        OpportunityAndContactRoles this_optyContactRoles = optyContactRoles;
        Map<String, Account> mindbodyIds = new Map<String, Account>();
        
        System.debug('####@@@....' + optyContactRoles);
        for(Opportunity opty : optyContactRoles.opportunities){
            accounts.add(opty.Account);
            if(!mindbodyIds.containsKey(opty.Account.MindbodyId__c)){
                mindbodyIds.put(opty.Account.MindbodyId__c, opty.Account);
            }
        }
        List<Account> accountList = new List<Account>(accounts);
        Database.UpsertResult[] upsertAccountResults = Database.upsert(accountList, Account.MindbodyId__c ,false);

        createAccountsResponseWrapperMap(accountList, upsertAccountResults);

        for(Opportunity theOpportunity : optyContactRoles.opportunities){
            if(mindbodyIds.containsKey(theOpportunity.Account.MindbodyId__c)){
                theOpportunity.AccountId = mindbodyIds.get(theOpportunity.Account.MindbodyId__c).Id;
                theOpportunity.Account = null;
            }
        }

        Database.UpsertResult[] upsertOpportunityResults = Database.upsert(optyContactRoles.opportunities, Opportunity.MindbodyId__c, false);
        createOpportunitiesResponseWrapperMap(optyContactRoles.opportunities, upsertOpportunityResults);
    }

    private static Map<String, Contact> createContacts(OpportunityAndContactRoles optyContactRoles){
        Set<Contact> contacts = new Set<Contact>();
        Map<String, Contact> mindbodyContactIds = new Map<String, Contact>();
        Set<String> accountMindbodyIds = new Set<String>();

        for(OpportunityContactRole theContact : optyContactRoles.contactRoles){
            theContact.Contact.MindbodyIdAndAccountId__c = theContact.Contact.Account.MindbodyId__c + theContact.Contact.MindbodyId__c;
            contacts.add(theContact.Contact);
            if(!mindbodyContactIds.containsKey(theContact.Contact.MindbodyIdAndAccountId__c)){
                mindbodyContactIds.put(theContact.Contact.MindbodyIdAndAccountId__c, theContact.Contact);
            }
            accountMindbodyIds.add(theContact.Contact.Account.MindBodyId__c);
        }

        Map<String, List<Account>> existingAccounts = GroupBy.strings(Account.MindbodyId__c, [SELECT MindbodyId__c FROM Account where MindbodyId__c in :accountMindbodyIds]);
        for(OpportunityContactRole theContact : optyContactRoles.contactRoles){
            if(existingAccounts.containsKey(theContact.Contact.Account.MindbodyId__c)){
                theContact.Contact.AccountId = existingAccounts.get(theContact.Contact.Account.MindbodyId__c)[0].Id;
                theContact.Contact.Account = null;
            }
        }

        List<Contact> contactList = new List<Contact>(contacts);
        Database.UpsertResult[] upsertContactResults = Database.upsert(contactList, Contact.MindbodyIdAndAccountId__c, false);
        
        createContactsResponseWrapperMap(contactList, upsertContactResults);

        return mindbodyContactIds;
    }


    private static void createNewContactRoles(Map<String, Contact> mindbodyContactIds, OpportunityAndContactRoles optyContactRoles){

        String dupReq = JSON.serialize(optyContactRoles);
        
        OpportunityAndContactRoles optyContactRoles1 = (OpportunityAndContactRoles)JSON.deserialize(dupReq, OpportunityAndContactRoles.class);
        
        Map<String, List<Opportunity>> uniqueOpportunities = GroupBy.strings(Opportunity.MindBodyId__c, optyContactRoles.opportunities);
        Map<Id, Account> bookerAccountIds = new Map<Id, Account>([SELECT MindbodyId__c FROM Account where Id in :Pluck.ids('Contact.AccountId', optyContactRoles.contactRoles)]);

        for(OpportunityContactRole theContactRole : optyContactRoles.contactRoles){
            Account bookerAccount = bookerAccountIds.get(theContactRole.Contact.AccountId);
            if(bookerAccount != null){
                String mindbodyAccountId = bookerAccount.MindbodyId__c;
                Contact bookerContact = mindbodyContactIds.get(mindbodyAccountId + theContactRole.Contact.MindbodyId__c);
                theContactRole.ContactId = bookerContact.Id;
                theContactRole.Contact = null;
            }

            if(uniqueOpportunities.containsKey(theContactRole.Opportunity.MindBodyId__c)){
                Opportunity bookerOpportunity = uniqueOpportunities.get(theContactRole.Opportunity.MindBodyId__c)[0];
                theContactRole.OpportunityId = bookerOpportunity.Id;
                theContactRole.Opportunity = null;
            }

        }

        List<Database.SaveResult> insertOcrResults = Database.insert(optyContactRoles.contactRoles, false);
        
        createOCRsResponseWrapperMap(optyContactRoles1.contactRoles, insertOcrResults);
    }

    private static void createContactRoles(OpportunityAndContactRoles optyContactRoles){
        Map<String, Contact> mindbodyContactIds = createContacts(optyContactRoles);
        List<OpportunityContactRole> existingContactRoles = [SELECT Id, Opportunity.MindbodyId__c, Contact.MindbodyId__c, Role
                                                             FROM OpportunityContactRole
                                                             where Opportunity.MindbodyId__c in :Pluck.strings(Opportunity.MindBodyId__c, optyContactRoles.opportunities)
                                                            ];

        delete existingContactRoles;
        createNewContactRoles(mindbodyContactIds, optyContactRoles);

    }

    @testVisible
    private static OpportunityResponse createOpportunityStructure(OpportunityAndContactRoles optyContactRoles){
        
        String newReq = JSON.serialize(optyContactRoles);
        
        OpportunityAndContactRoles optyContactRoles1 = (OpportunityAndContactRoles)JSON.deserialize(newReq, OpportunityAndContactRoles.class);
        
        createOpportunities(optyContactRoles);
        createContactRoles(optyContactRoles);
        
        return createResponse(optyContactRoles1);

    }

    private static OpportunityResponse createResponse(OpportunityAndContactRoles optyContactRoles){

        // complete Opportunity Wrapper
        for(Opportunity opp: optyContactRoles.opportunities){

            if(oppMindBodyIdVSocrWrapperList.containsKey(opp.MindbodyId__c)){
                oppMindBodyIdVSopportunityWrapper.get(opp.MindbodyId__c).ocrList = oppMindBodyIdVSocrWrapperList.get(opp.MindbodyId__c);
            }

            if(opp.Account != null && opp.Account.MindbodyId__c != null && accMindBodyIdVSaccountWrapper.containsKey(opp.Account.MindbodyId__c)){
                oppMindBodyIdVSopportunityWrapper.get(opp.MindbodyId__c).account = accMindBodyIdVSaccountWrapper.get(opp.Account.MindbodyId__c);
            }
        }

        OpportunityResponse response = new OpportunityResponse();
        response.opportunities = oppMindBodyIdVSopportunityWrapper.values();

        return response;

    }

    private static void createContactsResponseWrapperMap(List<Contact> previousContacts, List<Database.UpsertResult> contactUpsertResults){
        conMindBodyIdVSconWrapper = new Map<String, ContactWrapper>();
        for(Integer i=0;i<contactUpsertResults.size();i++){

            String conMindBodyId = previousContacts[i].MindbodyId__c;
            ContactWrapper contactWraper = new ContactWrapper();
            if(contactUpsertResults.get(i).isSuccess()){
                contactWraper.isSuccess = true;
                contactWraper.bookerId = contactUpsertResults[i].getId();
            }
            else{
                contactWraper.isSuccess = false;
                contactWraper.errorDetails = contactUpsertResults.get(i).getErrors().get(0).getMessage();
            }
            contactWraper.mindbodyId = conMindBodyId;

            conMindBodyIdVSconWrapper.put(conMindBodyId, contactWraper);
            
        }
    }

    private static void createAccountsResponseWrapperMap(List<Account> previousAccounts, List<Database.UpsertResult> accountUpsertResults){
        accMindBodyIdVSaccountWrapper = new Map<String, AccountWrapper>();

        for(Integer i=0;i<accountUpsertResults.size();i++){
            String accMindBodyId = previousAccounts[i].MindbodyId__c;
            AccountWrapper accWraper = new AccountWrapper();
            if(accountUpsertResults.get(i).isSuccess()){
                accWraper.isSuccess = true;
                accWraper.bookerId = accountUpsertResults[i].getId();
            }
            else{
                accWraper.isSuccess = false;
                accWraper.errorDetails = accountUpsertResults[i].getErrors().get(0).getMessage();
            }
            accWraper.mindbodyId = accMindBodyId;

            accMindBodyIdVSaccountWrapper.put(accMindBodyId, accWraper);
        }
    }

    private static void createOpportunitiesResponseWrapperMap(List<Opportunity> previousOpportunity, List<Database.UpsertResult> opportunityUpsertResults){
        oppMindBodyIdVSopportunityWrapper = new Map<String, ReponseOpportunityWrapper>();
        for(Integer i=0; i<opportunityUpsertResults.size(); i++){
            String oppMindBodyId = previousOpportunity[i].MindbodyId__c;
            ReponseOpportunityWrapper oppWraper = new ReponseOpportunityWrapper();
            if(opportunityUpsertResults.get(i).isSuccess()){

                oppWraper.isSuccess = true; // Booker Id needs to be set outside this loop.  We need the ID in the case of a failed update
                oppWraper.bookerId = opportunityUpsertResults[i].getId();
               }
            else{
                oppWraper.isSuccess = false;
                oppWraper.errorDetails = opportunityUpsertResults.get(i).getErrors().get(0).getMessage();
              }
            oppWraper.mindbodyId = oppMindBodyId;

            oppMindBodyIdVSopportunityWrapper.put(oppMindBodyId, oppWraper);
        }
    }

    private static void createOCRsResponseWrapperMap(List<OpportunityContactRole> previousOCRs, List<Database.SaveResult> ocrInsertResults){

        
        oppMindBodyIdVSocrWrapperList = new Map<String, List<OCRWrapper>>();
        for(Integer i=0;i<ocrInsertResults.size();i++){

            String ocrOpportunityMindBodyId = previousOCRs[i].Opportunity.MindbodyId__c;

            OCRWrapper ocrWraper = new OCRWrapper();
            ocrWraper.bookerId = ocrInsertResults[i].getId();

            if(ocrInsertResults.get(i).isSuccess()){
                ocrWraper.isSuccess = true;
            }
            else{
                ocrWraper.isSuccess = false;
                ocrWraper.errorDetails = ocrInsertResults.get(i).getErrors().get(0).getMessage();
            }
            //ocrWraper.mindbodyId = ocrOpportunityMindBodyId; //contact needs to be MindbodyIdAndAccountId__c
            if(conMindBodyIdVSconWrapper.containsKey(previousOCRs[i].Contact.MindbodyId__c)){
                    ocrWraper.contact = conMindBodyIdVSconWrapper.get(previousOCRs[i].Contact.MindbodyId__c);
            }

            if(!oppMindBodyIdVSocrWrapperList.containsKey(ocrOpportunityMindBodyId)){
                oppMindBodyIdVSocrWrapperList.put(ocrOpportunityMindBodyId, new List<OCRWrapper>());
            }
            oppMindBodyIdVSocrWrapperList.get(ocrOpportunityMindBodyId).add(ocrWraper);
        }
    }

    public class OpportunityAndContactRoles{
        public List<Opportunity> opportunities;
        public List<OpportunityContactRole> contactRoles;
    }

    global class OpportunityResponse{
        public List<ReponseOpportunityWrapper> opportunities{get; set;}
    }
    public class ReponseOpportunityWrapper{
        public String mindbodyId{get; set;}
        public String bookerId{get; set;}
        public Boolean isSuccess {get;set;}
        public String errorDetails{get;set;}

        public AccountWrapper account {get;set;}
        public List<OCRWrapper> ocrList {get;set;}
    }
    public class AccountWrapper{
        public String mindbodyId{get; set;}
        public String bookerId{get; set;}
        public Boolean isSuccess {get;set;}
        public String errorDetails{get;set;}
    }
    public class ContactWrapper{
        public String mindbodyId{get; set;}
        public String bookerId{get; set;}
        public Boolean isSuccess {get;set;}
        public String errorDetails{get;set;}
    }
    public class OCRWrapper{
        public String mindbodyId{get; set;}
        public String bookerId{get; set;}
        public Boolean isSuccess {get;set;}
        public String errorDetails{get;set;}

        public ContactWrapper contact {get;set;}
    }

}