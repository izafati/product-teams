/**
 * @description       : Test class for ProductTeamMemberController
 **/
@IsTest
public class ProductTeamMemberControllerTest {
    private final static String TEAM_MEMBER_ROLE = 'Marketing Agent';
    private final static String TEAM_MEMBER_FULL_ACCESS = 'Full Access';
    private final static String TEAM_MEMBER_READ_ACCESS = 'Read';
    private final static String TEAM_MEMBER_EDIT_ACCESS = 'Edit';
    private final static String TERRITORY_NAME = 'Test_Territory';
    private final static String PSET_NAME = 'Test_Permission_Set';
    private final static String ROLE_NAME = 'Test_Role';
    private final static String ADMIN_USER_LASTNAME = 'ADMIN_USER_LASTNAME';
    private final static String OWNER_USER_LASTNAME = 'OWNER_USER_LASTNAME';
    private final static String TEST_USER_LASTNAME = 'TEST_USER_LASTNAME';

    @TestSetup
    private static void prepareTestData() {
        User adminUser = TestUtility.buildUser('System Administrator', ADMIN_USER_LASTNAME, true);
        User ownerUser = TestUtility.buildUser('Standard User', OWNER_USER_LASTNAME, true);
        User testUser = TestUtility.buildUser('Standard User', TEST_USER_LASTNAME, true);

        System.runAs(ownerUser) {
            Product2 product = new Product2(Name = 'Test Product');
            insert product;
        }

        Group testQueue = new Group(Name = 'Test', type = 'Queue');
        insert testQueue;

        Group testGroup = new Group(Name = 'Test', type = 'Regular');
        insert testGroup;

        System.runAs(adminUser) {
            GroupMember groupMember = new GroupMember();
            groupMember.GroupId = testGroup.Id;
            groupMember.UserOrGroupId = ownerUser.Id;
            insert groupMember;

            Territory2Model territory2Model = [
                SELECT Id
                FROM Territory2Model
                LIMIT 1
            ];
            Territory2Type territory2Type = [SELECT Id FROM Territory2Type LIMIT 1];
            Territory2 testTerritory = new Territory2(
                Name = TERRITORY_NAME,
                DeveloperName = TERRITORY_NAME,
                Territory2ModelId = territory2Model.Id,
                Territory2TypeId = territory2Type.Id
            );
            insert testTerritory;

            UserTerritory2Association userTerritory2Association = new UserTerritory2Association(
                UserId = ownerUser.Id,
                Territory2Id = testTerritory.Id
            );
            insert userTerritory2Association;

            PermissionSet testPset = new PermissionSet(Name = PSET_NAME, Label = PSET_NAME);
            insert testPset;

            PermissionSetAssignment psetAssignment = new PermissionSetAssignment(
                PermissionSetId = testPset.Id,
                AssigneeId = ownerUser.id
            );
            insert psetAssignment;

            UserRole testUserRole = new UserRole(Name = ROLE_NAME);
            insert testUserRole;

            ownerUser.UserRoleId = testUserRole.Id;
            update ownerUser;
        }
    }

    @IsTest
    static void shouldFetchAllProductTeamMemberTypes() {
        // WHEN
        Test.startTest();
        List<ProductTeamMemberController.ProductTeamMemberType> types = ProductTeamMemberController.getProductTeamMemberTypes();
        Test.stopTest();

        // THEN
        System.assertNotEquals(0, types.size(), 'Expected non empty ProductTeamMemberType results');
    }

    @IsTest
    static void shouldSearchForUserSuccessfully() {
        // Having
        User ownerUser = [SELECT Id FROM User WHERE LastName = :OWNER_USER_LASTNAME LIMIT 1];
        System.assertNotEquals(null, ownerUser, 'We do not have a valid user for the test context.');
        Test.setFixedSearchResults(new List<Id>{ ownerUser.Id });
        String searchTerm = 'Test';
        List<String> selectedIds = new List<String>();
        String productTeamMemberTypeName = 'User';

        // WHEN
        List<LookupSearchResult> results = new List<LookupSearchResult>();
        System.runAs(ownerUser) {
            Test.startTest();
            results = ProductTeamMemberController.search(searchTerm, selectedIds, productTeamMemberTypeName);
            Test.stopTest();
        }

        // THEN
        System.assertNotEquals(null, results, 'Expected non-null results');
        System.assertNotEquals(0, results.size(), 'Expected non empty results');
        System.assertEquals(ownerUser.Id, results.get(0).getId(), 'user id found should match the test user id');
    }

