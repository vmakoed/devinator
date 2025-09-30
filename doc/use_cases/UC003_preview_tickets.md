# UC003: Preview Tickets

## Use Case Overview

**Use Case ID:** UC003
**Use Case Name:** Preview Tickets
**Actor:** Development Team Lead
**Priority:** High
**Status:** Not Started

## Description

As a development team lead, I want to preview fetched JIRA tickets with their details so that I can understand and confirm the scope of available work before proceeding with complexity analysis and AI recommendations.

## Pre-conditions

- User has an active mission with a saved JQL query (from UC002)
- Mission is in "in_progress" status
- JIRA API connection is available and configured
- User has appropriate JIRA permissions to view tickets
- JQL query has been validated by JIRA API

## Post-conditions

- Tickets are fetched from JIRA and stored in the system
- User has reviewed the list of fetched tickets
- User confirms the ticket list is correct
- System is ready to proceed to complexity analysis (UC004)

## Main Flow

1. User navigates to the Preview Tickets page from JQL input page (UC002)
2. System displays loading indicator
3. System executes JQL query against JIRA API
4. System fetches matching tickets with key details:
   - Ticket ID/Key
   - Title/Summary
   - Status
   - Priority
   - Assignee
   - Created Date
   - Labels
   - Description preview (first 200 characters)
5. System displays fetched tickets in a list/table format
6. System shows ticket count summary (e.g., "Found 47 tickets")
7. User reviews the ticket list
8. User clicks "Confirm and Continue" button
9. System stores tickets in the mission
10. System displays confirmation message
11. System provides navigation to "Analyze Tickets" (UC004)

## Alternative Flows

### AF1: No Tickets Found
**Step 4 Alternative:**
- If JQL query returns zero tickets:
  - System displays message "No tickets found matching your query"
  - System provides option to modify JQL query (return to UC002)
  - Process ends until query is modified

### AF2: JIRA API Error
**Step 3 Alternative:**
- If JIRA API is unavailable or returns error:
  - System displays error message with specific error details from JIRA
  - System provides "Retry" button to re-execute query
  - System provides option to modify JQL query (return to UC002)
  - Process ends until user takes action

### AF3: Invalid JQL Query
**Step 3 Alternative:**
- If JIRA API rejects JQL query as invalid:
  - System displays validation error with JIRA's error message
  - System provides option to modify JQL query (return to UC002)
  - Process ends until query is corrected

## Business Rules

- BR01: Tickets must include minimum fields: ID, title, status, priority
- BR02: Description preview is limited to first 200 characters
- BR03: Tickets are stored with the mission for future analysis
- BR04: User must confirm ticket list before proceeding to analysis
- BR05: Ticket data is cached to avoid repeated JIRA API calls

## Acceptance Criteria

- AC01: System fetches tickets using the saved JQL query
- AC02: Loading indicator is displayed during API call
- AC03: All fetched tickets are displayed with key details
- AC04: Ticket count summary is clearly visible
- AC05: User can scroll through the entire ticket list
- AC06: Error messages are displayed for JIRA API failures
- AC07: User can return to modify JQL query if needed
- AC08: User must confirm ticket list before proceeding
- AC09: Navigation to next step (Analyze Tickets) is clear
- AC10: System handles empty results gracefully

## UI/UX Requirements

- Loading spinner with "Fetching tickets from JIRA..." message
- Ticket list/table with clear column headers
- Responsive table layout that works on desktop and tablet
- Ticket count badge at top of list
- Expandable description preview (click to see full description)
- Clear "Confirm and Continue" button at bottom of list
- "Modify Query" link to return to UC002
- Error messages displayed prominently with retry options
- Empty state illustration and message when no tickets found
- Breadcrumb navigation showing current step in workflow

## Non-Functional Requirements

- Ticket fetching should complete within 10 seconds for typical queries
- System should display partial results if available during timeout
- JIRA API errors should be logged for debugging
- System should cache ticket data to minimize repeated API calls

## Dependencies

- JIRA API connectivity and authentication
- Mission entity with ticket storage capability
- Valid JQL query from UC002
- Network connectivity for external API calls

## Test Scenarios

### TS001: Successful Ticket Fetch and Preview
**Given:** User has active mission with valid JQL query
**When:** User navigates to Preview Tickets page
**Then:** Tickets are fetched from JIRA and displayed with all key details

### TS002: Empty Results Handling
**Given:** JQL query returns zero tickets
**When:** System executes query
**Then:** "No tickets found" message is displayed with option to modify query

### TS003: JIRA API Error
**Given:** JIRA API is unavailable
**When:** System attempts to fetch tickets
**Then:** Error message is displayed with retry option

### TS004: Invalid JQL Query
**Given:** JQL query has syntax error
**When:** System executes query against JIRA
**Then:** Validation error from JIRA is displayed with option to modify query

### TS005: Ticket Confirmation
**Given:** User has reviewed ticket list
**When:** User clicks "Confirm and Continue"
**Then:** Tickets are stored and user is navigated to Analyze Tickets page

## Notes

- JIRA API response time varies based on query complexity and result size
- Ticket data should be refreshed if user returns to modify query
- Store raw JIRA response for debugging and audit purposes
- Consider caching JIRA responses for 5 minutes to reduce API load
- Future enhancement: Allow user to manually deselect tickets before confirmation

## JIRA API Integration Details

**Endpoint:** `/rest/api/2/search`
**Method:** POST
**Required Headers:**
- Authorization (Basic or Bearer token)
- Content-Type: application/json

**Request Body:**
```json
{
  "jql": "[user's JQL query]",
  "fields": ["key", "summary", "status", "priority", "assignee", "created", "labels", "description"]
}
```

**Expected Response Fields:**
- `total`: Total number of matching tickets
- `issues[]`: Array of ticket objects with requested fields