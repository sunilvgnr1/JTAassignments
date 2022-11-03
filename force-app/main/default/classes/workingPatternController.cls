public with sharing class workingPatternController {

    public static final Set<String> days = New Set<String>{'Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'};
    public static final String StartTimeAPI ='_Start_Time__c';
    public static final String EndTimeAPI ='_End_Time__c';
    public static final String OrgPartitionName='local.WorkingPatternMasterData';

    /**
     * @description this method will be called from lwc component to return masterdata wrapper 
     * class instance from cache if its available else getWorkingPatternOfContract method will be called to form 
     * masterData class and put it in the cache.
     * @param  contractRecordId  
     * @return return masterData wrapper class instance 
     */ 
    @AuraEnabled
    public static masterData getWorkingPatternMasterDataOfContract(String contractRecordId){
        Contract contractDetails = getContractDetails(contractRecordId);
        return getWorkingPatternMasterDataFromCache(OrgPartitionName,contractDetails);
    }

    /**
     * @description 
     * step 1:Query shifts associated to working pattern of the contract record
     * Step 2:Loop through the shift records 
     * Step 3.Using Sobject.getPopulatedFieldsAsMap() method to get the Ma of field Vs Value of shift record.
     * Step 4:Loop through the set of days of week and 
     * use day+_Start_Time__c and day+_End_Time__c to dynamically get the value of shift record fields
     * Step 5: Create dayAndTime instance with Day,StartTime and EndTime and add it to the list
     * Step 6: After end of days loop, Create a Map<String,List<dayAndTime>> as Shift Name Vs List of dayAndTime. 
     * Step 5.1 Also Create Map of Day Vs List<dayAndTime>  and later use it sort based on chronogical order of days {Like Monday Tuesday ..}
     * Step 7.use sortListByDays method to sort the list<dayAndTime>
     * Step 8. Create masterData wrapper instance with workingPatternDayVsTimes,shiftVsDaysTimings  
     * @param  contractDetails it is contract record.
     */ 
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
    /**
     * @description It will return the shift records associated to Working Pattern
     * @param  workingPatternId 
     */
    public static List<Shift__c> getShifts(String workingPatternId){
        return [SELECT Id,Name, Monday_Start_Time__c, Monday_End_Time__c, Tuesday_Start_Time__c, Tuesday_End_Time__c,
        Wednesday_End_Time__c, Wednesday_Start_Time__c, Thursday_Start_Time__c, Thursday_End_Time__c, Friday_Start_Time__c, Friday_End_Time__c, 
        Saturday_Start_Time__c, Saturday_End_Time__c, Sunday_Start_Time__c, Sunday_End_Time__c, Working_Pattern__c FROM Shift__c 
        WHERE Working_Pattern__c =:workingPatternId];
    }

    public static Contract getContractDetails(String recordId){
        return [SELECT Working_Pattern__c FROM Contract WHERE Id =:recordId LIMIT 1];
    }
    /**
     * @description this method is used to fetch the data from the platform cache if data is not available then putWorkingPatternMasterData will used to store the data
     * @param  orgPartition   -  cache partition name
     * @param  contractDetails -  contract record
     * @return - masterData wrapper class instance
     */ 
    public static masterData getWorkingPatternMasterDataFromCache(String orgPartition,Contract contractDetails){
        masterData workingPatternData = new masterData();
        Cache.orgPartition orgPart = Cache.Org.getPartition(orgPartition);
            workingPatternData = (masterData)orgPart.get(contractDetails.Working_Pattern__c);
            if(workingPatternData != NULL){
                return workingPatternData;
            }
        return putWorkingPatternMasterData(orgPartition,contractDetails);
    }
    /**
     * @description It will be used to process the shift data by calling getWorkingPatternOfContract  
     * and insert the data /master data into platfomr cache 
     * @param  orgPartition   -  cache partition name
     * @param  contractDetails -  contract record
     * @return - masterData wrapper class instance
     */ 
    public static masterData  putWorkingPatternMasterData(String orgPartition,Contract contractDetails){
        masterData  workingPatternData = new masterData();
        Cache.orgPartition orgPart = Cache.Org.getPartition(orgPartition);
            workingPatternData=getWorkingPatternOfContract(contractDetails);
            orgPart.put(contractDetails.Working_Pattern__c, workingPatternData);
        return workingPatternData;
    }

    /**
     * @description convert Map of Shift Vs List<dayAndTime into a List<dayAndTime>
     * @param  temp  
     * @return sorted List of dayAndTime by Day.
     */ 
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
        dayAndTime(String day,String shift,Time startTime,Time endTime){ // Will be used for data table with Day, Shift, Start and End time columns
            this.day=day;
            this.shift=shift;
            this.startTime=startTime;
            this.endTime=endTime;
        }
        dayAndTime(String day,Time startTime,Time endTime){ // Will be used for data table with Monday to Sunday columns
            this.day=day;
            this.startTime=startTime;
            this.endTime=endTime;
        }
    }
}