    @IsTest
    static void shouldSearchForQueueSuccessfully() {
        // Having
        Group testQueue = [SELECT Id FROM Group WHERE Type = 'Queue' LIMIT 1];
        System.assertNotEquals(null, testQueue, 'We do not have a valid queue for the test context.');
        User ownerUser = [SELECT Id FROM User WHERE LastName = :OWNER_USER_LASTNAME LIMIT 1];
        System.assertNotEquals(null, ownerUser, 'We do not have a valid test user for the test context.');
        Test.setFixedSearchResults(new List<Id>{ testQueue.Id });
        String searchTerm = 'Test';
        List<String> selectedIds = new List<String>();
        String productTeamMemberTypeName = 'Queue';

        // WHEN
        List<LookupSearchResult> results = new List<LookupSearchResult>();
        System.runAs(ownerUser) {
            Test.startTest();
            results = ProductTeamMemberController.search(searchTerm, selectedIds, productTeamMemberTypeName);
            Test.stopTest();
        }

        // THEN
        System.assertNotEquals(null, results, 'Expected non-null results');
        System.assertNotEquals(0, results.size(), 'Expected non empty results');
        System.assertEquals(testQueue.Id, results.get(0).getId(), 'queue id found should match the test queue id');
    }

    @IsTest
    static void shouldSearchForPublicGroupSuccessfully() {
        // Having
        Group testGroup = [
            SELECT Id
            FROM Group
            WHERE Name = 'Test' AND Type = 'Regular'
            LIMIT 1
        ];
        System.assertNotEquals(null, testGroup, 'We do not have a valid public group for the test context.');

        User ownerUser = [SELECT Id FROM User WHERE LastName = :OWNER_USER_LASTNAME LIMIT 1];
        System.assertNotEquals(null, ownerUser, 'We do not have a valid test user for the test context.');

        Test.setFixedSearchResults(new List<Id>{ testGroup.Id });
        String searchTerm = 'Test';
        List<String> selectedIds = new List<String>();
        String productTeamMemberTypeName = 'Public_Group';

        // WHEN
        List<LookupSearchResult> results = new List<LookupSearchResult>();
        System.runAs(ownerUser) {
            Test.startTest();
            results = ProductTeamMemberController.search(searchTerm, selectedIds, productTeamMemberTypeName);
            Test.stopTest();
        }

        // THEN
        System.assertNotEquals(null, results, 'Expected non-null results');
        System.assertNotEquals(0, results.size(), 'Expected non empty results');
        System.assertEquals(testGroup.Id, results.get(0).getId(), 'group id found should match the test group id');
    }

    @IsTest
    static void shouldSearchForUserRoleSuccessfully() {
        // Having
        UserRole testUserRole = [
            SELECT Id
            FROM UserRole
            WHERE Name = :ROLE_NAME
            LIMIT 1
        ];
        System.assertNotEquals(null, testUserRole, 'We do not have a valid user role for the test context.');
        User adminUser = [SELECT Id FROM User WHERE LastName = :ADMIN_USER_LASTNAME LIMIT 1];
        System.assertNotEquals(null, adminUser, 'We do not have a valid admin user for the test context.');
        Test.setFixedSearchResults(new List<Id>{ testUserRole.Id });
        String searchTerm = 'Test';
        List<String> selectedIds = new List<String>();
        String productTeamMemberTypeName = 'Role';

        // WHEN
        List<LookupSearchResult> results = new List<LookupSearchResult>();
        System.runAs(adminUser) {
            Test.startTest();
            results = ProductTeamMemberController.search(searchTerm, selectedIds, productTeamMemberTypeName);
            Test.stopTest();
        }
        // THEN
        System.assertNotEquals(null, results, 'Expected non-null results');
        System.assertNotEquals(0, results.size(), 'Expected non empty results');
        System.assertEquals(
            testUserRole.Id,
            results.get(0).getId(),
            'user role id found should match the test user role id'
        );
    }

