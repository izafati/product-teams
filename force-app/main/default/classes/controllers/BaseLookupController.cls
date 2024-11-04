/**
 * @description       : BaseLookupController
 **/
public with sharing class BaseLookupController {
    public static List<LookupSearchResult> search(
        String searchTerm,
        List<String> selectedIds,
        Product_Team_Member_Type__mdt controller
    ) {
        List<SObject> searchResults;
        if (controller.IsSOQL__c) {
            searchResults = LookupSearchUtility.performSOQLSearch(
                searchTerm,
                controller.ObjectType__c,
                controller.QueryFields__c,
                controller.SearchCondition__c
            );
        } else {
            searchResults = LookupSearchUtility.performSOSLSearch(
                searchTerm,
                controller.ObjectType__c,
                controller.QueryFields__c,
                selectedIds
            );
        }

        List<LookupSearchResult> results = new List<LookupSearchResult>();
        for (SObject obj : searchResults) {
            results.add(mapToLookupSearchResult(obj, controller));
        }
        results.sort();

        return results;
    }

    private static LookupSearchResult mapToLookupSearchResult(SObject obj, Product_Team_Member_Type__mdt controller) {
        String subtitle = controller.ObjectTypeLabel__c + ' • ' + (String) obj.get('Name');
        return new LookupSearchResult(
            obj.Id,
            controller.ObjectTypeLabel__c,
            controller.ObjectIcon__c,
            (String) obj.get('Name'),
            subtitle
        );
    }
}