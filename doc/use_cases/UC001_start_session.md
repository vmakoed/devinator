# UC001: Start Session

## Overview
**Use Case ID**: UC001
**Use Case Name**: Start Session
**Related Requirement**: FR001
**Actor**: Development Team Lead
**System**: Devinator

## Description
A development team lead initiates a new analysis session to begin the ticket evaluation process. This creates a workspace where they can define queries, analyze tickets, and manage assignments to Devin.

## Preconditions
- User is authenticated in the system
- User has valid JIRA credentials configured
- User has appropriate role permissions (team_lead or admin)

## Postconditions
- **Success**: New session is created and active
- **Success**: Session is ready to accept JQL queries
- **Success**: Session configuration is initialized with user defaults
- **Failure**: User receives error message and remains on previous screen

## Main Flow
1. User clicks "New Session" button on the dashboard
2. System displays "Create Session" form with fields:
   - Session Name (required)
   - Description (optional)
   - Configuration template (dropdown with saved configurations)
3. User enters session name and optional description
4. User optionally selects a saved configuration template
5. User clicks "Create Session" button
6. System validates input data
7. System creates new session record in database
8. System initializes session with selected or default configuration
9. System redirects user to session workspace
10. System displays success message: "Session '[name]' created successfully"

## Alternative Flows

### A1: User selects saved configuration
**Trigger**: Step 4 - User selects a configuration template
1. System populates session settings with saved configuration values
2. System displays preview of configuration settings
3. Continue to step 5

### A2: Validation errors
**Trigger**: Step 6 - Input validation fails
1. System displays validation error messages
2. System highlights invalid fields in red
3. User corrects errors
4. Return to step 5

### A3: Maximum sessions reached
**Trigger**: Step 7 - User has reached maximum active sessions limit
1. System displays error: "Maximum active sessions reached. Please complete or archive an existing session first."
2. System provides link to session management page
3. Use case ends with failure

## Exception Flows

### E1: Database connection error
**Trigger**: Step 7 - Database is unavailable
1. System displays error: "Unable to create session. Please try again later."
2. System logs error for administrator review
3. Use case ends with failure

### E2: User loses authentication
**Trigger**: Any step - User session expires
1. System redirects to login page
2. System preserves form data in session storage
3. After re-authentication, system restores form data
4. Continue from step 5

## Business Rules
- **BR001**: Session names must be unique per user
- **BR002**: Users can have maximum 5 active sessions simultaneously
- **BR003**: Session names must be 3-50 characters long
- **BR004**: Only users with 'team_lead' or 'admin' role can create sessions
- **BR005**: Sessions auto-expire after 30 days of inactivity

## Data Requirements

### Input Data
- **session_name**: String (3-50 chars, required, unique per user)
- **description**: Text (optional, max 500 chars)
- **configuration_id**: Integer (optional, references SessionConfiguration)

### Output Data
- **session_id**: Integer (generated primary key)
- **created_at**: Timestamp (auto-generated)
- **status**: String (set to 'active')
- **user_id**: Integer (current user's ID)

## UI Requirements
- Form should use client-side validation for immediate feedback
- Session name field should check uniqueness on blur
- Configuration dropdown should show user's saved configurations only
- Form should be accessible (WCAG 2.1 AA compliant)
- Success/error messages should be displayed prominently

## Performance Requirements
- Session creation should complete within 2 seconds
- Form validation should respond within 500ms
- Configuration loading should complete within 1 second

## Security Requirements
- All input must be sanitized to prevent XSS attacks
- Session creation must be logged in audit trail
- User must be authorized before accessing session creation
- CSRF protection must be implemented for form submission

## Test Cases

### TC001: Successful session creation with minimal data
**Given**: Authenticated user on dashboard
**When**: User creates session with name "Bug Analysis Q4"
**Then**: Session is created and user is redirected to session workspace

### TC002: Session creation with saved configuration
**Given**: User has saved configuration "Default Bug Analysis"
**When**: User creates session and selects the saved configuration
**Then**: Session is created with configuration settings applied

### TC003: Duplicate session name validation
**Given**: User already has session named "Sprint Review"
**When**: User tries to create another session with same name
**Then**: Validation error is displayed and session is not created

### TC004: Maximum sessions limit reached
**Given**: User already has 5 active sessions
**When**: User tries to create a new session
**Then**: Error message is displayed with link to session management

### TC005: Session name length validation
**Given**: User on session creation form
**When**: User enters session name with 2 characters
**Then**: Validation error indicates minimum 3 characters required

## Acceptance Criteria
- [ ] User can create a new session with a unique name
- [ ] Session is automatically set to 'active' status
- [ ] User is redirected to session workspace after creation
- [ ] Validation prevents duplicate session names per user
- [ ] Form displays clear error messages for validation failures
- [ ] Session creation is logged in audit trail
- [ ] Saved configurations can be applied to new sessions
- [ ] Maximum session limit is enforced
- [ ] Session creation completes within performance requirements