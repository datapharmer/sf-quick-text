import { LightningElement, api, track } from 'lwc';
import { createRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import CASE_COMMENT_OBJECT from '@salesforce/schema/CaseComment';
import PARENT_ID_FIELD from '@salesforce/schema/CaseComment.ParentId';
import COMMENT_BODY_FIELD from '@salesforce/schema/CaseComment.CommentBody';
import IS_PUBLISHED_FIELD from '@salesforce/schema/CaseComment.IsPublished';

export default class CaseInternalCommentPublisher extends LightningElement {
    @api recordId; // Automatically gets the Case Id from the record page
    @track commentBody = '';
    @track isSaving = false;

    // 1. Handle manual typing
    handleTextChange(event) {
        this.commentBody = event.target.value;
    }

    // 2. Handle the Custom Event from sf-quick-text
    handleQuickTextSelect(event) {
        // The repo dispatches 'quicktextselect' with detail.value containing the text
        const selectedText = event.detail.value;
        
        // Append text to existing body (or replace, depending on preference)
        if (selectedText) {
            this.commentBody = this.commentBody 
                ? this.commentBody + '\n' + selectedText 
                : selectedText;
        }
    }

    // 3. Save the CaseComment Record
    async handleSave() {
        if (!this.commentBody) {
            this.showToast('Error', 'Comment cannot be empty', 'error');
            return;
        }

        this.isSaving = true;

        const fields = {};
        fields[PARENT_ID_FIELD.fieldApiName] = this.recordId;
        fields[COMMENT_BODY_FIELD.fieldApiName] = this.commentBody;
        fields[IS_PUBLISHED_FIELD.fieldApiName] = false; // Internal = false

        const recordInput = { apiName: CASE_COMMENT_OBJECT.objectApiName, fields };

        try {
            await createRecord(recordInput);
            this.showToast('Success', 'Internal comment posted', 'success');
            this.commentBody = ''; // Clear the input
            
            // Optional: Refresh the page view to show the new comment in the related list
            // usage of notifyRecordUpdateAvailable or RefreshEvent depends on your specific setup
        } catch (error) {
            this.showToast('Error', error.body.message, 'error');
        } finally {
            this.isSaving = false;
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }
}
