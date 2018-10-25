@isTest
private class MBPass2Bkr_TEST {
    @isTest static void M2B() {
        Test.setMock(WebServiceMock.class, new MockImpl());

        String output = WebSvcCallout.callEchoString('HelloWorld!');

        //add coverage for record(s) being sent to Booker SFDC
    }
}