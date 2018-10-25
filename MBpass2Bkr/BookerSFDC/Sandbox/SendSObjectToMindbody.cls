public with sharing class SendSObjectToMindbody {
    private static Map<sObjectType, List<APIMapping>> sObjectTypeToMetadataForTransformation;
    private static Map<sObjectType, String> sObjectTypeToEndPoint = new Map<sObjectType, String>{
        Opportunity.sObjectType => '/services/data/v43.0/sobjects/Opportunity/',
        Account.sObjectType => '/services/data/v43.0/sobjects/Account/',
        Contact.sObjectType => '/services/data/v43.0/sobjects/Contact/'
    };
    private static final String SALESFORCE_INSTANCE_URL = 'callout:BookerUrl';

    // Determine if any of the fields have changed for a given sObject
    // if the object changed; add it to a list
    // call sendToMindbody 
    public static void sendSObjectChangesToMindbody(List<sObject> newReferences, Map<Id, sObject> oldReferences){
        List<sObject> changedRecords = getChangedRecords(newReferences, oldReferences);
        sendToMindbody(changedRecords);
        // send the email for all error records
    }

    @testVisible
    private static List<sObject> getChangedRecords(List<sObject> newReferences, Map<Id, sObject> oldReferences){
        List<sObject> changedObjects = new List<sObject>();
        sObjectType objectType = newReferences.getSObjectType();
        Map<String, APIMapping> apiMappings = ApiMapping.getApiMappings(objectType);
        if(apiMappings != null){
            for(sObject newRecord : newReferences){
                String mindbodyId = (String)newRecord.get('MindbodyId__c');
                if(mindbodyId != null && oldReferences.containsKey(newRecord.Id)){
                    for(String field : apiMappings.keySet()){
                        Object newValue = newRecord.get(field);
                        Object oldValue = oldReferences.get(field);
                        if(newValue != oldValue){
                            changedObjects.add(newRecord);
                            break;
                        }
                    }
                }
            }

        }
        return changedObjects;
    }

    // Determines the endpoint to use for the sObject type
    // transforms the sObjects to MINDBODY form
    // Sends the data
    // Any errors are tracked
    public static List<sObject> sendToMindbody(List<sObject> objectsToSendToMindbody){
        List<sObject> failedRecords = new List<sObject>();
        sObjectType objectType = objectsToSendToMindbody.getSObjectType();
        Map<String, APIMapping> apiMapping = ApiMapping.getApiMappings(objectType);
        List<Object> transformedObjects = transform(objectsToSendToMindbody, apiMapping);

        String endPointUrl = sObjectTypeToEndPoint.get(objectType);
        if(endPointUrl != null){
            // Use a named credential instead
            String url = SALESFORCE_INSTANCE_URL + endpointUrl;
            Integer index = 0;
            for(Object obj : transformedObjects){
                String objectId = (String)((Map<String, Object>)obj).get('Id');
                HttpRequest req = new HttpRequest();
                req.setEndPoint(url + objectId);
                req.setMethod('PATCH');
                req.setBody(JSON.serialize(obj));
                sObject objectReference = objectsToSendToMindbody[index];
                
                HttpResponse response = new Http().send(req);
                // try & catch. OR non 200 response
                // add to failedRecords
                // objectReference.put('BookerIntegrationErrors__c', true);
                
                index++;
            }
            // (BookerIntegrationErrors__c) flag (set to true) any records that failed to be updated in Mindbody
            // so that they can be resent in the batches
        }
        update failedRecords;
        return failedRecords;

    }

    private static List<Object> transform(List<sObject> sObjects, Map<String, APIMapping> newMapping){
        List<Object> theOpportunities = new List<Object>();
        for(sObject thesObject : sObjects){
            Map<String, Object> objectNewKeys = new Map<String, Object>();
            theOpportunities.add(objectNewKeys);
            
            for(String fieldName : newMapping.keyset()){
                
                FieldReference ref = FieldReference.build(fieldName);
                Object fieldValue = ref.getFrom(thesObject);
                
                Map<String, Object> parentObject = objectNewKeys;
                while(ref instanceof FieldReference.ChainedFieldReference){
                    FieldReference.ChainedFieldReference chainedRef = ((FieldReference.ChainedFieldReference)ref);
                    String field = chainedRef.field;
                    
                    if(!parentObject.containsKey(field)){
                        parentObject.put(field, new Map<String, Object>());
                    }
                    parentObject = (Map<String, Object>)parentObject.get(field);
                    ref = chainedRef.next;
                    
                }
                
                parentObject.put(newMapping.get(fieldName).apiName, fieldValue);
            }
        }
        return theOpportunities;
    }

}