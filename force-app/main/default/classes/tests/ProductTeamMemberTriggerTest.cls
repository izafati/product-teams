/**
 * @description       : Unit Test for the Product Team Member Trigger
**/
@isTest
private class ProductTeamMemberTriggerTest {

    @TestSetup
    static void makeData() {
        Product2 product = new Product2(
            Name = 'My testing product 1'
        );
        
        insert product;

        TestUtility.buildUser('Standard User', 'Standard', true);
        TestUtility.buildUser('System Administrator', 'Admin', true);
        TestUtility.buildUser('Standard User', 'Standard 1', true);
    }

    @isTest
    private static void testCreateProductTeamMemberAsProductCreator() {
        Product2 product = [SELECT Id, Name FROM Product2 LIMIT 1];
        User randomUser = [SELECT Id FROM User WHERE LastName = 'Standard' LIMIT 1];
        ProductTeamMember__c ptm = TestUtility.buildProductTeamMember(product.Id, randomUser.Id , 'Read', false);
        
        Test.startTest();
        Database.SaveResult result = Database.insert(ptm, false);
        Test.stopTest();

        List<ProductTeamMember__c> createdProductTeamMember = [SELECT Id FROM ProductTeamMember__c WHERE User__r.LastName = 'Standard'];

        Assert.areEqual(true, result.isSuccess(), 'Product Team member was not created successfully even though the user has permission');
        Assert.isFalse(createdProductTeamMember.isEmpty(), 'The Product Team member was not created');
    }

    @isTest
    private static void testCreateProductTeamMemberWithNoPermission() {
        Product2 product = [SELECT Id, Name FROM Product2 LIMIT 1];
        User currentUser = [SELECT Id FROM User WHERE LastName = 'Standard' LIMIT 1];

        User randomeUser = [SELECT Id FROM User WHERE LastName = 'Standard 1' LIMIT 1];
        ProductTeamMember__c ptm = TestUtility.buildProductTeamMember(product.Id, randomeUser.Id , 'Read', false);

        Database.SaveResult result;
        System.runAs(currentUser) {
            Test.startTest();
            result = Database.insert(ptm, false);
            Test.stopTest();
        }

        List<ProductTeamMember__c> createdProductTeamMember = [SELECT Id FROM ProductTeamMember__c WHERE Product__c = :product.Id];

        Assert.areEqual(false, result.isSuccess(), 'Product Team member was created successfully even though the user has no permission');
        Assert.areEqual(System.Label.PTM_Adding_Product_Team_Member_Not_Allowed, result.getErrors().get(0).getMessage(), 'Error returned is not as expected');
        Assert.isTrue(createdProductTeamMember.isEmpty(), 'Product Team member was created even though user has no permissions');
    }

    @isTest
    private static void testCreateProductTeamMemberWithReadPermission() {
        Product2 product = [SELECT Id, Name FROM Product2 LIMIT 1];

        User currentUser = [SELECT Id FROM User WHERE LastName = 'Standard' LIMIT 1];
        ProductTeamMember__c currentUserPTM = TestUtility.buildProductTeamMember(product.Id, currentUser.Id , 'Read', true);

        User randomUser = [SELECT Id FROM User WHERE LastName = 'Standard 1' LIMIT 1];
        ProductTeamMember__c ptm = TestUtility.buildProductTeamMember(product.Id, randomUser.Id , 'Read', false);
        
        Database.SaveResult result;
        System.runAs(currentUser) {
            Test.startTest();
            result = Database.insert(ptm, false);
            Test.stopTest();
        }

        List<ProductTeamMember__c> createdProductTeamMember = [SELECT Id FROM ProductTeamMember__c WHERE Product__c = :product.Id AND User__c = :randomUser.Id];

        Assert.areEqual(false, result.isSuccess(), 'Product Team member was created successfully even though the user has no permission');
        Assert.areEqual(System.Label.PTM_Adding_Product_Team_Member_Not_Allowed, result.getErrors().get(0).getMessage(), 'Error returned is not as expected');
        Assert.isTrue(createdProductTeamMember.isEmpty(), 'Product Team member was created even though user has no permissions');
    }

    @isTest
    private static void testCreateProductTeamMemberWithAllPermission() {
        Product2 product = [SELECT Id, Name FROM Product2 LIMIT 1];

        User currentUser = [SELECT Id FROM User WHERE LastName = 'Standard' LIMIT 1];
        ProductTeamMember__c currentUserPTM = TestUtility.buildProductTeamMember(product.Id, currentUser.Id , 'Full Access', true);

        User randomUser = [SELECT Id FROM User WHERE LastName = 'Standard 1' LIMIT 1];
        ProductTeamMember__c ptm = TestUtility.buildProductTeamMember(product.Id, randomUser.Id , 'Read', false);
        
        Database.SaveResult result;
        System.runAs(currentUser) {
            Test.startTest();
            result = Database.insert(ptm, false);
            Test.stopTest();
        }

        List<ProductTeamMember__c> createdProductTeamMember = [SELECT Id FROM ProductTeamMember__c WHERE Product__c = :product.Id AND User__c = :randomUser.Id];

        Assert.areEqual(true, result.isSuccess(), 'Product Team member was not created successfully even though the user has permission');
        Assert.isFalse(createdProductTeamMember.isEmpty(), 'Product Team member was not created successfully even though the user has permission');
    }

    @isTest
    private static void testCreateProductTeamMemberWithAdminPermission() {
        Product2 product = [SELECT Id, Name FROM Product2 LIMIT 1];

        User currentUser = [SELECT Id FROM User WHERE LastName = 'Admin' LIMIT 1];
        ProductTeamMember__c currentUserPTM = TestUtility.buildProductTeamMember(product.Id, currentUser.Id , 'Read', true);

        User randomUser = [SELECT Id FROM User WHERE LastName = 'Standard 1' LIMIT 1];
        ProductTeamMember__c ptm = TestUtility.buildProductTeamMember(product.Id, randomUser.Id , 'Read', false);
        
        Database.SaveResult result;
        System.runAs(currentUser) {
            Test.startTest();
            result = Database.insert(ptm, false);
            Test.stopTest();
        }

        List<ProductTeamMember__c> createdProductTeamMember = [SELECT Id FROM ProductTeamMember__c WHERE Product__c = :product.Id AND User__c = :randomUser.Id];

        Assert.areEqual(true, result.isSuccess(), 'Product Team member was not created successfully even though the user has permission');
        Assert.isFalse(createdProductTeamMember.isEmpty(), 'Product Team member was not created successfully even though the user has permission');
    }
}