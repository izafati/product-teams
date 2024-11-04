/**
 * @description       : Controller class holds logic for :
 *  - Retrieving possible options for the product team member types
 *  - Search functionality depending on the selected product team member type
 *  - Product Team Member record creation
 **/
public with sharing class ProductTeamMemberController {
  private static final String PRODUCT_ACCESS_LEVEL = 'ProductAccessLevel';
  private static final String TEAM_MEMBER_ROLE = 'TeamMemberRole';
  private static final String USER_NAME = 'UserName';
  private static List<String> permissableAccesses = new List<String> { ProductAccessUtility.ACCESS_LEVELS.get('Full_Access') };
  private static final Map<String, String> REASON_MAPPING = new Map<String, String> {
    'Role__c' => 'Role',
    'PermissionSet__c' => 'Permission Set',
    'PublicGroup__c' => 'Public Group',
    'Queue__c' => 'Queue',
    'Territory__c' => 'Territory',
    'User__c' => 'User'
  };

  @AuraEnabled(cacheable=true)
  public static List<ProductTeamMemberType> getProductTeamMemberTypes() {
    List<ProductTeamMemberType> types = new List<ProductTeamMemberType>();
    for (Product_Team_Member_Type__mdt productTeamMemberType : [
      SELECT Label, DeveloperName, MemberTypeLookupField__c
      FROM Product_Team_Member_Type__mdt
    ]) {
      types.add(
        new ProductTeamMemberType(
          productTeamMemberType.Label,
          productTeamMemberType.DeveloperName,
          productTeamMemberType.MemberTypeLookupField__c
        )
      );
    }
    return types;
  }

  @AuraEnabled(cacheable=true scope='global')
  public static List<LookupSearchResult> search(
    String searchTerm,
    List<String> selectedIds,
    String productTeamMemberTypeName
  ) {
    try {
      Product_Team_Member_Type__mdt record = Product_Team_Member_Type__mdt.getInstance(
        productTeamMemberTypeName
      );
      return BaseLookupController.search(searchTerm, selectedIds, record);
    } catch (Exception e) {
      throw new AuraHandledException('error while searching ' + e.getMessage());
    }
  }

  @AuraEnabled
  public static String createProductTeamMember(
    String productId,
    String memberId,
    String accessLevel,
    String productTeamMemberLookupField,
    String productTeamMemberRole
  ) {
    try {
      ProductTeamMember__c productTeamMember = new ProductTeamMember__c();
      productTeamMember.Product__c = productId;
      productTeamMember.ProductAccessLevel__c = accessLevel;
      productTeamMember.TeamMemberRole__c = productTeamMemberRole;
      productTeamMember.Reason__c = REASON_MAPPING.get(
        productTeamMemberLookupField
      );
      productTeamMember.put(productTeamMemberLookupField, memberId);
      productTeamMember.Name__c = getRecordNameFromId(memberId);
      insert productTeamMember;
      return productTeamMember.Id;
    } catch (Exception e) {
      throw new AuraHandledException(
        'Failed to create product team member: ' + e.getMessage()
      );
    }
  }

  @AuraEnabled
  public static List<ProductTeamMemberAccessWrapper> fetchProductTeamMemberAccess(
    Id productId
  ) {
    Set<Id> productIds = new Set<Id>{ productId };
    Map<Id, List<ProductTeamMemberAccessWrapper>> productTeamMemberAccesses = ProductAccessUtility.fetchProductTeamMemberAccess(
      productIds
    );

    return productTeamMemberAccesses.get(productId);
  }

  private static String getRecordNameFromId(Id recordId) {
    String objectType = recordId.getSObjectType().getDescribe().getName();
    String fieldName = 'Name';

    if (fieldName != null) {
      String query =
        'SELECT ' +
        fieldName +
        ' FROM ' +
        objectType +
        ' WHERE Id = :recordId LIMIT 1';
      SObject result = Database.query(query);
      return (String) result.get(fieldName);
    }
    return null;
  }

  @AuraEnabled
  public static Boolean checkUserPermission(Id productId) {
    try {
      Id currentUserId = UserInfo.getUserId();
      Boolean hasGlobalPermission = ProductAccessUtility.hasModifyAllData(currentUserId);

      Product2 product = [SELECT Id, CreatedById FROM Product2 WHERE Id = :productId WITH USER_MODE LIMIT 1];
      
      Boolean hasAccess = (product.CreatedById == currentUserId) || hasGlobalPermission;

      if (!hasAccess) {
        Set<Id> productIds = new Set<Id> { productId };
        Map<Id, List<ProductTeamMemberAccessWrapper>> productsUserAccesses = ProductAccessUtility.fetchProductTeamMemberAccess(productIds, new List<Id> { currentUserId });
        List<ProductTeamMemberAccessWrapper> wrapperUserList = productsUserAccesses.get(productId);
        hasAccess = ProductAccessUtility.checkUserProductAccess(wrapperUserList, permissableAccesses);
      }

      return hasAccess;
    } catch(Exception e) {
      throw new AuraHandledException(
        'Error while checking access for user to manage product team member ' + e.getMessage()
      );
    }
  }

  public class ProductTeamMemberType {
    @AuraEnabled
    public String label { get; set; }
    @AuraEnabled
    public String value { get; set; }
    @AuraEnabled
    public String memberTypeLookupField { get; set; }

    public ProductTeamMemberType(
      String label,
      String value,
      String memberTypeLookupField
    ) {
      this.label = label;
      this.value = value;
      this.memberTypeLookupField = memberTypeLookupField;
    }
  }

  public class ProductTeamMemberAccess {
    @AuraEnabled
    public String name { get; set; }
    @AuraEnabled
    public String role { get; set; }
    @AuraEnabled
    public String access { get; set; }
    @AuraEnabled
    public String reason { get; set; }

    public ProductTeamMemberAccess(
      String name,
      String role,
      String access,
      String reason
    ) {
      this.name = name;
      this.role = role;
      this.access = access;
      this.reason = reason;
    }
  }
}