    @IsTest
    static void shouldSearchForCustomPermissionSetSuccessfully() {
        // Having
        PermissionSet testPset = [
            SELECT Id
            FROM PermissionSet
            WHERE name = :PSET_NAME AND IsCustom = TRUE
            LIMIT 1
        ];
        System.assertNotEquals(null, testPset, 'We do not have a valid permission set for the test context.');
        User adminUser = [SELECT Id FROM User WHERE LastName = :ADMIN_USER_LASTNAME LIMIT 1];
        System.assertNotEquals(null, adminUser, 'We do not have a valid admin user for the test context.');

        Test.setFixedSearchResults(new List<Id>{ testPset.Id });
        String searchTerm = 'Test';
        List<String> selectedIds = new List<String>();
        String productTeamMemberTypeName = 'Permission_Set';

        // WHEN
        List<LookupSearchResult> results = new List<LookupSearchResult>();
        System.runAs(adminUser) {
            Test.startTest();
            results = ProductTeamMemberController.search(searchTerm, selectedIds, productTeamMemberTypeName);
            Test.stopTest();
        }

        // THEN
        System.assertNotEquals(null, results, 'Expected non-null results');
        System.assertNotEquals(0, results.size(), 'Expected non empty results');
        System.assertEquals(
            testPset.Id,
            results.get(0).getId(),
            'user role id found should match the test user role id'
        );
    }

    @IsTest
    static void shouldSearchForTerritorySuccessfully() {
        // Having
        Territory2 testTerritory = [
            SELECT Id
            FROM Territory2
            WHERE DeveloperName = :TERRITORY_NAME
            LIMIT 1
        ];
        System.assertNotEquals(null, testTerritory, 'We do not have a valid Territory for the test context.');
        User ownerUser = [SELECT Id FROM User WHERE LastName = :OWNER_USER_LASTNAME LIMIT 1];
        System.assertNotEquals(null, ownerUser, 'We do not have a valid test user for the test context.');

        Test.setFixedSearchResults(new List<Id>{ testTerritory.Id });
        String searchTerm = 'Test';
        List<String> selectedIds = new List<String>();
        String productTeamMemberTypeName = 'Territory';

        // WHEN
        List<LookupSearchResult> results = new List<LookupSearchResult>();
        System.runAs(ownerUser) {
            Test.startTest();
            results = ProductTeamMemberController.search(searchTerm, selectedIds, productTeamMemberTypeName);
            Test.stopTest();
        }

        // THEN
        System.assertNotEquals(null, results, 'Expected non-null results');
        System.assertNotEquals(0, results.size(), 'Expected non empty results');
        System.assertEquals(
            testTerritory.Id,
            results.get(0).getId(),
            'territory id found should match the test territory id'
        );
    }

    @IsTest
    static void shouldCreateProductTeamMemberSuccessfully() {
        // Having
        Product2 product = [SELECT Id FROM Product2 LIMIT 1];
        System.assertNotEquals(null, product, 'We do not have a valid Product for the test context.');
        User ownerUser = [SELECT Id FROM User WHERE LastName = :OWNER_USER_LASTNAME LIMIT 1];
        System.assertNotEquals(null, ownerUser, 'We do not have a valid test user for the test context.');

        // fetching one sample value for the TeamMemberRole__c restricted picklist
        Schema.DescribeSObjectResult objDescribe = ProductTeamMember__c.sObjectType.getDescribe();
        Schema.DescribeFieldResult fieldDescribe = objDescribe.fields.getMap().get('TeamMemberRole__c').getDescribe();
        List<Schema.PicklistEntry> picklistValues = fieldDescribe.getPicklistValues();
        String teamMemberRoleValue = picklistValues.get(0)?.getLabel();

        // WHEN
        System.runAs(ownerUser) {
            Test.startTest();
            ProductTeamMemberController.createProductTeamMember(
                product.Id,
                ownerUser.Id,
                'Full Access',
                'User__c',
                teamMemberRoleValue
            );
            Test.stopTest();
        }

        // THEN
        ProductTeamMember__c productTeamMember = [
            SELECT Id, User__c, ProductAccessLevel__c
            FROM ProductTeamMember__c
        ];
        System.assertEquals(
            ownerUser.Id,
            productTeamMember.User__c,
            'product team member record should have a lookup to the test user'
        );
        System.assertEquals(
            'Full Access',
            productTeamMember.ProductAccessLevel__c,
            'product team member record should have the correct access level'
        );
    }

