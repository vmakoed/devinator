require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  def setup
    # Create test user without fixtures
    @user = User.create!(
      email: "admin@devinator.local",
      name: "Admin User",
      role: "admin",
      password_hash: "test_hash",
      is_active: true
    )

    # Mock authentication for tests
    SessionsController.any_instance.stubs(:authenticate_user!).returns(true)
    SessionsController.any_instance.stubs(:current_user).returns(@user)
  end

  # UC001 Index Action Tests

  test "should get index" do
    get sessions_url
    assert_response :success
    assert_select "h1", "Sessions"
  end

  test "should show sessions for current user" do
    session1 = Session.create!(user: @user, name: "Session 1")
    session2 = Session.create!(user: @user, name: "Session 2")

    get sessions_url
    assert_response :success

    # Should show user's sessions
    assert_select "a[href=?]", workspace_session_path(session1)
    assert_select "a[href=?]", workspace_session_path(session2)
  end

  test "should show empty state when no sessions" do
    get sessions_url
    assert_response :success
    assert_select "h2", "No sessions yet"
    assert_select "a[href=?]", new_session_path, text: "Create Your First Session"
  end

  # UC001 New Action Tests

  test "should get new" do
    get new_session_url
    assert_response :success
    assert_select "h1", "Create New Session"
    assert_select "form"
  end

  test "should show configuration dropdown when user has configurations" do
    session = Session.create!(user: @user, name: "Test Session")
    config = SessionConfiguration.create!(
      user: @user,
      session: session,
      configuration_name: "Test Config"
    )

    get new_session_url
    assert_response :success
    assert_select "select[name=?]", "session[configuration_id]"
    assert_select "option", text: "Test Config"
  end

  # UC001 Create Action Tests

  test "should create session with valid parameters" do
    assert_difference "Session.count", 1 do
      post sessions_url, params: {
        session: {
          name: "Test Session",
          description: "Test description"
        }
      }
    end

    session = Session.last
    assert_equal "Test Session", session.name
    assert_equal "Test description", session.description
    assert_equal @user, session.user
    assert_equal "active", session.status

    assert_redirected_to workspace_session_path(session)
    follow_redirect!
    assert_select ".notice", /Session 'Test Session' created successfully/
  end

  test "should create audit log entry on session creation" do
    assert_difference "AuditLog.count", 1 do
      post sessions_url, params: {
        session: {
          name: "Audited Session",
          description: ""
        }
      }
    end

    audit_log = AuditLog.last
    assert_equal "Session", audit_log.entity_type
    assert_equal "create", audit_log.action
    assert_equal @user, audit_log.user
  end

  test "should apply configuration when selected" do
    session = Session.create!(user: @user, name: "Config Test")
    config = SessionConfiguration.create!(
      user: @user,
      session: session,
      configuration_name: "Test Config",
      jql_templates: '["bug AND status = Open"]',
      complexity_settings: '{"max_score": 1.0}',
      notification_settings: '{"email": true}'
    )

    post sessions_url, params: {
      session: {
        name: "Configured Session",
        description: "",
        configuration_id: config.id
      }
    }

    new_session = Session.last
    assert_not_nil new_session.configuration
    config_data = JSON.parse(new_session.configuration)
    assert_includes config_data.keys, "jql_templates"
    assert_includes config_data.keys, "complexity_settings"
    assert_includes config_data.keys, "notification_settings"
  end

  test "should not create session with invalid parameters" do
    assert_no_difference "Session.count" do
      post sessions_url, params: {
        session: {
          name: "", # Invalid: blank name
          description: "Test"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select ".text-red-600", /can't be blank/
  end

  test "should not create session with duplicate name for same user" do
    Session.create!(user: @user, name: "Duplicate Session")

    assert_no_difference "Session.count" do
      post sessions_url, params: {
        session: {
          name: "Duplicate Session",
          description: "Different description"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select ".text-red-600", /already exists for this user/
  end

  test "should handle non-existent configuration gracefully" do
    post sessions_url, params: {
      session: {
        name: "Invalid Config Session",
        description: "",
        configuration_id: 999999 # Non-existent ID
      }
    }

    assert_redirected_to new_session_path
    follow_redirect!
    assert_select ".alert", /Selected configuration not found/
  end

  # UC001 Workspace Action Tests

  test "should get workspace for user's session" do
    session = Session.create!(user: @user, name: "Test Session")

    get workspace_session_url(session)
    assert_response :success
    assert_select "h1", "Test Session"
    assert_select "span", "Active"
  end

  test "should show session stats in workspace" do
    session = Session.create!(user: @user, name: "Stats Session")

    get workspace_session_url(session)
    assert_response :success

    # Should show stats cards
    assert_select "dt", "Active Queries"
    assert_select "dt", "Recent Tickets"
    assert_select "dt", "Devin Ready"
  end

  test "should show quick actions in workspace" do
    session = Session.create!(user: @user, name: "Actions Session")

    get workspace_session_url(session)
    assert_response :success

    # Should show action buttons
    assert_select "a[href=?]", new_session_jql_query_path(session), text: "Add JQL Query"
    assert_select "a[href=?]", session_tickets_path(session), text: "View All Tickets"
    assert_select "a[href=?]", session_recommendations_path(session), text: "Review Recommendations"
  end

  test "should not allow access to other user's session" do
    other_user = User.create!(
      email: "lead@devinator.local",
      name: "Team Lead User",
      role: "team_lead",
      password_hash: "test_hash",
      is_active: true
    )
    other_session = Session.create!(user: other_user, name: "Other Session")

    get workspace_session_url(other_session)
    assert_redirected_to sessions_path
    follow_redirect!
    assert_select ".alert", /Session not found/
  end

  # UC001 Authorization Tests

  test "should redirect when user cannot create sessions" do
    developer = User.create!(
      email: "dev@devinator.local",
      name: "Developer User",
      role: "developer",
      password_hash: "test_hash",
      is_active: true
    )
    SessionsController.any_instance.stubs(:current_user).returns(developer)

    get new_session_url
    assert_redirected_to root_path
    follow_redirect!
    assert_select ".alert", /You do not have permission to create sessions/
  end

  test "should redirect when user has reached session limit" do
    # Create 5 active sessions (the limit)
    5.times do |i|
      Session.create!(user: @user, name: "Session #{i + 1}", status: "active")
    end

    get new_session_url
    assert_redirected_to sessions_path
    follow_redirect!
    assert_select ".alert", /Maximum active sessions reached/
  end

  test "should allow session creation when user is under limit" do
    # Create 4 active sessions (under the limit)
    4.times do |i|
      Session.create!(user: @user, name: "Session #{i + 1}", status: "active")
    end

    get new_session_url
    assert_response :success
    assert_select "h1", "Create New Session"
  end

  # UC001 Show Action Tests

  test "should get show for user's session" do
    session = Session.create!(user: @user, name: "Show Session")

    get session_url(session)
    assert_response :success
  end

  test "should not show other user's session" do
    other_user = User.create!(
      email: "other@devinator.local",
      name: "Other User",
      role: "team_lead",
      password_hash: "test_hash",
      is_active: true
    )
    other_session = Session.create!(user: other_user, name: "Other Session")

    get session_url(other_session)
    assert_redirected_to sessions_path
    follow_redirect!
    assert_select ".alert", /Session not found/
  end
end
