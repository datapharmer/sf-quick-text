import { api, LightningElement, wire } from 'lwc';
import { FlowAttributeChangeEvent } from 'lightning/flowSupport'; 
import getQuickText from '@salesforce/apex/QuickTextHelper.getQuickText';
// Import the new resolve method
import resolveQuickText from '@salesforce/apex/QuickTextHelper.resolveQuickText';

export default class QuickText extends LightningElement {

    // IMPORTANT: Allow Salesforce to inject the current record ID
    @api recordId;
    
    @api channelsToInclude = '';
    @api btnVariant = 'brand';
    @api flowOutputText = '';

    quickTextValues = [];
    showQuickTextModal = false;
    selectedQuickText = ''; // This holds the RAW text (with merge fields)
    searchQuickTextKey = '';

    connectedCallback() {
        this.fetchQuickText();
    }

    get quickTextOptions() {
        if (this.searchQuickTextKey) {
            return this.quickTextValues.filter(item => (item?.label?.toLowerCase().includes(this.searchQuickTextKey)));
        }
        return this.quickTextValues;
    }

    async fetchQuickText() {
        try {
            const data = await getQuickText({
                channels: this.channelsToInclude
            });
            // Map Name to Label, and Message (raw) to Value
            this.quickTextValues = data.map(item => ({label: item.Name, value: item.Message}));
        } catch (error) {
            console.error('Error fetching QuickText:', error);
        }
    }

    handleAddQuickText() {
        this.showQuickTextModal = true;
    }

    closeQuickTextModal() {
        this.showQuickTextModal = false;
        this.selectedQuickText = '';
        this.searchQuickTextKey = '';
    }

    handleQuickTextSearch(event) {
        this.searchQuickTextKey = event.detail.value?.toLowerCase();
    }

    handleQuickTextSelect(event) {
        // Stores the raw message (e.g., "Hello {!Contact.FirstName}")
        this.selectedQuickText = event.detail.value;
    }
    
    async AddSelectedQuickText() {
        let finalText = this.selectedQuickText;

        // ONLY resolve if we have a recordId and text to resolve
        if (this.recordId && finalText && finalText.includes('{!')) {
            try {
                // Call Apex to resolve fields
                finalText = await resolveQuickText({ 
                    text: this.selectedQuickText, 
                    recordId: this.recordId 
                });
            } catch (error) {
                console.error('Error resolving merge fields', error);
                // Fallback: If resolution fails, we still send the raw text
                finalText = this.selectedQuickText; 
            }
        }

        // 1. Dispatch Custom Event (for standard LWC usage)
        this.dispatchEvent(
            new CustomEvent('quicktextselect', {
                detail: {
                    value: finalText
                }
            })
        );

        // 2. Update Flow Attribute (for Flow usage)
        this.flowOutputText = finalText; 
        this.dispatchEvent(
            new FlowAttributeChangeEvent('flowOutputText', this.flowOutputText)
        );

        this.closeQuickTextModal();
    }
}
