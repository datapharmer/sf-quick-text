import { api, LightningElement } from 'lwc';
import { FlowAttributeChangeEvent } from 'lightning/flowSupport'; 
import getQuickText from '@salesforce/apex/QuickTextHelper.getQuickText'

export default class QuickText extends LightningElement {

    @api channelsToInclude = ''
    @api btnVariant = 'brand'

    @api flowOutputText = '';

    quickTextValues = []
    showQuickTextModal = false
    selectedQuickText = ''
    searchQuickTextKey = ''

    connectedCallback() {
        this.fetchQuickText()
    }

    get quickTextOptions() {
        if (this.searchQuickTextKey) {
            return this.quickTextValues.filter(item => (item?.label?.toLowerCase().includes(this.searchQuickTextKey)))
        }
        return this.quickTextValues
    }

    async fetchQuickText() {
        try {
            this.quickTextValues = (await getQuickText({
                channels: this.channelsToInclude
            })).map(item => ({label:item.Name, value:item.Message}))

            console.log(JSON.parse(JSON.stringify(this.quickTextValues)))
        } catch (error) {
            console.log(error)
        }
    }

    handleAddQuickText() {
        this.showQuickTextModal = true
    }
    closeQuickTextModal() {
        this.showQuickTextModal = false
        this.selectedQuickText = ''
    }

    handleQuickTextSearch(event) {
        this.searchQuickTextKey = event.detail.value?.toLowerCase()
    }
    handleQuickTextSelect(event) {
        this.selectedQuickText = event.detail.value
    }
    
    AddSelectedQuickText() {
        this.dispatchEvent(
            new CustomEvent('quicktextselect', {
                detail: {
                    value: this.selectedQuickText
                }
            })
        )

        this.flowOutputText = this.selectedQuickText; 
        this.dispatchEvent(
            new FlowAttributeChangeEvent('flowOutputText', this.flowOutputText)
        );

        this.selectedQuickText = ''
        this.searchQuickTextKey = ''

        this.closeQuickTextModal()
    }
}
