public with sharing class QuickTextController {
    
    @AuraEnabled(cacheable=true)
    public static List<QuickText> getQuickTexts(String category) {
        // Basic filtering example
        String query = 'SELECT Id, Name, Message, Category FROM QuickText';
        if (String.isNotBlank(category)) {
            query += ' WHERE Category = :category';
        }
        query += ' ORDER BY Name ASC LIMIT 50';
        return Database.query(query);
    }

    // NEW METHOD: Resolves the specific text based on the record context
    @AuraEnabled
    public static String getResolvedMessage(Id quickTextId, Id contextRecordId) {
        // 1. Fetch the raw message
        QuickText qt = [SELECT Message FROM QuickText WHERE Id = :quickTextId LIMIT 1];
        
        if (String.isBlank(contextRecordId)) {
            return qt.Message;
        }

        // 2. Resolve fields
        return MergeFieldService.resolveTextMessage(qt.Message, contextRecordId);
    }
}
