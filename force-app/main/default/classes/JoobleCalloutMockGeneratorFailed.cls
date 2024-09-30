@isTest
public with sharing class JoobleCalloutMockGeneratorFailed implements HttpCalloutMock {

	public HTTPResponse respond(HTTPRequest req) {

		HttpResponse res = new HttpResponse();
		res.setHeader('Content-Type', 'application/json');
		res.setStatusCode(500);
		return res;
	}
}