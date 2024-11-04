/**
 * @description       : Product Trigger on update and insert
**/
trigger ProductTrigger on Product2 (before update) {
    ProductTriggerHandler handler = new ProductTriggerHandler();

    switch on Trigger.operationType {
        when BEFORE_UPDATE {
            Map<Id, Product2> products = (Map<Id, Product2>) Trigger.newMap;
            handler.validateUserProductEdit(products);
        }
    }
}
