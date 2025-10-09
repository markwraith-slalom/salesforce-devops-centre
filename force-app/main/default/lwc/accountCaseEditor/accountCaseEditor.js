import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import { NavigationMixin } from 'lightning/navigation';
import getCases from '@salesforce/apex/AccountCaseEditorController.getCases';
import getCasePicklistValues from '@salesforce/apex/AccountCaseEditorController.getCasePicklistValues';
import updateCase from '@salesforce/apex/AccountCaseEditorController.updateCase';

export default class AccountCaseEditor extends NavigationMixin(LightningElement) {
    @api recordId; // Account Id
    @track cases = [];
    @track isLoading = false;
    @track error;
    @track selectedCaseId = null;
    @track showDetailModal = false;
    @track picklistValues = {};

    // Column definitions for the enhanced datatable
    columns = [
        { 
            label: 'Case Number', 
            fieldName: 'CaseNumber', 
            type: 'text',
            cellAttributes: { class: 'slds-text-title_caps' }
        },
        { 
            label: 'Subject', 
            fieldName: 'Subject', 
            type: 'text',
            editable: true 
        },
        { 
            label: 'Status', 
            fieldName: 'Status', 
            type: 'picklist',
            typeAttributes: {
                fieldName: 'Status',
                keyField: 'Id',
                keyFieldValue: { fieldName: 'Id' },
                picklistValues: { fieldName: 'statusOptions' },
                editable: true
            }
        },
        { 
            label: 'Priority', 
            fieldName: 'Priority', 
            type: 'picklist',
            typeAttributes: {
                fieldName: 'Priority',
                keyField: 'Id',
                keyFieldValue: { fieldName: 'Id' },
                picklistValues: { fieldName: 'priorityOptions' },
                editable: true
            }
        },
        { 
            label: 'Origin', 
            fieldName: 'Origin', 
            type: 'picklist',
            typeAttributes: {
                fieldName: 'Origin',
                keyField: 'Id',
                keyFieldValue: { fieldName: 'Id' },
                picklistValues: { fieldName: 'originOptions' },
                editable: true
            }
        },
        { 
            label: 'Contact', 
            fieldName: 'ContactName', 
            type: 'text'
        },
        { 
            label: 'Owner', 
            fieldName: 'OwnerName', 
            type: 'text'
        },
        { 
            label: 'Escalated', 
            fieldName: 'IsEscalated', 
            type: 'boolean',
            editable: true 
        },
        {
            type: 'action',
            typeAttributes: { rowActions: this.getRowActions }
        }
    ];

    @wire(getCases, { accountId: '$recordId' })
    wiredCases(result) {
        this.casesWireResult = result;
        if (result.data) {
            this.cases = this.enhanceCasesWithPicklistValues(result.data);
            this.error = undefined;
        } else if (result.error) {
            this.error = result.error;
            this.cases = [];
        }
    }

    @wire(getCasePicklistValues)
    wiredPicklistValues({ error, data }) {
        if (data) {
            this.picklistValues = data;
            // Re-enhance cases if they're already loaded
            if (this.casesWireResult?.data) {
                this.cases = this.enhanceCasesWithPicklistValues(this.casesWireResult.data);
            }
        } else if (error) {
            console.error('Error loading picklist values:', error);
        }
    }

    enhanceCasesWithPicklistValues(casesData) {
        return casesData.map(caseRecord => ({
            ...caseRecord,
            statusOptions: this.picklistValues.Status || [],
            priorityOptions: this.picklistValues.Priority || [],
            originOptions: this.picklistValues.Origin || []
        }));
    }

    getRowActions(row, doneCallback) {
        const actions = [
            { label: 'Edit Details', name: 'editDetails' },
            { label: 'View', name: 'view' }
        ];
        doneCallback(actions);
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        
        switch (actionName) {
            case 'editDetails':
                this.editCaseDetails(row);
                break;
            case 'view':
                this.viewCase(row);
                break;
            default:
        }
    }

    editCaseDetails(caseRecord) {
        // Open a modal to edit additional case fields
        this.selectedCaseId = caseRecord.Id;
        this.showDetailModal = true;
    }

    viewCase(caseRecord) {
        // Navigate to Case record page
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: caseRecord.Id,
                objectApiName: 'Case',
                actionName: 'view'
            }
        });
    }

    handleSave(event) {
        this.isLoading = true;
        const draftValues = event.detail.draftValues;
        
        const promises = draftValues.map(draft => {
            return updateCase({ caseData: draft });
        });

        Promise.all(promises)
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Cases updated successfully',
                        variant: 'success'
                    })
                );
                // Refresh the cases data
                return refreshApex(this.casesWireResult);
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error updating cases',
                        message: error.body?.message || 'An error occurred',
                        variant: 'error'
                    })
                );
            })
            .finally(() => {
                this.isLoading = false;
                const datatable = this.template.querySelector('c-enhanced-datatable');
                if (datatable) {
                    datatable.draftValues = [];
                }
            });
    }

    handlePicklistChange(event) {
        // Handle picklist changes from enhanced datatable
        const draftValues = event.detail.draftValues;
        this.handleSave({ detail: { draftValues } });
    }

    handleCancel() {
        const datatable = this.template.querySelector('c-enhanced-datatable');
        if (datatable) {
            datatable.draftValues = [];
        }
    }

    closeModal() {
        this.showDetailModal = false;
        this.selectedCaseId = null;
    }

    handleModalSave() {
        // Refresh the cases after modal save
        refreshApex(this.casesWireResult);
        this.closeModal();
    }

    get hasCases() {
        return this.cases && this.cases.length > 0;
    }

    get selectedCase() {
        return this.cases.find(c => c.Id === this.selectedCaseId);
    }
}