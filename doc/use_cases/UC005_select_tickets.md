# UC005: Select Tickets for Assignment

## Use Case Overview

**Use Case ID:** UC005
**Use Case Name:** Select Tickets for Assignment
**Actor:** Development Team Lead
**Priority:** High
**Status:** Not Started

## Description

As a development team lead, I want to select low-complexity bugs from the analyzed tickets so that I can prepare them for assignment to the AI engineer (Devin) for automated resolution. This selection happens on the same page as ticket analysis (UC004).

## Pre-conditions

- User has completed ticket analysis (from UC004)
- Mission is in "in_progress" status
- Tickets have complexity scores assigned
- User is viewing the Analyze Tickets page with analysis results displayed

## Post-conditions

- User has selected specific tickets for AI assignment
- Low-complexity bugs are preselected by default (on first visit)
- Selection is saved to database with flag on ticket records
- System is ready to proceed to ticket assignment (UC006)

## Main Flow

1. During UC004, as part of displaying analysis results on the Analyze Tickets page, system displays checkboxes next to each analyzed ticket
2. System checks if mission already has any tickets with `selected_for_assignment` flag:
   - If YES (returning to this page): Display existing selection state from database
   - If NO (first time viewing analysis): Automatically preselect all low-complexity bugs (complexity score 1-3)
3. System displays selection summary showing count of selected tickets
4. User reviews the analyzed tickets and their selection states
5. User can manually check/uncheck tickets to adjust selection:
   - Uncheck low-complexity tickets if not suitable
   - Check medium-complexity tickets if desired
6. System updates selection count in real-time as user makes changes
7. User clicks "Assign Selected Tickets" button (on the same Analyze Tickets page)
8. System validates selection (at least one ticket selected)
9. System saves selection to database (sets `selected_for_assignment` flag on ticket records)
10. System proceeds to UC006 (Assign Tickets to AI)

## Alternative Flows

### AF1: No Low-Complexity Tickets Available
**Step 3 Alternative:**
- If no low-complexity bugs exist:
  - System displays all tickets with checkboxes but none preselected
  - System shows info message: "No low-complexity bugs found. You can manually select tickets to assign."
  - User can manually select any tickets
  - Process continues based on manual selection

### AF2: User Deselects All Tickets
**Step 9 Alternative:**
- If user attempts to proceed with no tickets selected:
  - System displays validation error: "Please select at least one ticket to assign"
  - "Assign Selected Tickets" button remains enabled
  - User must select at least one ticket to proceed

### AF3: User Wants to Refine Analysis
**Step 5 Alternative:**
- If user is not satisfied with available tickets:
  - User clicks "Back to Query" or breadcrumb navigation
  - System returns to UC002 to modify JQL query
  - User can start over with different query criteria
  - Selection is cleared when starting new analysis

### AF4: User Returns to Analyze Tickets Page
**Step 2 Alternative:**
- If user navigates back to Analyze Tickets page from UC006 or later steps:
  - System loads existing selection state from database
  - Previously selected tickets are checked
  - No automatic preselection occurs (existing selection preserved)
  - User can modify selection as needed
  - Analysis results are re-displayed without re-analysis

## Business Rules

- BR01: All low-complexity bugs (score 1-3) are preselected automatically only on first visit
- BR02: If mission has any `selected_for_assignment` tickets, do not run automatic preselection
- BR03: Medium and high complexity tickets are not preselected automatically
- BR04: User can manually select/deselect any tickets regardless of complexity
- BR05: At least one ticket must be selected to proceed
- BR06: Selection is saved to database when user proceeds to next step
- BR07: Only Bug type tickets should be considered for automatic preselection
- BR08: Maximum 50 tickets can be selected for assignment in one batch

## Acceptance Criteria

- AC01: Checkboxes appear next to all tickets in the list
- AC02: All low-complexity bugs (score 1-3) are preselected automatically on first visit
- AC03: Existing selection is restored if user returns to this step
- AC04: Medium and high complexity tickets have unchecked checkboxes (unless manually selected)
- AC05: Selection count is displayed and updates in real-time
- AC06: User can check/uncheck individual tickets
- AC07: "Select All" and "Deselect All" controls are available
- AC08: "Select Low-Complexity Only" quick filter is available
- AC09: Validation error appears if user tries to proceed with no selection
- AC10: "Assign Selected Tickets" button is clearly visible
- AC11: Selected ticket count is visible on the button (e.g., "Assign 12 Selected Tickets")
- AC12: Warning appears if user selects more than 50 tickets
- AC13: Visual indicator shows which tickets are selected (checkbox + row highlight)

## UI/UX Requirements

**Note:** All UI elements for ticket selection are integrated into the Analyze Tickets page (UC004).

- Checkbox column added to ticket list (leftmost position)
- Selection controls integrated with analysis results display:
  - Selection count display (e.g., "12 tickets selected")
  - "Select All" button
  - "Deselect All" button
  - "Select Low-Complexity Only" button
- Enhanced ticket list on Analyze Tickets page:
  - Checkboxes for each ticket
  - Row highlighting for selected tickets (subtle background color)
  - All existing columns remain (complexity, ID, title, status, priority)
  - Disabled checkboxes for blocked/invalid tickets (if any)
