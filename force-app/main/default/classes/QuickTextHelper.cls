public with sharing class QuickTextHelper {
    
    @AuraEnabled
    public static List<QuickText> getQuickText(String channels) {
        String query = 'SELECT Id, Name, Message, Category FROM QuickText';
        if (String.isNotBlank(channels)) {
            // Note: Ensure 'channels' passed from LWC matches picklist values allowed in the INCLUDES clause
            query += ' WHERE Channel INCLUDES (:channels)';
        }
        query += ' ORDER BY Name ASC';
        return Database.query(query);
    }

    @AuraEnabled
    public static String resolveQuickText(String text, Id recordId) {
        // Now calls the newly created class
        return MergeFieldService.resolveTextMessage(text, recordId);
    }
}
