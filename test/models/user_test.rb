require "test_helper"

class UserTest < ActiveSupport::TestCase
  def setup
    @user = User.new(
      email: "test@devinator.local",
      name: "Test User",
      role: "team_lead",
      password_hash: "test_hash",
      is_active: true
    )
  end

  # UC001 Session Permission Tests

  test "admin should be able to create sessions" do
    @user.role = "admin"
    assert @user.can_create_sessions?
  end

  test "team_lead should be able to create sessions" do
    @user.role = "team_lead"
    assert @user.can_create_sessions?
  end

  test "developer should not be able to create sessions" do
    @user.role = "developer"
    assert_not @user.can_create_sessions?
  end

  # UC001 Session Limit Tests

  test "should allow new session when under limit" do
    @user.save!
    assert @user.can_create_new_session?
  end

  test "should not allow new session when at limit" do
    @user.save!

    # Create 5 active sessions (the limit)
    5.times do |i|
      Session.create!(user: @user, name: "Session #{i + 1}", status: "active")
    end

    assert_not @user.can_create_new_session?
  end

  test "should allow new session when has completed sessions" do
    @user.save!

    # Create 5 completed sessions (don't count toward limit)
    5.times do |i|
      Session.create!(user: @user, name: "Completed #{i + 1}", status: "completed")
    end

    assert @user.can_create_new_session?
  end

  test "should count only active sessions toward limit" do
    @user.save!

    # Create 3 active and 5 completed sessions
    3.times { |i| Session.create!(user: @user, name: "Active #{i + 1}", status: "active") }
    5.times { |i| Session.create!(user: @user, name: "Completed #{i + 1}", status: "completed") }

    assert @user.can_create_new_session?, "Should allow new session when only 3 active sessions exist"
  end

  test "should not allow new session if role cannot create sessions" do
    @user.role = "developer"
    @user.save!

    assert_not @user.can_create_new_session?
  end

  # UC001 User Association Tests

  test "should have many sessions" do
    @user.save!
    session1 = Session.create!(user: @user, name: "Session 1")
    session2 = Session.create!(user: @user, name: "Session 2")

    assert_includes @user.sessions, session1
    assert_includes @user.sessions, session2
    assert_equal 2, @user.sessions.count
  end

  test "should return active sessions" do
    @user.save!
    active_session = Session.create!(user: @user, name: "Active", status: "active")
    completed_session = Session.create!(user: @user, name: "Completed", status: "completed")

    active_sessions = @user.active_sessions
    assert_includes active_sessions, active_session
    assert_not_includes active_sessions, completed_session
    assert_equal 1, active_sessions.count
  end

  test "should have many session configurations" do
    @user.save!
    config = SessionConfiguration.create!(
      user: @user,
      session: Session.create!(user: @user, name: "Test Session"),
      configuration_name: "Test Config"
    )

    assert_includes @user.session_configurations, config
  end

  test "should return default session configuration" do
    @user.save!
    session = Session.create!(user: @user, name: "Test Session")

    default_config = SessionConfiguration.create!(
      user: @user,
      session: session,
      configuration_name: "Default Config",
      is_default: true
    )

    other_config = SessionConfiguration.create!(
      user: @user,
      session: session,
      configuration_name: "Other Config",
      is_default: false
    )

    assert_equal default_config, @user.default_session_configuration
  end

  # UC001 Validation Tests

  test "should be valid with valid attributes" do
    assert @user.valid?
  end

  test "should require email" do
    @user.email = nil
    assert_not @user.valid?
    assert_includes @user.errors[:email], "can't be blank"
  end

  test "should require unique email" do
    @user.save!
    duplicate_user = User.new(
      email: "test@devinator.local",
      name: "Duplicate",
      role: "admin",
      password_hash: "hash"
    )

    assert_not duplicate_user.valid?
    assert_includes duplicate_user.errors[:email], "has already been taken"
  end

  test "should require valid email format" do
    @user.email = "invalid-email"
    assert_not @user.valid?
    assert_includes @user.errors[:email], "is invalid"
  end

  test "should require name" do
    @user.name = nil
    assert_not @user.valid?
    assert_includes @user.errors[:name], "can't be blank"
  end

  test "should require valid role" do
    @user.role = "invalid_role"
    assert_not @user.valid?
    assert_includes @user.errors[:role], "is not included in the list"
  end

  test "should accept valid roles" do
    %w[admin team_lead developer].each do |role|
      @user.role = role
      assert @user.valid?, "Should accept #{role} as valid role"
    end
  end

  # UC001 Scope Tests

  test "active scope should return only active users" do
    active_user = User.create!(
      email: "active@devinator.local",
      name: "Active User",
      role: "admin",
      password_hash: "hash",
      is_active: true
    )

    inactive_user = User.create!(
      email: "inactive@devinator.local",
      name: "Inactive User",
      role: "admin",
      password_hash: "hash",
      is_active: false
    )

    active_users = User.active
    assert_includes active_users, active_user
    assert_not_includes active_users, inactive_user
  end

  test "team_leads scope should return admins and team leads" do
    admin = User.create!(email: "admin@test.com", name: "Admin", role: "admin", password_hash: "hash", is_active: true)
    team_lead = User.create!(email: "lead@test.com", name: "Lead", role: "team_lead", password_hash: "hash", is_active: true)
    developer = User.create!(email: "dev@test.com", name: "Dev", role: "developer", password_hash: "hash", is_active: true)

    team_leads = User.team_leads
    assert_includes team_leads, admin
    assert_includes team_leads, team_lead
    assert_not_includes team_leads, developer
  end
end
