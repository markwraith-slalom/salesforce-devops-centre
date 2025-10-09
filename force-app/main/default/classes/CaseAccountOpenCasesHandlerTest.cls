@isTest
public class CaseAccountOpenCasesHandlerTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test account
        Account testAccount = new Account(
            Name = 'Test Account for Cases',
            Industry = 'Technology'
        );
        insert testAccount;
        
        // Create a second account for testing account changes
        Account testAccount2 = new Account(
            Name = 'Test Account 2 for Cases',
            Industry = 'Finance'
        );
        insert testAccount2;
    }
    
    /**
     * @description Creates a test case with minimal fields to avoid flow errors
     */
    private static Case createTestCase(Id accountId, String status, String subject) {
        return new Case(
            Subject = subject,
            Status = status,
            AccountId = accountId,
            Priority = 'Medium',
            Origin = 'Web'
        );
    }
    
    @isTest
    static void testOpenCasesCountOnInsert() {
        Account testAccount = [SELECT Id, NumberOfOpenCases__c FROM Account WHERE Name = 'Test Account for Cases' LIMIT 1];
        
        // Verify initial count is 0
        System.assertEquals(0, testAccount.NumberOfOpenCases__c, 'Initial open cases count should be 0');
        
        Test.startTest();
        
        // Create 3 open cases
        List<Case> testCases = new List<Case>();
        for (Integer i = 0; i < 3; i++) {
            testCases.add(createTestCase(testAccount.Id, 'New', 'Test Case ' + i));
        }
        insert testCases;
        
        Test.stopTest();
        
        // Verify the count was updated
        testAccount = [SELECT Id, NumberOfOpenCases__c FROM Account WHERE Id = :testAccount.Id];
        System.assertEquals(3, testAccount.NumberOfOpenCases__c, 'Open cases count should be 3 after inserting 3 open cases');
    }
    
    @isTest
    static void testOpenCasesCountOnStatusUpdate() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account for Cases' LIMIT 1];
        
        // Create cases with different statuses
        List<Case> testCases = new List<Case>();
        testCases.add(createTestCase(testAccount.Id, 'New', 'Test Case 1'));
        testCases.add(createTestCase(testAccount.Id, 'Working', 'Test Case 2'));
        testCases.add(createTestCase(testAccount.Id, 'Closed', 'Test Case 3'));
        insert testCases;
        
        // Verify initial count (2 open cases)
        testAccount = [SELECT Id, NumberOfOpenCases__c FROM Account WHERE Id = :testAccount.Id];
        System.assertEquals(2, testAccount.NumberOfOpenCases__c, 'Initial open cases count should be 2');
        
        Test.startTest();
        
        // Close one of the open cases
        testCases[0].Status = 'Closed';
        update testCases[0];
        
        Test.stopTest();
        
        // Verify the count decreased
        testAccount = [SELECT Id, NumberOfOpenCases__c FROM Account WHERE Id = :testAccount.Id];
        System.assertEquals(1, testAccount.NumberOfOpenCases__c, 'Open cases count should be 1 after closing one case');
    }
    
    @isTest
    static void testOpenCasesCountOnDelete() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account for Cases' LIMIT 1];
        
        // Create test cases
        List<Case> testCases = new List<Case>();
        for (Integer i = 0; i < 2; i++) {
            testCases.add(createTestCase(testAccount.Id, 'New', 'Test Case ' + i));
        }
        insert testCases;
        
        // Verify initial count
        testAccount = [SELECT Id, NumberOfOpenCases__c FROM Account WHERE Id = :testAccount.Id];
        System.assertEquals(2, testAccount.NumberOfOpenCases__c, 'Initial open cases count should be 2');
        
        Test.startTest();
        
        // Delete one case
        delete testCases[0];
        
        Test.stopTest();
        
        // Verify the count decreased
        testAccount = [SELECT Id, NumberOfOpenCases__c FROM Account WHERE Id = :testAccount.Id];
        System.assertEquals(1, testAccount.NumberOfOpenCases__c, 'Open cases count should be 1 after deleting one case');
    }
    
    @isTest
    static void testOpenCasesCountOnUndelete() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account for Cases' LIMIT 1];
        
        // Create test case
        Case testCase = createTestCase(testAccount.Id, 'New', 'Test Case for Undelete');
        insert testCase;
        
        // Verify initial count
        testAccount = [SELECT Id, NumberOfOpenCases__c FROM Account WHERE Id = :testAccount.Id];
        System.assertEquals(1, testAccount.NumberOfOpenCases__c, 'Initial open cases count should be 1');
        
        // Delete the case
        delete testCase;
        
        // Verify count is 0
        testAccount = [SELECT Id, NumberOfOpenCases__c FROM Account WHERE Id = :testAccount.Id];
        System.assertEquals(0, testAccount.NumberOfOpenCases__c, 'Open cases count should be 0 after deletion');
        
        Test.startTest();
        
        // Undelete the case
        undelete testCase;
        
        Test.stopTest();
        
        // Verify the count increased
        testAccount = [SELECT Id, NumberOfOpenCases__c FROM Account WHERE Id = :testAccount.Id];
        System.assertEquals(1, testAccount.NumberOfOpenCases__c, 'Open cases count should be 1 after undelete');
    }
    
    @isTest
    static void testOpenCasesCountWithClosedCases() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account for Cases' LIMIT 1];
        
        Test.startTest();
        
        // Create mix of open and closed cases
        List<Case> testCases = new List<Case>();
        testCases.add(createTestCase(testAccount.Id, 'New', 'Open Case 1'));
        testCases.add(createTestCase(testAccount.Id, 'Working', 'Open Case 2'));
        testCases.add(createTestCase(testAccount.Id, 'Closed', 'Closed Case 1'));
        testCases.add(createTestCase(testAccount.Id, 'Closed', 'Closed Case 2'));
        insert testCases;
        
        Test.stopTest();
        
        // Verify only open cases are counted
        testAccount = [SELECT Id, NumberOfOpenCases__c FROM Account WHERE Id = :testAccount.Id];
        System.assertEquals(2, testAccount.NumberOfOpenCases__c, 'Only open cases should be counted, expected 2');
    }
    
    @isTest
    static void testOpenCasesCountWithNoAccount() {
        Test.startTest();
        
        // Create case without account
        Case testCase = new Case(
            Subject = 'Test Case Without Account',
            Status = 'New',
            Priority = 'Medium',
            Origin = 'Web'
        );
        insert testCase;
        
        Test.stopTest();
        
        // This should not cause any errors and not update any account
        System.assert(true, 'Case without account should not cause errors');
    }
    
    @isTest
    static void testOpenCasesCountAccountChange() {
        // Get both test accounts
        List<Account> testAccounts = [SELECT Id, NumberOfOpenCases__c FROM Account ORDER BY Name];
        
        // Create case on first account
        Case testCase = createTestCase(testAccounts[0].Id, 'New', 'Test Case');
        insert testCase;
        
        // Verify first account has 1 open case
        testAccounts[0] = [SELECT Id, NumberOfOpenCases__c FROM Account WHERE Id = :testAccounts[0].Id];
        System.assertEquals(1, testAccounts[0].NumberOfOpenCases__c, 'First account should have 1 open case');
        
        Test.startTest();
        
        // Move case to second account
        testCase.AccountId = testAccounts[1].Id;
        update testCase;
        
        Test.stopTest();
        
        // Verify counts updated
        testAccounts[0] = [SELECT Id, NumberOfOpenCases__c FROM Account WHERE Id = :testAccounts[0].Id];
        testAccounts[1] = [SELECT Id, NumberOfOpenCases__c FROM Account WHERE Id = :testAccounts[1].Id];
        
        System.assertEquals(0, testAccounts[0].NumberOfOpenCases__c, 'First account should have 0 open cases after case move');
        System.assertEquals(1, testAccounts[1].NumberOfOpenCases__c, 'Second account should have 1 open case after case move');
    }
    
    @isTest
    static void testBulkOperations() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account for Cases' LIMIT 1];
        
        Test.startTest();
        
        // Create 200 cases for bulk testing
        List<Case> testCases = new List<Case>();
        for (Integer i = 0; i < 200; i++) {
            testCases.add(createTestCase(testAccount.Id, 'New', 'Bulk Test Case ' + i));
        }
        insert testCases;
        
        Test.stopTest();
        
        // Verify the count was updated correctly
        testAccount = [SELECT Id, NumberOfOpenCases__c FROM Account WHERE Id = :testAccount.Id];
        System.assertEquals(200, testAccount.NumberOfOpenCases__c, 'Bulk insert should update count to 200');
    }
    
    @isTest
    static void testTriggerHandler() {
        // Test that the trigger handler is properly set up
        CaseAccountOpenCasesHandler handler = new CaseAccountOpenCasesHandler();
        System.assertNotEquals(null, handler, 'Handler should be instantiated');
        
        // Test bypass functionality
        TriggerHandler.bypass('CaseAccountOpenCasesHandler');
        System.assertEquals(true, TriggerHandler.isBypassed('CaseAccountOpenCasesHandler'), 'Handler should be bypassed');
        
        TriggerHandler.clearBypass('CaseAccountOpenCasesHandler');
        System.assertEquals(false, TriggerHandler.isBypassed('CaseAccountOpenCasesHandler'), 'Handler should not be bypassed');
    }
}