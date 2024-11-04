/**
 * @description       : Unit test for the product access utility class
**/
@isTest
private class ProductAccessUtilityTest {

    @TestSetup
    static void makeData() {
        TestUtility.buildUser('System Administrator', 'Admin', true);
        TestUtility.buildUser('Standard User', 'Standard', true);
    }

    @isTest
    private static void testHasModifyAllData() {
        User createdUser = [SELECT Id FROM User WHERE LastName = 'Admin' LIMIT 1];

        Test.startTest();
        Boolean hasPermission = ProductAccessUtility.hasModifyAllData(createdUser.Id);
        Test.stopTest();

        Assert.isTrue(hasPermission, 'User has not Modify All data permission');
    }

    @isTest
    private static void testHasNotModifyAllData() {
        User createdUser = [SELECT Id FROM User WHERE LastName = 'Standard' LIMIT 1];

        Test.startTest();
        Boolean hasPermission = ProductAccessUtility.hasModifyAllData(createdUser.Id);
        Test.stopTest();

        Assert.isFalse(hasPermission, 'User has Modify All data permission');
    }

    @isTest
    private static void testCheckUserHasProductAccess() {
        Id currentUserId = UserInfo.getUserId();
        ProductTeamMemberAccessWrapper ptma = new ProductTeamMemberAccessWrapper(null, currentUserId, 'test user', '', 'Edit', 'User');
        List<ProductTeamMemberAccessWrapper> ptmaList = new List<ProductTeamMemberAccessWrapper> { ptma };
        List<String> permissions = new List<String> { 'Edit', 'Full Access' };

        Test.startTest();
        Boolean hasPermission = ProductAccessUtility.checkUserProductAccess(ptmaList, permissions);
        Test.stopTest();

        Assert.isTrue(hasPermission, 'User has not the correct permissions');
    }

    @isTest
    private static void testCheckUserHasNoProductAccess() {
        Id currentUserId = UserInfo.getUserId();
        ProductTeamMemberAccessWrapper ptma = new ProductTeamMemberAccessWrapper(null, currentUserId, 'test user', '', 'Read', 'User');
        List<ProductTeamMemberAccessWrapper> ptmaList = new List<ProductTeamMemberAccessWrapper> { ptma };
        List<String> permissions = new List<String> { 'Edit', 'Full Access' };

        Test.startTest();
        Boolean hasPermission = ProductAccessUtility.checkUserProductAccess(ptmaList, permissions);
        Test.stopTest();

        Assert.isFalse(hasPermission, 'User has not the correct permissions');
    }
}