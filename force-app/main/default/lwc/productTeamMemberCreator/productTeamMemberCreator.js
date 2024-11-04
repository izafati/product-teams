import { LightningElement, wire, api } from "lwc";

import { getObjectInfo } from "lightning/uiObjectInfoApi";
import { getPicklistValues } from "lightning/uiObjectInfoApi";
import { CloseActionScreenEvent } from "lightning/actions";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

import PRODUCT_TEAM_MEMBER from "@salesforce/schema/ProductTeamMember__c";
import PRODUCT_ACCESS_LEVEL from "@salesforce/schema/ProductTeamMember__c.ProductAccessLevel__c";
import TEAM_MEMBER_ROLE from "@salesforce/schema/ProductTeamMember__c.TeamMemberRole__c";

import search from "@salesforce/apex/ProductTeamMemberController.search";
import getProductTeamMemberTypes from "@salesforce/apex/ProductTeamMemberController.getProductTeamMemberTypes";
import createProductTeamMember from "@salesforce/apex/ProductTeamMemberController.createProductTeamMember";
import checkUserPermission from "@salesforce/apex/ProductTeamMemberController.checkUserPermission";

import selectTeamMemberMessage from "@salesforce/label/c.PTM_Select_Team_Member_Message";
import selectTeamMemberRoleMessage from "@salesforce/label/c.PTM_Select_Team_Member_Role_Message";
import selectTeamMemberAccessMessage from "@salesforce/label/c.PTM_Select_Team_Member_Access_Message";
import teamMember from "@salesforce/label/c.PTM_Team_Member_Label";
import searchForMember from "@salesforce/label/c.PTM_Search_For_The_Member_Label";
import shareProductBtnLabel from "@salesforce/label/c.PTM_Share_Product_Btn_Label";
import fetchProductTeamMemberFailed from "@salesforce/label/c.PTM_Fetch_Product_Team_Member_Failed";
import searchProductTeamMemberFailed from "@salesforce/label/c.PTM_Search_Product_Team_Member_Failed";
import fetchProductAccessValuesFailed from "@salesforce/label/c.PTM_Fetch_Product_Access_Values_Failed";
import fetchProductRoleValuesFailed from "@salesforce/label/c.PTM_Fetch_Product_Role_Values_Failed";
import productTeamMemberCreationSuccess from "@salesforce/label/c.PTM_Product_Team_Member_Creation_Success";
import productTeamMemberCreationFailed from "@salesforce/label/c.PTM_Product_Team_Member_Creation_Failed";
import productTeamMemberManagementFailed from "@salesforce/label/c.PTM_Adding_Product_Team_Member_Not_Allowed";
import productTeamMemberCheckUserAccessFailed from "@salesforce/label/c.PTM_Check_User_Access_Failed";

export default class ProductTeamMemberCreator extends LightningElement {
  _recordId;
  _showSpinner = true;

  productTeamMemberTypes;
  selectedTeamMemberType;
  selectedTeamMemberTypeValue;
  memberId;
  accessLevelOptions;
  teamMemberRoleOptions;
  selectedAccessLevel;
  selectedTeamMemberRole;
  isButtonDisabled = true;
  selectedMember;
  hasAccess = false;

  labels = {
    selectTeamMemberMessage,
    selectTeamMemberRoleMessage,
    selectTeamMemberAccessMessage,
    teamMember,
    searchForMember,
    shareProductBtnLabel,
    fetchProductTeamMemberFailed,
    searchProductTeamMemberFailed,
    fetchProductAccessValuesFailed,
    fetchProductRoleValuesFailed,
    productTeamMemberCreationSuccess,
    productTeamMemberCreationFailed,
    productTeamMemberManagementFailed,
    productTeamMemberCheckUserAccessFailed
  };

  @api set recordId(value) {
    this._recordId = value;
    if (value) {
      this.checkUserAccess();
    }
  }

  get recordId() {
    return this._recordId;
  }

