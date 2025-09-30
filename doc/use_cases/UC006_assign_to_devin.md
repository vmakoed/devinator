# UC006: Assign Tickets to Devin

## Use Case Overview

**Use Case ID:** UC006
**Use Case Name:** Assign Tickets to Devin
**Actor:** Development Team Lead
**Priority:** High
**Status:** Not Started

## Description

As a development team lead, I want to assign the selected low-complexity bug tickets to Devin (AI engineer) so that these tickets can be automatically resolved, freeing up human developers to focus on more complex work.

## Pre-conditions

- User has selected tickets for assignment (from UC005)
- Mission is in "in_progress" status
- At least one ticket has `selected_for_assignment=true` flag
- Devin API credentials are configured in the system
- User is viewing the Analyze Tickets page after confirming selection

## Post-conditions

- Selected tickets are assigned to Devin via API
- Each ticket has a corresponding Devin session created
- Devin session URLs are stored with ticket records
- Mission status is updated to "assigned"
- User can view assignment results and access Devin session links
- User receives confirmation of successful assignment

## Main Flow

1. User clicks "Assign Selected Tickets" button on Analyze Tickets page (from UC005 step 7)
2. System validates selection (at least one ticket selected)
3. System saves ticket selection to database (sets `selected_for_assignment` flag)
4. System displays assignment progress screen:
   - Shows "Assigning tickets to Devin..." message
   - Displays progress indicator/spinner
   - Lists tickets being assigned with status indicators
5. System retrieves selected tickets from database
6. For each selected ticket, system:
   - Calls Devin API to create new session with ticket details
   - Receives Devin session ID and URL
   - Stores Devin session information with ticket record
   - Updates ticket status to "assigned_to_devin"
   - Updates progress indicator for that ticket
7. System updates mission status to "assigned"
8. System displays assignment success screen:
   - Shows success message: "Successfully assigned X tickets to Devin"
   - Lists all assigned tickets with links to their Devin sessions
   - Provides "Start New Mission" option

## Alternative Flows

### AF1: Devin API Failure for Single Ticket
**Step 6 Alternative:**
- If Devin API call fails for one ticket:
  - System logs the error with ticket ID and error message
  - System marks that ticket as "assignment_failed" in database
  - System continues processing remaining tickets
  - At completion, system shows partial success message
  - Failed tickets are listed separately with error details
  - User can retry failed tickets individually

### AF2: Complete Devin API Failure
**Step 5 Alternative:**
- If Devin API is completely unavailable:
  - System detects API connectivity issue
  - System displays error message: "Unable to connect to Devin. Please check API configuration or try again later."
  - System does not update ticket statuses
  - Mission remains in "in_progress" status
  - "Retry Assignment" button is provided
  - User can return to ticket selection or try again

### AF3: Invalid API Credentials
**Step 5 Alternative:**
- If Devin API credentials are invalid or expired:
  - System receives authentication error from API
  - System displays error: "Devin API credentials are invalid. Please update credentials in settings."
  - System provides link to settings/configuration page
  - No tickets are assigned
  - Mission remains in "in_progress" status

### AF4: User Cancels During Assignment
**Step 6 Alternative:**
- If user clicks "Cancel" during assignment process:
  - System stops making new API calls
  - Already created Devin sessions remain active
  - System displays cancellation message with counts
  - Partially assigned tickets remain in "assigned_to_devin" status
  - Unassigned tickets return to "selected_for_assignment" status
  - User can resume assignment or modify selection

### AF5: Network Timeout
**Step 6 Alternative:**
- If network request times out for a ticket:
  - System waits up to 30 seconds per ticket
  - On timeout, marks ticket as "assignment_timeout"
  - Continues with remaining tickets
  - Shows partial success with timeout details
  - Provides "Retry Timed Out" option

## Business Rules

