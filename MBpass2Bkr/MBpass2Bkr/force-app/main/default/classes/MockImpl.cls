global class MockImpl implements WebServiceMock {
    global void doInvoke(
        Object stub,
        Object request,
        Map<String, Object> response,
        String endpoint,
        String soapAction,
        String requestName,
        String responseNS,
        String responseName,
        String responseType) {
            docSample.EchoStringResponse_element responseElement = new docSample.EchoStringResponse_element();
            responseElement EchoStringResult = 'Mock response';
            response.put('response_x', responseElement);
        }
}