    @IsTest
    static void shouldFetchProductTeamMemberAccessByUser() {
        // HAVING
        User ownerUser = [SELECT Id, Name FROM User WHERE LastName = :OWNER_USER_LASTNAME LIMIT 1];
        System.assertNotEquals(null, ownerUser, 'We do not have a valid test user for the test context.');
        Product2 product = [SELECT Id FROM Product2 LIMIT 1];
        System.assertNotEquals(null, product, 'We do not have a valid Product for the test context.');
        ProductTeamMember__c productTeamMember = new ProductTeamMember__c(
            Name__c = 'Product Team Member Name Test',
            Product__c = product.Id,
            ProductAccessLevel__c = TEAM_MEMBER_FULL_ACCESS,
            TeamMemberRole__c = TEAM_MEMBER_ROLE,
            User__c = ownerUser.Id
        );
        // WHEN
        List<ProductTeamMemberAccessWrapper> productTeamMemberAccessList = new List<ProductTeamMemberAccessWrapper>();
        System.runAs(ownerUser) {
            Test.startTest();
            insert productTeamMember;
            productTeamMemberAccessList = ProductTeamMemberController.fetchProductTeamMemberAccess(product.Id);
            Test.stopTest();
        }
        // THEN
        System.assertNotEquals(
            0,
            productTeamMemberAccessList.size(),
            'product team member access should not return an empty list.'
        );
        System.assertEquals(
            ownerUser.name,
            productTeamMemberAccessList.get(0).name,
            'product team member name should match the name of the test user.'
        );
        System.assertEquals(
            TEAM_MEMBER_ROLE,
            productTeamMemberAccessList.get(0).role,
            'product team member role should match the team member role for testing context.'
        );
        System.assertEquals(
            TEAM_MEMBER_FULL_ACCESS,
            productTeamMemberAccessList.get(0).access,
            'product team member access should match the team member access for testing context.'
        );
    }

    @IsTest
    static void shouldFetchProductTeamMemberAccessByGroup() {
        // HAVING
        Group testGroup = [
            SELECT Id
            FROM Group
            WHERE Name = 'Test' AND Type = 'Regular'
            LIMIT 1
        ];
        System.assertNotEquals(null, testGroup, 'We do not have a valid public group for the test context.');
        GroupMember groupMemeber = [
            SELECT GroupId, UserOrGroupId, UserOrGroup.Name
            FROM GroupMember
            WHERE GroupId = :testGroup.Id
            LIMIT 1
        ];
        System.assertNotEquals(null, groupMemeber, 'We do not have a valid group member for the test context.');
        Product2 product = [SELECT Id FROM Product2 LIMIT 1];
        System.assertNotEquals(null, product, 'We do not have a valid Product for the test context.');
        User ownerUser = [SELECT Id, Name FROM User WHERE LastName = :OWNER_USER_LASTNAME LIMIT 1];
        System.assertNotEquals(null, ownerUser, 'We do not have a valid test user for the test context.');

        ProductTeamMember__c productTeamMember = new ProductTeamMember__c(
            Name__c = 'Product Team Member Name Test',
            Product__c = product.Id,
            ProductAccessLevel__c = TEAM_MEMBER_FULL_ACCESS,
            TeamMemberRole__c = TEAM_MEMBER_ROLE,
            PublicGroup__c = testGroup.Id
        );

        // WHEN
        List<ProductTeamMemberAccessWrapper> productTeamMemberAccessList = new List<ProductTeamMemberAccessWrapper>();
        System.runAs(ownerUser) {
            insert productTeamMember;
            Test.startTest();
            productTeamMemberAccessList = ProductTeamMemberController.fetchProductTeamMemberAccess(product.Id);
            Test.stopTest();
        }

        // THEN
        System.assertNotEquals(
            0,
            productTeamMemberAccessList.size(),
            'product team member access should not return an empty list.'
        );
        System.assertEquals(
            groupMemeber.UserOrGroup?.Name,
            productTeamMemberAccessList.get(0).name,
            'product team member name should match the name of the group user.'
        );
        System.assertEquals(
            TEAM_MEMBER_ROLE,
            productTeamMemberAccessList.get(0).role,
            'product team member role should match the team member role for testing context.'
        );
        System.assertEquals(
            TEAM_MEMBER_FULL_ACCESS,
            productTeamMemberAccessList.get(0).access,
            'product team member access should match the team member access for testing context.'
        );
    }

