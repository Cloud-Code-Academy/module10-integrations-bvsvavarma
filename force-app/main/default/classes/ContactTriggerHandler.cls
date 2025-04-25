public with sharing class ContactTriggerHandler {
    public static void beforeInsert(List<Contact> contacts) {
     
        for(Contact contact : contacts){
            // When a contact is inserted
	        // if DummyJSON_Id__c is null, generate a random number between 0 and 100 and set this as the contact's DummyJSON_Id__c value
            if(contact.DummyJSON_Id__c == null){
                contact.DummyJSON_Id__c = String.valueOf((Integer) Math.floor(Math.random() * 101));
            }else if(Integer.valueOf(contact.DummyJSON_Id__c) <=100){
                //When a contact is inserted
	            // if DummyJSON_Id__c is less than or equal to 100, call the getDummyJSONUserFromId API
                DummyJSONCallout.getDummyJSONUserFromId(contact.id);
            }
        }
    }
    public static void afterUpdate(List<Contact> contacts) {
        for(Contact con : contacts){
            //When a contact is updated
	        // if DummyJSON_Id__c is greater than 100, call the postCreateDummyJSONUser API
            if(Integer.valueOf(con.DummyJSON_Id__c) > 100){
                DummyJSONCallout.postCreateDummyJSONUser(con.DummyJSON_Id__c);
            }
        }
    }
}