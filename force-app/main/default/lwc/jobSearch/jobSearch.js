import { LightningElement, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import searchJobs from '@salesforce/apex/JobBoardCallout.getJobs';
import processSelectedJobs from '@salesforce/apex/JobBoardCallout.processSelectedJobs';
import getColumnAttributes from '@salesforce/apex/IntegrationFieldMappingHelper.getLwcColumnsFromIntegrationFieldMappings';

export default class JobSearch extends LightningElement {

    // Search parameters entered by the user
    jobKeywords = '';
    jobLocation = '';

    // Error handling
    error;
    errorMessage;
    activeError = false;

    // Used for buttons, navigation and the UI in general
    searchButtonDisabled = true;
    firstButtonDisabled = true;
    nextButtonDisabled = true;
    backButtonDisabled = true;
    lastButtonDisabled = true
    saveSelectedJobsButtonDisabled = true;
    pageNumberMessage = '';
    jobTableColumns = [];
    isLoading = false;
    shouldDisplayTable = false;
    searchComplete = false;
    sortBy = 'updated';
    sortDirection = 'desc';

    // Total jobs and pages to be available for review in the UI
    totalJobs = 0; 
    totalPages = 0; 
    pageSize = 100;
    
    // Tracks the current page and requested pages
    currentPage = 1; 
    requestedPage = 1; 

    // Jobs currently displayed in the UI and those selected
    currentlyDisplayedJobs = [];
    currentlySelectedJobs = [];

    // All jobs fetched across all pages and those selected on all pages
    selectedJobsByPageNumber = {};
    allJobsByPageNumber = {};

    // Wire callout since I don't need to explicitly control when it is done
    @wire(getColumnAttributes, {calloutConfigDevName: 'Jooble_Post'})
    columnHandler({error, data}) {
        if (data) {
            this.jobTableColumns = data;
        } else if (error) {
            this.error = error;
        }
    }
    
    // Sets search parameters as the user enters them into the UI
    handleSearchParameters(event){
        const fieldName = event.target.name;
        let newValue = String(event.target.value);
        if (fieldName == 'jobKeywords') {
            this.jobKeywords = newValue;
        } else {
            this.jobLocation = newValue;
        }
        if (this.jobKeywords && this.jobLocation && this.searchButtonDisabled) {
            this.searchButtonDisabled = false
        } else if ((!this.jobKeywords || !this.jobLocation) && !this.searchButtonDisabled) {
            this.searchButtonDisabled = true;
        }
    }

    // Handles a user clicking the search button
    handleSearchClick() {
        this.isLoading = true;
        if (this.searchComplete) {
            this.resetVariablesForNewSearch();
        }
        this.getJobs();
    }

    // Resets variables when a new search is initiated when results are already displayed
    resetVariablesForNewSearch() {
        this.error = null;
        this.errorMessage = null;
        this.activeError = false;
        this.firstButtonDisabled = true;
        this.nextButtonDisabled = true;
        this.backButtonDisabled = true;
        this.lastButtonDisabled = true
        this.saveSelectedJobsButtonDisabled = true;
        this.pageNumberMessage = '';
        this.shouldDisplayTable = false;
        this.totalJobs = 0; 
        this.totalPages = 0; 
        this.pageSize = 100;
        this.currentPage = 1; 
        this.requestedPage = 1; 
        this.currentlyDisplayedJobs = [];
        this.currentlySelectedJobs = [];
        this.selectedJobsByPageNumber = {};
        this.allJobsByPageNumber = {};
        this.searchComplete = false;
        this.sortBy = 'updated';
        this.sortDirection = 'desc';
    }

    // Imperative callout since I want to explicitly control when it is done    
    // Fetches jobs to display, whether by making a callout or fetching jobs that have already been saved from a callout
    async getJobs() { 
        // Checks if the requested page of the results has already been obtained by the API and stored.
        try {
            if (this.allJobsByPageNumber[Number(this.requestedPage)]) {
                // Loads the jobs already stored and selected jobs for this page
                this.currentlyDisplayedJobs = this.allJobsByPageNumber[Number(this.requestedPage)];
                const selectedRowsForPage = this.selectedJobsByPageNumber[Number(this.requestedPage)] || [];
                this.currentlySelectedJobs = selectedRowsForPage.map(row => row.id);
            } else {
                // API call to get the jobs for the requested page, since they haven't been obtained yet
                let response = await searchJobs({
                    jobKeywords: this.jobKeywords,
                    jobLocation: this.jobLocation,
                    pageNumber: Number(this.requestedPage)
                });
                this.allJobsByPageNumber[Number(this.requestedPage)] = response.jobs; // Stores the returned jobs for the page so we don't need to call to get them again
                this.totalJobs = Number(response.jobCount); // Stores the total job count to help with pagination since the API only returns 100 jobs but does say the total count
                this.totalPages = Number(response.maxPages); // The number of pages of jobs we'll display in the LWC
                this.currentlyDisplayedJobs = response.jobs; // Sets the returned jobs to be visible in the UI now
                this.currentlySelectedJobs = []; // Doesn't pre-select the page, since this is the first time it has been shown
                this.checkIfTableShouldDisplay();
                this.searchComplete = true;
                }
        } catch (error) {
            this.isLoading = false;
            this.error = error;
            this.showError(this.error);
        } finally {
            this.handlePageNumberMessage();
            this.shouldNextLastButtonsBeEnabled();
            this.shouldBackFirstButtonsBeEnabled();
            this.currentPage = Number(this.requestedPage);
            this.requestedPage = null;
            this.isLoading = false;
        }
    }

    // Constructs error message to display in the UI
    showError(error){
        this.errorMessage = error.body ? (error.body.message || JSON.stringify(error.body)) : 'An unknown error occurred';
        this.activeError = true;
    }

    // Checks whether the data table should be displayed by seeing of any jobs were returned
    checkIfTableShouldDisplay() {
        if (Object.keys(this.allJobsByPageNumber).length != 0) {  
            this.shouldDisplayTable = true;
        } else {
            this.shouldDisplayTable = false;
        }
    }

    // Checks if any jobs have been saved across all pages
    checkIfJobsSavedOnAllPages() {
        return Object.values(this.selectedJobsByPageNumber).some(selectedJobs => selectedJobs.length > 0);
    }

    // When a user selects a job from the data table, this selection is stored. Ensures real-time changes are kept up to date.
    handleJobSelection(event) {
        // From the current page, gets the selected row Ids and the full contents of the datatable
        const selectedJobs = event.detail.selectedRows;
        const selectedIds = selectedJobs.map(row => String(row.id));

        // If no row Ids are selected on the current page, clear the variables tracking any selections on this page
        if (selectedIds.length === 0) {
            this.currentlySelectedJobs = [];
            this.selectedJobsByPageNumber[Number(this.currentPage)] = [];
            // Check if the save jobs button should be disabled
            if (!this.checkIfJobsSavedOnAllPages() && !this.saveSelectedJobsButtonDisabled) {
                this.saveSelectedJobsButtonDisabled = true;
            }
        } else {
            // Adds existing and new selections and removes any dupes using Set. Spread operator before new Set converts to an array.
            const currentlySelectedIds = new Set(selectedIds);
            const jobsNotYetSelected = selectedJobs.filter(id => !currentlySelectedIds.has(id));

            this.selectedJobsByPageNumber[Number(this.currentPage)] = jobsNotYetSelected;

            // If jobs are selected on this or any pages and the save jobs button is disabled, enable it
            if((selectedIds.length != 0 || this.checkIfJobsSavedOnAllPages()) && this.saveSelectedJobsButtonDisabled) {
                this.saveSelectedJobsButtonDisabled = false;
            }
        }
    }   

    // Determines if the next and last buttons should be disabled
    shouldNextLastButtonsBeEnabled() {
        if (Number(this.requestedPage) == Number(this.totalPages)) {
            this.nextButtonDisabled = true
            this.lastButtonDisabled = true
        } else {
            this.nextButtonDisabled = false;
            this.lastButtonDisabled = false
        }
    }

    // Determines if the back and first buttons should be disabled
    shouldBackFirstButtonsBeEnabled() {
        if (Number(this.requestedPage == 1)) {
            this.backButtonDisabled = true;
            this.firstButtonDisabled = true;
        } else {
            this.backButtonDisabled = false;
            this.firstButtonDisabled = false;
        }
    }

    // Handles a user clicking the button to go to the first page of results
    handleFirstPage() {
        this.isLoading = true;
        this.requestedPage = 1;
        this.getJobs();
    }

    // Handles when a user clicks the back button
    handleBackPage() {
        this.isLoading = true;
        this.requestedPage = (Number(this.currentPage) - 1);
        this.getJobs();
    }
    
    // Handles when a user clicks the next button
    handleNextPage() {;
        this.isLoading = true;
        this.requestedPage = (Number(this.currentPage + 1)); 
        this.getJobs();
    } 
    
    // Handles a user clicking the button to go to the last page of results
    handleLastPage() {;
        this.isLoading = true;
        this.requestedPage = Number(this.totalPages); 
        this.getJobs();
    }    

    // Generates the message to let the user know the page they are on
    handlePageNumberMessage() {
        this.pageNumberMessage = 'Page ' + this.requestedPage + ' of ' + this.totalPages;
    }

    // All sorting is based on the current jobs on the page.
    // Since Jooble API only lets me return 100 or so records at a time, I can only sort the page I have
    // Only alternative I can think of is calling for all pages back to back, but that seems bad performance wise
    handleTableSort(event) {
        const fieldName = event.detail.fieldName; // The field to sort by
        const sortDirection = event.detail.sortDirection; // 'asc' or 'desc'
        
        // Sort the data based on the field and direction
        const parsedData = [...this.currentlyDisplayedJobs];
        
        parsedData.sort(this.sortByField(fieldName, sortDirection));
    
        // Update the data table
        this.currentlyDisplayedJobs = parsedData; // Newly sorted data
        this.sortBy = fieldName; // Update the current field that is sorted
        this.sortDirection = sortDirection; // Update the current sorting direction
    }

    sortByField(sortByField, sortByDirection) {
        /* Called from the standard .sort array method which expects the following: 
            > Return a negative number if the first job should sort before the second
            > Return a positive number if the second job should sort before the first
            > Return 0 if they are equal
        This method will automatically pass in pairs of jobs from the array of rows on the data table page
        If sortDirection is ascending, multiplier = 1. Else, it = -1*/
        const multiplier = sortByDirection === 'asc' ? 1 : -1;
        
        // For the two jobs being compared, get the values of the field being sorted by
        return (firstJob, secondJob) => {
            const firstJobSortByValue = firstJob[sortByField];
            const secondJobSortByValue = secondJob[sortByField];
    
            // Checks if the first job does not have a value. If it doesn't, checks if the second doesn't either.
            if (firstJobSortByValue === null || firstJobSortByValue === undefined || firstJobSortByValue === '') {
                if (secondJobSortByValue === null || secondJobSortByValue === undefined || secondJobSortByValue === '') {
                    // No value in either means the jobs are equal from a sorting perspective, so 0 is returned
                    return 0;
                } else {
                    return -multiplier;
                }
            }

            // The first job has a value if it hits this block So, we check if the second job has a value
            if (secondJobSortByValue === null || secondJobSortByValue === undefined || secondJobSortByValue === '') {
                return multiplier;
            }
            
            if (typeof firstJobSortByValue === 'number' && typeof secondJobSortByValue === 'number') {
                return multiplier * (firstJobSortByValue - secondJobSortByValue);
            }
            
            const firstJobSortByString = String(firstJobSortByValue).toLowerCase();
            const secondJobSortByString = String(secondJobSortByValue).toLowerCase();
            return multiplier * firstJobSortByString.localeCompare(secondJobSortByString);
            }
        }

    // Imperative callout since I want to explicitly control when it is done    
    async handleJobSave() {
        // Create an array to store all selected jobs across all pages
        this.isLoading = true;
        let allSelectedJobs = [];
        // Loop through each page and add the selected jobs to the array
        for (let pageNumber in this.selectedJobsByPageNumber) {
            if (this.selectedJobsByPageNumber.hasOwnProperty(pageNumber)) {
                let selectedJob = this.selectedJobsByPageNumber[pageNumber];
                allSelectedJobs = [...allSelectedJobs, ...selectedJob];
            }
        }
        // Call the method to create the records
        try {
            let response = await processSelectedJobs({
                selectedJobs: allSelectedJobs
            });
        } catch (error) {
            this.isLoading = false;
            this.error = error;
            this.showError(this.error);
        } finally {
            this.resetVariablesForNewSearch();
            this.isLoading = false;
            const event = new ShowToastEvent({
                title: 'Success!',
                message: 'The selected Jobs have been saved as Saved Job Applications!',
                variant: 'success'
            });
            this.dispatchEvent(event);
        }
    }
}