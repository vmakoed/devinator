# Use Case Diagram

This diagram illustrates the key use cases for the Devinator system, mapped to the functional requirements.

```mermaid
graph TB
    subgraph "Devinator System"
        UC001[UC001: Start Session<br/>FR001]
        UC002[UC002: Input JQL Query<br/>FR002]
        UC003[UC003: Fetch JIRA Tickets<br/>FR003]
        UC004[UC004: Review Ticket List<br/>FR004]
        UC005[UC005: Analyze Ticket Complexity<br/>FR005]
        UC006[UC006: Generate Recommendations<br/>FR006]
        UC007[UC007: Confirm Final Selection<br/>FR007]
        UC008[UC008: Assign Tickets to Devin<br/>FR008]
        UC009[UC009: View Complexity Details<br/>FR009]
        UC010[UC010: Override Complexity Assessment<br/>FR010]
        UC011[UC011: Configure Complexity Criteria<br/>FR011]
        UC012[UC012: Save/Load Session Configuration<br/>FR012]
    end

    subgraph "External Systems"
        JIRA[JIRA API]
        Devin[Devin AI Engineer]
        Slack[Slack Notifications]
    end

    subgraph "Actors"
        TL[Development Team Lead]
    end

    %% Primary workflow connections
    TL --> UC001
    TL --> UC002
    TL --> UC004
    TL --> UC007
    TL --> UC009
    TL --> UC010
    TL --> UC011
    TL --> UC012

    %% System interactions
    UC002 --> UC003
    UC003 --> JIRA
    UC004 --> UC005
    UC005 --> UC006
    UC007 --> UC008
    UC008 --> Devin
    UC008 --> Slack

    %% Supporting use cases
    TL --> UC009
    TL --> UC010
    TL --> UC011
    TL --> UC012

    %% Styling
    classDef primaryFlow fill:#e1f5fe
    classDef supportingFlow fill:#f3e5f5
    classDef actor fill:#e8f5e8
    classDef external fill:#fff3e0

    class UC001,UC002,UC003,UC004,UC005,UC006,UC007,UC008 primaryFlow
    class UC009,UC010,UC011,UC012 supportingFlow
    class TL actor
    class JIRA,Devin,Slack external
```

## Use Case Descriptions

### Primary Workflow Use Cases

**UC001: Start Session (FR001)**
- **Actor**: Development Team Lead
- **Description**: User initiates a new analysis session to begin the ticket evaluation process
- **Preconditions**: User has access to the system
- **Postconditions**: New session is created and ready for JQL input

**UC002: Input JQL Query (FR002)**
- **Actor**: Development Team Lead
- **Description**: User enters a JQL query to define which tickets to fetch from JIRA
- **Preconditions**: Session is active
- **Postconditions**: JQL query is validated and ready for execution

**UC003: Fetch JIRA Tickets (FR003)**
- **Actor**: System
- **Description**: System executes JQL query against JIRA API and retrieves matching tickets
- **Preconditions**: Valid JQL query is provided, JIRA connection is available
- **Postconditions**: Tickets are fetched and displayed to user

**UC004: Review Ticket List (FR004)**
- **Actor**: Development Team Lead
- **Description**: User reviews the fetched tickets and confirms the list for analysis
- **Preconditions**: Tickets have been fetched from JIRA
- **Postconditions**: Ticket list is confirmed for complexity analysis

**UC005: Analyze Ticket Complexity (FR005)**
- **Actor**: System
- **Description**: System automatically analyzes each ticket using complexity heuristics
- **Preconditions**: Ticket list is confirmed
- **Postconditions**: Each ticket has a complexity score

**UC006: Generate Recommendations (FR006)**
- **Actor**: System
- **Description**: System generates recommendations for which tickets are suitable for Devin
- **Preconditions**: Tickets have complexity scores
- **Postconditions**: Recommendations are generated and displayed

**UC007: Confirm Final Selection (FR007)**
- **Actor**: Development Team Lead
- **Description**: User reviews recommendations and confirms final ticket selection
- **Preconditions**: Recommendations are available
- **Postconditions**: Final ticket selection is confirmed

**UC008: Assign Tickets to Devin (FR008)**
- **Actor**: System
- **Description**: System assigns selected tickets to Devin and logs the assignment
- **Preconditions**: Final selection is confirmed
- **Postconditions**: Tickets are assigned, logged, and notifications sent

### Supporting Use Cases

**UC009: View Complexity Details (FR009)**
- **Actor**: Development Team Lead
- **Description**: User views detailed complexity scoring information for tickets
- **Preconditions**: Complexity analysis has been performed
- **Postconditions**: Complexity details are displayed

**UC010: Override Complexity Assessment (FR010)**
- **Actor**: Development Team Lead
- **Description**: User manually overrides system complexity assessment for specific tickets
- **Preconditions**: Complexity analysis exists
- **Postconditions**: Manual override is applied and recorded

**UC011: Configure Complexity Criteria (FR011)**
- **Actor**: Development Team Lead
- **Description**: User configures the heuristics and criteria used for complexity assessment
- **Preconditions**: User has administrative privileges
- **Postconditions**: Complexity criteria are updated

**UC012: Save/Load Session Configuration (FR012)**
- **Actor**: Development Team Lead
- **Description**: User saves current session configuration or loads a previously saved configuration
- **Preconditions**: Session is active
- **Postconditions**: Configuration is saved/loaded successfully