import { LightningElement, api, wire } from 'lwc';
import getQuickText from '@salesforce/apex/QuickTextService.getQuickText';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { FlowNavigationFinishEvent } from 'lightning/flowSupport'; // <-- Added Flow Support

export default class QuickText extends LightningElement {
    @api channelsToInclude = '';
    @api btnVariant = 'brand';
    @api channelsToFilter;
    
    // API property required to receive available Flow actions
    @api availableActions = []; 

    // Quick Text Properties
    @api message;
    @api quickTextLabel;
    @api selectedQuickText;
    @api recordId;

    quickText = [];
    quickTextOptions = [];
    isLoading = false;
    error;

    // Existing wire service to fetch Quick Text data
    @wire(getQuickText, { channelsToInclude: '$channelsToInclude' })
    wiredQuickText({ error, data }) {
        // ... (Existing implementation to process data) ...
        if (data) {
            this.quickText = data;
            this.quickTextOptions = data.map(qt => ({
                label: qt.Name,
                value: qt.Id,
                message: qt.Message
            }));
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.quickText = undefined;
            this.quickTextOptions = undefined;
            this.showNotification('Error', this.error.body.message, 'error');
        }
        this.isLoading = false;
    }

    handleQuickTextSelect(event) {
        this.selectedQuickText = event.detail.value;
        const selectedItem = this.quickText.find(qt => qt.Id === this.selectedQuickText);
        this.message = selectedItem ? selectedItem.Message : '';

        // Optional: Dispatch event if needed to update parent component/Flow variable
        // const selectEvent = new CustomEvent('quicktextselect', { detail: this.message });
        // this.dispatchEvent(selectEvent);
    }

    handleSend() {
        // 1. --- PLACE YOUR DATA SUBMISSION/SAVING LOGIC HERE ---
        // e.g., Call an Apex method to save the message, close a task, etc.
        console.log('Sending message:', this.message);
        
        // 2. Once submission is complete, call the function to finish the flow.
        this.handleFinish();
    }
    
    handleFinish() {
        if (this.availableActions.find(action => action === 'FINISH')) {
            const navigateFinishEvent = new FlowNavigationFinishEvent();
            this.dispatchEvent(navigateFinishEvent);
        } else {
            console.error('The FINISH action is not available. Cannot close the Flow.');
        }
    }

    showNotification(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(evt);
    }
}
