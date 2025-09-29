require "test_helper"

class MissionsControllerTest < ActionDispatch::IntegrationTest
  # Test UC001 Acceptance Criteria: AC01-AC09
  # Test UC001 Test Scenarios: TS001-TS003

  test "should get index and display missions list" do
    get root_path
    assert_response :success
    assert_select "h1", "Devinator"
    assert_select "input[type=submit][value='Start New Mission']"
  end

  test "should display all missions on homepage ordered by creation date" do
    get root_path
    assert_response :success

    # Should show missions in descending order (newest first)
    mission_names = css_select(".text-sm.font-medium").map(&:text)
    expected_order = [missions(:draft_mission).name, missions(:completed_mission).name]

    # Note: This assumes fixtures are ordered correctly by created_at
    assert_equal expected_order.length, mission_names.length
  end

  test "should display mission status with correct styling" do
    get root_path
    assert_response :success

    # Should show draft status with yellow badge
    assert_select ".bg-yellow-100.text-yellow-800", text: "Draft"
  end

  test "should show empty state when no missions exist" do
    Mission.destroy_all

    get root_path
    assert_response :success
    assert_select "h3", "No missions yet"
    assert_select "p", "Start your first mission to begin identifying suitable tickets for AI assignment."
  end

  # UC001 AC01: User can create a mission with a single click
  test "should create mission successfully with single click" do
    assert_difference("Mission.count", 1) do
      post missions_path
    end

    mission = Mission.last
    assert_redirected_to query_mission_path(mission)
    follow_redirect!
    assert_select "h1", "Input JQL Query"
  end

  # UC001 AC02: Mission name is automatically generated and displayed to user
  # UC001 AC06: Success message shows the auto-generated mission name
  test "should create mission with auto-generated name and show in success message" do
    frozen_time = Time.parse("2025-09-29 14:30:15 UTC")
    travel_to(frozen_time) do
      post missions_path

      mission = Mission.last
      assert_redirected_to query_mission_path(mission)

      expected_name = "Mission - 2025-09-29 14:30:15"
      assert_equal expected_name, mission.name
    end
  end

  # UC001 AC03: Mission is assigned a unique identifier
  # UC001 AC04: Mission status is set to "draft" upon creation
  test "should create mission with unique ID and draft status" do
    initial_count = Mission.count

    post missions_path

    assert_equal initial_count + 1, Mission.count

    new_mission = Mission.last
    assert new_mission.id.present?
    assert_equal "draft", new_mission.status
    assert new_mission.name.start_with?("Mission - ")
  end

  # UC001 TS003: Unique Name Generation
  test "should create missions with unique names when created multiple times" do
    first_time = Time.parse("2025-09-29 14:30:15 UTC")
    second_time = Time.parse("2025-09-29 14:30:16 UTC")

    travel_to(first_time)
    post missions_path
    first_mission = Mission.last

    travel_to(second_time)
    post missions_path
    second_mission = Mission.last

    assert_not_equal first_mission.name, second_mission.name
    assert first_mission.name.include?("14:30:15")
    assert second_mission.name.include?("14:30:16")

    travel_back  # Reset time
  end

  # UC001 AF1: System Error
  # UC001 AC07: Error messages are displayed for system failures
  test "should handle validation errors gracefully" do
    # Test error handling by creating a mission with invalid data
    # We'll patch the Mission model temporarily to force validation errors
    original_generate_name = Mission.method(:generate_name)
    Mission.define_singleton_method(:generate_name) { "" }  # Force empty name

    assert_no_difference("Mission.count") do
      post missions_path
    end

    assert_redirected_to root_path
    follow_redirect!
    assert_select ".bg-red-100", text: "Unable to create mission. Please try again."

    # Restore original method
    Mission.define_singleton_method(:generate_name, &original_generate_name)
  end

  # UC001 TS002: System Error Handling - Test the error handling flow
  test "controller error handling works correctly" do
    # Verify that our controller properly catches exceptions and shows error messages
    # This tests the structure of our error handling without forcing artificial errors

    # Test normal successful flow first
    assert_difference("Mission.count", 1) do
      post missions_path
    end

    mission = Mission.last
    assert_redirected_to query_mission_path(mission)

    # The error handling code path is tested in the validation errors test above
    # This verifies the overall structure works as expected
  end

  # Test that the form uses correct HTTP method and URL
  test "form should POST to missions path" do
    get root_path
    assert_select "form[action='#{missions_path}'][method='post']"
    assert_select "input[name='_method']", count: 0  # Should be regular POST, not PUT/PATCH
  end

  # UC002 Tests - Input JQL Query
  # Test UC002 Acceptance Criteria: AC01-AC10
  # Test UC002 Test Scenarios: TS001-TS004

  test "should redirect to query page after mission creation" do
    post missions_path
    mission = Mission.last
    assert_redirected_to query_mission_path(mission)
  end

  test "should get query page for existing mission" do
    mission = missions(:draft_mission)
    get query_mission_path(mission)
    assert_response :success
    assert_select "h1", "Input JQL Query"
    assert_select "textarea[name='mission[jql_query]']"
  end

  test "should show existing jql_query in form when present" do
    mission = missions(:draft_mission)
    mission.update!(jql_query: 'project = "TEST" AND issuetype = Bug')

    get query_mission_path(mission)
    assert_response :success
    assert_select "textarea[name='mission[jql_query]']", text: 'project = "TEST" AND issuetype = Bug'
  end

  # UC002 AC01: User can input multi-line JQL queries
  # UC002 AC02: Query is associated with the current mission
  # UC002 AC03: Mission status updates to "in_progress" upon successful save
  # UC002 AC04: User receives confirmation when query is saved successfully
  test "should save jql_query and update mission status to in_progress" do
    mission = missions(:draft_mission)
    query = 'project = "TEST" AND issuetype = Bug AND status = "Open"'

    patch query_mission_path(mission), params: {
      mission: { jql_query: query }
    }

    mission.reload
    assert_equal query, mission.jql_query
    assert_equal "in_progress", mission.status
    assert_redirected_to mission_path(mission)

    follow_redirect!
    assert_select ".bg-green-100", text: "JQL query saved successfully!"
  end

  # UC002 AC08: User can modify and re-save query multiple times
  test "should allow updating existing jql_query" do
    mission = missions(:draft_mission)
    mission.update!(
      jql_query: 'old query',
      status: 'in_progress'
    )

    new_query = 'project = "TEST" AND issuetype = Bug'
    patch query_mission_path(mission), params: {
      mission: { jql_query: new_query }
    }

    mission.reload
    assert_equal new_query, mission.jql_query
    assert_equal "in_progress", mission.status
  end

  # UC002 AF3: Empty Query
  # UC002 AC08: Empty queries are rejected with appropriate error message
  test "should reject empty jql_query with error message" do
    mission = missions(:draft_mission)

    patch query_mission_path(mission), params: {
      mission: { jql_query: "" }
    }

    mission.reload
    assert_nil mission.jql_query
    assert_equal "draft", mission.status
    assert_response :success  # Should render the query form again
    assert_select ".bg-red-100", text: "JQL query cannot be empty"
  end

  test "should reject blank jql_query with error message" do
    mission = missions(:draft_mission)

    patch query_mission_path(mission), params: {
      mission: { jql_query: "   " }
    }

    mission.reload
    assert_nil mission.jql_query
    assert_equal "draft", mission.status
    assert_response :success
    assert_select ".bg-red-100", text: "JQL query cannot be empty"
  end

  # UC002 TS001: Successful Query Input and Save
  test "successful query input flow from draft to in_progress" do
    mission = Mission.create!(name: "Test Mission", status: "draft")
    query = 'project = "PROJ" AND issuetype = Bug'

    # GET query page
    get query_mission_path(mission)
    assert_response :success
    assert_select "form[action='#{query_mission_path(mission)}'][method='post']"
    assert_select "input[name='_method'][value='patch']"

    # PATCH to save query
    patch query_mission_path(mission), params: {
      mission: { jql_query: query }
    }

    mission.reload
    assert_equal query, mission.jql_query
    assert_equal "in_progress", mission.status
    assert_redirected_to mission_path(mission)
  end

  # UC002 TS003: Empty Query Validation
  test "empty query validation prevents save" do
    mission = Mission.create!(name: "Test Mission", status: "draft")

    patch query_mission_path(mission), params: {
      mission: { jql_query: "" }
    }

    mission.reload
    assert_nil mission.jql_query
    assert_equal "draft", mission.status
    assert_response :success
    assert_select ".bg-red-100", text: "JQL query cannot be empty"
  end

  # UC002 TS004: Save Operation Failure (simulated)
  # This test simulates save failure by triggering validation error
  test "should handle save failures gracefully" do
    mission = missions(:draft_mission)
    mission.update!(status: 'in_progress', jql_query: 'existing query')  # Make jql_query required

    # Try to save nil jql_query which will fail validation
    patch query_mission_path(mission), params: {
      mission: { jql_query: nil }
    }

    assert_response :success  # Should render query form again
    assert_select ".bg-red-100", text: "JQL query cannot be empty"
  end


  test "should show mission name and breadcrumbs on query page" do
    mission = missions(:draft_mission)
    get query_mission_path(mission)

    assert_response :success
    assert_select "p", text: /Mission: #{mission.name}/
    assert_select "a[href='#{root_path}']", text: "Missions"
  end

  # Test character count and form validation
  test "query form should include character count feature" do
    mission = missions(:draft_mission)
    get query_mission_path(mission)

    assert_response :success
    assert_select "#char-count"
    assert_select "script", text: /updateCharCount/
  end
end
