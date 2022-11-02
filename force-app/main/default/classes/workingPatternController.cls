public with sharing class workingPatternController {

    public static final Set<String> days = New Set<String>{'Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'};
    public static final String StartTimeAPI ='_Start_Time__c';
    public static final String EndTimeAPI ='_End_Time__c';
    public static final String OrgPartitionName='local.WorkingPatternMasterData';

    @AuraEnabled
    public static masterData getWorkingPatternMasterDataOfContract(String contractRecordId){
        Contract contractDetails = getContractDetails(contractRecordId);
        return getWorkingPatternMasterDataFromCache(OrgPartitionName,contractDetails);
    }

    @AuraEnabled
    public static masterData getWorkingPatternOfContract(Contract contractDetails){
        String dayStartTimeFieldAPI,dayEndTimeFieldAPI;
        List<dayAndTime> dayVsTimesForEachShift;
        Map<String, Object> shiftFieldsToValue;
        List<dayAndTime> workingPatternDayVsTimes= New List<dayAndTime>();
        List<Shift__c> shiftsOfWorkingPattern = new List<Shift__c>();
        Map<String,List<dayAndTime>> shiftVsDaysTimings= new Map<String,List<dayAndTime>>();
        shiftsOfWorkingPattern = getShifts(contractDetails.Working_Pattern__c);
        Map<String,List<dayAndTime>> daysVsListOfShiftDetails= new Map<String,List<dayAndTime>>();
        for(Shift__c singleShift:shiftsOfWorkingPattern){
            dayVsTimesForEachShift = New List<dayAndTime>();
            shiftFieldsToValue = singleShift.getPopulatedFieldsAsMap();
            for(String day:days){
                dayStartTimeFieldAPI=day+StartTimeAPI;
                dayEndTimeFieldAPI=day+EndTimeAPI;
                dayVsTimesForEachShift.add(new dayAndTime(day,(Time)singleShift.get(dayStartTimeFieldAPI),(Time)singleShift.get(dayEndTimeFieldAPI)));
                if(singleShift.get(dayStartTimeFieldAPI) != null && singleShift.get(dayEndTimeFieldAPI) != null){
                    dayAndTime dayAndTimeDetails = new dayAndTime(day,singleShift.Name,(Time)singleShift.get(dayStartTimeFieldAPI),(Time)singleShift.get(dayEndTimeFieldAPI));
                    if(daysVsListOfShiftDetails.containsKey(day)){
                        daysVsListOfShiftDetails.get(day).add(dayAndTimeDetails);
                    }else{
                        daysVsListOfShiftDetails.put(day,new List<dayAndTime>{dayAndTimeDetails});
                    }
                }
            }
            shiftVsDaysTimings.put(singleShift.Name,dayVsTimesForEachShift);
        }
        workingPatternDayVsTimes = sortListByDays(daysVsListOfShiftDetails);
        return new masterData(workingPatternDayVsTimes,shiftVsDaysTimings);
    }

    public static List<Shift__c> getShifts(String workingPatternId){
        return [SELECT Id,Name, Monday_Start_Time__c, Monday_End_Time__c, Tuesday_Start_Time__c, Tuesday_End_Time__c,
        Wednesday_End_Time__c, Wednesday_Start_Time__c, Thursday_Start_Time__c, Thursday_End_Time__c, Friday_Start_Time__c, Friday_End_Time__c, 
        Saturday_Start_Time__c, Saturday_End_Time__c, Sunday_Start_Time__c, Sunday_End_Time__c, Working_Pattern__c FROM Shift__c 
        WHERE Working_Pattern__c =:workingPatternId];
    }

    public static Contract getContractDetails(String recordId){
        return [SELECT Working_Pattern__c FROM Contract WHERE Id =:recordId LIMIT 1];
    }
    public static masterData getWorkingPatternMasterDataFromCache(String orgPartition,Contract contractDetails){
        masterData workingPatternData = new masterData();
        Cache.orgPartition orgPart = Cache.Org.getPartition(orgPartition);
            workingPatternData = (masterData)orgPart.get(contractDetails.Working_Pattern__c);
            if(workingPatternData != NULL){
                return workingPatternData;
            }
        return putWorkingPatternMasterData(orgPartition,contractDetails);
    }
    
    public static masterData  putWorkingPatternMasterData(String orgPartition,Contract contractDetails){
        masterData  workingPatternData = new masterData();
        Cache.orgPartition orgPart = Cache.Org.getPartition(orgPartition);
            workingPatternData=getWorkingPatternOfContract(contractDetails);
            orgPart.put(contractDetails.Working_Pattern__c, workingPatternData);
        return workingPatternData;
    }

    public  static  List<dayAndTime>  sortListByDays(Map<String,List<dayAndTime>> temp) {
        List<dayAndTime> allRecordsByDays= new List<dayAndTime>();
        for(String day:temp.keySet()){
            allRecordsByDays.addAll(temp.get(day));
        }
        return allRecordsByDays;
    }

    public class masterData {
        @AuraEnabled public List<dayAndTime>  workingPatternDayVsTimes;
        @AuraEnabled public Map<String,List<dayAndTime>>  shiftVsDaysTimings;
        masterData(){}
        masterData(List<dayAndTime>  workingPatternDayVsTimes,Map<String,List<dayAndTime>>  shiftVsDaysTimings){
            this.workingPatternDayVsTimes=workingPatternDayVsTimes;
            this.shiftVsDaysTimings=shiftVsDaysTimings;
        }
    }

    public class dayAndTime {
        @AuraEnabled public String day;
        @AuraEnabled public String shift;
        @AuraEnabled public Time startTime;
        @AuraEnabled public Time endTime;
        dayAndTime(String day,String shift,Time startTime,Time endTime){
            this.day=day;
            this.shift=shift;
            this.startTime=startTime;
            this.endTime=endTime;
        }
        dayAndTime(String day,Time startTime,Time endTime){
            this.day=day;
            this.startTime=startTime;
            this.endTime=endTime;
        }
    }
}