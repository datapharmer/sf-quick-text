public with sharing class MergeFieldService {
    
    /**
     * Replaces merge fields in the format {!Object.Field} with actual values
     * @param rawText The Quick Text message containing merge fields
     * @param recordId The ID of the record we are currently viewing (Context)
     * @return String The text with fields resolved
     */
    public static String resolveTextMessage(String rawText, Id recordId) {
        if (String.isBlank(rawText)) return rawText;
        
        // 1. Identify all merge fields using Regex
        // Pattern matches: {!Something}
        Pattern p = Pattern.compile('\\{!(.*?)\\}');
        Matcher m = p.matcher(rawText);
        
        Set<String> mergeFields = new Set<String>();
        while(m.find()) {
            mergeFields.add(m.group(1)); // Extract inner text e.g., Case.Account.Name
        }
        
        if (mergeFields.isEmpty()) return rawText;

        // 2. Separate fields based on Context (Current Record) vs Globals ($User, etc)
        // Note: This example focuses on the Context Record. 
        // Global variable handling ($User, $Organization) requires separate logic.
        
        String sObjectType = recordId.getSobjectType().getDescribe().getName();
        Set<String> queryFields = new Set<String>();
        
        for (String fieldPath : mergeFields) {
            // Remove the Object Name prefix if present to normalize (e.g., Case.Status -> Status)
            // Or handle cross-object references.
            if (fieldPath.startsWithIgnoreCase(sObjectType + '.')) {
                queryFields.add(fieldPath.removeStartIgnoreCase(sObjectType + '.'));
            } else if (!fieldPath.contains('.')) {
                // Direct field reference without object prefix
                queryFields.add(fieldPath);
            } else {
                 // It might be a parent relationship (Account.Name) while on Case. 
                 // Keep as is if valid, otherwise ignore globals like $User for this specific query
                 if (!fieldPath.startsWith('$')) {
                     queryFields.add(fieldPath);
                 }
            }
        }
        
        // 3. Perform Dynamic SOQL to get values
        if (queryFields.isEmpty()) return rawText;
        
        String queryString = 'SELECT ' + String.join(new List<String>(queryFields), ',') + 
                             ' FROM ' + sObjectType + 
                             ' WHERE Id = :recordId LIMIT 1';
                             
        SObject recordData;
        try {
            recordData = Database.query(queryString);
        } catch (Exception e) {
            // If query fails (e.g. security or invalid field), return raw text or handle error
            System.debug('Merge Error: ' + e.getMessage());
            return rawText;
        }

        // 4. Replace values in the text
        String resolvedText = rawText;
        
        for (String originalMerge : mergeFields) {
            String fieldPath = originalMerge;
            
            // Handle standard Globals briefly (Example)
            if (fieldPath.startsWith('$User')) {
                // You would implement User info fetching here
                continue; 
            }

            // Normalize path for lookup
            String lookupPath = fieldPath;
            if (lookupPath.startsWithIgnoreCase(sObjectType + '.')) {
                lookupPath = lookupPath.removeStartIgnoreCase(sObjectType + '.');
            }

            Object val = getFieldValue(recordData, lookupPath);
            String strVal = (val == null) ? '' : String.valueOf(val);
            
            // Regex replace
            resolvedText = resolvedText.replace('{!' + originalMerge + '}', strVal);
        }
        
        return resolvedText;
    }

    // Helper to traverse relationships (e.g. Case.Account.Name)
    private static Object getFieldValue(SObject record, String fieldPath) {
        if (record == null) return null;
        if (!fieldPath.contains('.')) {
            return record.get(fieldPath);
        } else {
            String relation = fieldPath.substringBefore('.');
            String remaining = fieldPath.substringAfter('.');
            return getFieldValue(record.getSObject(relation), remaining);
        }
    }
}
