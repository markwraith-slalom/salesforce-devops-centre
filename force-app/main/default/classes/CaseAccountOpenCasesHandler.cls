public class CaseAccountOpenCasesHandler extends TriggerHandler {
    
    /**
     * @description After insert handler - updates Account.NumberOfOpenCases__c when new cases are created
     */
    public override void afterInsert() {
        updateAccountOpenCasesCount((List<Case>)Trigger.new, null);
    }
    
    /**
     * @description After update handler - updates Account.NumberOfOpenCases__c when case status changes or account changes
     */
    public override void afterUpdate() {
        updateAccountOpenCasesCount((List<Case>)Trigger.new, (Map<Id, Case>)Trigger.oldMap);
    }
    
    /**
     * @description After delete handler - updates Account.NumberOfOpenCases__c when cases are deleted
     */
    public override void afterDelete() {
        updateAccountOpenCasesCount((List<Case>)Trigger.old, null);
    }
    
    /**
     * @description After undelete handler - updates Account.NumberOfOpenCases__c when cases are undeleted
     */
    public override void afterUndelete() {
        updateAccountOpenCasesCount((List<Case>)Trigger.new, null);
    }
    
    /**
     * @description Main method to update the Number of Open Cases field on related Accounts
     * @param newCases List of new or current Case records
     * @param oldCasesMap Map of old Case records (for updates)
     */
    private void updateAccountOpenCasesCount(List<Case> newCases, Map<Id, Case> oldCasesMap) {
        Set<Id> accountIdsToUpdate = new Set<Id>();
        
        // Collect Account IDs that need their open cases count updated
        for (Case currentCase : newCases) {
            // Add current account ID if it exists
            if (currentCase.AccountId != null) {
                accountIdsToUpdate.add(currentCase.AccountId);
            }
            
            // For updates, also add the old account ID if it changed
            if (oldCasesMap != null && oldCasesMap.containsKey(currentCase.Id)) {
                Case oldCase = oldCasesMap.get(currentCase.Id);
                if (oldCase.AccountId != null && oldCase.AccountId != currentCase.AccountId) {
                    accountIdsToUpdate.add(oldCase.AccountId);
                }
            }
        }
        
        // For delete context, get account IDs from the cases being deleted
        if (Trigger.isDelete) {
            for (Case deletedCase : newCases) {
                if (deletedCase.AccountId != null) {
                    accountIdsToUpdate.add(deletedCase.AccountId);
                }
            }
        }
        
        if (!accountIdsToUpdate.isEmpty()) {
            updateAccountCounts(accountIdsToUpdate);
        }
    }
    
    /**
     * @description Updates the NumberOfOpenCases__c field for the specified accounts
     * @param accountIds Set of Account IDs to update
     */
    private void updateAccountCounts(Set<Id> accountIds) {
        // Query accounts with their open cases count
        Map<Id, Account> accountsToUpdate = new Map<Id, Account>();
        
        // Get the current count of open cases for each account
        List<AggregateResult> caseCounts = [
            SELECT AccountId, COUNT(Id) caseCount
            FROM Case 
            WHERE AccountId IN :accountIds 
            AND IsClosed = false
            GROUP BY AccountId
        ];
        
        // Initialize all accounts with 0 count
        for (Id accountId : accountIds) {
            accountsToUpdate.put(accountId, new Account(Id = accountId, NumberOfOpenCases__c = 0));
        }
        
        // Update with actual counts
        for (AggregateResult result : caseCounts) {
            Id accountId = (Id) result.get('AccountId');
            Integer count = (Integer) result.get('caseCount');
            accountsToUpdate.get(accountId).NumberOfOpenCases__c = count;
        }
        
        // Update the accounts
        if (!accountsToUpdate.isEmpty()) {
            update accountsToUpdate.values();
        }
    }
}