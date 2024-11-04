public inherited sharing class LookupSearchUtility {
    public static List<SObject> performSOSLSearch(
        String searchTerm,
        String objectType,
        String queryFields,
        List<String> selectedIds
    ) {
        searchTerm += '*';
        String query =
            'FIND \'' +
            String.escapeSingleQuotes(searchTerm) +
            '\' IN ALL FIELDS RETURNING ' +
            objectType +
            '(' +
            queryFields +
            ' WHERE Id NOT IN :selectedIds) LIMIT ' +
            Constants.MAX_RESULTS;
        List<List<sObject>> searchResults = search.query(query);
        return searchResults.isEmpty() ? new List<SObject>() : searchResults[0];
    }

    public static List<SObject> performSOQLSearch(
        String searchTerm,
        String objectType,
        String queryFields,
        String searchCondition
    ) {
        String soqlQuery = 'SELECT ' + queryFields + ' FROM ' + objectType + ' WHERE ' + searchCondition;
        Map<String, Object> bindVariablesMap = new Map<String, Object>{
            'searchTerm' => String.escapeSingleQuotes('%' + searchTerm + '%')
        };
        return Database.queryWithBinds(soqlQuery, bindVariablesMap, AccessLevel.SYSTEM_MODE);
    }
}