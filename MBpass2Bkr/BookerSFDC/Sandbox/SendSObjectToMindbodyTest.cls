@isTest
private class SendSObjectToMindbodyTest {
  @isTest
  static void sendSObjectChangesToMindbody(){
    // define/assign SendSObjectToMindbody.apiMappings
    // 
    Test.startTest();

    Test.stopTest();
    // assert flag on sObject is still false
    // assert num emails = 0
    // assert request body is a transformation of api mapping
  }

  @isTest
  static void sendSObjectChangesToMindbody_MindbodyTimeout(){

    Test.startTest();

      //Integer numEmailsSent = Limits.getNumEmailsSent();
    Test.stopTest();

    // Assert flag on sObject is set
    // Assert error message
    // numEmailsSent assert size 1
  }

  @isTest
  static void sendSObjectChangesToMindbody_MindbodyDMLError(){
    Test.startTest();

      //Integer numEmailsSent = Limits.getNumEmailsSent();
    Test.stopTest();

    // Assert flag on sObject is set
    // Assert error message
    // numEmailsSent assert size 1
  }

  @isTest
  static void testValidMetadata(){
    // get metadata from server; SendSObjectToMindbody.apiMappings
    // get unique sObject Types
    // init unique object types using reflection
    Test.startTest();
    // SendSObjectToMindbody.getChangedRecords for each sObject type
    Test.stopTest();

    // assert exception thrown = false
  }

}