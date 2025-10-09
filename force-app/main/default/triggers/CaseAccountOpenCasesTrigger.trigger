trigger CaseAccountOpenCasesTrigger on Case (after insert, after update, after delete, after undelete) {
    new CaseAccountOpenCasesHandler().run();
}