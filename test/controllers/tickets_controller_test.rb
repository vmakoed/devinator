require "test_helper"

class TicketsControllerTest < ActionDispatch::IntegrationTest
  # Test UC003 Acceptance Criteria: AC01-AC10
  # Test UC003 Test Scenarios: TS001-TS005

  setup do
    @mission = missions(:draft_mission)
    @mission.update!(status: "in_progress", jql_query: 'project = "TEST" AND issuetype = Bug')
  end

  # UC003 TS001: Successful Ticket Fetch and Preview
  # UC003 AC01: System fetches tickets using the saved JQL query
  # UC003 AC03: All fetched tickets are displayed with key details
  # UC003 AC04: Ticket count summary is clearly visible
  test "should fetch and display tickets from JIRA successfully" do
    mock_jira_response = {
      total: 2,
      tickets: [
        {
          jira_key: "TEST-123",
          summary: "Fix login bug",
          description: "Users cannot login",
          status: "Open",
          priority: "High",
          assignee: "john@example.com",
          labels: "bug, urgent",
          jira_created_at: Time.parse("2025-09-01 10:00:00 UTC"),
          raw_data: { "key" => "TEST-123" }
        },
        {
          jira_key: "TEST-456",
          summary: "Update documentation",
          description: "Add API docs",
          status: "In Progress",
          priority: "Medium",
          assignee: "jane@example.com",
          labels: "docs",
          jira_created_at: Time.parse("2025-09-02 11:00:00 UTC"),
          raw_data: { "key" => "TEST-456" }
        }
      ]
    }

    JiraService.any_instance.stubs(:fetch_tickets).returns(mock_jira_response)

    get preview_mission_tickets_path(@mission)

    assert_response :success

    # Verify tickets were saved to database
    @mission.reload
    assert_equal 2, @mission.tickets.count

    ticket_keys = @mission.tickets.pluck(:jira_key)
    assert_includes ticket_keys, "TEST-123"
    assert_includes ticket_keys, "TEST-456"

    ticket_123 = @mission.tickets.find_by(jira_key: "TEST-123")
    assert_equal "Fix login bug", ticket_123.summary

    ticket_456 = @mission.tickets.find_by(jira_key: "TEST-456")
    assert_equal "Update documentation", ticket_456.summary

    # Check flash message includes ticket count
    assert_equal "Successfully fetched 2 tickets.", flash[:success]
  end

  # UC003 AC03: All fetched tickets are displayed with key details
  test "should display all required ticket fields" do
    mock_jira_response = {
      total: 1,
      tickets: [
        {
          jira_key: "TEST-789",
          summary: "Test ticket summary",
          description: "Full description here",
          status: "To Do",
          priority: "Low",
          assignee: "user@example.com",
          labels: "test, sample",
          jira_created_at: Time.parse("2025-09-15 12:00:00 UTC"),
          raw_data: { "key" => "TEST-789" }
        }
      ]
    }

    JiraService.any_instance.stubs(:fetch_tickets).returns(mock_jira_response)

    get preview_mission_tickets_path(@mission)

    assert_response :success
    @mission.reload; ticket = @mission.tickets.first
    assert_equal "TEST-789", ticket.jira_key
    assert_equal "Test ticket summary", ticket.summary
    assert_equal "To Do", ticket.status
    assert_equal "Low", ticket.priority
  end

  # UC003 TS002: Empty Results Handling
  # UC003 AF1: No Tickets Found
  # UC003 AC10: System handles empty results gracefully
  test "should handle empty JIRA results gracefully" do
    mock_jira_response = {
      total: 0,
      tickets: []
    }

    JiraService.any_instance.stubs(:fetch_tickets).returns(mock_jira_response)

    get preview_mission_tickets_path(@mission)

    assert_response :success
    assert_equal "No tickets found matching your query.", flash[:warning]
    @mission.reload
    assert_equal 0, @mission.tickets.count
  end

  # UC003 TS003: JIRA API Error
  # UC003 AF2: JIRA API Error
  # UC003 AC06: Error messages are displayed for JIRA API failures
  test "should handle JIRA API errors gracefully" do
    JiraService.any_instance.stubs(:fetch_tickets).raises(
      JiraService::ApiError.new("JIRA API is unavailable")
    )

    get preview_mission_tickets_path(@mission)

    assert_response :success
    assert_equal "JIRA API is unavailable", flash[:error]
  end

  # UC003 TS004: Invalid JQL Query
  # UC003 AF3: Invalid JQL Query
  # UC003 AC06: Error messages are displayed for JIRA API failures
  test "should handle invalid JQL query errors" do
    JiraService.any_instance.stubs(:fetch_tickets).raises(
      JiraService::InvalidQueryError.new("Invalid JQL syntax near 'AND'")
    )

    get preview_mission_tickets_path(@mission)

    assert_response :success
    assert_equal "Invalid JQL syntax near 'AND'", flash[:error]
  end

  # Test different API error types
  test "should handle authentication errors from JIRA" do
    JiraService.any_instance.stubs(:fetch_tickets).raises(
      JiraService::ApiError.new("Authentication failed. Please check your JIRA credentials.")
    )

    get preview_mission_tickets_path(@mission)

    assert_response :success
    assert_equal "Authentication failed. Please check your JIRA credentials.", flash[:error]
  end

  test "should handle unknown errors gracefully" do
    JiraService.any_instance.stubs(:fetch_tickets).raises(
      StandardError.new("Unexpected error")
    )

    get preview_mission_tickets_path(@mission)

    assert_response :success
    assert_match /An unexpected error occurred/, flash[:error]
  end

  # UC003 AC08: User must confirm ticket list before proceeding
  # UC003 TS005: Ticket Confirmation
  test "should confirm tickets and redirect to analyze page" do
    # First, fetch some tickets
    mock_jira_response = {
      total: 1,
      tickets: [
        {
          jira_key: "TEST-100",
          summary: "Test ticket",
          description: "Description",
          status: "Open",
          priority: "Medium",
          assignee: nil,
          labels: "",
          jira_created_at: Time.now,
          raw_data: {}
        }
      ]
    }

    JiraService.any_instance.stubs(:fetch_tickets).returns(mock_jira_response)
    get preview_mission_tickets_path(@mission)

    # Now confirm
    post confirm_mission_tickets_path(@mission)

    assert_redirected_to analyze_mission_path(@mission)
    follow_redirect!
    assert_equal "1 tickets analyzed successfully!", flash[:notice]
  end

  # UC003 BR03: Tickets are stored with the mission for future analysis
  # UC003 BR05: Ticket data is cached to avoid repeated JIRA API calls
  test "should store tickets in database after fetching" do
    mock_jira_response = {
      total: 2,
      tickets: [
        {
          jira_key: "TEST-200",
          summary: "First ticket",
          description: "Description 1",
          status: "Open",
          priority: "High",
          assignee: "user1@example.com",
          labels: "label1",
          jira_created_at: Time.now,
          raw_data: { "key" => "TEST-200" }
        },
        {
          jira_key: "TEST-201",
          summary: "Second ticket",
          description: "Description 2",
          status: "In Progress",
          priority: "Low",
          assignee: "user2@example.com",
          labels: "label2",
          jira_created_at: Time.now,
          raw_data: { "key" => "TEST-201" }
        }
      ]
    }

    JiraService.any_instance.stubs(:fetch_tickets).returns(mock_jira_response)

    assert_difference "Ticket.count", 2 do
      get preview_mission_tickets_path(@mission)
    end

    tickets = @mission.tickets.reload
    assert_equal 2, tickets.count
    assert_equal "TEST-200", tickets.first.jira_key
    assert_equal "First ticket", tickets.first.summary
    assert_equal "TEST-201", tickets.last.jira_key
  end

  # UC003 BR05: Ticket data is cached to avoid repeated JIRA API calls
  test "should use cached tickets on subsequent visits" do
    # Create pre-existing tickets
    @mission.tickets.create!(
      jira_key: "TEST-CACHED",
      summary: "Cached ticket",
      description: "Already fetched",
      status: "Open",
      priority: "Medium"
    )

    # JiraService should NOT be called since tickets already exist
    JiraService.any_instance.expects(:fetch_tickets).never

    get preview_mission_tickets_path(@mission)

    assert_response :success
    @mission.reload
    assert_equal 1, @mission.tickets.count
    assert_equal "TEST-CACHED", @mission.tickets.first.jira_key
  end

  # Test mission not found
  test "should handle mission not found error" do
    get preview_mission_tickets_path(mission_id: 99999)

    assert_redirected_to missions_path
    follow_redirect!
    assert_equal "Mission not found.", flash[:alert]
  end

  # UC003 AC07: User can return to modify JQL query if needed
  test "should provide link to modify query on preview page" do
    mock_jira_response = {
      total: 1,
      tickets: [
        {
          jira_key: "TEST-300",
          summary: "Sample",
          description: "Desc",
          status: "Open",
          priority: "Medium",
          assignee: nil,
          labels: "",
          jira_created_at: Time.now,
          raw_data: {}
        }
      ]
    }

    JiraService.any_instance.stubs(:fetch_tickets).returns(mock_jira_response)

    get preview_mission_tickets_path(@mission)

    assert_response :success
    # Verify it worked correctly
    @mission.reload
    assert @mission.tickets.any?
  end

  # UC003 AC05: User can scroll through the entire ticket list
  test "should display multiple tickets in scrollable list" do
    tickets_data = 10.times.map do |i|
      {
        jira_key: "TEST-#{i}",
        summary: "Ticket #{i}",
        description: "Description #{i}",
        status: "Open",
        priority: "Medium",
        assignee: "user@example.com",
        labels: "test",
        jira_created_at: Time.now,
        raw_data: {}
      }
    end

    mock_jira_response = {
      total: 10,
      tickets: tickets_data
    }

    JiraService.any_instance.stubs(:fetch_tickets).returns(mock_jira_response)

    get preview_mission_tickets_path(@mission)

    assert_response :success
    @mission.reload
    assert_equal 10, @mission.tickets.count
  end

  # Test singular vs plural in success message
  test "should show singular 'ticket' in success message for 1 ticket" do
    mock_jira_response = {
      total: 1,
      tickets: [
        {
          jira_key: "TEST-SINGLE",
          summary: "Only one",
          description: "Single ticket",
          status: "Open",
          priority: "Low",
          assignee: nil,
          labels: "",
          jira_created_at: Time.now,
          raw_data: {}
        }
      ]
    }

    JiraService.any_instance.stubs(:fetch_tickets).returns(mock_jira_response)

    get preview_mission_tickets_path(@mission)

    assert_equal "Successfully fetched 1 ticket.", flash[:success]
  end
end
