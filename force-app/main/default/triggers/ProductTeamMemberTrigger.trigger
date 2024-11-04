/**
 * @description       : Product Team Member Trigger on update and insert
**/
trigger ProductTeamMemberTrigger on ProductTeamMember__c (before update, before insert) {
    ProductTeamMemberTriggerHandler handler = new ProductTeamMemberTriggerHandler();

    switch on Trigger.operationType {
        when BEFORE_UPDATE, BEFORE_INSERT {
            List<ProductTeamMember__c> productTeamMembers = (List<ProductTeamMember__c>) Trigger.new;
            handler.validateUserProductTeamMemberAccess(productTeamMembers);
        }
    }
}
