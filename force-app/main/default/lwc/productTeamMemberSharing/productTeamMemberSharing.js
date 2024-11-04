import { LightningElement, api, track } from "lwc";
import fetchProductTeamMemberAccess from "@salesforce/apex/ProductTeamMemberController.fetchProductTeamMemberAccess";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

import productTeamMember from "@salesforce/label/c.PTM_Product_Team_Member_Label";
import productTeamMemberAccess from "@salesforce/label/c.PTM_Product_Team_Member_Access_Label";
import productTeamRole from "@salesforce/label/c.PTM_Product_Team_Role_Label";
import productTeamAccess from "@salesforce/label/c.PTM_Product_Team_Access_Label";
import productSharingReason from "@salesforce/label/c.PTM_Product_Sharing_Label";
import fetchProductTeamMemberRecordsFailed from "@salesforce/label/c.PTM_Fetch_Product_Team_Member_Records_Failed";

const COLUMNS = [
  { label: productTeamMember, fieldName: "name", type: "text" },
  { label: productTeamRole, fieldName: "role", type: "text" },
  { label: productTeamAccess, fieldName: "access", type: "text" },
  { label: productSharingReason, fieldName: "reason", type: "text" }
];
export default class ProductTeamMemberSharing extends LightningElement {
  @track data = [];
  _recordId;
  _showSpinner = true;

  columns = COLUMNS;

  @api set recordId(value) {
    this._recordId = value;
    if (value) {
      this.loadData();
    }
  }

  get recordId() {
    return this.currectRecordId;
  }

  labels = {
    productTeamMemberAccess,
    fetchProductTeamMemberRecordsFailed
  };

  async loadData() {
    try {
      this.data = await fetchProductTeamMemberAccess({
        productId: this._recordId
      });
    } catch (error) {
      console.error(this.labels.fetchProductTeamMemberRecordsFailed, error);
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Error",
          message: this.labels.fetchProductTeamMemberRecordsFailed,
          variant: "error"
        })
      );
    } finally {
      this._showSpinner = false;
    }
  }
}
