public class APIMapping{
  private SendSObjectToMindbody__mdt apiMapping;
  
  private APIMapping(List<SendSObjectToMindbody__mdt> groupedObjects){
    apiMapping = groupedObjects[0];
  }
  
  public String apiName{
    get{
      return apiMapping.MindbodyAPI_Name__c;
    }
  }

    public static String getFields(Map<String, APIMapping> apiMappings){
        return getFields(apiMappings, new Set<String>());
    }
    
    public static String getFields(Map<String, APIMapping> apiMappings, Set<String> requiredQueryFields){
        Set<String> fieldNames = new Set<String>();
        for(String key : apiMappings.keySet()){
            fieldNames.add(key);
        }
        
        fieldNames.add('Id');
        fieldNames.addAll(requiredQueryFields);
        return String.join(new List<String>(fieldNames), ',');
    }

    public static Map<String, APIMapping> getApiMappings(sObjectType objectType){
        List<SendSObjectToMindbody__mdt> apiMappingsPerType = sObjectByMapping.get(String.valueOf(objectType));
        return apiMappingsPerType == null ? null : buildAPIMappings(apiMappingsPerType);
    }

    private static Map<String, APIMapping> buildAPIMappings(List<SendSObjectToMindbody__mdt> apiMappings){
        Map<String, APIMapping> builtMappings = new Map<String, APIMapping>();
        Map<String, List<SendSObjectToMindbody__mdt>> newMapping = GroupBy.strings(SendSObjectToMindbody__mdt.BookerAPI_Name__c , apiMappings);
        for(String key : newMapping.keySet()){
            builtMappings.put(key, new APIMapping(newMapping.get(key)));
        }
        return builtMappings;
    }

    @testVisible
    private static List<SendSObjectToMindbody__mdt> apiMappings{
        get{
            if(apiMappings == null){
                apiMappings = [SELECT BookerAPI_Name__c, MindbodyAPI_Name__c, SObjectType__c from SendSObjectToMindbody__mdt];
            }
            return apiMappings;
        }
        private set;
    }

    private static Map<String, List<SendSObjectToMindbody__mdt>> sObjectByMapping {
        get{
            if(sObjectByMapping == null){
                sObjectByMapping = GroupBy.strings(SendSObjectToMindbody__mdt.SObjectType__c, apiMappings);
            }
            return sObjectByMapping;
        }
        private set;
    }

}