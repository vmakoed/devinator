# UC002: Input JQL Query

## Use Case Overview

**Use Case ID**: UC002
**Use Case Name**: Input JQL Query
**Functional Requirement**: FR002
**Actor**: Development Team Lead
**Priority**: High
**Status**: Not Started

## Description

As a development team lead, I want to input JQL queries so that I can fetch specific bug tickets from JIRA for complexity analysis and potential assignment to Devin.

## Preconditions

1. User is authenticated and has appropriate permissions
2. An active session exists (UC001 completed)
3. User has access to JIRA and understands JQL syntax
4. Session is in a state that can accept JQL queries

## Main Flow

1. User navigates to the JQL query input interface within an active session
2. System displays JQL query form with:
   - Text area for JQL query input
   - Query validation feedback
   - Template/example queries dropdown
   - Query history (if available)
   - Save query option
3. User enters or selects a JQL query
4. System validates JQL syntax in real-time
5. User reviews and confirms the query
6. System saves the query to the session
7. System enables the "Fetch Tickets" action for UC003

## Alternative Flows

### Alt Flow 1: Invalid JQL Syntax
1. User enters invalid JQL syntax
2. System displays validation error with specific feedback
3. System suggests corrections or provides syntax help
4. User corrects the query
5. Return to main flow step 4

### Alt Flow 2: Load Saved Query
1. User selects a previously saved query from history
2. System populates the query field
3. Continue with main flow step 4

### Alt Flow 3: Use Query Template
1. User selects from predefined query templates
2. System populates query field with template
3. User can modify the template as needed
4. Continue with main flow step 4

## Exception Flows

### Exception 1: Session Not Active
- **Condition**: User attempts to input query without active session
- **Action**: System redirects to session creation (UC001)
- **Recovery**: Return to main flow after session is created

### Exception 2: Permission Denied
- **Condition**: User lacks permission to create JQL queries
- **Action**: System displays error message and disables query input
- **Recovery**: Contact administrator for permissions

## Postconditions

### Success Postconditions
1. JQL query is validated and stored in the session
2. Query is available for ticket fetching (UC003)
3. Query is saved to user's query history
4. Session state updated to "query_ready"

### Failure Postconditions
1. Invalid query is not saved
2. Session remains in previous state
3. User receives clear error feedback

## Business Rules

1. **BR001**: Only users with session creation permissions can input JQL queries
2. **BR002**: JQL queries must be syntactically valid before saving
3. **BR003**: Each session can have multiple JQL queries
4. **BR004**: Query history is maintained per user across sessions
5. **BR005**: Queries are automatically validated against JIRA API format
6. **BR006**: Maximum query length is 2000 characters
7. **BR007**: Queries are logged for audit purposes

## Data Requirements

### Input Data
- JQL query string (required)
- Query name/description (optional)
- Save to history flag (optional)

### Output Data
- Validation results
- Query ID (for saved queries)
- Formatted query display
- Query execution readiness status

## Interface Requirements

### User Interface
- Clean, intuitive query input form
- Real-time syntax validation feedback
- Autocomplete for JQL functions and fields
- Query history dropdown
- Template library access
- Clear error messaging

### System Interface
- JIRA API connectivity for validation
- Session state management
- Query persistence layer
- Audit logging integration

## Performance Requirements

- Query validation response time: < 2 seconds
- Query save operation: < 1 second
- Template/history loading: < 1 second
- Real-time validation feedback: < 500ms

## Security Requirements

1. Input sanitization to prevent injection attacks
2. JQL query validation against malicious patterns
3. User permission verification before query creation
4. Audit logging of all query operations
5. Secure storage of query history

## Acceptance Criteria

1. **AC001**: User can input valid JQL queries and receive confirmation
2. **AC002**: Invalid queries are rejected with clear error messages
3. **AC003**: Query templates are available and functional
4. **AC004**: Query history is accessible and usable
5. **AC005**: Real-time validation works correctly
6. **AC006**: Saved queries persist across sessions
7. **AC007**: All query operations are logged for audit
8. **AC008**: System handles edge cases (empty queries, very long queries)
9. **AC009**: Integration with session management works correctly
10. **AC010**: User permissions are properly enforced

## Test Scenarios

### Functional Tests
- Valid JQL query input and validation
- Invalid JQL syntax handling
- Query template selection and modification
- Query history loading and reuse
- Query saving and persistence
- Session integration

### Integration Tests
- JIRA API connectivity for validation
- Session state management integration
- Audit logging verification
- Permission system integration

### Performance Tests
- Validation response time under load
- Concurrent query operations
- Large query handling
- Template/history loading performance

### Security Tests
- Input sanitization verification
- Malicious query detection
- Permission bypass attempts
- Audit log integrity

## Dependencies

### Internal Dependencies
- UC001: Start Session (must be completed first)
- Session management system
- User authentication and authorization
- Audit logging system

### External Dependencies
- JIRA API for query validation
- Database for query persistence
- User permission system

## Risk Assessment

### Technical Risks
- JIRA API connectivity issues
- JQL syntax validation complexity
- Query performance with large datasets
- Real-time validation latency

### Business Risks
- User error in complex JQL queries
- Over-reliance on templates
- Query history privacy concerns
- Audit compliance requirements

### Mitigation Strategies
- Robust error handling and user feedback
- Comprehensive template library
- Clear privacy policies for query history
- Regular audit log reviews and compliance checks

## Future Enhancements

1. Advanced JQL query builder UI
2. Query performance optimization suggestions
3. Collaborative query sharing
4. Integration with JIRA query favorites
5. Machine learning-based query suggestions
6. Query result preview functionality
7. Scheduled query execution
8. Query performance metrics and analytics