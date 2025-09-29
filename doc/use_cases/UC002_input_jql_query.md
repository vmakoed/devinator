# UC002: Input JQL Query

## Use Case Overview

**Use Case ID:** UC002
**Use Case Name:** Input JQL Query
**Actor:** Development Team Lead
**Priority:** High
**Status:** Not Started

## Description

As a development team lead, I want to input a JQL (JIRA Query Language) query so that I can fetch specific bug tickets from our JIRA backlog that are candidates for automated resolution by the AI engineer.

## Pre-conditions

- User has an active mission (created via UC001)
- Mission is in "draft" or "in_progress" status
- User has knowledge of JQL syntax
- JIRA API connection is available and configured
- User has appropriate JIRA permissions to query tickets

## Post-conditions

- JQL query is stored in the mission
- Mission status is updated to "in_progress"
- System is ready to fetch tickets from JIRA (UC003)

## Main Flow

1. User navigates to the JQL input page for their active mission
2. System displays JQL query input form with:
   - Large text area for JQL query input
   - Query syntax helper/documentation link
   - Example queries for common bug ticket scenarios
3. User enters their JQL query in the text area
4. User clicks "Save Query" button
5. System saves the JQL query to the mission
6. System updates mission status to "in_progress"
7. System displays success message
8. System provides option to proceed to "Preview Tickets" (UC003)

## Alternative Flows

### AF1: Empty Query
**Step 4 Alternative:**
- If user attempts to save empty query:
  - System displays validation error "JQL query cannot be empty"
  - Focus returns to query input field
  - Process continues from step 3

### AF2: Save Operation Failure
**Step 5 Alternative:**
- If system cannot save query:
  - System displays error message "Unable to save query. Please try again."
  - System logs the error for debugging
  - User can retry from step 4

## Business Rules

- BR01: JQL query cannot be empty
- BR02: Only one JQL query per mission is allowed
- BR03: Query can be modified until tickets are fetched (UC003)
- BR04: Mission status changes to "in_progress" when query is saved

## Acceptance Criteria

- AC01: User can input multi-line JQL queries with proper formatting
- AC02: Query is associated with the current mission
- AC03: Mission status updates to "in_progress" upon successful save
- AC04: User receives confirmation when query is saved successfully
- AC05: System provides JQL syntax help and examples
- AC06: User can modify and re-save query multiple times
- AC07: Clear navigation path to next step (Preview Tickets)
- AC08: Empty queries are rejected with appropriate error message

## UI/UX Requirements

- Large text area for JQL input (minimum 5 rows)
- Real-time character count display
- "Save Query" button with clear styling
- Collapsible help section with JQL syntax reference
- Example queries section with copy-to-clipboard functionality
- Clear error messaging for empty query
- Loading indicators during save operations
- Breadcrumb navigation showing current step in workflow

## Non-Functional Requirements

- Query save should complete within 2 seconds
- Text area should support queries up to 5000 characters
- System should handle save failures gracefully
- Help documentation should be accessible offline

## Dependencies

- Mission entity with query storage capability
- JIRA API connectivity for eventual query execution

## Test Scenarios

### TS001: Successful Query Input and Save
**Given:** User has an active mission in "draft" status
**When:** User enters JQL query and clicks "Save Query"
**Then:** Query is saved, mission status becomes "in_progress", success message displayed

### TS002: Empty Query Validation
**Given:** User leaves query field empty
**When:** User clicks "Save Query"
**Then:** Validation error prevents save and prompts for query input

### TS003: Query Modification
**Given:** User has previously saved a query
**When:** User modifies query and saves again
**Then:** Updated query replaces previous query in mission

### TS004: Save Operation Failure
**Given:** System cannot save query (e.g., database error)
**When:** User attempts to save query
**Then:** Error message is displayed with retry option

## Notes

- System accepts any non-empty text as valid JQL
- Query validation will occur when executing against JIRA (UC003)
- Consider implementing query templates for common scenarios
- Store query save timestamp for audit purposes

## Example JQL Queries

**Basic bug query:**
```
project = "PROJ" AND issuetype = Bug AND status = "Open"
```

**Priority-focused query:**
```
project = "PROJ" AND issuetype = Bug AND priority in (Low, Medium) AND status in ("To Do", "Open")
```

**Component-specific query:**
```
project = "PROJ" AND issuetype = Bug AND component = "Frontend" AND labels = "tech-debt"
```