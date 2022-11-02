@isTest
public with sharing class workingPatternController_Test {

    @TestSetup
    static void makeTestData(){
        Set<String> shiftsInADay= new Set<String>{'Early','Late','Night'};
        List<Working_Pattern__c> workingPatternRecords= new List<Working_Pattern__c>();
        workingPatternRecords.add(getWorkingPattern('Berlin Full Time','Germany'));
        workingPatternRecords.add(getWorkingPattern('Berlin Part Time','Germany'));
        insert workingPatternRecords;
        List<Shift__c> shiftRecords= New List<Shift__c>();
        for(String shift:shiftsInADay){
            shiftRecords.add(getShift(shift,Time.newInstance(08, 00, 00, 00),Time.newInstance(14, 00, 00, 00),workingPatternRecords[0].Id));
            shiftRecords.add(getShift(shift,Time.newInstance(08, 00, 00, 00),Time.newInstance(14, 00, 00, 00),workingPatternRecords[1].Id));
        }
        insert shiftRecords;

    Id recordTypeId =Schema.SObjectType.Account.getRecordTypeInfosByName().get('Person Account').getRecordTypeId();
        Account testAccount = new Account( RecordTypeID=recordTypeId,
        FirstName='Test',LastName='Account',
        PersonMailingStreet='test@yahoo.com',
        PersonMailingPostalCode='12345',
        PersonMailingCity='SFO',
        PersonEmail='test@yahoo.com',
        PersonHomePhone='1234567',
        PersonMobilePhone='12345678');
        insert testAccount;
    }

    public static shift__c getShift(String day,Time startTimeValue,Time endTimeValue,String workingPatternId){
         return new Shift__c(Name=day,Working_Pattern__c=workingPatternId,
            Monday_Start_Time__c=startTimeValue, Monday_End_Time__c=endTimeValue,
            Wednesday_Start_Time__c=startTimeValue,Wednesday_End_Time__c=endTimeValue, 
            Friday_Start_Time__c=startTimeValue, Friday_End_Time__c=endTimeValue,
            Saturday_Start_Time__c=startTimeValue, Saturday_End_Time__c=endTimeValue,
            Sunday_Start_Time__c=startTimeValue, Sunday_End_Time__c=endTimeValue,
            Thursday_Start_Time__c=startTimeValue, Thursday_End_Time__c=endTimeValue,
            Tuesday_Start_Time__c=startTimeValue, Tuesday_End_Time__c=endTimeValue);
    }

    public static Working_Pattern__c getWorkingPattern(String Name,String countryName){
       return  new Working_Pattern__c(
            Name=Name,
            Country__c=countryName
        );
    }
  
    @IsTest
    static void testFlow_AutoAssignWorkingPattern(){
        Account testAccount = [Select Id from Account Where Name='Test Account'];
        Contract contractRecord = new Contract(AccountId=testAccount.Id,Status='Draft',StartDate=System.today(), 
            ContractTerm=12, Country__c='Germany', Delivery_Area__c='Berlin', Contract_Type__c='Full Time'
        );
        insert contractRecord;
        Test.startTest();
        System.assertEquals('Berlin Full Time', [Select Id,Working_Pattern__r.Name from Contract ].Working_Pattern__r.Name);
        Test.stopTest();
    }

    @IsTest
    static void testFlow_AutoChangeAssignWorkingPattern_AfterUpdatingContractType(){
        Test.startTest();
        Account testAccount = [Select Id from Account Where Name='Test Account'];
        Contract contractRecord = new Contract(AccountId=testAccount.Id,Status='Draft',StartDate=System.today(), 
            ContractTerm=12, Country__c='Germany', Delivery_Area__c='Berlin', Contract_Type__c='Full Time'
        );
        insert contractRecord;
        System.assertEquals('Berlin Full Time', [Select Id,Working_Pattern__r.Name from Contract ].Working_Pattern__r.Name);
        contractRecord.Contract_Type__c = 'Part Time'; 
        update contractRecord;
        System.assertEquals('Berlin Part Time', [Select Id,Working_Pattern__r.Name from Contract ].Working_Pattern__r.Name);
        Test.stopTest();
    }

    @IsTest
    static void testFlow_AutoAssignWorkingPattern_WhenNoContractType (){
        Test.startTest();
        Account testAccount = [Select Id from Account Where Name='Test Account'];
        Contract contractRecord = new Contract(AccountId=testAccount.Id,Status='Draft',StartDate=System.today(), 
            ContractTerm=12, Country__c='Germany', Delivery_Area__c='Munich', Contract_Type__c='Full Time'
        );
        insert contractRecord;
        System.assertEquals(null, [Select Id,Working_Pattern__r.Name from Contract ].Working_Pattern__c);
        Test.stopTest();
    }

    @IsTest
    static void test_getContractDetails_method_returnContractRecord(){
        Test.startTest();
        Account testAccount = [Select Id from Account Where Name='Test Account'];
        Contract contractRecord = new Contract(AccountId=testAccount.Id,Status='Draft',StartDate=System.today(), 
            ContractTerm=12, Country__c='Germany', Delivery_Area__c='Berlin', Contract_Type__c='Full Time'
        );
        insert contractRecord;
        System.assertEquals(contractRecord.Id, workingPatternController.getContractDetails(contractRecord.Id).Id);
        Test.stopTest();
    }
    
    @IsTest
    static void test_getShifts_method_returnsShiftRecords(){
        Test.startTest();
        Account testAccount = [Select Id from Account Where Name='Test Account'];
        Contract contractRecord = new Contract(AccountId=testAccount.Id,Status='Draft',StartDate=System.today(), 
            ContractTerm=12, Country__c='Germany', Delivery_Area__c='Berlin', Contract_Type__c='Full Time'
        );
        insert contractRecord;
        contractRecord = workingPatternController.getContractDetails(contractRecord.Id);
        System.assertEquals(3, workingPatternController.getShifts(contractRecord.Working_Pattern__c).size());
        Test.stopTest();
    }

    @IsTest
    static void test_getWorkingPatternOfContract_method_returnsMasterDataWrapper(){
        Test.startTest();
        Account testAccount = [Select Id from Account Where Name='Test Account'];
        Contract contractRecord = new Contract(AccountId=testAccount.Id,Status='Draft',StartDate=System.today(), 
            ContractTerm=12, Country__c='Germany', Delivery_Area__c='Berlin', Contract_Type__c='Full Time'
        );
        insert contractRecord;
        contractRecord=workingPatternController.getContractDetails(contractRecord.Id);
        workingPatternController.masterData masterDataSet= workingPatternController.getWorkingPatternOfContract(contractRecord);
        System.assertNotEquals(null, masterDataSet);
        System.assertNotEquals(null, masterDataSet.shiftVsDaysTimings);
        System.assertNotEquals(null, masterDataSet.workingPatternDayVsTimes);
        System.assertEquals(3, masterDataSet.shiftVsDaysTimings.size()); //3
        System.assertEquals(21, masterDataSet.workingPatternDayVsTimes.size()); // 7 day * 3 shifts
        System.assertEquals('Monday', masterDataSet.workingPatternDayVsTimes[0].day); //Sorting
        System.assertEquals('Tuesday', masterDataSet.workingPatternDayVsTimes[3].day);
        System.assertEquals('Wednesday', masterDataSet.workingPatternDayVsTimes[6].day);
        System.assertEquals('Thursday', masterDataSet.workingPatternDayVsTimes[9].day);
        System.assertEquals('Friday', masterDataSet.workingPatternDayVsTimes[12].day);
        System.assertEquals('Saturday', masterDataSet.workingPatternDayVsTimes[15].day);
        System.assertEquals('Sunday', masterDataSet.workingPatternDayVsTimes[18].day);
        System.assertEquals(Time.newInstance(08, 00, 00, 00), masterDataSet.workingPatternDayVsTimes[0].startTime);
        System.assertEquals(Time.newInstance(14, 00, 00, 00), masterDataSet.workingPatternDayVsTimes[0].endTime);
        Test.stopTest();
    }

    @IsTest
    static void test_getWorkingPatternMasterDataOfContract_method_returnsMasterDataWrapper(){ 
        Test.startTest();
        Account testAccount = [Select Id from Account Where Name='Test Account'];
        Contract contractRecord = new Contract(AccountId=testAccount.Id,Status='Draft',StartDate=System.today(), 
            ContractTerm=12, Country__c='Germany', Delivery_Area__c='Berlin', Contract_Type__c='Full Time'
        );
        insert contractRecord;
        workingPatternController.getWorkingPatternMasterDataOfContract(contractRecord.Id); // This will store data in 
        workingPatternController.masterData masterDataSet= workingPatternController.getWorkingPatternMasterDataOfContract(contractRecord.Id);
        System.assertNotEquals(null, masterDataSet);
        System.assertNotEquals(null, masterDataSet.shiftVsDaysTimings);
        System.assertNotEquals(null, masterDataSet.workingPatternDayVsTimes);
        System.assertEquals(3, masterDataSet.shiftVsDaysTimings.size()); //3
        System.assertEquals(21, masterDataSet.workingPatternDayVsTimes.size()); // 7 day * 3 shifts
        System.assertEquals('Monday', masterDataSet.workingPatternDayVsTimes[0].day); //Sorting
        System.assertEquals('Tuesday', masterDataSet.workingPatternDayVsTimes[3].day);
        System.assertEquals('Wednesday', masterDataSet.workingPatternDayVsTimes[6].day);
        System.assertEquals('Thursday', masterDataSet.workingPatternDayVsTimes[9].day);
        System.assertEquals('Friday', masterDataSet.workingPatternDayVsTimes[12].day);
        System.assertEquals('Saturday', masterDataSet.workingPatternDayVsTimes[15].day);
        System.assertEquals('Sunday', masterDataSet.workingPatternDayVsTimes[18].day);
        System.assertEquals(Time.newInstance(08, 00, 00, 00), masterDataSet.workingPatternDayVsTimes[0].startTime);
        System.assertEquals(Time.newInstance(14, 00, 00, 00), masterDataSet.workingPatternDayVsTimes[0].endTime);
        Test.stopTest();
    }
}