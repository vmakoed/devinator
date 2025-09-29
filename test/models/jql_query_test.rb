require "test_helper"

class JqlQueryTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(
      email: "test@example.com",
      name: "Test User",
      role: "admin",
      password_hash: "test_hash",
      is_active: true
    )
    @session = Session.create!(user: @user, name: "Test Session")
  end

  # UC002 Core Validation Tests

  test "should be valid with valid attributes" do
    query = JqlQuery.new(
      session: @session,
      query_text: 'project = "TEST" AND issuetype = Bug'
    )

    assert query.valid?
    assert query.save
    assert_equal "pending", query.status
  end

  test "should require query_text" do
    query = JqlQuery.new(session: @session, query_text: "")
    assert_not query.valid?
    assert_includes query.errors[:query_text], "can't be blank"
  end

  test "should require session" do
    query = JqlQuery.new(query_text: 'project = "TEST"')
    assert_not query.valid?
    assert_includes query.errors[:session], "must exist"
  end

  test "should enforce maximum query length" do
    long_query = "project = 'TEST' AND " + ("status = Open OR " * 150) + "priority = High"
    query = JqlQuery.new(session: @session, query_text: long_query)

    assert_not query.valid?
    assert_includes query.errors[:query_text], "is too long (maximum is 2000 characters)"
  end

  test "should validate status inclusion" do
    query = JqlQuery.new(session: @session, query_text: 'project = "TEST"', status: "invalid_status")
    assert_not query.valid?
    assert_includes query.errors[:status], "is not included in the list"
  end

  # UC002 JQL Syntax Validation Tests

  test "should validate basic JQL syntax" do
    valid_queries = [
      'project = "TEST"',
      'issuetype = Bug AND status != Done',
      'priority IN (High, Critical)',
      'assignee IS EMPTY',
      'created >= -30d'
    ]

    valid_queries.each do |query_text|
      query = JqlQuery.new(session: @session, query_text: query_text)
      assert query.valid?, "Query should be valid: #{query_text}"
    end
  end

  test "should reject invalid JQL syntax" do
    invalid_queries = [
      'project = "TEST" AND (status = Open',  # Unbalanced parentheses
      "project = 'TEST' AND status = 'Open",  # Unmatched quotes
      'project = "TEST" AND AND status = Open'  # Invalid logical operators
    ]

    invalid_queries.each do |query_text|
      query = JqlQuery.new(session: @session, query_text: query_text)
      assert_not query.valid?, "Query should be invalid: #{query_text}"
      assert query.errors[:query_text].any?
    end
  end

  # UC002 Business Logic Tests

  test "should set default status to pending" do
    query = JqlQuery.create!(session: @session, query_text: 'project = "DEFAULT"')
    assert_equal "pending", query.status
  end

  test "should provide display name when name is present" do
    query = JqlQuery.create!(session: @session, query_text: 'project = "TEST"', name: "My Query")
    assert_equal "My Query", query.display_name
  end

  test "should provide fallback display name when name is blank" do
    query = JqlQuery.create!(session: @session, query_text: 'project = "TEST"')
    assert_equal "Query #{query.id}", query.display_name
  end

  test "should format query text correctly" do
    query_with_spaces = "  project = \"TEST\"  AND  status = Open  "
    query = JqlQuery.create!(session: @session, query_text: query_with_spaces)
    assert_equal 'project = "TEST"  AND  status = Open', query.formatted_query
  end

  test "should determine execution readiness correctly" do
    pending_query = JqlQuery.create!(session: @session, query_text: 'project = "READY"', status: "pending")
    executing_query = JqlQuery.create!(session: @session, query_text: 'project = "BUSY"', status: "executing")
    completed_query = JqlQuery.create!(session: @session, query_text: 'project = "DONE"', status: "completed")

    assert pending_query.ready_for_execution?
    assert_not executing_query.ready_for_execution?
    assert_not completed_query.ready_for_execution?
  end

  test "should determine execution capability correctly" do
    active_session = Session.create!(user: @user, name: "Active Session", status: "active")
    inactive_session = Session.create!(user: @user, name: "Inactive Session", status: "completed")

    ready_query = JqlQuery.create!(session: active_session, query_text: 'project = "READY"', status: "pending")
    blocked_query = JqlQuery.create!(session: inactive_session, query_text: 'project = "BLOCKED"', status: "pending")

    assert ready_query.can_execute?
    assert_not blocked_query.can_execute?
  end

  # UC002 Query Execution Tests

  test "should execute query successfully" do
    query = JqlQuery.create!(session: @session, query_text: 'project = "EXECUTE"', status: "pending")

    assert query.execute!

    query.reload
    assert_equal "completed", query.status
    assert_not_nil query.executed_at
    assert_equal 0, query.ticket_count  # Placeholder implementation
  end

  test "should not execute query if not ready" do
    completed_query = JqlQuery.create!(session: @session, query_text: 'project = "DONE"', status: "completed")

    assert_not completed_query.execute!

    completed_query.reload
    assert_equal "completed", completed_query.status
  end

  test "should not execute query if session not active" do
    inactive_session = Session.create!(user: @user, name: "Inactive", status: "completed")
    query = JqlQuery.create!(session: inactive_session, query_text: 'project = "INACTIVE"', status: "pending")

    assert_not query.execute!
  end

  # UC002 Audit Logging Tests

  test "should create audit log on query creation" do
    assert_difference "AuditLog.count", 1 do
      JqlQuery.create!(session: @session, query_text: 'project = "AUDIT"', name: "Audit Test")
    end

    audit_log = AuditLog.last
    assert_equal "JqlQuery", audit_log.entity_type
    assert_equal "create", audit_log.action
    assert_equal @user, audit_log.user
    assert_equal @session, audit_log.session
  end

  # UC002 Association Tests

  test "should belong to session" do
    query = JqlQuery.create!(session: @session, query_text: 'project = "ASSOCIATION"')
    assert_equal @session, query.session
  end

  test "should access user through session" do
    query = JqlQuery.create!(session: @session, query_text: 'project = "USER_ACCESS"')
    assert_equal @user, query.user
  end

  test "should be destroyed when session is destroyed" do
    query = JqlQuery.create!(session: @session, query_text: 'project = "DEPENDENT"')
    query_id = query.id

    @session.destroy

    assert_nil JqlQuery.find_by(id: query_id)
  end
end
