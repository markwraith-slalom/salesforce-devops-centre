/**
 * Controller class for the Account Case Editor component
 * Provides methods to retrieve and update Case records for a given Account
 */
public with sharing class AccountCaseEditorController {
    
    /**
     * Retrieves picklist values for Case fields
     * @return Map of field names to their picklist values
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, List<PicklistValue>> getCasePicklistValues() {
        Map<String, List<PicklistValue>> picklistMap = new Map<String, List<PicklistValue>>();
        
        try {
            Schema.DescribeFieldResult statusField = Case.Status.getDescribe();
            Schema.DescribeFieldResult priorityField = Case.Priority.getDescribe();
            Schema.DescribeFieldResult originField = Case.Origin.getDescribe();
            Schema.DescribeFieldResult reasonField = Case.Reason.getDescribe();
            Schema.DescribeFieldResult languageField = Case.Language.getDescribe();
            
            picklistMap.put('Status', getPicklistValues(statusField));
            picklistMap.put('Priority', getPicklistValues(priorityField));
            picklistMap.put('Origin', getPicklistValues(originField));
            picklistMap.put('Reason', getPicklistValues(reasonField));
            picklistMap.put('Language', getPicklistValues(languageField));
            
        } catch (Exception e) {
            System.debug('Error retrieving picklist values: ' + e.getMessage());
        }
        
        return picklistMap;
    }
    
    /**
     * Helper method to convert Schema picklist values to our custom format
     */
    private static List<PicklistValue> getPicklistValues(Schema.DescribeFieldResult fieldResult) {
        List<PicklistValue> values = new List<PicklistValue>();
        
        for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
            if (entry.isActive()) {
                values.add(new PicklistValue(entry.getLabel(), entry.getValue()));
            }
        }
        
        return values;
    }
    
    /**
     * Retrieves Cases related to a specific Account
     * @param accountId The Id of the Account
     * @return List of Case records with related data
     */
    @AuraEnabled(cacheable=true)
    public static List<CaseWrapper> getCases(Id accountId) {
        try {
            List<Case> cases = [
                SELECT Id, CaseNumber, Subject, Status, Priority, Origin, Description,
                       SDO_Service_Close_Summary__c, Case_Feedback__c, OwnerId, Owner.Name,
                       ContactId, Contact.Name, Reason, Language, IsEscalated, AssetId, 
                       Asset.Name, CreatedDate, LastModifiedDate
                FROM Case 
                WHERE AccountId = :accountId 
                ORDER BY CreatedDate DESC
                LIMIT 100
            ];
            
            List<CaseWrapper> wrappedCases = new List<CaseWrapper>();
            for (Case c : cases) {
                CaseWrapper wrapper = new CaseWrapper();
                wrapper.Id = c.Id;
                wrapper.CaseNumber = c.CaseNumber;
                wrapper.Subject = c.Subject;
                wrapper.Status = c.Status;
                wrapper.Priority = c.Priority;
                wrapper.Origin = c.Origin;
                wrapper.Description = c.Description;
                wrapper.CloseSummary = c.SDO_Service_Close_Summary__c;
                wrapper.CaseFeedback = c.Case_Feedback__c;
                wrapper.OwnerId = c.OwnerId;
                wrapper.OwnerName = c.Owner?.Name;
                wrapper.ContactId = c.ContactId;
                wrapper.ContactName = c.Contact?.Name;
                wrapper.Reason = c.Reason;
                wrapper.Language = c.Language;
                wrapper.IsEscalated = c.IsEscalated;
                wrapper.AssetId = c.AssetId;
                wrapper.AssetName = c.Asset?.Name;
                wrapper.CreatedDate = c.CreatedDate;
                wrapper.LastModifiedDate = c.LastModifiedDate;
                
                wrappedCases.add(wrapper);
            }
            
            return wrappedCases;
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving cases: ' + e.getMessage());
        }
    }
    
    /**
     * Updates a Case record with provided data
     * @param caseData Map containing field names and values to update
     * @return Success message
     */
    @AuraEnabled
    public static String updateCase(Map<String, Object> caseData) {
        try {
            if (!caseData.containsKey('Id')) {
                throw new AuraHandledException('Case Id is required for update');
            }
            
            Id caseId = (Id) caseData.get('Id');
            
            // Check if user has access to update the Case
            if (!Schema.sObjectType.Case.isUpdateable()) {
                throw new AuraHandledException('You do not have permission to update Cases');
            }
            
            Case caseToUpdate = new Case(Id = caseId);
            
            // Map the provided data to Case fields
            for (String fieldName : caseData.keySet()) {
                if (fieldName != 'Id' && caseData.get(fieldName) != null) {
                    try {
                        caseToUpdate.put(fieldName, caseData.get(fieldName));
                    } catch (Exception fieldEx) {
                        System.debug('Error setting field ' + fieldName + ': ' + fieldEx.getMessage());
                    }
                }
            }
            
            update caseToUpdate;
            
            return 'Success';
        } catch (DmlException e) {
            throw new AuraHandledException('Error updating case: ' + e.getDmlMessage(0));
        } catch (Exception e) {
            throw new AuraHandledException('Error updating case: ' + e.getMessage());
        }
    }
    
    /**
     * Wrapper class for Case data to be sent to the Lightning component
     */
    public class CaseWrapper {
        @AuraEnabled public Id Id { get; set; }
        @AuraEnabled public String CaseNumber { get; set; }
        @AuraEnabled public String Subject { get; set; }
        @AuraEnabled public String Status { get; set; }
        @AuraEnabled public String Priority { get; set; }
        @AuraEnabled public String Origin { get; set; }
        @AuraEnabled public String Description { get; set; }
        @AuraEnabled public String CloseSummary { get; set; }
        @AuraEnabled public String CaseFeedback { get; set; }
        @AuraEnabled public Id OwnerId { get; set; }
        @AuraEnabled public String OwnerName { get; set; }
        @AuraEnabled public Id ContactId { get; set; }
        @AuraEnabled public String ContactName { get; set; }
        @AuraEnabled public String Reason { get; set; }
        @AuraEnabled public String Language { get; set; }
        @AuraEnabled public Boolean IsEscalated { get; set; }
        @AuraEnabled public Id AssetId { get; set; }
        @AuraEnabled public String AssetName { get; set; }
        @AuraEnabled public DateTime CreatedDate { get; set; }
        @AuraEnabled public DateTime LastModifiedDate { get; set; }
    }
    
    /**
     * Wrapper class for picklist values
     */
    public class PicklistValue {
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public String value { get; set; }
        
        public PicklistValue(String label, String value) {
            this.label = label;
            this.value = value;
        }
    }
}