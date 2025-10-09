import LightningDatatable from "lightning/datatable";
import picklistColumnType from "./picklistColumnType.html";

/**
 * Enhanced LightningDatatable that supports dynamic picklist columns
 */
export default class EnhancedDatatable extends LightningDatatable {
    static customTypes = {
        picklist: {
            template: picklistColumnType,
            standardCellLayout: false,
            typeAttributes: ['fieldName', 'keyField', 'keyFieldValue', 'picklistValues', 'editable']
        }
    };

    editMode = false;

    get options() {
        if (!this.typeAttributes?.picklistValues) return [];
        return this.typeAttributes.picklistValues.map(item => ({
            label: item.label,
            value: item.value
        }));
    }

    handleEdit() {
        if (this.typeAttributes?.editable) {
            this.editMode = true;
            // Focus on the combobox after rendering
            setTimeout(() => {
                const combobox = this.template.querySelector('lightning-combobox');
                if (combobox) {
                    combobox.classList.remove('slds-hide');
                    combobox.focus();
                }
            }, 0);
        }
    }

    handleChange(event) {
        const newValue = event.detail.value;
        this.value = newValue;
        this.editMode = false;

        // Hide combobox
        const combobox = this.template.querySelector('lightning-combobox');
        if (combobox) {
            combobox.classList.add('slds-hide');
        }

        // Dispatch custom event similar to lightning-datatable's oncellchange
        const changeEvent = new CustomEvent('picklistchange', {
            composed: true,
            bubbles: true,
            detail: {
                draftValues: [{
                    [this.typeAttributes.keyField]: this.typeAttributes.keyFieldValue,
                    [this.typeAttributes.fieldName]: newValue
                }]
            }
        });
        this.dispatchEvent(changeEvent);
    }

    handleCancel() {
        this.editMode = false;
        const combobox = this.template.querySelector('lightning-combobox');
        if (combobox) {
            combobox.classList.add('slds-hide');
        }
    }
}