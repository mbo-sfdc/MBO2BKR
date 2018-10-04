@isTest
private class WebSvcCallout_TEST {
    @isTest static void testEchoString() {
        Test.setMock(WebServiceMock.class, new MockImpl());

        String output = WebSvcCallout.callEchoString('HelloWorld!');

        System.assertEquals('Mock response', output);
    }
}