- BR01: Only tickets with `selected_for_assignment=true` are assigned to Devin
- BR02: Each ticket gets a unique Devin session
- BR03: Assignment is performed sequentially with progress tracking
- BR04: Failed assignments do not block successful ones
- BR05: Devin session URL must be stored for user access
- BR06: Mission status changes to "assigned" only after at least one successful assignment
- BR07: Original JIRA ticket ID and key are included in Devin session request
- BR08: Ticket title, description, and relevant metadata are sent to Devin
- BR09: Maximum 100 tickets can be assigned in one operation
- BR10: Assignment timeout is 30 seconds per ticket

## Acceptance Criteria

- AC01: "Assign Selected Tickets" button triggers assignment process
- AC02: Progress screen shows real-time assignment status
- AC03: Each ticket's assignment status is visible during process
- AC04: Success screen displays after all assignments complete
- AC05: Devin session links are clickable and open in new tab
- AC06: Assignment results are persisted to database
- AC07: Error messages are clear and actionable
- AC08: Partial failures are handled gracefully
- AC09: User can navigate to individual Devin sessions
- AC10: "Start New Mission" option is available after completion
- AC11: Assignment progress cannot be lost on page refresh
- AC12: Failed assignments can be retried individually
- AC13: Assignment history is preserved for audit trail

## UI/UX Requirements

**Assignment Progress Screen:**
- Page header: "Assigning Tickets to Devin"
- Progress indicator showing X of Y tickets assigned
- Live status list for each ticket:
  - Ticket ID and title
  - Status icon (pending/in-progress/success/failed)
  - Status text (e.g., "Creating Devin session...", "Assigned", "Failed")
- "Cancel Assignment" button (during process)
- Cannot navigate away during active assignment

**Assignment Success Screen:**
- Page header: "Assignment Complete"
- Success message: "Successfully assigned X tickets to Devin"
- Summary card:
  - Total tickets assigned
  - Total Devin sessions created
  - Timestamp of assignment
- Ticket list with assignment details:
  - Ticket ID and title as link to JIRA
  - Devin session link (opens in new tab)
  - Complexity score badge
  - Assignment timestamp
- If partial failures:
  - Failed tickets section with error messages
  - "Retry Failed Assignments" button
- Primary action:
  - "Start New Mission" button
- Breadcrumb navigation updated to show completion

**Error Screens:**
- Clear error message at top
- Description of what went wrong
- Suggested next steps
- "Try Again" button
- "Go Back" button
- Support/help link if applicable

## Non-Functional Requirements

- Each Devin API call should complete within 30 seconds
- UI must remain responsive during assignment process
- Progress updates should occur at least every 2 seconds
- Assignment of 50 tickets should complete within 5 minutes
- Failed assignments should be logged for debugging
- API retry logic with exponential backoff (3 attempts)
- Session data must be persisted before showing success
- Page refresh during assignment should show current progress
- Browser back button should be disabled during assignment
- Assignment operation should be idempotent (safe to retry)

## Dependencies

- Devin API integration and authentication
- Network connectivity to Devin service
- Database fields for storing Devin session data:
  - `devin_session_id` (string)
  - `devin_session_url` (string)
  - `assigned_to_devin_at` (datetime)
  - `assignment_status` (enum: pending/assigned/failed)
- Selected tickets from UC005
- JIRA ticket metadata for Devin context

## Test Scenarios

### TS001: Successful Assignment - All Tickets
**Given:** Mission has 5 tickets selected for assignment and Devin API is available
**When:** User clicks "Assign Selected Tickets"
**Then:** All 5 tickets are assigned, Devin sessions created, success screen shows 5 assignments with links

### TS002: Successful Assignment - Single Ticket
**Given:** Mission has 1 ticket selected for assignment
**When:** User clicks "Assign Selected Tickets"
**Then:** Ticket is assigned, Devin session created, success screen shows 1 assignment with link