    @IsTest
    static void shouldFetchProductTeamMemberAccessByTerritory() {
        // HAVING
        User ownerUser = [SELECT Id, Name FROM User WHERE LastName = :OWNER_USER_LASTNAME LIMIT 1];
        System.assertNotEquals(null, ownerUser, 'We do not have a valid test user for the test context.');
        Territory2 testTerritory = [
            SELECT Id
            FROM Territory2
            WHERE DeveloperName = :TERRITORY_NAME
            LIMIT 1
        ];
        System.assertNotEquals(null, testTerritory, 'We do not have a valid Territory for the test context.');
        UserTerritory2Association userTerritory2Association = [
            SELECT Id, UserId, User.Name, Territory2Id
            FROM UserTerritory2Association
            WHERE Territory2Id = :testTerritory.Id
            LIMIT 1
        ];
        System.assertNotEquals(
            null,
            userTerritory2Association,
            'We do not have a valid UserTerritory2Association for the test context.'
        );
        Product2 product = [SELECT Id FROM Product2 LIMIT 1];
        System.assertNotEquals(null, product, 'We do not have a valid Product for the test context.');
        ProductTeamMember__c productTeamMember = new ProductTeamMember__c(
            Name__c = 'Product Team Member Name Test',
            Product__c = product.Id,
            ProductAccessLevel__c = TEAM_MEMBER_FULL_ACCESS,
            TeamMemberRole__c = TEAM_MEMBER_ROLE,
            Territory__c = testTerritory.Id
        );

        // WHEN
        List<ProductTeamMemberAccessWrapper> productTeamMemberAccessList = new List<ProductTeamMemberAccessWrapper>();
        System.runAs(ownerUser) {
            insert productTeamMember;
            Test.startTest();
            productTeamMemberAccessList = ProductTeamMemberController.fetchProductTeamMemberAccess(product.Id);
            Test.stopTest();
        }

        // THEN
        System.assertNotEquals(
            0,
            productTeamMemberAccessList.size(),
            'product team member access should not return an empty list.'
        );
        System.assertEquals(
            userTerritory2Association.User?.Name,
            productTeamMemberAccessList.get(0).name,
            'product team member name should match the name of the territory user.'
        );
        System.assertEquals(
            TEAM_MEMBER_ROLE,
            productTeamMemberAccessList.get(0).role,
            'product team member role should match the team member role for testing context.'
        );
        System.assertEquals(
            TEAM_MEMBER_FULL_ACCESS,
            productTeamMemberAccessList.get(0).access,
            'product team member access should match the team member access for testing context.'
        );
    }

    @IsTest
    static void shouldFetchProductTeamMemberAccessByPset() {
        // HAVING
        User ownerUser = [SELECT Id, Name FROM User WHERE LastName = :OWNER_USER_LASTNAME LIMIT 1];
        System.assertNotEquals(null, ownerUser, 'We do not have a valid test user for the test context.');
        PermissionSet testPset = [
            SELECT Id
            FROM PermissionSet
            WHERE name = :PSET_NAME AND IsCustom = TRUE
            LIMIT 1
        ];
        System.assertNotEquals(null, testPset, 'We do not have a valid permission set for the test context.');
        PermissionSetAssignment psetAssignment = [
            SELECT PermissionSetId, AssigneeId, Assignee.Name
            FROM PermissionSetAssignment
            WHERE PermissionSetId = :testPset.Id
            LIMIT 1
        ];
        System.assertNotEquals(
            null,
            psetAssignment,
            'We do not have a valid PermissionSetAssignment for the test context.'
        );
        Product2 product = [SELECT Id FROM Product2 LIMIT 1];
        System.assertNotEquals(null, product, 'We do not have a valid Product for the test context.');
        ProductTeamMember__c productTeamMember = new ProductTeamMember__c(
            Name__c = 'Product Team Member Name Test',
            Product__c = product.Id,
            ProductAccessLevel__c = TEAM_MEMBER_FULL_ACCESS,
            TeamMemberRole__c = TEAM_MEMBER_ROLE,
            PermissionSet__c = testPset.Id
        );

        // WHEN
        List<ProductTeamMemberAccessWrapper> productTeamMemberAccessList = new List<ProductTeamMemberAccessWrapper>();
        System.runAs(ownerUser) {
            insert productTeamMember;
            Test.startTest();
            productTeamMemberAccessList = ProductTeamMemberController.fetchProductTeamMemberAccess(product.Id);
            Test.stopTest();
        }

        // THEN
        System.assertNotEquals(
            0,
            productTeamMemberAccessList.size(),
            'product team member access should not return an empty list.'
        );
        System.assertEquals(
            psetAssignment.Assignee?.Name,
            productTeamMemberAccessList.get(0).name,
            'product team member name should match the name of the permission set user.'
        );
        System.assertEquals(
            TEAM_MEMBER_ROLE,
            productTeamMemberAccessList.get(0).role,
            'product team member role should match the team member role for testing context.'
        );
        System.assertEquals(
            TEAM_MEMBER_FULL_ACCESS,
            productTeamMemberAccessList.get(0).access,
            'product team member access should match the team member access for testing context.'
        );
    }

