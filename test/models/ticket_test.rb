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
        "customFields" => [ "field1", "field2" ]
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

  # UC005 Tests - Selection functionality
  # Test selection fields and methods

  test "should default selected_for_assignment to false" do
    ticket = @mission.tickets.create!(
      jira_key: "TEST-SEL-1",
      summary: "Test selection",
      status: "Open"
    )

    assert_not ticket.selected_for_assignment
    assert_not ticket.selected?
    assert_nil ticket.selected_at
  end

  test "should select ticket for assignment" do
    ticket = @mission.tickets.create!(
      jira_key: "TEST-SEL-2",
      summary: "Test selection",
      status: "Open"
    )

    ticket.select_for_assignment!

    ticket.reload
    assert ticket.selected_for_assignment
    assert ticket.selected?
    assert_not_nil ticket.selected_at
    assert ticket.selected_at <= Time.current
  end

  test "should deselect ticket for assignment" do
    ticket = @mission.tickets.create!(
      jira_key: "TEST-SEL-3",
      summary: "Test selection",
      status: "Open"
    )

    # First select it
    ticket.select_for_assignment!
    assert ticket.selected?

    # Then deselect it
    ticket.deselect_for_assignment!

    ticket.reload
    assert_not ticket.selected_for_assignment
    assert_not ticket.selected?
    assert_nil ticket.selected_at
  end

  test "selected_for_assignment scope should return only selected tickets" do
    # Create selected tickets
    2.times do |i|
      ticket = @mission.tickets.create!(
        jira_key: "SELECTED-#{i + 1}",
        summary: "Selected ticket",
        status: "Open"
      )
      ticket.select_for_assignment!
    end

    # Create unselected tickets
    3.times do |i|
      @mission.tickets.create!(
        jira_key: "UNSELECTED-#{i + 1}",
        summary: "Unselected ticket",
        status: "Open"
      )
    end

    selected = @mission.tickets.selected_for_assignment
    assert_equal 2, selected.count
    selected.each do |ticket|
      assert ticket.selected_for_assignment
    end
  end

  test "not_selected scope should return only unselected tickets" do
    # Create selected tickets
    2.times do |i|
      ticket = @mission.tickets.create!(
        jira_key: "SELECTED-#{i + 1}",
        summary: "Selected ticket",
        status: "Open"
      )
      ticket.select_for_assignment!
    end

    # Create unselected tickets
    3.times do |i|
      @mission.tickets.create!(
        jira_key: "UNSELECTED-#{i + 1}",
        summary: "Unselected ticket",
        status: "Open"
      )
    end

    not_selected = @mission.tickets.not_selected
    assert_equal 3, not_selected.count
    not_selected.each do |ticket|
      assert_not ticket.selected_for_assignment
    end
  end

  # Test complexity category validations
  test "should validate complexity_score range" do
    ticket = @mission.tickets.build(
      jira_key: "TEST-COMPLEX",
      summary: "Test complexity",
      status: "Open",
      complexity_score: 11
    )

    assert_not ticket.valid?
    assert_includes ticket.errors[:complexity_score], "is not included in the list"
  end

  test "should allow valid complexity_score values" do
    (1..10).each do |score|
      ticket = @mission.tickets.build(
        jira_key: "TEST-SCORE-#{score}",
        summary: "Test score #{score}",
        status: "Open",
        complexity_score: score
      )
      assert ticket.valid?
    end
  end

  test "should validate complexity_category values" do
    invalid_ticket = @mission.tickets.build(
      jira_key: "TEST-CAT-1",
      summary: "Test category",
      status: "Open",
      complexity_category: "invalid"
    )

    assert_not invalid_ticket.valid?
    assert_includes invalid_ticket.errors[:complexity_category], "is not included in the list"
  end

  test "should allow valid complexity_category values" do
    [ "low", "medium", "high" ].each do |category|
      ticket = @mission.tickets.build(
        jira_key: "TEST-CAT-#{category}",
        summary: "Test category #{category}",
        status: "Open",
        complexity_category: category
      )
      assert ticket.valid?
    end
  end

  # Test complexity helper methods
  test "should identify low complexity tickets" do
    ticket = @mission.tickets.create!(
      jira_key: "TEST-LOW",
      summary: "Low complexity",
      status: "Open",
      complexity_category: "low",
      complexity_score: 2
    )

    assert ticket.low_complexity?
    assert_not ticket.medium_complexity?
    assert_not ticket.high_complexity?
  end

  test "should identify medium complexity tickets" do
    ticket = @mission.tickets.create!(
      jira_key: "TEST-MED",
      summary: "Medium complexity",
      status: "Open",
      complexity_category: "medium",
      complexity_score: 5
    )

    assert_not ticket.low_complexity?
    assert ticket.medium_complexity?
    assert_not ticket.high_complexity?
  end

  test "should identify high complexity tickets" do
    ticket = @mission.tickets.create!(
      jira_key: "TEST-HIGH",
      summary: "High complexity",
      status: "Open",
      complexity_category: "high",
      complexity_score: 8
    )

    assert_not ticket.low_complexity?
    assert_not ticket.medium_complexity?
    assert ticket.high_complexity?
  end

  # Test analyzed? method
  test "should identify analyzed tickets" do
    unanalyzed = @mission.tickets.create!(
      jira_key: "TEST-UNANALYZED",
      summary: "Not analyzed",
      status: "Open"
    )

    assert_not unanalyzed.analyzed?

    analyzed = @mission.tickets.create!(
      jira_key: "TEST-ANALYZED",
      summary: "Analyzed",
      status: "Open",
      analyzed_at: Time.current,
      complexity_score: 3,
      complexity_category: "low"
    )

    assert analyzed.analyzed?
  end

  # Test scopes work together
  test "should combine complexity and selection scopes" do
    # Create low-complexity selected ticket
    low_selected = @mission.tickets.create!(
      jira_key: "LOW-SEL",
      summary: "Low selected",
      status: "Open",
      complexity_category: "low"
    )
    low_selected.select_for_assignment!

    # Create low-complexity unselected ticket
    @mission.tickets.create!(
      jira_key: "LOW-UNSEL",
      summary: "Low unselected",
      status: "Open",
      complexity_category: "low"
    )

    # Create medium-complexity selected ticket
    med_selected = @mission.tickets.create!(
      jira_key: "MED-SEL",
      summary: "Medium selected",
      status: "Open",
      complexity_category: "medium"
    )
    med_selected.select_for_assignment!

    # Test combined scopes
    low_and_selected = @mission.tickets.low_complexity.selected_for_assignment
    assert_equal 1, low_and_selected.count
    assert_equal "LOW-SEL", low_and_selected.first.jira_key

    all_low = @mission.tickets.low_complexity
    assert_equal 2, all_low.count
  end
end
