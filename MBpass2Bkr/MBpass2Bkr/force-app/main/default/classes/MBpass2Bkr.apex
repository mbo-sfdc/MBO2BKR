public class MBpass2Bkr {
    @future(callout=true)
    //??change to trigger on Opp and soql the Contact and Account?
    public static void push2Bkr(Id OppID) {
        Opportunity o = new Opportunity();

        Http h = new Http();
        HttpRequest req = new HttpRequest();
        HttpResponse res = new HttpResponse();

        BkrSFDCIntegration__c bkrConstant = BkrSFDCIntegration__c.getOrgDefaults();

        String url = bkrConstant.EndpointURL__c;

        String jsonBody;
        
        jsonBody = createJSON4Bkr.genJSON4Bkr(OppID);

        IF(!Test.isRunningTest()) {
            String username = bkrConstant.username__c;
            String password = bkrConstant.password__c;
            String token = bkrConstant.token__c;
            Blob headerValue = Blob.valueOf(username + ':' + password + token);
            String authorizationHeader = 'Basic' + EncodingUtil.base64Encode(headerValue);

            IF(url != null) {
                req.setEndpoint(url);
            }else{
                req.setEndpoint('www.booker.com');
            }
            req.setMethod('POST');
            req.setBody(jsonBody);

            req.setHeader('Authorization', authorizationHeader);
            req.setHeader('Content-Type', 'application/json');

            try{
                res = h.send(req);
            }catch(System.CalloutException e) {
                System.debug('Callout error: ' + e);
                System.debug(res.toString());
            }

            o.Id = OppID;
            //Store on the account any error that may have occured
            o.SyncResponse__c = res.toString();
            update o;
        }
    }
}