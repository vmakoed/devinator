require "test_helper"

class JqlQueriesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(
      email: "admin@devinator.local",
      name: "Admin User",
      role: "admin",
      password_hash: "test_hash",
      is_active: true
    )

    @session = Session.create!(user: @user, name: "Test Session")

    # Mock authentication
    JqlQueriesController.any_instance.stubs(:authenticate_user!).returns(true)
    JqlQueriesController.any_instance.stubs(:current_user).returns(@user)
  end

  # UC002 Index Tests

  test "should get index" do
    get session_jql_queries_url(@session)
    assert_response :success
    assert_select "h1", "JQL Queries"
  end

  test "should show empty state when no queries exist" do
    get session_jql_queries_url(@session)
    assert_response :success
    assert_select "h3", "No JQL queries"
    assert_select "p", /Get started by creating your first JQL query/
  end

  test "should show JQL queries list when queries exist" do
    query1 = JqlQuery.create!(session: @session, query_text: 'project = "TEST" AND issuetype = Bug')
    query2 = JqlQuery.create!(session: @session, query_text: 'priority = High', name: "High Priority Issues")

    get session_jql_queries_url(@session)
    assert_response :success

    assert_select "code", /project = \"TEST\" AND issuetype = Bug/
    assert_select "h3", "High Priority Issues"
  end

  # UC002 New Action Tests

  test "should get new" do
    get new_session_jql_query_url(@session)
    assert_response :success
    assert_select "h1", "Create JQL Query"
    assert_select "form"
  end

  test "should show query templates" do
    get new_session_jql_query_url(@session)
    assert_response :success
    assert_select "h3", "Query Templates"
    assert_select ".template-card", minimum: 1
  end

  test "should show query history when user has previous queries" do
    # Create a query in another session for the same user
    other_session = Session.create!(user: @user, name: "Other Session")
    JqlQuery.create!(session: other_session, query_text: 'project = "OLD" AND status = Open')

    get new_session_jql_query_url(@session)
    assert_response :success
    assert_select "h3", "Recent Queries"
  end

  # UC002 Create Action Tests

  test "should create JQL query with valid parameters" do
    assert_difference "JqlQuery.count", 1 do
      post session_jql_queries_url(@session), params: {
        jql_query: {
          query_text: 'project = "TEST" AND issuetype = Bug',
          name: "Test Bug Query",
          description: "Query for test bugs"
        }
      }
    end

    query = JqlQuery.last
    assert_equal 'project = "TEST" AND issuetype = Bug', query.query_text
    assert_equal "Test Bug Query", query.name
    assert_equal "Query for test bugs", query.description
    assert_equal @session, query.session
    assert_equal "pending", query.status

    assert_redirected_to session_jql_queries_path(@session)
    follow_redirect!
    assert_select ".notice", /Test Bug Query.*created successfully/
  end

  test "should create audit log entry on query creation" do
    assert_difference "AuditLog.count", 1 do
      post session_jql_queries_url(@session), params: {
        jql_query: {
          query_text: 'project = "AUDIT" AND status = Open',
          name: "Audit Test Query"
        }
      }
    end

    audit_log = AuditLog.last
    assert_equal "JqlQuery", audit_log.entity_type
    assert_equal "create", audit_log.action
    assert_equal @user, audit_log.user
  end

  test "should not create query with invalid parameters" do
    assert_no_difference "JqlQuery.count" do
      post session_jql_queries_url(@session), params: {
        jql_query: {
          query_text: "", # Invalid: blank query
          name: "Empty Query"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select ".text-red-600", /can't be blank/
  end

  test "should not create query that is too long" do
    long_query = "project = 'TEST' AND " + ("status = Open OR " * 100) + "priority = High"

    assert_no_difference "JqlQuery.count" do
      post session_jql_queries_url(@session), params: {
        jql_query: {
          query_text: long_query,
          name: "Too Long Query"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select ".text-red-600", /too long/
  end

  test "should validate JQL syntax on creation" do
    # Test with unbalanced parentheses
    assert_no_difference "JqlQuery.count" do
      post session_jql_queries_url(@session), params: {
        jql_query: {
          query_text: 'project = "TEST" AND (status = Open',
          name: "Invalid Syntax Query"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  # UC002 Edit Action Tests

  test "should get edit" do
    query = JqlQuery.create!(session: @session, query_text: 'project = "TEST"', name: "Edit Test")

    get edit_session_jql_query_url(@session, query)
    assert_response :success
    assert_select "h1", "Edit JQL Query"
    assert_select "form"
  end

  test "should show current query status in edit form" do
    query = JqlQuery.create!(session: @session, query_text: 'project = "TEST"', status: "completed")

    get edit_session_jql_query_url(@session, query)
    assert_response :success
    assert_select "span", "Completed"
  end

  # UC002 Update Action Tests

  test "should update JQL query with valid parameters" do
    query = JqlQuery.create!(session: @session, query_text: 'project = "OLD"', name: "Old Query")

    patch session_jql_query_url(@session, query), params: {
      jql_query: {
        query_text: 'project = "NEW" AND issuetype = Bug',
        name: "Updated Query",
        description: "Updated description"
      }
    }

    query.reload
    assert_equal 'project = "NEW" AND issuetype = Bug', query.query_text
    assert_equal "Updated Query", query.name
    assert_equal "Updated description", query.description

    assert_redirected_to session_jql_queries_path(@session)
    follow_redirect!
    assert_select ".notice", /updated successfully/
  end

  test "should not update query with invalid parameters" do
    query = JqlQuery.create!(session: @session, query_text: 'project = "TEST"', name: "Valid Query")

    patch session_jql_query_url(@session, query), params: {
      jql_query: {
        query_text: "", # Invalid: blank query
        name: "Invalid Update"
      }
    }

    assert_response :unprocessable_entity
    assert_select ".text-red-600", /can't be blank/

    # Ensure query wasn't updated
    query.reload
    assert_equal 'project = "TEST"', query.query_text
    assert_equal "Valid Query", query.name
  end

  # UC002 Destroy Action Tests

  test "should destroy JQL query" do
    query = JqlQuery.create!(session: @session, query_text: 'project = "DELETE"', name: "Delete Me")

    assert_difference "JqlQuery.count", -1 do
      delete session_jql_query_url(@session, query)
    end

    assert_redirected_to session_jql_queries_path(@session)
    follow_redirect!
    assert_select ".notice", /Delete Me.*deleted successfully/
  end

  # UC002 Validation Action Tests

  test "should validate valid JQL query via AJAX" do
    post validate_session_jql_queries_url(@session), params: {
      query_text: 'project = "TEST" AND issuetype = Bug'
    }

    assert_response :success
    response_data = JSON.parse(response.body)
    assert response_data["valid"]
    assert_nil response_data["error"]
  end

  test "should reject invalid JQL query via AJAX" do
    post validate_session_jql_queries_url(@session), params: {
      query_text: 'project = "TEST" AND (unbalanced'
    }

    assert_response :success
    response_data = JSON.parse(response.body)
    assert_not response_data["valid"]
    assert_not_nil response_data["error"]
  end

  test "should reject empty query via AJAX" do
    post validate_session_jql_queries_url(@session), params: {
      query_text: ""
    }

    assert_response :success
    response_data = JSON.parse(response.body)
    assert_not response_data["valid"]
    assert_equal "Query cannot be empty", response_data["error"]
  end

  # UC002 Authorization Tests

  test "should redirect when user cannot create queries" do
    developer = User.create!(
      email: "dev@devinator.local",
      name: "Developer User",
      role: "developer",
      password_hash: "test_hash",
      is_active: true
    )
    JqlQueriesController.any_instance.stubs(:current_user).returns(developer)

    get new_session_jql_query_url(@session)
    assert_redirected_to root_path
    follow_redirect!
    assert_select ".alert", /You do not have permission to create JQL queries/
  end

  test "should not allow access to other user's session queries" do
    other_user = User.create!(
      email: "lead@devinator.local",
      name: "Team Lead User",
      role: "team_lead",
      password_hash: "test_hash",
      is_active: true
    )
    other_session = Session.create!(user: other_user, name: "Other Session")

    get session_jql_queries_url(other_session)
    assert_redirected_to sessions_path
    follow_redirect!
    assert_select ".alert", /Session not found/
  end

  test "should not allow modifying queries from other user's session" do
    other_user = User.create!(
      email: "other@devinator.local",
      name: "Other User",
      role: "team_lead",
      password_hash: "test_hash",
      is_active: true
    )
    other_session = Session.create!(user: other_user, name: "Other Session")
    other_query = JqlQuery.create!(session: other_session, query_text: 'project = "OTHER"')

    get edit_session_jql_query_url(other_session, other_query)
    assert_redirected_to sessions_path
  end

  # UC002 Business Logic Tests

  test "should show query execution status correctly" do
    pending_query = JqlQuery.create!(session: @session, query_text: 'project = "PENDING"', status: "pending")
    completed_query = JqlQuery.create!(
      session: @session,
      query_text: 'project = "DONE"',
      status: "completed",
      executed_at: 1.hour.ago,
      ticket_count: 42
    )

    get session_jql_queries_url(@session)
    assert_response :success

    # Check status badges
    assert_select "span.bg-yellow-100", "Pending"
    assert_select "span.bg-green-100", "Completed"
  end

  test "should show query execution summary" do
    query = JqlQuery.create!(
      session: @session,
      query_text: 'project = "SUMMARY"',
      status: "completed",
      executed_at: Time.current,
      ticket_count: 15
    )

    get session_jql_queries_url(@session)
    assert_response :success
    assert_select "span", /15 tickets found/
  end

  test "should provide query templates with different categories" do
    get new_session_jql_query_url(@session)
    assert_response :success

    # Check that various template categories are present
    assert_select ".template-card", text: /Open Bugs/
    assert_select ".template-card", text: /High Priority/
    assert_select ".template-card", text: /Recent Bugs/
    assert_select ".template-card", text: /Unassigned/
    assert_select ".template-card", text: /Ready for Development/
  end

  test "should handle query with similar existing queries" do
    existing_query = JqlQuery.create!(session: @session, query_text: 'project = "TEST" AND status = Open')

    post session_jql_queries_url(@session), params: {
      jql_query: {
        query_text: 'project = "TEST" AND issuetype = Bug',
        name: "Similar Query"
      }
    }

    assert_response :redirect
    new_query = JqlQuery.last
    assert_not_empty new_query.similar_queries
  end

  # UC002 Integration Tests

  test "should integrate properly with session workspace" do
    JqlQuery.create!(session: @session, query_text: 'project = "WORKSPACE"', name: "Workspace Test")

    get workspace_session_url(@session)
    assert_response :success

    # Should show JQL queries in workspace
    assert_select "h3", "JQL Queries"
    assert_select "h4", "Workspace Test"
  end

  test "should maintain proper workflow state transitions" do
    # Create query (UC002)
    post session_jql_queries_url(@session), params: {
      jql_query: {
        query_text: 'project = "WORKFLOW" AND issuetype = Bug',
        name: "Workflow Test"
      }
    }

    query = JqlQuery.last
    assert_equal "pending", query.status
    assert query.ready_for_execution?
    assert query.can_execute?

    # Query should be ready for UC003 (Fetch JIRA Tickets)
    assert query.session.active?
    assert_not_nil query.formatted_query
  end
end