@isTest
public with sharing class JoobleCalloutMockGenerator implements HttpCalloutMock {

	public HTTPResponse respond(HTTPRequest req) {

        Callout_Configuration__mdt joobleCallout = Callout_Configuration__mdt.getInstance('Jooble_Post');
		String mockResponse = TestDataFactory.generateTestJoobleCalloutString(Integer.valueOf(joobleCallout.Record_Count_To_Get__c));

		HttpResponse res = new HttpResponse();
		res.setHeader('Content-Type', 'application/json');
        res.setBody(mockResponse);
		res.setStatusCode(200);
		return res;
	}
}
