public class createJSON4Bkr {
    public static String genJSON4Bkr(Id OppID) {
        //pull related Account and Contact from Opp Id
        Id oID = OppID;
        Id aID;
        Id cID;
        List<Opportunity> aList = new List<Opportunity>();
        List<OpportunityContactRole> cList = new List<OpportunityContactRole>();
        
        aList = [SELECT Id, AccountId FROM Opportunity WHERE Id =: OppID];
        aID = aList[0].AccountId;
        
        cList = [SELECT Id, ContactId FROM OpportunityContactRole WHERE OpportunityId =: oID AND IsPrimary = True];
        cID = cList[0].ContactId;
        
        System.debug('>>>>>> OppID: ' + oID);
        System.debug('>>>>>> AcctID: ' + aID);
        System.debug('>>>>>> ConID: ' + cID);
		
        //populate lists with associated field data
		List<Account> a = new List<Account>();
        a = [SELECT Id, BillingCity, BillingCountry, BillingPostalCode, BillingState, BillingStreet, Industry, Name, Website, Phone FROM Account WHERE Id=: aID];
        
        List<Contact> c = new List<Contact>();
        c = [SELECT Id, FirstName, LastName, Email, Phone FROM Contact WHERE Id =: cID];
        
        List<Opportunity> o = new List<Opportunity>();
        o = [SELECT Id, Booker_Aria_Responsibility_Level__c, Booker_Currency__c, Booker_MAP_Partner__c, Booker_Merchant_Processing__c, Booker_Not_on_Google__c, Booker_POS_Version__c, Booker_Product__c, Booker_Revenue_Pillar__c, Booker_Status__c, Booker_Term__c, Name, CloseDate FROM Opportunity WHERE Id =: oID];
       	
		//createJson composite
		JSONGenerator master = JSON.createGenerator(true);
        	master.writeStartObject();
        	master.writeFieldName('compositeRequest');
        	master.writeStartArray();
        	master.writeStartObject();
			master.writeObjectField('method', 'POST');
			master.writeObjectField('url', '/services/data/v41.0/sobjects/Account');
			master.writeObjectField('referenceId', 'refAccount');
            //master.writeObjectField('body', aBody);
        	master.writeFieldName('body');
        	master.writeStartObject();
        	master.writeObjectField('Name', a[0].Name);
        	master.writeObjectField('Phone', a[0].Phone);
        	master.writeObjectField('Website', a[0].Website);
        	master.writeObjectField('BillingCity', a[0].BillingCity);
        	master.writeObjectField('BillingCountry', a[0].BillingCountry);
        	master.writeObjectField('BillingPostalCode', a[0].BillingPostalCode);
        	master.writeObjectField('BillingState', a[0].BillingState);
        	master.writeObjectField('BillingStreet', a[0].BillingStreet);
        	master.writeObjectField('Location_Business_Type__c', a[0].Industry);
        	master.writeObjectField('RecordTypeId', '01270000000MzxF');
        	master.writeObjectField('SB_Lead_Status__c', 'Prospect');
        	master.writeObjectField('Segment__c', a[0].Industry);
        	master.writeObjectField('OwnerID', '00539000006D6K2');
        	master.writeObjectField('MBO_ExternalID__c', a[0].Id);
        	master.writeEndObject();
        	master.writeEndObject();
        	master.writeStartObject();
			master.writeObjectField('method', 'POST');
			master.writeObjectField('url', '/services/data/v41.0/sobjects/Contact');
			master.writeObjectField('referenceId', 'refContact');
            //master.writeObjectField('body', cBody);
            master.writeFieldName('body');
        	master.writeStartObject();
        	master.writeObjectField('AccountId', '@{refAccount.id}');
        	master.writeObjectField('LastName', c[0].LastName);
        	master.writeObjectField('FirstName', c[0].FirstName);
        	master.writeObjectField('Email', c[0].Email);
        	master.writeObjectField('Phone', c[0].Phone);
        	master.writeObjectField('RecordTypeId', '012390000005zH0');
        	master.writeObjectField('MBO_ExternalID__c', c[0].Id);
        	master.writeEndObject();
        	master.writeEndObject();
        	master.writeStartObject();
			master.writeObjectField('method', 'POST');
			master.writeObjectField('url', '/services/data/v41.0/sobjects/Opportunity');
			master.writeObjectField('referenceId', 'refOpportunity');
            //master.writeObjectField('body', oBody);
        	master.writeFieldName('body');
        	master.writeStartObject();
        	master.writeObjectField('Name', o[0].Name);
			master.writeObjectField('AccountId', '@{refAccount.id}');
			master.writeObjectField('Booker_Product_Term__c', o[0].Booker_Term__c);
			master.writeObjectField('CloseDate', o[0].CloseDate);
			master.writeObjectField('Currency__c', o[0].Booker_Currency__c);
			master.writeObjectField('Does_this_represent_a_brand__c', 'FALSE');
			master.writeObjectField('Location_Business_Type__c', a[0].Industry);
			master.writeObjectField('MAP_Partner__c', o[0].Booker_MAP_Partner__c);
			master.writeObjectField('Master_Lead_Source__c', 'MB Transfer');
			master.writeObjectField('Merchant_Processing__c', o[0].Booker_Merchant_Processing__c);
			master.writeObjectField('Product__c', o[0].Booker_Product__c);
			master.writeObjectField('RecordTypeId', '01270000000Mya4');
			master.writeObjectField('Revenue_Pillar__c', o[0].Booker_Revenue_Pillar__c);
			master.writeObjectField('StageName', 'Prospect');
			master.writeObjectField('Type', 'New Customer');
        	master.writeObjectField('MBO_ExternalID__c', o[0].Id);
			master.writeEndObject();
        	master.writeEndObject();
        	master.writeStartObject();
			master.writeObjectField('method', 'POST');
			master.writeObjectField('url', '/services/data/v41.0/sobjects/OpportunityContactRole');
			master.writeObjectField('referenceId', 'refOppConRole');
            //master.writeObjectField('body', ocrBody);
        	master.writeFieldName('body');
        	master.writeStartObject();
        	master.writeObjectField('ContactId', '@{refContact.id}');
			master.writeObjectField('OpportunityId', '@{refOpportunity.id}');
			master.writeObjectField('Role', 'Decision Maker');
        	master.writeEndObject();
        	master.writeEndObject();
        	master.writeEndArray();
        	master.writeEndObject();
        
        String jsonString = master.getAsString();
        return jsonString;
    }
}