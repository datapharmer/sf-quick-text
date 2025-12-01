public with sharing class MergeFieldService {
    
    // Pattern to match merge fields like {!Object.Field}
    private static final Pattern MERGE_FIELD_PATTERN = Pattern.compile('\\{!(.*?)\\}');

    public static String resolveTextMessage(String text, Id recordId) {
        if (String.isBlank(text) || recordId == null) {
            return text;
        }

        // 1. Find all merge tokens
        Matcher matcher = MERGE_FIELD_PATTERN.matcher(text);
        Set<String> mergeFields = new Set<String>();
        while (matcher.find()) {
            mergeFields.add(matcher.group(1)); // Extract "Object.Field"
        }

        if (mergeFields.isEmpty()) {
            return text;
        }

        // 2. Identify Object Type and Fields to Query
        String sObjectType = String.valueOf(recordId.getSobjectType());
        Set<String> fieldsToQuery = new Set<String>();
        
        for (String fieldToken : mergeFields) {
            List<String> parts = fieldToken.split('\\.');
            // Check if token starts with the correct object name (e.g. Case.Subject)
            if (parts.size() >= 2 && parts[0].equalsIgnoreCase(sObjectType)) {
                // Remove the Object prefix to get the actual field path
                fieldsToQuery.add(fieldToken.substring(parts[0].length() + 1));
            }
        }

        if (fieldsToQuery.isEmpty()) {
            return text;
        }

        // 3. Dynamic Query
        String query = 'SELECT ' + String.join(new List<String>(fieldsToQuery), ',') + 
                       ' FROM ' + sObjectType + 
                       ' WHERE Id = :recordId LIMIT 1';
        
        try {
            SObject record = Database.query(query);

            // 4. Replacement Logic
            for (String fullToken : mergeFields) {
                List<String> parts = fullToken.split('\\.');
                if (parts.size() >= 2 && parts[0].equalsIgnoreCase(sObjectType)) {
                    String fieldPath = fullToken.substring(parts[0].length() + 1);
                    Object val = getFieldValue(record, fieldPath);
                    String replacement = (val != null) ? String.valueOf(val) : '';
                    text = text.replace('{!' + fullToken + '}', replacement);
                }
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'MergeFieldService Error: ' + e.getMessage());
            // Return text unresolved if query fails
        }

        return text;
    }

    // Helper to safely traverse relationships (e.g. Account.Owner.Name)
    private static Object getFieldValue(SObject record, String fieldPath) {
        SObject current = record;
        List<String> fields = fieldPath.split('\\.');
        for (Integer i = 0; i < fields.size() - 1; i++) {
            current = current.getSObject(fields[i]);
            if (current == null) return null;
        }
        return current.get(fields[fields.size() - 1]);
    }
}
