/**
 * @description       : wrapper class for the product team member access for users.
 **/
public with sharing class ProductTeamMemberAccessWrapper {
    public String id { get; set; }
    public String userId { get; set; }
    @AuraEnabled
    public String name { get; set; }
    @AuraEnabled
    public String role { get; set; }
    @AuraEnabled
    public String access { get; set; }
    @AuraEnabled
    public String reason { get; set; }

    public ProductTeamMemberAccessWrapper(String id, String userId, String name, String role, String access, String reason) {
        this.id = id;
        this.userId = userId;
        this.name = name;
        this.role = role;
        this.access = access;
        this.reason = reason;
    }
}