public class MBpass2Bkr {
    @future(callout=true)
    //??change to trigger on Opp and soql the Contact and Account?
    public static void push2Bkr(Id OppID) {
        Opportunity o = new Opportunity();

        Http h = new Http();
        HttpRequest req = new HttpRequest();
        HttpResponse res = new HttpResponse();

        BkrSFDCIntegration__c bkrConstant = BkrSFDCIntegration__c.getOrgDefaults();

        String url = bkrConstant.PostEndpointURL__c;
        url = 'callout:MBO2BKRcred' + url;
        
        String jsonBody;
        
        jsonBody = createJSON4Bkr.genJSON4Bkr(OppID);

        IF(!Test.isRunningTest()) {
            IF(url != null) {
                req.setEndpoint(url);
            }else{
                req.setEndpoint('https://cs66.salesforce.com/services/data/v43.0/composite');
            }
            req.setMethod('POST');
            req.setBody(jsonBody);
            //System.debug('Ouput JSON: ' + jsonBody);
            req.setHeader('Content-Type', 'application/json');
            
            try{
                res = h.send(req);
            }catch(System.CalloutException e) {
                System.debug('Callout error: ' + e);
                System.debug(res.toString());
            }

            //o.Id = OppID;
            //Store on the account any error that may have occured
            //o.SyncResponse__c = res.toString();
            //update o;
            /*
            JSONParser parser = JSON.createParser(res.getBody());
        WHILE (parser.nextToken() != null) {
            IF((parser.getCurrentToken() == JSONToken.FIELD_NAME)) {
                String fieldName = parser.getText();
                parser.nextToken();
                if(fieldName == 'access_token') {
                    accesstoken = parser.getText();
                }
            }
        }
        return accesstoken;
            */
        }
    }
}

    