trigger MB2BK on Opportunity (after update) {
    for(Opportunity updatedOpportunity : Trigger.new) {
        //Ready_for_Sync__c should be used in a workflow when event happens that data is ready to be pushed from the mbo sfdc to the bkr sfdc
        //SyncSuccess__c should be set with a response from the Bkr instance that the data was accepted and not errored.
        //Data_Sent__c should be used to denote what has been sent
        If(updatedOpportunity.Ready_for_Sync__c == True && updatedOpportunity.SyncSuccess__c == False && updatedOpportunity.DataSent__c == False) {
            MBpass2Bkr.push2Bkr(updatedOpportunity.Id);
            updatedOpportunity.DataSent__c = True;
        }
    }
}