### TS003: Partial Failure
**Given:** Mission has 10 tickets selected and Devin API fails for 2 tickets
**When:** Assignment process runs
**Then:** 8 tickets assigned successfully, 2 marked as failed, partial success screen shows both lists, retry option available

### TS004: Complete API Failure
**Given:** Devin API is completely unavailable
**When:** User clicks "Assign Selected Tickets"
**Then:** Error message displays, no tickets assigned, mission status unchanged, retry button shown

### TS005: Invalid Credentials
**Given:** Devin API credentials are expired
**When:** Assignment attempts to authenticate
**Then:** Authentication error shown, link to settings provided, no assignments made

### TS006: User Cancels Mid-Assignment
**Given:** Assignment is in progress for 20 tickets, 8 assigned
**When:** User clicks "Cancel Assignment"
**Then:** Process stops, 8 tickets remain assigned, 12 return to selected state, cancellation summary shown

### TS007: Network Timeout
**Given:** Network is slow and 2 tickets timeout during assignment
**When:** Assignment process runs for 15 tickets
**Then:** 13 succeed, 2 timeout, partial success shown, retry option for timed out tickets

### TS008: Page Refresh During Assignment
**Given:** Assignment is in progress
**When:** User refreshes page
**Then:** Progress screen reappears showing current assignment status, process continues

### TS009: Progress Tracking
**Given:** 30 tickets being assigned
**When:** Assignment is in progress
**Then:** Progress indicator updates in real-time, each ticket shows status, current count visible

### TS010: Retry Failed Assignment
**Given:** Previous assignment had 3 failures
**When:** User clicks "Retry Failed Assignments"
**Then:** System attempts to assign only the 3 failed tickets, results displayed

## Notes

- This is the final step in the MVP happy flow
- Assignment process is irreversible (tickets cannot be "unassigned")
- Future enhancement: Allow assigning additional tickets to existing mission
- Future enhancement: Bulk assignment across multiple missions
- Future enhancement: Schedule assignments for later time
- Future enhancement: Integration with JIRA to update ticket status
- Future enhancement: Real-time status updates from Devin
- Future enhancement: Devin session monitoring dashboard
- Consider webhook integration for Devin completion notifications
- Consider email notifications when Devin completes work
- May want to track assignment metrics (success rate, time taken)
- Consider adding assignment notes/comments for audit trail

## Devin API Integration

### API Request Format
```
POST /api/sessions
Headers:
  Authorization: Bearer {api_key}
  Content-Type: application/json

Body:
{
  "ticket_id": "PROJ-123",
  "title": "Ticket title",
  "description": "Full ticket description",
  "priority": "Medium",
  "labels": ["bug", "low-complexity"],
  "jira_url": "https://jira.company.com/browse/PROJ-123",
  "metadata": {
    "complexity_score": 2,
    "mission_id": 456
  }
}
```

### API Response Format
```
{
  "session_id": "devin_abc123",
  "session_url": "https://devin.ai/sessions/abc123",
  "status": "created",
  "created_at": "2025-09-30T14:30:00Z"
}
```

### Error Handling
- 401 Unauthorized: Invalid credentials
- 403 Forbidden: API quota exceeded
- 429 Too Many Requests: Rate limit hit
- 500 Internal Server Error: Devin service issue
- Timeout: No response within 30 seconds

### Database Schema Updates

Add to `tickets` table:
- `devin_session_id` (string, nullable)
- `devin_session_url` (string, nullable)
- `assigned_to_devin_at` (datetime, nullable)
- `assignment_status` (string, default: 'pending', values: 'pending'|'assigned'|'failed'|'timeout')
- `assignment_error` (text, nullable)
- `assignment_retry_count` (integer, default: 0)

Add to `missions` table:
- `assigned_at` (datetime, nullable)
- `assignment_completed_at` (datetime, nullable)
- `total_assigned_count` (integer, default: 0)
- `failed_assignment_count` (integer, default: 0)