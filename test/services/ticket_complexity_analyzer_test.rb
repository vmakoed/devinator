require "test_helper"

class TicketComplexityAnalyzerTest < ActiveSupport::TestCase
  # Test UC004 Complexity Scoring Algorithm
  # Test UC004 Acceptance Criteria: AC01, AC02, AC03, AC11
  # Test UC004 Business Rules: BR03, BR04

  setup do
    @mission = Mission.create!(name: "Test Mission", status: "in_progress", jql_query: "test query")
  end

  # BR03: Complexity score is based on objective factors
  # AC02: Each ticket receives a complexity score (1-10)
  test "should calculate base complexity score of 3 for minimal ticket" do
    ticket = create_ticket_with_minimal_data

    TicketComplexityAnalyzer.new(ticket).analyze!

    ticket.reload
    assert_equal 3, ticket.complexity_score  # base(3) + adequate_desc(0)
    assert_equal "low", ticket.complexity_category  # score 1-4 is low complexity
    assert ticket.analyzed?
  end

  # Test description length factor - very short (<100 chars)
  test "should add 2 complexity for very short description" do
    ticket = create_ticket_with_description("Short text", length: 50)

    TicketComplexityAnalyzer.new(ticket).analyze!

    ticket.reload
    assert_equal 5, ticket.complexity_score  # base(3) + short_desc(2)
    assert_equal 2, ticket.complexity_factors["description_length"]
  end

  # Test description length factor - short (100-500 chars)
  test "should add 1 complexity for short description" do
    ticket = create_ticket_with_description("A" * 250, length: 250)

    TicketComplexityAnalyzer.new(ticket).analyze!

    ticket.reload
    assert_equal 4, ticket.complexity_score  # base(3) + short(1)
    assert_equal 1, ticket.complexity_factors["description_length"]
  end

  # Test description length factor - adequate (500-2000 chars)
  test "should add 0 complexity for adequate description" do
    ticket = create_ticket_with_description("A" * 1000, length: 1000)

    TicketComplexityAnalyzer.new(ticket).analyze!

    ticket.reload
    assert_equal 3, ticket.complexity_score  # base(3) + adequate(0)
    assert_equal 0, ticket.complexity_factors["description_length"]
  end

  # Test description length factor - very long (>2000 chars)
  test "should add 1 complexity for very long description" do
    ticket = create_ticket_with_description("A" * 2500, length: 2500)

    TicketComplexityAnalyzer.new(ticket).analyze!

    ticket.reload
    assert_equal 4, ticket.complexity_score  # base(3) + long(1)
    assert_equal 1, ticket.complexity_factors["description_length"]
  end

  # BR04: Tickets must have minimum information to be analyzable
  # AC11: System handles tickets with missing data gracefully
  test "should handle missing description gracefully" do
    ticket = create_ticket_with_raw_data({
      "fields" => {
        "issuetype" => { "name" => "Bug" }
      }
    })

    TicketComplexityAnalyzer.new(ticket).analyze!

    ticket.reload
    assert_equal 5, ticket.complexity_score  # base(3) + missing_desc(2)
    assert_equal 2, ticket.complexity_factors["description_length"]
  end

  # Test comments factor - 0-2 comments
  test "should add 0 complexity for 0-2 comments" do
    ticket = create_ticket_with_comments(2)

    TicketComplexityAnalyzer.new(ticket).analyze!

    ticket.reload
    assert_equal 3, ticket.complexity_score  # base(3) + comments(0)
    assert_equal 0, ticket.complexity_factors["comments"]
  end

  # Test comments factor - 3-5 comments
  test "should add 1 complexity for 3-5 comments" do
    ticket = create_ticket_with_comments(4)

    TicketComplexityAnalyzer.new(ticket).analyze!

    ticket.reload
    assert_equal 4, ticket.complexity_score  # base(3) + comments(1)
    assert_equal 1, ticket.complexity_factors["comments"]
  end

  # Test comments factor - 6-10 comments
  test "should add 2 complexity for 6-10 comments" do
    ticket = create_ticket_with_comments(8)

    TicketComplexityAnalyzer.new(ticket).analyze!

    ticket.reload
    assert_equal 5, ticket.complexity_score  # base(3) + comments(2)
    assert_equal 2, ticket.complexity_factors["comments"]
  end

  # Test comments factor - >10 comments
  test "should add 3 complexity for more than 10 comments" do
    ticket = create_ticket_with_comments(15)

    TicketComplexityAnalyzer.new(ticket).analyze!

    ticket.reload
    assert_equal 6, ticket.complexity_score  # base(3) + comments(3)
    assert_equal 3, ticket.complexity_factors["comments"]
  end

  # Test linked issues factor - 0 links
  test "should add 0 complexity for no linked issues" do
    ticket = create_ticket_with_linked_issues(0)

    TicketComplexityAnalyzer.new(ticket).analyze!

    ticket.reload
    assert_equal 3, ticket.complexity_score
    assert_equal 0, ticket.complexity_factors["linked_issues"]
  end

  # Test linked issues factor - 1-2 links
  test "should add 1 complexity for 1-2 linked issues" do
    ticket = create_ticket_with_linked_issues(2)

    TicketComplexityAnalyzer.new(ticket).analyze!

    ticket.reload
    assert_equal 4, ticket.complexity_score  # base(3) + links(1)
    assert_equal 1, ticket.complexity_factors["linked_issues"]
  end

  # Test linked issues factor - 3-5 links
  test "should add 2 complexity for 3-5 linked issues" do
    ticket = create_ticket_with_linked_issues(4)

    TicketComplexityAnalyzer.new(ticket).analyze!

    ticket.reload
    assert_equal 5, ticket.complexity_score  # base(3) + links(2)
    assert_equal 2, ticket.complexity_factors["linked_issues"]
  end

  # Test linked issues factor - >5 links
  test "should add 3 complexity for more than 5 linked issues" do
    ticket = create_ticket_with_linked_issues(7)

    TicketComplexityAnalyzer.new(ticket).analyze!

    ticket.reload
    assert_equal 6, ticket.complexity_score  # base(3) + links(3)
    assert_equal 3, ticket.complexity_factors["linked_issues"]
  end

  # BR01: Only tickets with type "Bug" are considered for AI assignment
  # Test issue type factor - Bug
  test "should add 0 complexity for Bug issue type" do
    ticket = create_ticket_with_issue_type("Bug")

    TicketComplexityAnalyzer.new(ticket).analyze!

    ticket.reload
    assert_equal 3, ticket.complexity_score  # base(3) + bug(0)
    assert_equal 0, ticket.complexity_factors["issue_type"]
  end

  # Test issue type factor - Task
  test "should add 1 complexity for Task issue type" do
    ticket = create_ticket_with_issue_type("Task")

    TicketComplexityAnalyzer.new(ticket).analyze!

    ticket.reload
    assert_equal 4, ticket.complexity_score  # base(3) + task(1)
    assert_equal 1, ticket.complexity_factors["issue_type"]
  end

  # Test issue type factor - Story
  test "should add 2 complexity for Story issue type" do
    ticket = create_ticket_with_issue_type("Story")

    TicketComplexityAnalyzer.new(ticket).analyze!

    ticket.reload
    assert_equal 5, ticket.complexity_score  # base(3) + story(2)
    assert_equal 2, ticket.complexity_factors["issue_type"]
  end

  # Test issue type factor - Epic
  test "should add 3 complexity for Epic issue type" do
    ticket = create_ticket_with_issue_type("Epic")

    TicketComplexityAnalyzer.new(ticket).analyze!

    ticket.reload
    assert_equal 6, ticket.complexity_score  # base(3) + epic(3)
    assert_equal 3, ticket.complexity_factors["issue_type"]
  end

  # Test labels factor - quick-win
  test "should reduce complexity by 2 for quick-win label" do
    ticket = create_ticket_with_labels(["quick-win"])

    TicketComplexityAnalyzer.new(ticket).analyze!

    ticket.reload
    assert_equal 1, ticket.complexity_score  # base(3) + quick-win(-2), clamped to 1
    assert_equal(-2, ticket.complexity_factors["labels"])
  end

  # Test labels factor - technical-debt
  test "should add 0 complexity for technical-debt label" do
    ticket = create_ticket_with_labels(["technical-debt"])

    TicketComplexityAnalyzer.new(ticket).analyze!

    ticket.reload
    assert_equal 3, ticket.complexity_score  # base(3) + tech-debt(0)
    assert_equal 0, ticket.complexity_factors["labels"]
  end

  # Test labels factor - complex
  test "should add 3 complexity for complex label" do
    ticket = create_ticket_with_labels(["complex"])

    TicketComplexityAnalyzer.new(ticket).analyze!

    ticket.reload
    assert_equal 6, ticket.complexity_score  # base(3) + complex(3)
    assert_equal 3, ticket.complexity_factors["labels"]
  end

  # Test labels factor - needs-investigation
  test "should add 2 complexity for needs-investigation label" do
    ticket = create_ticket_with_labels(["needs-investigation"])

    TicketComplexityAnalyzer.new(ticket).analyze!

    ticket.reload
    assert_equal 5, ticket.complexity_score  # base(3) + needs-investigation(2)
    assert_equal 2, ticket.complexity_factors["labels"]
  end

  # Test labels factor - multiple labels
  test "should combine multiple label effects" do
    ticket = create_ticket_with_labels(["quick-win", "complex"])

    TicketComplexityAnalyzer.new(ticket).analyze!

    ticket.reload
    assert_equal 4, ticket.complexity_score  # base(3) + quick-win(-2) + complex(3) = 4
    assert_equal 1, ticket.complexity_factors["labels"]  # -2 + 3 = 1
  end

  # Test time in backlog factor - <31 days
  test "should add 0 complexity for tickets less than 31 days old" do
    ticket = create_ticket_with_age(20)

    TicketComplexityAnalyzer.new(ticket).analyze!

    ticket.reload
    assert_equal 3, ticket.complexity_score  # base(3) + age(0)
    assert_equal 0, ticket.complexity_factors["time_in_backlog"]
  end

  # Test time in backlog factor - 31-90 days
  test "should add 1 complexity for tickets 31-90 days old" do
    ticket = create_ticket_with_age(60)

    TicketComplexityAnalyzer.new(ticket).analyze!

    ticket.reload
    assert_equal 4, ticket.complexity_score  # base(3) + age(1)
    assert_equal 1, ticket.complexity_factors["time_in_backlog"]
  end

  # Test time in backlog factor - >90 days
  test "should add 1 complexity for tickets over 90 days old" do
    ticket = create_ticket_with_age(120)

    TicketComplexityAnalyzer.new(ticket).analyze!

    ticket.reload
    assert_equal 4, ticket.complexity_score  # base(3) + age(1)
    assert_equal 1, ticket.complexity_factors["time_in_backlog"]
  end

  # AC11: System handles tickets with missing data gracefully
  test "should handle missing jira_created_at gracefully" do
    ticket = create_ticket_with_minimal_data
    ticket.update_column(:jira_created_at, nil)

    TicketComplexityAnalyzer.new(ticket).analyze!

    ticket.reload
    assert_equal 3, ticket.complexity_score
    assert_equal 0, ticket.complexity_factors["time_in_backlog"]
  end

  # AC03: Tickets are categorized into low/medium/high complexity groups
  # BR02: Low-complexity threshold is score 1-4
  test "should categorize score 1-4 as low complexity" do
    ticket = create_ticket_with_labels(["quick-win"])

    TicketComplexityAnalyzer.new(ticket).analyze!

    ticket.reload
    assert_equal 1, ticket.complexity_score
    assert_equal "low", ticket.complexity_category
    assert ticket.low_complexity?
  end

  test "should categorize score 5-7 as medium complexity" do
    ticket = create_ticket_with_comments(8)  # 6-10 comments = +2, so base(3) + comments(2) = 5

    TicketComplexityAnalyzer.new(ticket).analyze!

    ticket.reload
    assert_equal 5, ticket.complexity_score
    assert_equal "medium", ticket.complexity_category
    assert ticket.medium_complexity?
  end

  test "should categorize score 8-10 as high complexity" do
    ticket = create_ticket_with_raw_data({
      "fields" => {
        "issuetype" => { "name" => "Epic" },
        "comment" => { "total" => 15 },
        "issuelinks" => Array.new(6, {}),
        "labels" => ["complex"]
      }
    })

    TicketComplexityAnalyzer.new(ticket).analyze!

    ticket.reload
    assert ticket.complexity_score >= 8
    assert_equal "high", ticket.complexity_category
    assert ticket.high_complexity?
  end

  # Test score clamping to 1-10 range
  test "should clamp score to minimum of 1" do
    ticket = create_ticket_with_raw_data({
      "fields" => {
        "description" => create_adf_document("A" * 1000),
        "issuetype" => { "name" => "Bug" },
        "labels" => ["quick-win", "quick-win"],  # Attempt to reduce below 1
        "comment" => { "total" => 0 },
        "issuelinks" => []
      }
    })

    TicketComplexityAnalyzer.new(ticket).analyze!

    ticket.reload
    assert ticket.complexity_score >= 1
    assert_equal "low", ticket.complexity_category
  end

  test "should clamp score to maximum of 10" do
    ticket = create_ticket_with_raw_data({
      "fields" => {
        "description" => create_adf_document("A" * 50),
        "issuetype" => { "name" => "Epic" },
        "labels" => ["complex", "needs-investigation"],
        "comment" => { "total" => 20 },
        "issuelinks" => Array.new(10, {})
      }
    })
    ticket.update_column(:jira_created_at, 100.days.ago)

    TicketComplexityAnalyzer.new(ticket).analyze!

    ticket.reload
    assert ticket.complexity_score <= 10
    assert_equal "high", ticket.complexity_category
  end

  # Test complexity factors are stored
  # AC09: Complexity factors are visible for each ticket
  test "should store all complexity factors in ticket" do
    ticket = create_ticket_with_raw_data({
      "fields" => {
        "description" => create_adf_document("A" * 250),
        "issuetype" => { "name" => "Bug" },
        "labels" => ["quick-win"],
        "comment" => { "total" => 4 },
        "issuelinks" => Array.new(2, {})
      }
    })
    ticket.update_column(:jira_created_at, 60.days.ago)

    TicketComplexityAnalyzer.new(ticket).analyze!

    ticket.reload
    factors = ticket.complexity_factors

    assert_equal 1, factors["description_length"]
    assert_equal 1, factors["comments"]
    assert_equal 1, factors["linked_issues"]
    assert_equal 0, factors["issue_type"]
    assert_equal(-2, factors["labels"])
    assert_equal 1, factors["time_in_backlog"]
  end

  # Test analyzed_at timestamp is set
  test "should set analyzed_at timestamp" do
    ticket = create_ticket_with_minimal_data
    assert_nil ticket.analyzed_at

    TicketComplexityAnalyzer.new(ticket).analyze!

    ticket.reload
    assert_not_nil ticket.analyzed_at
    assert ticket.analyzed_at <= Time.current
    assert ticket.analyzed_at >= 1.second.ago
  end

  # Test ADF (Atlassian Document Format) text extraction
  test "should extract text from nested ADF structure" do
    ticket = create_ticket_with_raw_data({
      "fields" => {
        "description" => {
          "type" => "doc",
          "content" => [
            {
              "type" => "paragraph",
              "content" => [
                { "type" => "text", "text" => "First paragraph" }
              ]
            },
            {
              "type" => "paragraph",
              "content" => [
                { "type" => "text", "text" => "Second paragraph" }
              ]
            }
          ]
        }
      }
    })

    TicketComplexityAnalyzer.new(ticket).analyze!

    ticket.reload
    # Both paragraphs combined should be short
    assert_equal 2, ticket.complexity_factors["description_length"]
  end

  # BR05: Analysis results are stored and can be re-displayed without re-analysis
  test "should update existing analysis when called again" do
    ticket = create_ticket_with_minimal_data

    # First analysis
    TicketComplexityAnalyzer.new(ticket).analyze!
    ticket.reload
    first_score = ticket.complexity_score
    first_analyzed_at = ticket.analyzed_at

    # Modify ticket data to change score
    ticket.update_column(:raw_data, {
      "fields" => {
        "issuetype" => { "name" => "Bug" },
        "labels" => ["complex"]
      }
    })

    # Second analysis
    sleep 0.01  # Ensure timestamp changes
    TicketComplexityAnalyzer.new(ticket).analyze!
    ticket.reload

    assert_not_equal first_score, ticket.complexity_score
    assert ticket.analyzed_at > first_analyzed_at
  end

  private

  def create_ticket_with_minimal_data
    # Create ticket with adequate description to avoid +2 penalty
    create_ticket_with_raw_data({
      "fields" => {
        "description" => create_adf_document("A" * 1000),  # Adequate length
        "issuetype" => { "name" => "Bug" }
      }
    })
  end

  def create_ticket_with_raw_data(raw_data)
    Ticket.create!(
      mission: @mission,
      jira_key: "TEST-#{rand(1000..9999)}",
      summary: "Test ticket",
      status: "Open",
      raw_data: raw_data
    )
  end

  def create_ticket_with_description(text, length:)
    create_ticket_with_raw_data({
      "fields" => {
        "description" => create_adf_document(text),
        "issuetype" => { "name" => "Bug" }
      }
    })
  end

  def create_adf_document(text)
    {
      "type" => "doc",
      "content" => [
        {
          "type" => "paragraph",
          "content" => [
            { "type" => "text", "text" => text }
          ]
        }
      ]
    }
  end

  def create_ticket_with_comments(count)
    create_ticket_with_raw_data({
      "fields" => {
        "description" => create_adf_document("A" * 1000),
        "issuetype" => { "name" => "Bug" },
        "comment" => { "total" => count }
      }
    })
  end

  def create_ticket_with_linked_issues(count)
    create_ticket_with_raw_data({
      "fields" => {
        "description" => create_adf_document("A" * 1000),
        "issuetype" => { "name" => "Bug" },
        "issuelinks" => Array.new(count, {})
      }
    })
  end

  def create_ticket_with_issue_type(type)
    create_ticket_with_raw_data({
      "fields" => {
        "description" => create_adf_document("A" * 1000),
        "issuetype" => { "name" => type }
      }
    })
  end

  def create_ticket_with_labels(labels)
    create_ticket_with_raw_data({
      "fields" => {
        "description" => create_adf_document("A" * 1000),
        "issuetype" => { "name" => "Bug" },
        "labels" => labels
      }
    })
  end

  def create_ticket_with_age(days)
    ticket = create_ticket_with_minimal_data
    ticket.update_column(:jira_created_at, days.days.ago)
    ticket
  end
end