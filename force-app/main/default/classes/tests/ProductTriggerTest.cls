/**
 * @description       : Unit Test for the Product Trigger
**/
@isTest
private class ProductTriggerTest {

    @TestSetup
    static void makeData() {
        Product2 product1 = new Product2(
            Name = 'My testing product 1'
        );

        Product2 product2 = new Product2(
            Name = 'My testing product 2'
        );

        insert new List<Product2> { product1, product2 };

        TestUtility.buildUser('Standard User', 'Jhon', true);
    }

    @isTest
    private static void testUpdateProductAsTheProductCreator() {
        String newProductName = 'My updated product';
        Product2 product = [SELECT Id, Name FROM Product2 LIMIT 1];
        product.Name = newProductName;

        Test.startTest();
        Database.SaveResult result = Database.update(product, false);
        Test.stopTest();

        Product2 updatedProduct = [SELECT Id, Name FROM Product2 WHERE Id = :product.Id LIMIT 1];

        Assert.areEqual(true, result.isSuccess(), 'Update of products was not successfull');
        Assert.areEqual(newProductName, updatedProduct.Name, 'Name field of product was not updated as expected');
    }


    @isTest
    private static void testUpdateProductAsTheProductCreatorBulk() {
        String newProductName = 'My updated product';
        List<Product2> products = [SELECT Id, Name FROM Product2];
        for (Product2 p : products) {
            p.Name = newProductName;
        }

        Test.startTest();
        List<Database.SaveResult> results = Database.update(products, false);
        Test.stopTest();

        Boolean isSuccessfull = true;

        for (Database.SaveResult result : results) {
            if (!result.isSuccess()) {
                isSuccessfull = false;
            }
        }

        Assert.areEqual(true, isSuccessfull, 'Update of products was not successfull');
    }

    @isTest
    private static void testUpdateProductWithNoPermission() {
        String newProductName = 'My updated product';

        Product2 product = [SELECT Id, Name FROM Product2 LIMIT 1];
        product.Name = newProductName;

        User currentUser = [SELECT Id FROM User WHERE LastName = 'Jhon' LIMIT 1];

        Database.SaveResult result;

        System.runAs(currentUser) {
            Test.startTest();
            result = Database.update(product, false);
            Test.stopTest();
        }

        Assert.areEqual(false, result.isSuccess(), 'Update of products was successfull even though has no permission');
        Assert.areEqual(System.Label.PTM_Updating_Product_Not_Allowed, result.getErrors().get(0).getMessage(), 'Error message is not as expected');
    }

    @isTest
    private static void testUpdateProductWithOnlyReadPermission() {
        String newProductName = 'My updated product';

        Product2 product = [SELECT Id, Name FROM Product2 LIMIT 1];
        product.Name = newProductName;

        User currentUser = [SELECT Id FROM User WHERE LastName = 'Jhon' LIMIT 1];
        TestUtility.buildProductTeamMember(product.Id, currentUser.Id, 'Read', true);
        
        Database.SaveResult result;

        System.runAs(currentUser) {
            Test.startTest();
            result = Database.update(product, false);
            Test.stopTest();
        }

        Assert.areEqual(false, result.isSuccess(), 'Update of products was successfull even though has no permission');
        Assert.areEqual(System.Label.PTM_Updating_Product_Not_Allowed, result.getErrors().get(0).getMessage(), 'Error message is not as expected');
    }

    @isTest
    private static void testUpdateProductWithOnlyEditPermission() {
        String newProductName = 'My updated product';

        Product2 product = [SELECT Id, Name FROM Product2 LIMIT 1];
        product.Name = newProductName;
        
        User currentUser = [SELECT Id FROM User WHERE LastName = 'Jhon' LIMIT 1];
        TestUtility.buildProductTeamMember(product.Id, currentUser.Id, 'Edit', true);

        Database.SaveResult result;

        System.runAs(currentUser) {
            Test.startTest();
            result = Database.update(product, false);
            Test.stopTest();
        }

        Assert.areEqual(true, result.isSuccess(), 'Update of products was not successfull');
    }

    @isTest
    private static void testUpdateProductWithOnlyAllPermission() {
        String newProductName = 'My updated product';

        Product2 product = [SELECT Id, Name FROM Product2 LIMIT 1];
        product.Name = newProductName;
        
        User currentUser = [SELECT Id FROM User WHERE LastName = 'Jhon' LIMIT 1];
        TestUtility.buildProductTeamMember(product.Id, currentUser.Id, 'Full Access', true);

        Database.SaveResult result;

        System.runAs(currentUser) {
            Test.startTest();
            result = Database.update(product, false);
            Test.stopTest();
        }

        Assert.areEqual(true, result.isSuccess(), 'Update of products was not successfull');
    }
}
