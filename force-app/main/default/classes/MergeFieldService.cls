public with sharing class MergeFieldService {
    
    // Pattern to match merge fields like {!Object.Field}
    private static final Pattern MERGE_FIELD_PATTERN = Pattern.compile('\\{!(.*?)\\}');

    /**
     * Replaces merge fields in the given text with values from the recordId.
     * @param text The text containing merge fields (e.g., "Hello {!Contact.FirstName}")
     * @param recordId The ID of the record to pull data from.
     * @return The text with merge fields resolved.
     */
    public static String resolve(String text, Id recordId) {
        if (String.isBlank(text) || recordId == null) {
            return text;
        }

        // 1. Identify all merge fields in the text
        Matcher matcher = MERGE_FIELD_PATTERN.matcher(text);
        Set<String> mergeFields = new Set<String>();
        while (matcher.find()) {
            mergeFields.add(matcher.group(1)); // Extract "Object.Field"
        }

        if (mergeFields.isEmpty()) {
            return text;
        }

        // 2. Determine SObject Type and validate fields
        String sObjectType = String.valueOf(recordId.getSobjectType());
        Set<String> fieldsToQuery = new Set<String>();
        
        for (String fieldToken : mergeFields) {
            // Token format expected: SObjectType.FieldName (e.g., Case.Subject)
            List<String> parts = fieldToken.split('\\.');
            if (parts.size() >= 2 && parts[0].equalsIgnoreCase(sObjectType)) {
                // Remove the Object prefix to get the field path
                fieldsToQuery.add(fieldToken.substring(parts[0].length() + 1));
            }
        }

        if (fieldsToQuery.isEmpty()) {
            return text;
        }

        // 3. Query the record
        String query = 'SELECT ' + String.join(new List<String>(fieldsToQuery), ',') + 
                       ' FROM ' + sObjectType + 
                       ' WHERE Id = :recordId LIMIT 1';
        
        try {
            SObject record = Database.query(query);

            // 4. Replace tokens in the text
            for (String fullToken : mergeFields) {
                List<String> parts = fullToken.split('\\.');
                // Only process tokens matching the current object type
                if (parts.size() >= 2 && parts[0].equalsIgnoreCase(sObjectType)) {
                    String fieldPath = fullToken.substring(parts[0].length() + 1);
                    Object val = getFieldValue(record, fieldPath);
                    String replacement = (val != null) ? String.valueOf(val) : '';
                    text = text.replace('{!' + fullToken + '}', replacement);
                }
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error resolving merge fields: ' + e.getMessage());
            // Return original text on failure to avoid breaking the UI
        }

        return text;
    }

    // Helper to handle potential cross-object traversals (e.g., Account.Name) if queried
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
