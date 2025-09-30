require "test_helper"

class TicketTest < ActiveSupport::TestCase
  # Test UC003 Business Rules: BR01, BR02, BR03

  setup do
    @mission = missions(:draft_mission)
    @mission.update!(status: "in_progress", jql_query: 'project = "TEST"')
  end

  # UC003 BR01: Tickets must include minimum fields: ID, title, status, priority
  test "should be valid with all required fields" do
    ticket = Ticket.new(
      mission: @mission,
      jira_key: "TEST-123",
      summary: "Fix bug in login",
      status: "Open"
    )
    assert ticket.valid?
  end

  # UC003 BR01: Tickets must include minimum fields
  test "should require jira_key presence" do
    ticket = Ticket.new(
      mission: @mission,
      summary: "Fix bug",
      status: "Open"
    )
    assert_not ticket.valid?
    assert_includes ticket.errors[:jira_key], "can't be blank"
  end

  test "should require summary presence" do
    ticket = Ticket.new(
      mission: @mission,
      jira_key: "TEST-123",
      status: "Open"
    )
    assert_not ticket.valid?
    assert_includes ticket.errors[:summary], "can't be blank"
  end

  test "should require status presence" do
    ticket = Ticket.new(
      mission: @mission,
      jira_key: "TEST-123",
      summary: "Fix bug"
    )
    assert_not ticket.valid?
    assert_includes ticket.errors[:status], "can't be blank"
  end

  # Test uniqueness constraint
  test "should require unique jira_key within mission scope" do
    # Create first ticket
    @mission.tickets.create!(
      jira_key: "TEST-999",
      summary: "First ticket",
      status: "Open"
    )

    # Try to create duplicate
    duplicate_ticket = @mission.tickets.build(
      jira_key: "TEST-999",
      summary: "Duplicate ticket",
      status: "Open"
    )

    assert_not duplicate_ticket.valid?
    assert_includes duplicate_ticket.errors[:jira_key], "has already been taken"
  end

  test "should allow same jira_key for different missions" do
    mission2 = Mission.create!(
      name: "Second Mission",
      status: "in_progress",
      jql_query: 'project = "TEST2"'
    )

    # Create ticket in first mission
    @mission.tickets.create!(
      jira_key: "TEST-777",
      summary: "First mission ticket",
      status: "Open"
    )

    # Create ticket with same key in second mission
    ticket2 = mission2.tickets.build(
      jira_key: "TEST-777",
      summary: "Second mission ticket",
      status: "Open"
    )

    assert ticket2.valid?
  end

  # Test association
  test "should belong to mission" do
    ticket = Ticket.new(
      jira_key: "TEST-555",
      summary: "Test ticket",
      status: "Open"
    )

    assert_nil ticket.mission

    ticket.mission = @mission
    assert_equal @mission, ticket.mission
  end

  # Test optional fields
  test "should allow optional fields to be nil" do
    ticket = Ticket.new(
      mission: @mission,
      jira_key: "TEST-444",
      summary: "Minimal ticket",
      status: "Open",
      description: nil,
      priority: nil,
      assignee: nil,
      labels: nil,
      jira_created_at: nil,
      raw_data: nil
    )
    assert ticket.valid?
  end

  # UC003 BR02: Description preview is limited to first 200 characters
  test "should store full description even if long" do
    long_description = "A" * 500

    ticket = @mission.tickets.create!(
      jira_key: "TEST-LONG",
      summary: "Ticket with long description",
      status: "Open",
      description: long_description
    )

    assert_equal 500, ticket.description.length
    assert ticket.description.start_with?("AAAA")
  end

  # Test saving all fields
  test "should save all ticket fields correctly" do
    created_time = Time.parse("2025-09-15 10:30:00 UTC")

    ticket = @mission.tickets.create!(
      jira_key: "TEST-FULL",
      summary: "Complete ticket",
      description: "Full description here",
      status: "In Progress",
      priority: "High",
      assignee: "john@example.com",
      labels: "bug, urgent, security",
      jira_created_at: created_time,
      raw_data: { "key" => "TEST-FULL", "fields" => { "extra" => "data" } }
    )

    ticket.reload
    assert_equal "TEST-FULL", ticket.jira_key
    assert_equal "Complete ticket", ticket.summary
    assert_equal "Full description here", ticket.description
    assert_equal "In Progress", ticket.status
    assert_equal "High", ticket.priority
    assert_equal "john@example.com", ticket.assignee
    assert_equal "bug, urgent, security", ticket.labels
    assert_equal created_time.to_i, ticket.jira_created_at.to_i
    assert_equal({ "key" => "TEST-FULL", "fields" => { "extra" => "data" } }, ticket.raw_data)
  end

  # Test UUID generation
  test "should auto-generate UUID for id before create" do
    ticket = @mission.tickets.create!(
      jira_key: "TEST-UUID",
      summary: "Test UUID generation",
      status: "Open"
    )

    assert ticket.id.present?
    assert_match(/\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/, ticket.id)
  end

  test "should allow manual UUID assignment" do
    custom_uuid = "12345678-1234-1234-1234-123456789abc"

    ticket = @mission.tickets.create!(
      id: custom_uuid,
      jira_key: "TEST-CUSTOM-UUID",
      summary: "Custom UUID ticket",
      status: "Open"
    )

    assert_equal custom_uuid, ticket.id
  end

  # Test ticket count for mission
  test "mission should have correct ticket count" do
    assert_equal 0, @mission.tickets.count

    @mission.tickets.create!(
      jira_key: "TEST-1",
      summary: "First",
      status: "Open"
    )

    @mission.tickets.create!(
      jira_key: "TEST-2",
      summary: "Second",
      status: "Open"
    )

    assert_equal 2, @mission.tickets.count
  end

  # Test cascading delete (tickets should be deleted when mission is deleted)
  test "tickets should be deleted when mission is deleted" do
    @mission.tickets.create!(
      jira_key: "TEST-CASCADE",
      summary: "Will be deleted",
      status: "Open"
    )

    assert_difference "Ticket.count", -1 do
      @mission.destroy
    end
  end

  # Test updating tickets
  test "should allow updating ticket fields" do
    ticket = @mission.tickets.create!(
      jira_key: "TEST-UPDATE",
      summary: "Original summary",
      status: "Open",
      priority: "Low"
    )

    ticket.update!(
      summary: "Updated summary",
      status: "In Progress",
      priority: "High"
    )

    ticket.reload
    assert_equal "Updated summary", ticket.summary
    assert_equal "In Progress", ticket.status
    assert_equal "High", ticket.priority
  end

  # Test labels as comma-separated string
  test "should handle labels as comma-separated string" do
    ticket = @mission.tickets.create!(
      jira_key: "TEST-LABELS",
      summary: "Ticket with labels",
      status: "Open",
      labels: "frontend, css, bug"
    )

    assert_equal "frontend, css, bug", ticket.labels
  end

  test "should handle empty labels" do
    ticket = @mission.tickets.create!(
      jira_key: "TEST-NO-LABELS",
      summary: "Ticket without labels",
      status: "Open",
      labels: ""
    )

    assert_equal "", ticket.labels
  end

  # Test raw_data JSON field
  test "should store complex JSON in raw_data" do
    complex_data = {
      "id" => "12345",
      "key" => "TEST-JSON",
      "fields" => {
        "project" => { "key" => "TEST", "name" => "Test Project" },
        "issuetype" => { "name" => "Bug" },
        "customFields" => ["field1", "field2"]
      }
    }

    ticket = @mission.tickets.create!(
      jira_key: "TEST-JSON",
      summary: "Ticket with JSON",
      status: "Open",
      raw_data: complex_data
    )

    ticket.reload
    assert_equal complex_data, ticket.raw_data
    assert_equal "Test Project", ticket.raw_data["fields"]["project"]["name"]
  end
end