    @IsTest
    static void shouldFetchProductTeamMemberAccessByUserRole() {
        // HAVING
        UserRole testUserRole = [
            SELECT Id
            FROM UserRole
            WHERE Name = :ROLE_NAME
            LIMIT 1
        ];
        System.assertNotEquals(null, testUserRole, 'We do not have a valid user role for the test context.');
        User testUser = [
            SELECT Id, name
            FROM User
            WHERE userRoleId = :testUserRole.Id
            LIMIT 1
        ];
        System.assertNotEquals(null, testUser, 'We do not have a valid user for the test context.');
        Product2 product = [SELECT Id FROM Product2 LIMIT 1];
        System.assertNotEquals(null, product, 'We do not have a valid Product for the test context.');
        ProductTeamMember__c productTeamMember = new ProductTeamMember__c(
            Name__c = 'Product Team Member Name Test',
            Product__c = product.Id,
            ProductAccessLevel__c = TEAM_MEMBER_FULL_ACCESS,
            TeamMemberRole__c = TEAM_MEMBER_ROLE,
            Role__c = testUserRole.Id
        );

        // WHEN
        List<ProductTeamMemberAccessWrapper> productTeamMemberAccessList = new List<ProductTeamMemberAccessWrapper>();
        System.runAs(testUser) {
            insert productTeamMember;
            Test.startTest();
            productTeamMemberAccessList = ProductTeamMemberController.fetchProductTeamMemberAccess(product.Id);
            Test.stopTest();
        }

        // THEN
        System.assertNotEquals(
            0,
            productTeamMemberAccessList.size(),
            'product team member access should not return an empty list.'
        );
        System.assertEquals(
            testUser.Name,
            productTeamMemberAccessList.get(0).name,
            'product team member name should match the name of the role user.'
        );
        System.assertEquals(
            TEAM_MEMBER_ROLE,
            productTeamMemberAccessList.get(0).role,
            'product team member role should match the team member role for testing context.'
        );
        System.assertEquals(
            TEAM_MEMBER_FULL_ACCESS,
            productTeamMemberAccessList.get(0).access,
            'product team member access should match the full team member access for testing context.'
        );
    }

