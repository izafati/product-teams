/**
 * @description       : Contain reusable utility methods for test classes
**/
@isTest
public class TestUtility {

    private static final String PERMISSION_SET_NAME = 'Product_Team_Access';
    
    public static User buildUser(String profileName, String lastName, Boolean shouldInsert) {
        Profile p = [SELECT Id FROM Profile WHERE Name = :profileName];
        User u = new User(
            Alias = 'standt',
            Email = 'standarduser@testorg.com',
            EmailEncodingKey = 'UTF-8',
            LastName = lastName,
            LanguageLocaleKey ='en_US',
            LocaleSidKey ='en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = Crypto.getRandomLong() + '@' + Crypto.getRandomLong() + '.abc',
            isActive = true
        );

        if (shouldInsert) {
            insert u;
            assignPermissionSet(u.Id);
        }

        return u;
    }

    public static ProductTeamMember__c buildProductTeamMember(Id productId, Id userId, String access, Boolean shouldInsert) {
        ProductTeamMember__c ptm = new ProductTeamMember__c(
            Name__c = 'Product Team Member Name Test',
            Product__c = productId,
            User__c = userId,
            ProductAccessLevel__c = access
        );

        if (shouldInsert) {
            insert ptm;
        }

        return ptm;
    }

    @future
    public static void assignPermissionSet(Id userId) {
        PermissionSet ps = [
            SELECT Id
            FROM PermissionSet
            WHERE Name = :PERMISSION_SET_NAME
        ];

        insert new PermissionSetAssignment(AssigneeId = userId, PermissionSetId = ps.Id);
    }
}