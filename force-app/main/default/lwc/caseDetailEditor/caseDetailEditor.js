import { LightningElement, api, track, wire } from 'lwc';
import { getRecord, updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';

// Case object and fields
import CASE_OBJECT from '@salesforce/schema/Case';
import CASE_ID_FIELD from '@salesforce/schema/Case.Id';
import CASE_ORIGIN_FIELD from '@salesforce/schema/Case.Origin';
import CASE_ASSET_FIELD from '@salesforce/schema/Case.AssetId';
import CASE_STATUS_FIELD from '@salesforce/schema/Case.Status';
import CASE_PRIORITY_FIELD from '@salesforce/schema/Case.Priority';
import CASE_SUBJECT_FIELD from '@salesforce/schema/Case.Subject';
import CASE_DESCRIPTION_FIELD from '@salesforce/schema/Case.Description';
import CASE_CLOSE_SUMMARY_FIELD from '@salesforce/schema/Case.SDO_Service_Close_Summary__c';
import CASE_FEEDBACK_FIELD from '@salesforce/schema/Case.Case_Feedback__c';
import CASE_OWNER_FIELD from '@salesforce/schema/Case.OwnerId';
import CASE_CONTACT_FIELD from '@salesforce/schema/Case.ContactId';
import CASE_REASON_FIELD from '@salesforce/schema/Case.Reason';
import CASE_LANGUAGE_FIELD from '@salesforce/schema/Case.Language';
import CASE_ESCALATED_FIELD from '@salesforce/schema/Case.IsEscalated';

const CASE_FIELDS = [
    CASE_ID_FIELD,
    CASE_ORIGIN_FIELD,
    CASE_ASSET_FIELD,
    CASE_STATUS_FIELD,
    CASE_PRIORITY_FIELD,
    CASE_SUBJECT_FIELD,
    CASE_DESCRIPTION_FIELD,
    CASE_CLOSE_SUMMARY_FIELD,
    CASE_FEEDBACK_FIELD,
    CASE_OWNER_FIELD,
    CASE_CONTACT_FIELD,
    CASE_REASON_FIELD,
    CASE_LANGUAGE_FIELD,
    CASE_ESCALATED_FIELD
];

export default class CaseDetailEditor extends LightningElement {
    @api recordId;
    @track caseRecord = {};
    @track isLoading = false;
    @track originOptions = [];
    @track statusOptions = [];
    @track priorityOptions = [];
    @track reasonOptions = [];
    @track languageOptions = [];

    @wire(getRecord, { recordId: '$recordId', fields: CASE_FIELDS })
    wiredCase({ error, data }) {
        if (data) {
            this.caseRecord = { ...data.fields };
        } else if (error) {
            this.showToast('Error', 'Error loading case record', 'error');
        }
    }

    @wire(getObjectInfo, { objectApiName: CASE_OBJECT })
    caseObjectInfo;

    @wire(getPicklistValues, { recordTypeId: '$caseObjectInfo.data.defaultRecordTypeId', fieldApiName: CASE_ORIGIN_FIELD })
    originPicklistValues({ data, error }) {
        if (data) {
            this.originOptions = data.values;
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$caseObjectInfo.data.defaultRecordTypeId', fieldApiName: CASE_STATUS_FIELD })
    statusPicklistValues({ data, error }) {
        if (data) {
            this.statusOptions = data.values;
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$caseObjectInfo.data.defaultRecordTypeId', fieldApiName: CASE_PRIORITY_FIELD })
    priorityPicklistValues({ data, error }) {
        if (data) {
            this.priorityOptions = data.values;
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$caseObjectInfo.data.defaultRecordTypeId', fieldApiName: CASE_REASON_FIELD })
    reasonPicklistValues({ data, error }) {
        if (data) {
            this.reasonOptions = data.values;
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$caseObjectInfo.data.defaultRecordTypeId', fieldApiName: CASE_LANGUAGE_FIELD })
    languagePicklistValues({ data, error }) {
        if (data) {
            this.languageOptions = data.values;
        }
    }

    handleInputChange(event) {
        const fieldName = event.target.dataset.field;
        const value = event.target.type === 'checkbox' ? event.target.checked : event.target.value;
        
        this.caseRecord = {
            ...this.caseRecord,
            [fieldName]: { ...this.caseRecord[fieldName], value: value }
        };
    }

    handleSave() {
        this.isLoading = true;
        
        const fields = {};
        fields[CASE_ID_FIELD.fieldApiName] = this.recordId;
        
        // Map all the updated field values
        Object.keys(this.caseRecord).forEach(fieldName => {
            if (this.caseRecord[fieldName] && this.caseRecord[fieldName].value !== undefined) {
                const apiName = fieldName.replace('__r', '__c'); // Handle lookup field names
                fields[apiName] = this.caseRecord[fieldName].value;
            }
        });

        const recordInput = { fields };

        updateRecord(recordInput)
            .then(() => {
                this.showToast('Success', 'Case updated successfully', 'success');
                this.dispatchEvent(new CustomEvent('save'));
            })
            .catch(error => {
                this.showToast('Error', 'Error updating case: ' + (error.body?.message || error.message), 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    handleCancel() {
        this.dispatchEvent(new CustomEvent('cancel'));
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant
            })
        );
    }

    get subjectValue() {
        return this.caseRecord.Subject?.value || '';
    }

    get descriptionValue() {
        return this.caseRecord.Description?.value || '';
    }

    get closeSummaryValue() {
        return this.caseRecord.CloseSummary?.value || '';
    }

    get feedbackValue() {
        return this.caseRecord.CaseFeedback?.value || '';
    }

    get originValue() {
        return this.caseRecord.Origin?.value || '';
    }

    get statusValue() {
        return this.caseRecord.Status?.value || '';
    }

    get priorityValue() {
        return this.caseRecord.Priority?.value || '';
    }

    get reasonValue() {
        return this.caseRecord.Reason?.value || '';
    }

    get languageValue() {
        return this.caseRecord.Language?.value || '';
    }

    get escalatedValue() {
        return this.caseRecord.IsEscalated?.value || false;
    }

    get contactValue() {
        return this.caseRecord.ContactId?.value || '';
    }

    get ownerValue() {
        return this.caseRecord.OwnerId?.value || '';
    }

    get assetValue() {
        return this.caseRecord.AssetId?.value || '';
    }
}