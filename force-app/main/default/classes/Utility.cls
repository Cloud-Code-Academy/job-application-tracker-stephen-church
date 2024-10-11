public with sharing class Utility {

    @TestVisible final static String GENERIC_ERROR_MESSAGE_START = 'An error occurred. Give your Salesforce Developer these details: ';
    @TestVisible final static String ILLEGAL_ARGUMENT_EXCEPTION_START = 'An Illegal Argument Exception occurred: ';
    @TestVisible final static String HANDLED_EXCEPTION_START = 'An error occurred: ';
    @TestVisible final static String AURA_HANDLED_EXCEPTION_START = 'An Aura Handled Exception occurred: ';
    @TestVisible final static String CALLOUT_EXCEPTION_START = 'A Callout Exception occurred: ';
    @TestVisible final static String DML_EXCEPTION_START = 'A DML Exception occurred: ';
    @TestVisible final static String QUERY_EXCEPTION_START = 'A Query Exception occurred: ';
    @TestVisible final static String TYPE_EXCEPTION_START = 'A Type Exception occurred: ';
    @TestVisible final static String SEPARATOR_FOR_STACK_TRACE = ' || Stack Trace ';
    public static String errorMessage = null;

    public static void throwUiFriendlyException(String message) {
        throw new AuraHandledException(message);
    }

    public static void throwHandledException(String message) {
        errorMessage = GENERIC_ERROR_MESSAGE_START + HANDLED_EXCEPTION_START + message;
        try {
            throw new HandledException(errorMessage);
        } catch (HandledException e) {
            throw new handledException(errorMessage + SEPARATOR_FOR_STACK_TRACE + e.getStackTraceString());
        }
    }
    
    public static void throwIllegalArgumentException(String message) {
        errorMessage = GENERIC_ERROR_MESSAGE_START + ILLEGAL_ARGUMENT_EXCEPTION_START + message;
        try {
            throw new IllegalArgumentException(errorMessage);
        } catch (IllegalArgumentException e) {
            throw new IllegalArgumentException(errorMessage + SEPARATOR_FOR_STACK_TRACE + e.getStackTraceString());
        }
    }

    public static void throwTypeException(String message) {
        errorMessage = GENERIC_ERROR_MESSAGE_START + TYPE_EXCEPTION_START + message;
        try {
            throw new TypeException(errorMessage);
        } catch (TypeException e) {
            throw new TypeException(errorMessage + SEPARATOR_FOR_STACK_TRACE + e.getStackTraceString());
        }
    }

    public static void throwAuraHandledException(String message) {
        errorMessage = GENERIC_ERROR_MESSAGE_START + AURA_HANDLED_EXCEPTION_START + message;
        try {
            throw new AuraHandledException(errorMessage);
        } catch (AuraHandledException e) {
            throw new AuraHandledException(errorMessage + SEPARATOR_FOR_STACK_TRACE + e.getStackTraceString());
        }
    }

    public static void throwCalloutException(Integer statusCode, String message) {
        errorMessage = GENERIC_ERROR_MESSAGE_START + CALLOUT_EXCEPTION_START + 'Status code: ' + statusCode + ': ' + message;
        try {
            throw new CalloutException(errorMessage);
        } catch (CalloutException e) {
            throw new CalloutException(errorMessage + SEPARATOR_FOR_STACK_TRACE + e.getStackTraceString());
        }
    }

    public static void throwDmlException(DmlException e) {
        errorMessage = GENERIC_ERROR_MESSAGE_START + DML_EXCEPTION_START + e.getMessage();
        try {
            throw new DmlException(errorMessage);
        } catch (DmlException ex) {
            throw new DmlException(errorMessage + SEPARATOR_FOR_STACK_TRACE + ex.getStackTraceString());
        }
    }

    public static void throwQueryException(String message) {
        errorMessage = GENERIC_ERROR_MESSAGE_START + QUERY_EXCEPTION_START + message;
        try {
            throw new QueryException(errorMessage);
        } catch (QueryException e) {
            throw new QueryException(errorMessage + SEPARATOR_FOR_STACK_TRACE + e.getStackTraceString());
        }
    }

    public static Boolean checkIfResponseCodeIsSuccess (Integer responseCode) {
        if (responseCode == null) {
            throwIllegalArgumentException('The exception thrown is null');
        }
        Boolean isSuccessCode = false;
        if (responseCode >= 200 && responseCode <= 299) {
            isSuccessCode = true;
        }
        return isSuccessCode;
    }

    public static Map<String, Object> deserializeJson (String jsonResponse) {
        if (jsonResponse == null) {
            throwIllegalArgumentException('The jsonResponse argument was null');
        }
        Map<String, Object> deserializedJson = (Map<String, Object>) JSON.deserializeUntyped(jsonResponse);
        return deserializedJson;
    }

    public static Set<String> getSingleStringFromEachMapInList (
        String firstKeyToTryToExtract,
        String secondKeyIfFirstNotAvailable, 
        List<Map<String, Object>> listOfMaps) {
        
        if (firstKeyToTryToExtract == null || secondKeyIfFirstNotAvailable == null || listOfMaps.isEmpty()) {
            throwIllegalArgumentException('The method received null arguments');
        }
        
        Set<String> stringsToReturn = new Set<String>();
        for(Map<String, Object> currentMap : listOfMaps) {
            String stringToReturn = String.valueOf(currentMap.get(firstKeyToTryToExtract));
            if (stringToReturn != null) {
                stringsToReturn.add(stringToReturn);
                continue;
            }
            stringToReturn = String.valueOf(currentMap.get(secondKeyIfFirstNotAvailable));
            if (stringToReturn != null) {
                stringsToReturn.add(stringToReturn);
            }     
        }
        return stringsToReturn;
    }

    public static set<String> getSetOfStringsFromField (List<sObject> sObjects, String fieldToExtract) {
        
        if (sObjects.isEmpty() || fieldToExtract == null) {
            throwIllegalArgumentException('The method received null arguments');
        }

        Set<String> stringsToReturn = new Set<String>();
        String extractedString = null;
        for (sObject record : sObjects) {
            extractedString = String.valueOf(record.get(fieldToExtract));
            if (extractedString != null) {
                stringsToReturn.add(extractedString);
            }
        }
        return stringsToReturn;
    }

    public static List<sObject> insertRecords (List<sObject> recordsToInsert) {

        if (recordsToInsert.isEmpty()) {
            throwIllegalArgumentException('The recordsToInsert Argument is null');
        }

        try {
            insert recordsToInsert;
        } catch (DmlException e) {
            Utility.throwDmlException(e);
        }
        return recordsToInsert;
    }

    public static List<sObject> updateRecords (List<sObject> recordsToUpdate) {

        if (recordsToUpdate.isEmpty()) {
            throwIllegalArgumentException('The recordsToInsert Argument is null');
        }

        try {
            update recordsToUpdate;
        } catch (DmlException e) {
            Utility.throwDmlException(e);
        }
        return recordsToUpdate;
    }

    public static String getSObjectFieldValueLoweredNoWhiteSpace (SObject record, String fieldValueToGet) {

        if (record == null || fieldValueToGet == null) {
            Utility.throwIllegalArgumentException('An argument was null');
        }
        
        String fieldValue = null;
        if (record.get(fieldValueToGet) != null) {
            fieldValue = String.valueOf(record.get(fieldValueToGet));
            fieldValue = fieldValue.deleteWhitespace();
            fieldValue = fieldValue.toLowerCase();
        }
        return fieldValue;
    }

    public static Boolean checkStringMatchesPattern (String stringToCheck, String regexPatternToCheck) {

        if (stringToCheck == null || regexPatternToCheck == null) {
            throwIllegalArgumentException('Some arguments were null');
        }

        Boolean patternMatches = false;
        Pattern pattern = Pattern.compile(regexPatternToCheck);
        Matcher matcher = pattern.matcher(stringToCheck);

        if (matcher.matches()) {
            patternMatches = true;
        } 
        return patternMatches;
    }
}