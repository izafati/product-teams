/**
 * @description       : utility class holds logic for getting the users access sharing level
 **/
public with sharing class ProductAccessUtility {
  public static final Map<String, String> ACCESS_LEVELS = new Map<String, String>{ 'Read' => 'Read', 'Edit' => 'Edit', 'Full_Access' => 'Full Access' };
  private static final String PRODUCT_TEAM_MEMBER_TYPE_ID = 'ProductTeamMemberTypeId';
  private static final String PRODUCT_ACCESS_LEVEL = 'ProductAccessLevel';
  private static final String TEAM_MEMBER_ROLE = 'TeamMemberRole';
  private static final String USER_NAME = 'UserName';
  private static final String SHARING_REASON = 'SharingReason';
  public static List<Id> userIds = new List<Id>();

  public static Map<Id, List<ProductTeamMemberAccessWrapper>> fetchProductTeamMemberAccess(Set<Id> productIds, List<Id> userIdsList) {
    if (!userIdsList.isEmpty()) {
      userIds = userIdsList;
    }
    return fetchProductTeamMemberAccess(productIds);
  }

  public static Map<Id, List<ProductTeamMemberAccessWrapper>> fetchProductTeamMemberAccess(Set<Id> productIds) {
    try {
      // Fetch all the product team members for the given product IDs
      List<ProductTeamMember__c> productTeamMembers = [
        SELECT Id, Product__c, ProductAccessLevel__c, TeamMemberRole__c, PublicGroup__c, Queue__c, Role__c, Territory__c, PermissionSet__c, User__c, User__r.Name, Reason__c
        FROM ProductTeamMember__c
        WHERE Product__c IN :productIds
        WITH USER_MODE
      ];

      // Collect all related Ids in sets for bulk querying
      Set<Id> roleIds = new Set<Id>();
      Set<Id> territoryIds = new Set<Id>();
      Set<Id> groupIds = new Set<Id>();
      Set<Id> customPermissionIds = new Set<Id>();

      for (ProductTeamMember__c member : productTeamMembers) {
        if (member.Role__c != null)
          roleIds.add(member.Role__c);
        if (member.Territory__c != null)
          territoryIds.add(member.Territory__c);
        if (member.PublicGroup__c != null)
          groupIds.add(member.PublicGroup__c);
        if (member.Queue__c != null)
          groupIds.add(member.Queue__c);
        if (member.PermissionSet__c != null)
          customPermissionIds.add(member.PermissionSet__c);
      }

      String query;
      String filter;
      String formattedQuery;

      // Query users by role
      Map<Id, List<User>> usersByRole = new Map<Id, List<User>>();
      if (!roleIds.isEmpty()) {
        query = 'SELECT Id, Name, UserRoleId FROM User WHERE UserRoleId IN :roleIds {0} WITH USER_MODE';
        filter = 'AND Id IN :userIds';
        formattedQuery = String.format(query, new List<String>{ !userIds.isEmpty() ? filter : '' });
        List<User> userRoles = Database.query(formattedQuery);
        for (User user : userRoles) {
          if (!usersByRole.containsKey(user.UserRoleId)) {
            usersByRole.put(user.UserRoleId, new List<User>());
          }
          usersByRole.get(user.UserRoleId).add(user);
        }
      }

      // Query users by territory
      Map<Id, List<UserTerritory2Association>> usersByTerritory = new Map<Id, List<UserTerritory2Association>>();
      if (!territoryIds.isEmpty()) {
        query = 'SELECT Id, UserId, User.Name, Territory2Id FROM UserTerritory2Association WHERE Territory2Id IN :territoryIds {0} WITH USER_MODE';
        filter = 'AND UserId IN :userIds';
        formattedQuery = String.format(query, new List<String>{ !userIds.isEmpty() ? filter : '' });
        List<UserTerritory2Association> territoryUsers = Database.query(formattedQuery);
        for (UserTerritory2Association uta : territoryUsers) {
          if (!usersByTerritory.containsKey(uta.Territory2Id)) {
            usersByTerritory.put(uta.Territory2Id, new List<UserTerritory2Association>());
          }
          usersByTerritory.get(uta.Territory2Id).add(uta);
        }
      }

      // Query users by group
      Map<Id, List<GroupMember>> usersByGroup = new Map<Id, List<GroupMember>>();
      if (!groupIds.isEmpty()) {
        query = 'SELECT GroupId, UserOrGroupId, UserOrGroup.Name FROM GroupMember WHERE GroupId IN :groupIds {0} WITH USER_MODE';
        filter = 'AND UserOrGroupId IN :userIds';
        formattedQuery = String.format(query, new List<String>{ !userIds.isEmpty() ? filter : '' });
        List<GroupMember> groupMembers = Database.query(formattedQuery);
        for (GroupMember gm : groupMembers) {
          if (!usersByGroup.containsKey(gm.GroupId)) {
            usersByGroup.put(gm.GroupId, new List<GroupMember>());
          }
          usersByGroup.get(gm.GroupId).add(gm);
        }
      }

      // Query users by permisison set
      Map<Id, List<PermissionSetAssignment>> usersByPermissionSet = new Map<Id, List<PermissionSetAssignment>>();
      if (!customPermissionIds.isEmpty()) {
        query = 'SELECT PermissionSetId, AssigneeId, Assignee.Name FROM PermissionSetAssignment WHERE PermissionSetId IN :customPermissionIds {0} WITH USER_MODE';
        filter = 'AND AssigneeId IN :userIds';
        formattedQuery = String.format(query, new List<String>{ !userIds.isEmpty() ? filter : '' });
        List<PermissionSetAssignment> permissionSetAssignments = Database.query(formattedQuery);
        for (PermissionSetAssignment psa : permissionSetAssignments) {
          if (!usersByPermissionSet.containsKey(psa.PermissionSetId)) {
            usersByPermissionSet.put(psa.PermissionSetId, new List<PermissionSetAssignment>());
          }
          usersByPermissionSet.get(psa.PermissionSetId).add(psa);
        }
      }

      // Maps to store access level details for each team member type
      Map<Id, Map<Id, Map<String, String>>> userTeamMemberDetailsMapByProduct = new Map<Id, Map<Id, Map<String, String>>>();

      // Populate the maps with the fetched product team members
      for (ProductTeamMember__c member : productTeamMembers) {
        Id productId = member.Product__c;

        if (!userTeamMemberDetailsMapByProduct.containsKey(productId)) {
          userTeamMemberDetailsMapByProduct.put(productId, new Map<Id, Map<String, String>>());
        }

        if (member.User__c != null && (userIds.isEmpty() || userIds.contains(member.User__c))) {
          populateAccessLevelMap(userTeamMemberDetailsMapByProduct.get(productId), member.User__c, member.Id, member.ProductAccessLevel__c, member.User__r.Name, member.TeamMemberRole__c, member.Reason__c);
        }

        if (member.Role__c != null && usersByRole.containsKey(member.Role__c)) {
          for (User user : usersByRole.get(member.Role__c)) {
            populateAccessLevelMap(userTeamMemberDetailsMapByProduct.get(productId), user.Id, member.Id, member.ProductAccessLevel__c, user.Name, member.TeamMemberRole__c, member.Reason__c);
          }
        }

        if (member.Territory__c != null && usersByTerritory.containsKey(member.Territory__c)) {
          for (UserTerritory2Association uta : usersByTerritory.get(member.Territory__c)) {
            populateAccessLevelMap(userTeamMemberDetailsMapByProduct.get(productId), uta.UserId, member.Id, member.ProductAccessLevel__c, uta.User.Name, member.TeamMemberRole__c, member.Reason__c);
          }
        }

        if (member.PublicGroup__c != null && usersByGroup.containsKey(member.PublicGroup__c)) {
          for (GroupMember gm : usersByGroup.get(member.PublicGroup__c)) {
            if (gm.UserOrGroupId.getSObjectType() == User.SObjectType) {
              populateAccessLevelMap(userTeamMemberDetailsMapByProduct.get(productId), gm.UserOrGroupId, member.Id, member.ProductAccessLevel__c, gm.UserOrGroup.Name, member.TeamMemberRole__c, member.Reason__c);
            }
          }
        }

        if (member.Queue__c != null && usersByGroup.containsKey(member.Queue__c)) {
          for (GroupMember gmq : usersByGroup.get(member.Queue__c)) {
              if (gmq.UserOrGroupId.getSObjectType() == User.SObjectType) {
                  populateAccessLevelMap(userTeamMemberDetailsMapByProduct.get(productId), gmq.UserOrGroupId, member.Id, member.ProductAccessLevel__c, gmq.UserOrGroup.Name, member.TeamMemberRole__c, member.Reason__c);
              }
          }
        }

        if (member.PermissionSet__c != null && usersByPermissionSet.containsKey(member.PermissionSet__c)) {
          for (PermissionSetAssignment psa : usersByPermissionSet.get(member.PermissionSet__c)) {
            if (psa.AssigneeId.getSObjectType() == User.SObjectType) {
              populateAccessLevelMap(userTeamMemberDetailsMapByProduct.get(productId), psa.AssigneeId, member.Id, member.ProductAccessLevel__c, psa.Assignee.Name, member.TeamMemberRole__c, member.Reason__c);
            }
          }
        }
      }

      // Aggregate user access by product ID
      Map<Id, List<ProductTeamMemberAccessWrapper>> productTeamMemberAccessMap = new Map<Id, List<ProductTeamMemberAccessWrapper>>();
      for (Id productId : productIds) {
        List<ProductTeamMemberAccessWrapper> accessList = new List<ProductTeamMemberAccessWrapper>();

        if (userTeamMemberDetailsMapByProduct.containsKey(productId)) {
          for (Id userId : userTeamMemberDetailsMapByProduct.get(productId).keySet()) {
            String memberTypeId = userTeamMemberDetailsMapByProduct.get(productId).get(userId).get(PRODUCT_TEAM_MEMBER_TYPE_ID);
            String productAccessLevel = userTeamMemberDetailsMapByProduct.get(productId).get(userId).get(PRODUCT_ACCESS_LEVEL);
            String teamMemberRole = userTeamMemberDetailsMapByProduct.get(productId).get(userId).get(TEAM_MEMBER_ROLE);
            String userName = userTeamMemberDetailsMapByProduct.get(productId).get(userId).get(USER_NAME);
            String reason = userTeamMemberDetailsMapByProduct.get(productId).get(userId).get(SHARING_REASON);
            accessList.add(new ProductTeamMemberAccessWrapper(memberTypeId, userId, userName, teamMemberRole, productAccessLevel, reason));
          }
        }

        if (!accessList.isEmpty()) {
          productTeamMemberAccessMap.put(productId, accessList);
        }
      }

      return productTeamMemberAccessMap;
    } catch (Exception e) {
      throw new AuraHandledException('Error while fetching for Product Team Member Access: ' + e.getMessage());
    }
  }

  private static void populateAccessLevelMap(Map<Id, Map<String, String>> accessLevelMap, Id objectId, String productTeamMemberTypeId, String newAccessLevel, String userName, String teamMemberRole, String reason) {
    String currentAccessLevel = accessLevelMap.get(objectId)?.get(PRODUCT_ACCESS_LEVEL);
    if (currentAccessLevel == null || isHigherAccessLevel(newAccessLevel, currentAccessLevel)) {
      Map<String, String> details = new Map<String, String>();
      details.put(PRODUCT_TEAM_MEMBER_TYPE_ID, productTeamMemberTypeId);
      details.put(TEAM_MEMBER_ROLE, teamMemberRole);
      details.put(PRODUCT_ACCESS_LEVEL, newAccessLevel);
      details.put(USER_NAME, userName);
      details.put(SHARING_REASON, reason);
      accessLevelMap.put(objectId, details);
    }
  }

  private static Boolean isHigherAccessLevel(String newAccessLevel, String currentAccessLevel) {
    List<String> accessLevelsList = ACCESS_LEVELS.values();
    Integer newAccessIndex = accessLevelsList.indexOf(newAccessLevel);
    Integer currentAccessIndex = accessLevelsList.indexOf(currentAccessLevel);
    return newAccessIndex > currentAccessIndex;
  }

  /**
   * @description checks the user product access based on if he is the creator of the record, has modify all data or is part of the product team member
   * @param userId
   * @param wrapperUserList
   * @param permissableAccesses
   * @return Boolean
   **/
  public static Boolean checkUserProductAccess(List<ProductTeamMemberAccessWrapper> wrapperUserList, List<String> permissableAccesses) {
    Boolean permissionGranted = false;
    if (wrapperUserList != null && !wrapperUserList.isEmpty()) {
      ProductTeamMemberAccessWrapper wrapperUser = wrapperUserList.get(0);
      if (permissableAccesses.contains(wrapperUser.access)) {
        permissionGranted = true;
      }
    }
    return permissionGranted;
  }

  /**
   * @description checks if the user has modify all data permission
   * @param userId
   * @return Boolean
   **/
  public static Boolean hasModifyAllData(Id userId) {
    List<PermissionSetAssignment> modifyAllDataPSAs = [
      SELECT AssigneeId
      FROM PermissionSetAssignment
      WHERE PermissionSet.PermissionsModifyAllData = TRUE AND AssigneeId = :userId
      WITH USER_MODE
    ];

    return !modifyAllDataPSAs.isEmpty();
  }
}
