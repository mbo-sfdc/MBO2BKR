global class AccountToMindbodyResendBatch implements Database.Batchable<sObject>, Schedulable  {
    static final Integer MAX_HTTP_CALLOUTS = 100;


    // select Count(Id), sObjectType from SendSObjectToMindbody__mdt group by sObjectYpe
    // 3 -> (Account, Contact, Opportunity)
    // loop through all the distinct sObject Types for the SendSOBjectTOMindbody
    // init AccountToMindbodyResendBatch with sObject Type
    // schedule job

    // Constructor of sObjectType
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        sObjectType objectType = Account.sObjectType;
        Map<String, APIMapping> apiMappings = ApiMapping.getApiMappings(objectType);
        String fieldsToquery = ApiMapping.getFields(apiMappings);
        return Database.getQueryLocator('SELECT ' + fieldsToQuery + ' FROM ' + objectType + ' BookerIntegrationErrors__c WHERE = true');
    }


    global void execute(Database.BatchableContext BC, List<sObject> scope) {
        List<sObject> failedRecords = SendSObjectToMindbody.sendToMindbody(scope);
        Set<Id> recordIds = Pluck.ids(failedRecords);
        List<sObject> successfulItems = new List<sObject>();
        for(sObject theSObject : scope){
            if(!recordIds.contains(theSObject.Id)){
                theSObject.put('BookerIntegrationErrors__c', false);
                theSObject.put('BookerIntegrationErrorDetails__c', '');
                successfulItems.add(theSObject);
            }
        }
        update successfulItems;
    }
    
    global void finish(Database.BatchableContext BC) {}

    global void execute(SchedulableContext sc) {
        Database.executebatch(new AccountToMindbodyResendBatch(), MAX_HTTP_CALLOUTS);
    }
    


}