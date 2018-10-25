public class SupportPage_Controller {
    public string nameQuery{get;set;}
    public string AID {get;set;}
    public string AName {get;set;}
    public string selectedRep {get;set;}
    public string selectedCon {get;set;}
    public string selectedType {get;set;}
    public List<Account> Accts{get;set;}
    public Boolean isTableExit {get;set;}
    public Boolean conRender {get;set;}
    
    public Support_Data_Insert__c sdi {get;set;}
    public Account acct {get;set;}
    public Contact cont {get;set;}
    
    String searchText;
    List<Account> results;
    
    public SupportPage_Controller() {
        acct = new Account();
        cont = new Contact();
        sdi = new Support_Data_Insert__c();
        isTableExit = False;
        conRender = False;
    }
    
    public PageReference executeSearch() {
        AName = 'No Account found';
        if(nameQuery == null || nameQuery == '') {
            ApexPages.Message errMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Please enter a Location ID');
            ApexPages.addMessage(errMsg);
        }else{
            Accts = [SELECT Id, Name, SB_Location_ID__c FROM Account WHERE SB_Location_ID__c =: nameQuery];
          if(Accts.size() < 1) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, 'Location ID Not Found'));
            }else{
              isTableExit = True;
              AID = String.valueOf(Accts[0].Id);
                AName = String.valueOF(Accts[0].Name);
              System.debug('>>>>> AcctID: ' + AID);
          }
        }
        return null;
    }
    public SelectOption[] getCons() {
        SelectOption[] foundCons = new SelectOption[]{};
            System.debug('>>>>> AccountID: ' + AID);
            for(Contact c : [SELECT Id, Name, Email FROM Contact WHERE AccountId =: AID]) {
                
                foundCons.add(new SelectOption(String.valueOF(c.Id), c.Name));
            }
        return foundCons;
    }
    
    public SelectOption[] getselectValues() {
        SelectOption[] options = new SelectOption[]{};
            for(Rep__c r : [SELECT Id, Name, Email__c FROM Rep__c WHERE Department__c =: 'Support']) {
                options.add(new SelectOption(String.valueOf(r.Id), r.Name));
            }
        System.debug('>>>>>>' + options.size());
        return options;    
    }
    
    public SelectOption [] getOppType() {
        SelectOption[] oType = new SelectOption[]{};
          oType.add(new SelectOption('Downsell/Downgrade', 'Downsell/Downgrade'));
          oType.add(new SelectOption('Upsell/Upgrade', 'Upsell/Upgrade'));
          oType.add(new SelectOption('Frederick', 'Frederick'));
          oType.add(new SelectOption('New Business', 'New Business'));
          oType.add(new SelectOption('Hardware', 'Hardware'));
        return oType;
    }
    
    public PageReference saveOpp() {
        Support_Data_Insert__c newSDI = new Support_Data_Insert__c();
        newSDI.IsOpp__c = True;
        newSDI.Account_Name__c = Accts[0].Id;
        newSDI.Opportunity_Name__c = sdi.Opportunity_Name__c;
        newSDI.Opportunity_Close_Date__c = sdi.Opportunity_Close_Date__c;
        newSDI.Opportunity_Notes__c = sdi.Opportunity_Notes__c;
        newSDI.Opportunity_Product__c = sdi.Opportunity_Product__c;
        newSDI.RepName__c = selectedRep;
        newSDI.Contact__c = selectedCon;
        newSDI.Opp_Type__c = selectedType;
        newSDI.OppMnthlyFee__c = sdi.OppMnthlyFee__c;
                
        insert newSDI;
        
        PageReference redirectURL = new PageReference('http://google.com');
        
        return redirectURL;
    }
    
    public PageReference saveCase() {
        Support_Data_Insert__c newSDI = new Support_Data_Insert__c();
        newSDI.IsCase__c = True;
        newSDI.Account_Name__c = Accts[0].Id;
        newSDI.Remediation_Type__c = sdi.Remediation_Type__c;
        newSDI.Remediation_Description__c = sdi.Remediation_Description__c;
        newSDI.New_Remediation_Reason_Code__c = sdi.New_Remediation_Reason_Code__c;
        newSDI.New_Remediation_Reason_Sub_Code__c = sdi.New_Remediation_Reason_Sub_Code__c;
        newSDI.Remediation_Amount__c = sdi.Remediation_Amount__c;
        newSDI.RepName__c = selectedRep;
        newSDI.Contact__c = selectedCon;
        
        insert newSDI;
        
        PageReference redirectURL = new PageReference('http://google.com');
        
        return redirectURL;
    }
}