- Selection summary card/banner integrated with analysis summary:
  - Total tickets analyzed
  - Selected tickets count
  - Breakdown by complexity (e.g., "10 low, 2 medium")
- Primary action button on Analyze Tickets page:
  - "Assign Selected Tickets" or "Assign X Tickets" (dynamic count)
  - Positioned prominently at bottom of list and in header
  - Replaces or supersedes "View Recommendations" button
  - Enabled when at least one ticket selected
- Warning message if >50 tickets selected:
  - "Warning: Selecting too many tickets may reduce success rate. Consider limiting to 20-30 tickets per batch."
- Validation error display area for error messages
- Breadcrumb navigation showing workflow progress

## Non-Functional Requirements

- Checkbox state changes should be instantaneous (<100ms)
- Selection count updates should be real-time
- Page should handle up to 500 tickets with checkboxes without performance issues
- Database save operation when proceeding should complete within 2 seconds
- Loading existing selection state should complete within 1 second
- Keyboard accessibility for checkbox selection (space bar to toggle)
- "Select All" operation should complete within 1 second even for 500 tickets

## Dependencies

- Completed analysis from UC004
- Ticket entities with complexity scores
- Database fields to store selection flag and timestamp on ticket records

## Test Scenarios

### TS001: First Visit - Default Preselection
**Given:** Mission has 30 analyzed tickets (10 low, 15 medium, 5 high complexity) and no tickets have `selected_for_assignment` flag
**When:** Analysis results are displayed on Analyze Tickets page for first time
**Then:** 10 low-complexity tickets are preselected, others unchecked, count shows "10 tickets selected"

### TS002: Return Visit - Restore Selection
**Given:** Mission has 8 tickets with `selected_for_assignment=true`
**When:** User returns to Analyze Tickets page from later step
**Then:** Previously selected 8 tickets are checked, no automatic preselection occurs, analysis results are displayed

### TS003: Manual Selection Change
**Given:** Low-complexity tickets are preselected
**When:** User unchecks 2 low-complexity tickets and checks 3 medium-complexity tickets
**Then:** Selection count updates to "11 tickets selected", checked tickets are highlighted

### TS004: Select All Operation
**Given:** Some tickets are selected
**When:** User clicks "Select All" button
**Then:** All tickets become selected, count shows total ticket count

### TS005: Deselect All Operation
**Given:** Multiple tickets are selected
**When:** User clicks "Deselect All" button
**Then:** All checkboxes are unchecked, count shows "0 tickets selected"

### TS006: Select Low-Complexity Only
**Given:** User has manually selected various tickets
**When:** User clicks "Select Low-Complexity Only" button
**Then:** Only low-complexity tickets are selected, others unchecked

### TS007: Validation Error - No Selection
**Given:** No tickets are selected
**When:** User clicks "Assign Selected Tickets"
**Then:** Error message displays "Please select at least one ticket to assign", navigation blocked

### TS008: Successful Navigation to Assignment
**Given:** User has selected 8 tickets
**When:** User clicks "Assign 8 Selected Tickets"
**Then:** System saves `selected_for_assignment=true` for 8 tickets, `selected_for_assignment=false` for others, and navigates to UC006

### TS009: Warning for Large Selection
**Given:** User selects 55 tickets
**When:** Selection count reaches 51
**Then:** Warning message appears suggesting limiting batch size

### TS010: No Low-Complexity Tickets
**Given:** All tickets are medium or high complexity and no prior selection exists
**When:** Analysis results are displayed on Analyze Tickets page
**Then:** No tickets preselected, info message explains no low-complexity bugs found

## Notes

- Selection functionality is integrated into UC004 Analyze Tickets page
- No separate page or navigation is needed for ticket selection
- Selection state is persistent and survives page refreshes/navigation
- Consider adding bulk selection by complexity category in future
- May want to show estimated total resolution time for selection
- Future enhancement: Remember user's selection preferences across missions
- Future enhancement: Suggest optimal batch size based on Devin capacity
- Consider adding "Why is this preselected?" info button for transparency
- Consider adding export selected tickets feature for record keeping

## Selection Logic

### Preselection Criteria (Only on First Visit)
- Check if mission has any tickets with `selected_for_assignment=true`
- If YES: Load existing selection, skip preselection logic
- If NO: Apply automatic preselection:
  - Ticket must have complexity_score between 1 and 3 (inclusive)
  - Ticket must be of type "Bug"
  - Ticket must not have "blocked" status
  - Ticket must not have "blocked" label

### Database Persistence
- Add boolean field `selected_for_assignment` to tickets table (default: false)
- Add datetime field `selected_at` to tickets table (nullable)
- When user proceeds to next step:
  - Set `selected_for_assignment=true` and `selected_at=current_timestamp` for checked tickets
  - Set `selected_for_assignment=false` and `selected_at=null` for unchecked tickets
  - Update all tickets in the mission atomically

### Batch Size Recommendations
- Optimal: 10-20 tickets per batch
- Acceptable: 21-50 tickets per batch
- Warning threshold: >50 tickets
- Hard limit: 100 tickets (prevent selection beyond this)