  @wire(getProductTeamMemberTypes)
  wiredProductTeamMemberTypes({ data, error }) {
    if (data) {
      this.productTeamMemberTypes = data;
    } else if (error) {
      console.error(this.labels.fetchProductTeamMemberFailed, error);
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Error",
          message: this.labels.fetchProductTeamMemberFailed,
          variant: "error"
        })
      );
    }
  }

  @wire(getObjectInfo, { objectApiName: PRODUCT_TEAM_MEMBER })
  objectInfo;

  @wire(getPicklistValues, {
    recordTypeId: "$objectInfo.data.defaultRecordTypeId",
    fieldApiName: PRODUCT_ACCESS_LEVEL
  })
  wiredAccessLevelValues({ error, data }) {
    if (data) {
      this.accessLevelOptions = data.values.map((value) => {
        return { label: value.label, value: value.value };
      });
    } else if (error) {
      console.error(this.labels.fetchProductAccessValuesFailed, error);
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Error",
          message: this.labels.fetchProductAccessValuesFailed,
          variant: "error"
        })
      );
    }
  }

  @wire(getPicklistValues, {
    recordTypeId: "$objectInfo.data.defaultRecordTypeId",
    fieldApiName: TEAM_MEMBER_ROLE
  })
  wiredTeamMemberRoleValues({ error, data }) {
    if (data) {
      this.teamMemberRoleOptions = data.values.map((value) => {
        return { label: value.label, value: value.value };
      });
    } else if (error) {
      console.error(this.labels.fetchProductRoleValuesFailed, error);
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Error",
          message: this.labels.fetchProductRoleValuesFailed,
          variant: "error"
        })
      );
    }
  }

  get isCreationButtonDisabled() {
    return !(
      this.selectedTeamMemberType &&
      this.memberId &&
      this.selectedAccessLevel
    );
  }

  handleAccessLevelChange(event) {
    this.selectedAccessLevel = event.detail.value;
  }

  handleTeamMemberRoleChange(event) {
    this.selectedTeamMemberRole = event.detail.value;
  }

  handleSelectionChange(event) {
    const selectedIds = event.detail;
    this.memberId = selectedIds[0];
  }

  async createProductMember() {
    try {
      await createProductTeamMember({
        productId: this._recordId,
        memberId: this.memberId,
        accessLevel: this.selectedAccessLevel,
        productTeamMemberLookupField:
          this.selectedTeamMemberType?.memberTypeLookupField,
        productTeamMemberRole: this.selectedTeamMemberRole
      });

      this.dispatchEvent(
        new ShowToastEvent({
          title: "Success",
          message: this.labels.productTeamMemberCreationSuccess,
          variant: "success"
        })
      );
    } catch (error) {
      console.error(this.labels.productTeamMemberCreationFailed, error);
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Error",
          message: this.labels.productTeamMemberCreationFailed,
          variant: "error"
        })
      );
    } finally {
      this.closeAction();
    }
  }

  handleTeamMemberTypeChange(event) {
    this.selectedTeamMemberType = this.productTeamMemberTypes.find(
      (type) => type.value === event.detail.value
    );
    this.selectedTeamMemberTypeValue = event.detail.value;
    this.memberId = null;
    const lookup = this.template.querySelector("c-lookup");
    if (lookup) {
      this.selectedMember = null;
      lookup.selection = [];
    }
  }

  async handleSearch(event) {
    const lookupElement = event.target;
    const { searchTerm, selectedIds } = event.detail;
    try {
      const results = await search({
        searchTerm: searchTerm,
        selectedIds: selectedIds,
        productTeamMemberTypeName: this.selectedTeamMemberType?.value
      });
      lookupElement.setSearchResults(results);
    } catch (error) {
      console.error(this.labels.searchProductTeamMemberFailed, error);
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Error",
          message: this.labels.searchProductTeamMemberFailed,
          variant: "error"
        })
      );
    }
  }

  closeAction() {
    this.dispatchEvent(new CloseActionScreenEvent());
  }

  async checkUserAccess() {
    let isError = false;
    let errorMessage;
    try {
      const data = await checkUserPermission({
        productId: this._recordId
      });
      
      if (data) {
        this.hasAccess = true;
      } else {
        isError = true;
        errorMessage = this.labels.productTeamMemberManagementFailed;
      }
    } catch(error) {
      isError = true;
      errorMessage = this.labels.productTeamMemberCheckUserAccessFailed;
      console.error(errorMessage, error);
    } finally {
      this._showSpinner = false;
      if (isError) {
        this.hasAccess = false;
        this.dispatchEvent(
          new ShowToastEvent({
            title: "Error",
            message: errorMessage,
            variant: "error"
          })
        );
        this.closeAction();
      }
    }
  }
}
