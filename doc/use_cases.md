# Use Cases - Devinator MVP

## Use Case Diagram

```mermaid
graph TB
    User[Development Team Lead]

    %% Core MVP Use Cases (Happy Flow)
    UC001[UC001: Start Mission<br/>Start a new mission to organize workflow]
    UC002[UC002: Input JQL Query<br/>Enter JQL query to fetch bug tickets from JIRA]
    UC003[UC003: Preview Tickets<br/>Preview and confirm fetched JIRA tickets]
    UC004[UC004: Analyze Complexity<br/>System analyzes and scores ticket complexity]
    UC005[UC005: Confirm Selection<br/>Review and confirm final ticket selection]
    UC006[UC006: Assign to Devin<br/>Assign selected tickets to AI engineer]

    %% External Systems
    JIRA[(JIRA API)]
    Devin[AI Engineer - Devin]

    %% User interactions
    User --> UC001
    User --> UC002
    User --> UC003
    User --> UC005
    User --> UC006

    %% System interactions
    UC002 --> JIRA
    UC003 --> JIRA
    UC004 --> UC004
    UC006 --> Devin

    %% Sequential workflow
    UC001 -.-> UC002
    UC002 -.-> UC003
    UC003 -.-> UC004
    UC004 -.-> UC005
    UC005 -.-> UC006

    %% Styling
    classDef mvpCore fill:#ff6b6b,stroke:#c92a2a,color:#fff
    classDef external fill:#e9ecef,stroke:#868e96,color:#000

    class UC001,UC002,UC003,UC004,UC005,UC006 mvpCore
    class JIRA,Devin external
```

## Use Case Descriptions

### Core MVP Use Cases (Happy Flow)

**UC001: Start Mission**
- Actor: Development Team Lead
- Description: Start a new mission to organize ticket analysis workflow
- Priority: High

**UC002: Input JQL Query**
- Actor: Development Team Lead
- Description: Enter JQL query to fetch specific bug tickets from JIRA
- Priority: High

**UC003: Preview Tickets**
- Actor: Development Team Lead
- Description: Preview and confirm fetched JIRA tickets with details
- Priority: High

**UC004: Analyze Complexity**
- Actor: System
- Description: Automatically analyze and score ticket complexity using heuristics
- Priority: High

**UC005: Confirm Selection**
- Actor: Development Team Lead
- Description: Review and confirm final ticket selection for assignment
- Priority: High

**UC006: Assign to Devin**
- Actor: Development Team Lead
- Description: Assign selected tickets to Devin (AI engineer) for resolution
- Priority: High

## MVP Happy Flow Sequence

The complete MVP workflow follows this linear sequence:

1. **UC001** (Start Mission) →
2. **UC002** (Input JQL Query) →
3. **UC003** (Preview Tickets) →
4. **UC004** (Analyze Complexity) →
5. **UC005** (Confirm Selection) →
6. **UC006** (Assign to Devin)

This represents the essential end-to-end workflow with no optional features or alternative paths.