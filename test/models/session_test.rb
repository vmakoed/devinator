require "test_helper"

class SessionTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(
      email: "test@example.com",
      name: "Test User",
      role: "admin",
      password_hash: "test_hash",
      is_active: true
    )
    @session = Session.new(
      user: @user,
      name: "Test Session",
      description: "Test description"
    )
  end

  # UC001 Business Rule Tests

  test "should be valid with valid attributes" do
    assert @session.valid?
  end

  test "should require name" do
    @session.name = nil
    assert_not @session.valid?
    assert_includes @session.errors[:name], "can't be blank"
  end

  test "should require name minimum length of 3 characters" do
    @session.name = "AB"
    assert_not @session.valid?
    assert_includes @session.errors[:name], "is too short (minimum is 3 characters)"
  end

  test "should require name maximum length of 50 characters" do
    @session.name = "A" * 51
    assert_not @session.valid?
    assert_includes @session.errors[:name], "is too long (maximum is 50 characters)"
  end

  test "should require unique name per user" do
    @session.save!
    duplicate_session = Session.new(
      user: @user,
      name: "Test Session",
      description: "Different description"
    )

    assert_not duplicate_session.valid?
    assert_includes duplicate_session.errors[:name], "already exists for this user"
  end

  test "should allow same name for different users" do
    other_user = User.create!(
      email: "other@example.com",
      name: "Other User",
      role: "team_lead",
      password_hash: "test_hash",
      is_active: true
    )
    @session.save!

    other_session = Session.new(
      user: other_user,
      name: "Test Session",
      description: "Different user"
    )

    assert other_session.valid?
  end

  test "should require user" do
    @session.user = nil
    assert_not @session.valid?
    assert_includes @session.errors[:user_id], "can't be blank"
  end

  test "should require valid status" do
    @session.status = "invalid_status"
    assert_not @session.valid?
    assert_includes @session.errors[:status], "is not included in the list"
  end

  test "should accept valid status values" do
    %w[active completed archived].each do |status|
      @session.status = status
      assert @session.valid?, "Should accept #{status} as valid status"
    end
  end

  # UC001 Default Behavior Tests

  test "should set default status to active" do
    session = Session.create!(user: @user, name: "New Session")
    assert_equal "active", session.status
  end

  test "should be active by default" do
    session = Session.create!(user: @user, name: "New Session")
    assert session.active?
  end

  test "should accept queries when active" do
    session = Session.create!(user: @user, name: "Active Session")
    assert session.can_accept_queries?
  end

  test "should not accept queries when not active" do
    session = Session.create!(user: @user, name: "Completed Session", status: "completed")
    assert_not session.can_accept_queries?
  end

  # UC001 Configuration Tests

  test "should apply configuration correctly" do
    test_session = Session.create!(user: @user, name: "Config Test Session")
    config = SessionConfiguration.create!(
      user: @user,
      session: test_session,
      configuration_name: "Test Config",
      jql_templates: '["bug AND status = Open"]',
      complexity_settings: '{"max_score": 1.0}',
      notification_settings: '{"email": true}'
    )
    @session.apply_configuration(config)

    assert_not_nil @session.configuration
    parsed_config = JSON.parse(@session.configuration)
    assert_includes parsed_config.keys, "jql_templates"
    assert_includes parsed_config.keys, "complexity_settings"
    assert_includes parsed_config.keys, "notification_settings"
  end

  test "should handle nil configuration gracefully" do
    @session.apply_configuration(nil)
    assert_nil @session.configuration
  end

  # UC001 Audit Logging Tests

  test "should create audit log entry after creation" do
    assert_difference "AuditLog.count", 1 do
      Session.create!(user: @user, name: "Audited Session")
    end

    audit_log = AuditLog.last
    assert_equal "Session", audit_log.entity_type
    assert_equal "create", audit_log.action
    assert_equal @user, audit_log.user
    assert_not_nil audit_log.new_values
  end

  # UC001 Association Tests

  test "should belong to user" do
    session = Session.create!(user: @user, name: "User Session")
    assert_equal @user, session.user
  end

  test "should have workspace path" do
    session = Session.create!(user: @user, name: "Path Session")
    expected_path = "/sessions/#{session.id}/workspace"
    assert_equal expected_path, session.workspace_path
  end

  # UC001 Scopes Tests

  test "active scope should return only active sessions" do
    active_session = Session.create!(user: @user, name: "Active", status: "active")
    completed_session = Session.create!(user: @user, name: "Completed", status: "completed")

    active_sessions = Session.active
    assert_includes active_sessions, active_session
    assert_not_includes active_sessions, completed_session
  end

  test "for_user scope should return sessions for specific user" do
    other_user = User.create!(
      email: "other@example.com",
      name: "Other User",
      role: "team_lead",
      password_hash: "test_hash",
      is_active: true
    )
    user_session = Session.create!(user: @user, name: "User Session")
    other_session = Session.create!(user: other_user, name: "Other Session")

    user_sessions = Session.for_user(@user)
    assert_includes user_sessions, user_session
    assert_not_includes user_sessions, other_session
  end
end
