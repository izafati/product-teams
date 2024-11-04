/**
 * @description       : Trigger Handler class for the Product Trigger
**/
public with sharing class ProductTriggerHandler {

    private List<String> permissableAccesses = new List<String> { ProductAccessUtility.ACCESS_LEVELS.get('Edit'), ProductAccessUtility.ACCESS_LEVELS.get('Full_Access') };

    /**
    * @description validate if the current user has the right to update the product
    * @param products 
    **/
    public void validateUserProductEdit(Map<Id, Product2> products) {
        Id currentUserId = UserInfo.getUserId();
        User u = [SELECT Id, Name FROM User WHERE id = :currentUserId WITH USER_MODE];
        Set<Id> productIds = new Set<Id> (products.keySet());
        Map<Id, List<ProductTeamMemberAccessWrapper>> productsUserAccesses = ProductAccessUtility.fetchProductTeamMemberAccess(productIds, new List<Id> { currentUserId });

        Boolean hasGlobalPermission = ProductAccessUtility.hasModifyAllData(currentUserId);

        for (Id productId : products.keySet()) {

            Product2 product = products.get(productId);
            if (hasGlobalPermission || (currentUserId == product.CreatedById)) {
                continue;
            }

            List<ProductTeamMemberAccessWrapper> wrapperUserList = productsUserAccesses.get(productId);

            Boolean permissionGranted = ProductAccessUtility.checkUserProductAccess(wrapperUserList, permissableAccesses);

            if (!permissionGranted) {
                String errorMessage = System.Label.PTM_Updating_Product_Not_Allowed;
                product.addError(errorMessage);
            }
        }
    }
}