    @IsTest
    static void shouldFetchProductTeamMemberAccessForHigherAccess() {
        // HAVING
        User testUser = [SELECT Id, Name FROM User WHERE LastName = :TEST_USER_LASTNAME LIMIT 1];
        System.assertNotEquals(null, testUser, 'We do not have a valid test user for the test context.');
        Product2 product = [SELECT Id FROM Product2 LIMIT 1];
        System.assertNotEquals(null, product, 'We do not have a valid Product for the test context.');
        List<ProductTeamMember__c> productTeamMembers = new List<ProductTeamMember__c>{
            new ProductTeamMember__c(
                Name__c = 'Product Team Member Name Test 1',
                Product__c = product.Id,
                ProductAccessLevel__c = TEAM_MEMBER_READ_ACCESS,
                TeamMemberRole__c = TEAM_MEMBER_ROLE,
                User__c = testUser.Id
            ),
            new ProductTeamMember__c(
                Name__c = 'Product Team Member Name Test 2',
                Product__c = product.Id,
                ProductAccessLevel__c = TEAM_MEMBER_EDIT_ACCESS,
                TeamMemberRole__c = TEAM_MEMBER_ROLE,
                User__c = testUser.Id
            )
        };
        insert productTeamMembers;

        // WHEN
        ProductAccessUtility.userIds = new List<Id>();
        List<ProductTeamMemberAccessWrapper> productTeamMemberAccessList = new List<ProductTeamMemberAccessWrapper>();
        System.runAs(testUser) {
            Test.startTest();
            productTeamMemberAccessList = ProductTeamMemberController.fetchProductTeamMemberAccess(product.Id);
            Test.stopTest();
        }

        // THEN
        System.assertEquals(
            1,
            productTeamMemberAccessList.size(),
            'product team member access should return one record.'
        );
        System.assertEquals(
            testUser.name,
            productTeamMemberAccessList.get(0).name,
            'product team member name should match the name of the test user.'
        );
        System.assertEquals(
            TEAM_MEMBER_ROLE,
            productTeamMemberAccessList.get(0).role,
            'product team member role should match the team member role for testing context.'
        );
        System.assertEquals(
            TEAM_MEMBER_EDIT_ACCESS,
            productTeamMemberAccessList.get(0).access,
            'product team member access should return the higher permission access for testing context.'
        );
    }

    @isTest
    static void shouldHavePermissionToManageProductTeamMember() {
        User adminUser = [SELECT Id FROM User WHERE LastName = :ADMIN_USER_LASTNAME LIMIT 1];
        System.assertNotEquals(null, adminUser, 'We do not have a valid admin user for the test context.');
        Product2 product = [SELECT Id FROM Product2 LIMIT 1];
        Boolean hasAccess = false;

        System.runAs(adminUser) {
            hasAccess = ProductTeamMemberController.checkUserPermission(product.Id);
        }

        System.assertEquals(true, hasAccess, 'User should be able to manage product team member since he is an admin');
    }

    @isTest
    static void shouldNotHavePermissionToManageProductTeamMemberNotMember() {
        User testUser = [SELECT Id FROM User WHERE LastName = :TEST_USER_LASTNAME LIMIT 1];
        System.assertNotEquals(null, testUser, 'We do not have a valid test user for the test context.');
        Product2 product = [SELECT Id FROM Product2 LIMIT 1];

        Boolean hasAccess = false;
        System.runAs(testUser) {
            hasAccess = ProductTeamMemberController.checkUserPermission(product.Id);
        }

        System.assertEquals(
            false,
            hasAccess,
            'User should not be able to manage product team member since he is not a member and not an admin'
        );
    }

    @isTest
    static void shouldHavePermissionToManageProductTeamMemberAsMember() {
        User testUser = [SELECT Id FROM User WHERE LastName = :TEST_USER_LASTNAME LIMIT 1];
        System.assertNotEquals(null, testUser, 'We do not have a valid test user for the test context.');
        Product2 product = [SELECT Id FROM Product2 LIMIT 1];
        ProductTeamMember__c ptm = TestUtility.buildProductTeamMember(
            product.Id,
            testUser.Id,
            TEAM_MEMBER_FULL_ACCESS,
            true
        );

        Boolean hasAccess = false;
        System.runAs(testUser) {
            hasAccess = ProductTeamMemberController.checkUserPermission(product.Id);
        }

        System.assertEquals(
            true,
            hasAccess,
            'User should be able to manage product team member since they are member with full access level'
        );
    }

    @isTest
    static void shouldNotHavePermissionToManageProductTeamMemberAsEditMember() {
        User testUser = [SELECT Id FROM User WHERE LastName = :TEST_USER_LASTNAME LIMIT 1];
        System.assertNotEquals(null, testUser, 'We do not have a valid test user for the test context.');
        Product2 product = [SELECT Id FROM Product2 LIMIT 1];
        ProductTeamMember__c ptm = TestUtility.buildProductTeamMember(
            product.Id,
            testUser.Id,
            TEAM_MEMBER_EDIT_ACCESS,
            true
        );

        Boolean hasAccess = false;
        System.runAs(testUser) {
            hasAccess = ProductTeamMemberController.checkUserPermission(product.Id);
        }

        System.assertEquals(
            false,
            hasAccess,
            'User should not be able to manage product team member since they are member with Edit access level'
        );
    }
}