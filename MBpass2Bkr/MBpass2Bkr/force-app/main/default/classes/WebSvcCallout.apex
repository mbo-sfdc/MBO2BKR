public class WebSvcCallout {
    public static String callEchoString(String input) {
        docSample.DocSamplePort sample = new docSample.DocSamplePort();
        sample.endpoint_x = 'http://example.com/example/test';

        String echo = sample.EchoString(input);

        return echo;
    }
}