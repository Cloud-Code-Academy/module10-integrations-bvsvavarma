/*
 * DummyJSONCallout Class Description:
 * 
 * This class, DummyJSONCallout, facilitates HTTP callouts to an external system (presumably 'DummyJsonUser' in this context) 
 * to either fetch or send user information based on a given identifier. The class supports both GET (to fetch data) 
 * and POST (to send data) operations.
 * 
 * Overview of HTTP Callouts:
 * 
 * HTTP callouts are a way for Salesforce to communicate with external systems using HTTP protocols. Through HTTP callouts, 
 * you can invoke external web services, collect data from them, or send data for further processing. Apex provides 
 * classes that enable you to both send and receive HTTP data. The primary classes for this are `HttpRequest`, which 
 * represents the request you're sending, and `HttpResponse`, which represents the response you receive.
 * 
 * Best Practices:
 * 1. Handle Exceptions: Always handle exceptions that might be thrown, to ensure your code doesn't break unexpectedly.
 * 2. Named Credentials: Use Named Credentials to store endpoint URLs and authentication details securely.
 * 3. Test Callouts: Use mock classes and interfaces to test HTTP callouts without making actual callouts.
 * 
 * For more detailed information on HTTP callouts in Apex, refer to the official Salesforce documentation: 
 * https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_classes_restful_http_httprequest.htm
 */

 public with sharing class DummyJSONCallout {

	/* 
	 * Question 1
     * Fetches user information from an external system https://dummyjson.com/user/{id} ('DummyJsonUser') based on the provided dummy user ID. 
     * If the callout is successful and returns an HTTP status of 200, the method will update a contact based on the DummyJSON_Id__c with the data returned from the external system.
	 * Use the createContactFromJson method to parse the JSON response and create a Salesforce Contact object.
     * Documentation: https://dummyjson.com/docs/users
	 * This callout method should work in triggers
	 * 
     * @param dummyUserId The ID of the user in the external system to fetch data for.
     */

	@future(callout=true)
	public static void getDummyJSONUserFromId(String dummyUserId) {

		// Create HTTP request to send.
		Http http = new Http();
		HttpRequest request = new HttpRequest();

		// Set the endpoint URL. Use direct URL or for best practices use Named Credential.
		request.setEndpoint('https://dummyjson.com/users/' + dummyUserId);

		// Set the HTTP method to GET.
		request.setMethod('GET');

		// Send the HTTP request and get the response.
		HttpResponse response = http.send(request);

		// If the HTTP response code is successful, parse the JSON response and update the contact.
		if (response.getStatusCode() == 200) {
			// Deserialize the JSON string into collections of primitive data types.
			String jsonResponse = response.getBody();
			
			Contact cont = createContactFromJson(jsonResponse);

			upsert cont DummyJSON_Id__c; //insert/update from the JSON response using the external id (dummyUserId)

		}else {
            // If the status code is not 200, something went wrong with the request
            System.debug('HTTP request failed. Status code: ' + response.getStatusCode());
            System.debug('Response body: ' + response.getBody());
        }
	}

	/* 
	 * Question 2
     * Transforms a JSON response from the external system https://dummyjson.com/users into a Salesforce Contact object.
     * The method parses the JSON string to extract user details and map them to a Salesforce Contact object.
     * The contact fields populated from the JSON include Email, Phone, Birthdate, and various address-related fields.
     * The method is primarily designed to work in conjunction with callouts that fetch user details from the external system. 
	 * 
	 * Fields from JSON used to populate Salesforce Contact
	 * Fields: Email, Phone, Birthdate, MailingStreet, MailingCity, MailingPostalCode, MailingState, MailingCountry
	 * 
     * Documentation: https://dummyjson.com/docs/users
     * 
     * @param String jsonResponse The JSON string from the external system that contains user details.
     * @return Contact The Salesforce Contact object populated with details from the JSON string.
     */
	@TestVisible // Allows test class to see this method. Since it is private, it would not be visible otherwise.

	private static Contact createContactFromJson(String jsonResponse) {
		// Deserialize the JSON string into map of primitive data types.
		Map<String,Object> jsonMap = (Map<String,Object>) JSON.deserializeUntyped(jsonResponse);

		// Create a new contact from the JSON response.
		Contact cont = new Contact();

		// Set the contact fields from the JSON response.
		cont.DummyJSON_Id__c = String.valueOf(jsonMap.get('id'));
		cont.FirstName = String.valueOf(jsonMap.get('firstName'));
		cont.LastName = String.valueOf(jsonMap.get('lastName'));
		cont.email = String.valueOf(jsonMap.get('email'));
		cont.phone = String.valueOf(jsonMap.get('phone'));
		cont.Birthdate = Date.valueOf(String.valueOf(jsonMap.get('birthDate')));

		
		// Deserialize the address from the JSON response.
		Map<String,Object> addressMap = (Map<String,Object>) jsonMap.get('address');

		// Set the address fields on the contact object.	
		cont.MailingStreet = String.valueOf(addressMap.get('address'));
		cont.MailingCity = String.valueOf(addressMap.get('city'));
		cont.MailingPostalCode = String.valueOf(addressMap.get('postalCode'));
		cont.MailingState = String.valueOf(addressMap.get('state'));
		cont.MailingCountry = String.valueOf(addressMap.get('country'));
		return cont;
	}

	/* 
	 * Question 3
     * Sends Contact information to an external system https://dummyjson.com/users/add ('DummyJsonUser') to create or update a user based on the provided Salesforce Contact ID.
     * The method prepares a JSON payload with the contact's information and sends it to the 'DummyJsonUser' add endpoint.
     * If the callout is successful (HTTP status code between 200 and 299), the method updates the contact's 'DummyJSON_Last_Updated__c' field in Salesforce to the current time.
	 * Salesforce Contact should be used to generate the JSON payload
	 * Fields: Id, FirstName, LastName, Email, Phone
	 * This callout method should work in triggers
	 * 
     * Documentation: https://dummyjson.com/docs/users
     * 
     * @param contactId The Salesforce Contact ID used to generate the JSON payload for the external system.
     */
	
	@future(callout=true)
	public static void postCreateDummyJSONUser(String contactId) {
		// Create HTTP request to send.
		Http http = new Http();
		HttpRequest request = new HttpRequest();

		// Set the endpoint URL. Use direct URL or for best practices use Named Credential.
		request.setEndpoint('https://dummyjson.com/users/add');
		// Set the HTTP method to POST.
		request.setMethod('POST');
		request.setHeader('Content-Type', 'application/json');
		// Set the body using generateDummyJsonUserPayload method.
		String responseBody = generateDummyJsonUserPayload(contactId);
		
		// Set the body to the request.
		request.setBody(responseBody);
		
		// Send the HTTP request and get the response.
		HttpResponse response = http.send(request);

		// If the HTTP response code is successful, update the contact.
		if (response.getStatusCode() >= 200 && response.getStatusCode() < 300) {
			// Update the Contact record with the last updated time.
			Contact cont = new Contact(Id=contactId, DummyJSON_Last_Updated__c=DateTime.now());
			update cont;
		}
	}

	/*
	 * Question 4
     * Generates a JSON payload based on a Salesforce Contact's fields to be sent to an external system https://dummyjson.com/users/add for user creation or update.
     * The method queries a contact from Salesforce based on the provided contactId and maps its fields into a JSON payload.
     * The fields from Salesforce Contact that are transformed into the JSON payload include Id, FirstName, LastName, Email, and Phone.
     * The generated JSON payload can be sent to the external system for various operations like creating or updating a user.
	 * 
	 * Fields from Salesforce Contact used to generate JSON payload:
	 * Fields: Id => salesforceId, FirstName => firstName, LastName => lastName, Email => email, Phone => phone
	 * 
     * Documentation: https://dummyjson.com/docs/users
     * 
     * @param String contactId The Salesforce Contact ID used to fetch the contact's fields and generate the JSON payload.
     * @return String The JSON string payload that represents the Contact's details.
     */
	@TestVisible // Allows test class to see this method. Since it is private, it would not be visible otherwise.
	private static String generateDummyJsonUserPayload(String contactId) {
		// Query the contact to get the field values to generate the JSON payload.
		Contact contact = [SELECT Id, FirstName, LastName, Email, Phone FROM Contact WHERE Id = :contactId];

		// Create a map of the field values.
		Map<String, Object> contactPayloadMap = new Map<String, Object>();
		contactPayloadMap.put('salesforceId', contact.Id);
		contactPayloadMap.put('firstName', contact.FirstName);
		contactPayloadMap.put('lastName', contact.LastName);
		contactPayloadMap.put('email', contact.Email);
		contactPayloadMap.put('phone', contact.Phone);

		// Serialize the map into a JSON string.
		String jsonString  = JSON.serialize(contactPayloadMap);
		// Make sure to check that required contacts fields have a value. Default the value to unknown if it does not exists.
		// Integration data can change over time. It is a best practice to add safeguards/validation to ensure the integration does not break.
		return jsonString;
	}
}