require "test_helper"

class SimpleSessionTest < ActiveSupport::TestCase
  self.use_transactional_tests = true

  def setup
    # Create test data without fixtures
    @user = User.create!(
      email: "test@example.com",
      name: "Test User",
      role: "admin",
      password_hash: "test_hash",
      is_active: true
    )
  end

  # Test core UC001 functionality
  test "should create session with valid attributes" do
    session = Session.new(
      user: @user,
      name: "Test Session",
      description: "Test description"
    )

    assert session.valid?
    assert session.save
    assert_equal "active", session.status
    assert_equal @user, session.user
  end

  test "should validate name uniqueness per user" do
    Session.create!(user: @user, name: "Unique Session")

    duplicate_session = Session.new(user: @user, name: "Unique Session")
    assert_not duplicate_session.valid?
    assert_includes duplicate_session.errors[:name], "already exists for this user"
  end

  test "should enforce name length requirements" do
    # Too short
    short_session = Session.new(user: @user, name: "AB")
    assert_not short_session.valid?
    assert_includes short_session.errors[:name], "is too short (minimum is 3 characters)"

    # Too long
    long_session = Session.new(user: @user, name: "A" * 51)
    assert_not long_session.valid?
    assert_includes long_session.errors[:name], "is too long (maximum is 50 characters)"
  end

  test "should check user session creation permissions" do
    admin = User.create!(email: "admin@test.com", name: "Admin", role: "admin", password_hash: "hash", is_active: true)
    team_lead = User.create!(email: "lead@test.com", name: "Lead", role: "team_lead", password_hash: "hash", is_active: true)
    developer = User.create!(email: "dev@test.com", name: "Dev", role: "developer", password_hash: "hash", is_active: true)

    assert admin.can_create_sessions?
    assert team_lead.can_create_sessions?
    assert_not developer.can_create_sessions?
  end

  test "should enforce session limit" do
    # Create 5 sessions (the limit)
    5.times do |i|
      Session.create!(user: @user, name: "Session #{i + 1}")
    end

    assert_not @user.can_create_new_session?
  end

  test "should count only active sessions toward limit" do
    # Create 3 active and 2 completed sessions
    3.times { |i| Session.create!(user: @user, name: "Active #{i + 1}", status: "active") }
    2.times { |i| Session.create!(user: @user, name: "Completed #{i + 1}", status: "completed") }

    assert @user.can_create_new_session?, "Should allow new session when only 3 active sessions exist"
  end

  test "should create audit log on session creation" do
    assert_difference "AuditLog.count", 1 do
      Session.create!(user: @user, name: "Audited Session")
    end

    audit_log = AuditLog.last
    assert_equal "Session", audit_log.entity_type
    assert_equal "create", audit_log.action
    assert_equal @user, audit_log.user
  end
end