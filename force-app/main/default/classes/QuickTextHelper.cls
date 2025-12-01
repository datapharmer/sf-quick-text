public with sharing class QuickTextHelper {
    
    @AuraEnabled
    public static List<QuickText> getQuickText(String channels) {
        String query = 'SELECT Id, Name, Message, Category FROM QuickText';
        if (String.isNotBlank(channels)) {
            query += ' WHERE Channel INCLUDES (:channels)';
        }
        query += ' ORDER BY Name ASC';
        return Database.query(query);
    }

    @AuraEnabled
    public static String resolveQuickText(String text, Id recordId) {
        return MergeFieldService.resolveTextMessage(text, recordId);
    }
}
