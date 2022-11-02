import { LightningElement,api, track } from 'lwc';
import getWorkingPatternMasterDataOfContract from '@salesforce/apex/workingPatternController.getWorkingPatternMasterDataOfContract';

const columns = [
    { label: 'Day', fieldName: 'day' },
    { label: 'Shift', fieldName: 'shift' },
    { label: 'Start Time', fieldName: 'startTime', type: 'date' ,typeAttributes:{
        hour:"2-digit",
        minute:"2-digit",
        timeZone : "UTC"
    }},
    { label: 'End Time', fieldName: 'endTime', type: 'date',typeAttributes:{
        hour:"2-digit",
        minute:"2-digit",
        timeZone : "UTC"
    } }
];
const columnsOfShiftGrid = ['Shift Name','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
export default class RelatedWorkingPattern extends LightningElement {
      @api recordId;
      @api gridType
      columns = columns;
      columnsOfShiftGrid = columnsOfShiftGrid;
      @track workingPatternByDays=[];
      @track WorkingPatternByShifts=[];
      error;
      connectedCallback() {
        getWorkingPatternMasterDataOfContract({ contractRecordId: this.recordId })
        .then(result => {
            if(result !== null && result !== undefined){
                this.workingPatternByDays = result.workingPatternDayVsTimes;
                Object.keys(result.shiftVsDaysTimings).forEach(key =>  this.WorkingPatternByShifts.push({key:key,value:result.shiftVsDaysTimings[key]}) );
            }
        })
        .catch(error => {
            this.error = error;
        });
      }

      get showWorkingByDays(){
          return this.gridType === 'days' ? true :false;
      }

      get showWorkingByShifts(){
        return this.gridType === 'shifts' ? true :false;
    }
    

}