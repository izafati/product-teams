/**
 * @description       : Trigger Handler class for the Product Team Member Trigger
 **/
public with sharing class ProductTeamMemberTriggerHandler {
  private List<String> permissableAccesses = new List<String>{
    ProductAccessUtility.ACCESS_LEVELS.get('Full_Access')
  };

  /**
   * @description validate the user access to see if he has the right to create a team member
   * @param productTeamMembers
   **/
  public void validateUserProductTeamMemberAccess(
    List<ProductTeamMember__c> productTeamMembers
  ) {
    Id currentUserId = UserInfo.getUserId();

    Set<Id> productIds = fetchProductsFromProductTeamMembers(
      productTeamMembers
    );

    Map<Id, Product2> products = new Map<Id, Product2>(
      [
        SELECT Id, CreatedById
        FROM Product2
        WHERE Id IN :productIds
        WITH USER_MODE
      ]
    );

    Map<Id, List<ProductTeamMemberAccessWrapper>> productsUserAccesses = ProductAccessUtility.fetchProductTeamMemberAccess(
      productIds,
      new List<Id>{ currentUserId }
    );

    Boolean hasGlobalPermission = ProductAccessUtility.hasModifyAllData(
      currentUserId
    );

    for (ProductTeamMember__c ptm : productTeamMembers) {
      Id productId = ptm.Product__c;
      Product2 product = products.get(productId);
      if (hasGlobalPermission || (currentUserId == product.CreatedById)) {
        continue;
      }

      List<ProductTeamMemberAccessWrapper> wrapperUserList = productsUserAccesses.get(
        productId
      );
      Boolean permissionGranted = ProductAccessUtility.checkUserProductAccess(
        wrapperUserList,
        permissableAccesses
      );

      if (!permissionGranted) {
        String errorMessage = System.Label.PTM_Adding_Product_Team_Member_Not_Allowed;
        ptm.addError(errorMessage);
      }
    }
  }

  /**
   * @description return productIds from a list of product team members
   * @param productTeamMembers
   * @return Set<Id>
   **/
  private static Set<Id> fetchProductsFromProductTeamMembers(
    List<ProductTeamMember__c> productTeamMembers
  ) {
    Set<Id> productIds = new Set<Id>();
    for (ProductTeamMember__c productTeamMember : productTeamMembers) {
      productIds.add(productTeamMember.Product__c);
    }

    return productIds;
  }
}
