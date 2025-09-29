# Devinator - Requirements Document

## Project Overview

Devinator is a proof of concept for an internal tool designed to help development teams tackle tech debt more efficiently by identifying low-complexity bug tickets in their JIRA backlog and assigning them to an AI engineer (Devin) for automated resolution.

The app guides users through the complete workflow: starting a mission → entering JQL queries → previewing tickets → AI analysis → reviewing recommendations → final confirmation → assignment to Devin.

## User Flow

1. **Start Mission**: A user starts a new "Mission"
2. **Enter JQL Query**: They enter a JQL query (used to fetch bug tickets from JIRA)
3. **Fetch & Preview**: The system fetches the matching tickets from the JIRA API and displays them in a list
4. **Review Tickets**: The user reviews and confirms the list of tickets
5. **Analyze Complexity**: The system analyzes each ticket and scores them based on their complexity (e.g., using heuristics like title length, presence of description, labels, etc.)
6. **Show Recommendations**: Based on the score, the system recommends which tickets are suitable to be assigned to Devin
7. **Confirm Selection**: The user reviews the recommendations and confirms the final selection
8. **Assign to Devin**: The system assigns the selected tickets to Devin (simulated by logging or Slack message)

## Functional Requirements

| ID | User Story | Priority | Status |
|----|------------|----------|--------|
| FR01 | As a development team lead, I want to start a new mission so that I can organize my ticket analysis workflow | High | Not Started |
| FR02 | As a development team lead, I want to input JQL queries to fetch specific tickets from JIRA so that I can focus on relevant bug tickets | High | Not Started |
| FR03 | As a development team lead, I want to preview fetched JIRA tickets with their details so that I can understand and confirm the scope of available work | High | Not Started |
| FR04 | As a development team lead, I want the system to automatically analyze and score ticket complexity so that I can identify which tickets are suitable for AI automation | High | Not Started |
| FR05 | As a development team lead, I want to see AI-generated recommendations of low-complexity bug tickets so that I can review suitable candidates for automation | High | Not Started |
| FR06 | As a development team lead, I want to review and confirm the final selection of tickets so that I can ensure only appropriate tickets are assigned | High | Not Started |
| FR07 | As a development team lead, I want to assign selected tickets to Devin (AI engineer) so that they can be automatically resolved | High | Not Started |
| FR08 | As a development team lead, I want to validate JQL syntax before execution so that I can avoid errors and wasted API calls | Medium | Not Started |
| FR09 | As a development team lead, I want to save and reuse JQL queries so that I can quickly access frequently used searches | Medium | Not Started |
| FR10 | As a development team lead, I want to track mission history and progress so that I can monitor automation effectiveness over time | Low | Not Started |

## Non-Functional Requirements

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| NFR01 | The system must integrate with JIRA API to fetch ticket data | High | Not Started |
| NFR02 | The system must provide a web-based user interface | High | Not Started |
| NFR03 | The system must validate JQL queries before execution | High | Not Started |
| NFR04 | The system must handle JIRA API rate limits gracefully | Medium | Not Started |
| NFR05 | The system must provide real-time feedback during ticket fetching | Medium | Not Started |
| NFR06 | The system must store mission data persistently across workflow steps | Medium | Not Started |
| NFR07 | The system must provide audit logging for compliance | Low | Not Started |
| NFR08 | The system must be responsive across desktop and tablet devices | Low | Not Started |

## MVP Scope - Mission-Based Workflow

For the MVP, we will implement the complete mission-based workflow with the following pages/screens:

### Required Pages/Screens
1. **Start a New Mission** - Mission creation and setup page
2. **Enter JQL Query** - Query input form with validation
3. **Preview Tickets** - Display fetched tickets from JIRA with review capability
4. **Analyze Tickets** - Show complexity scores and analysis results
5. **Display Recommended Tickets** - AI recommendations with rationale
6. **Final Confirmation and Assignment** - Review selections and assign to Devin

### End-to-End Workflow
1. **Mission Creation**: User starts a new mission to organize their workflow
2. **JQL Input**: User inputs and validates a JQL query to search for bug tickets
3. **Ticket Fetching**: System fetches tickets from JIRA API using the query
4. **Ticket Preview**: System displays the fetched tickets with key details for user review
5. **Complexity Analysis**: System analyzes tickets using heuristics (title length, description presence, labels, etc.)
6. **AI Recommendations**: System recommends low-complexity tickets suitable for Devin
7. **User Confirmation**: User reviews and confirms the final selection
8. **Devin Assignment**: System assigns selected tickets to Devin (simulated via logging/Slack)

## Out of Scope for MVP

- User authentication and authorization
- Role-based access control
- Advanced scalability features
- Complex integrations beyond JIRA
- Advanced analytics and reporting
- Multi-tenant architecture
- Advanced security features

## Technical Constraints

- Ruby on Rails 8.0.2
- SQLite database
- Tailwind CSS for styling
- Focus on desktop/tablet experience
- RESTful API design patterns

## Acceptance Criteria Summary

The MVP will be considered complete when:

1. A user can start a new mission
2. A user can input and validate JQL queries with real-time feedback
3. The system fetches and displays JIRA tickets with preview capability
4. A user can review and confirm the fetched tickets
5. The system analyzes tickets and displays complexity scores
6. The system generates and displays AI recommendations with rationale
7. A user can review and confirm final ticket selection
8. The system successfully assigns tickets to Devin (simulated)
9. All 6 required pages/screens are functional and connected
10. The complete mission workflow works end-to-end without errors

## Success Metrics

- User can complete a full mission workflow in under 8 minutes
- JQL validation prevents > 90% of invalid queries from being executed
- System correctly identifies at least 3 complexity factors per ticket
- Complexity scoring uses multiple heuristics (title length, description, labels, etc.)
- AI recommendations include at least 60% genuinely low-complexity tickets (when available)
- Mission workflow completion rate > 95% without technical errors
- User can navigate between all workflow steps intuitively