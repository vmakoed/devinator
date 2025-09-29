require "test_helper"

class MissionTest < ActiveSupport::TestCase
  # Test UC001 Business Rules: BR01, BR02, BR03, BR04

  test "should be valid with name and status" do
    mission = Mission.new(name: "Test Mission", status: "draft")
    assert mission.valid?
  end

  test "should require name presence" do
    mission = Mission.new(status: "draft")
    assert_not mission.valid?
    assert_includes mission.errors[:name], "can't be blank"
  end

  test "should require status presence" do
    mission = Mission.new(name: "Test Mission")
    assert_not mission.valid?
    assert_includes mission.errors[:status], "can't be blank"
  end

  test "generate_name should create unique timestamp-based names" do
    # Freeze time to ensure consistent testing
    frozen_time = Time.parse("2025-09-29 14:30:15 UTC")
    travel_to(frozen_time) do
      expected_name = "Mission - 2025-09-29 14:30:15"
      assert_equal expected_name, Mission.generate_name
    end
  end

  test "generate_name should create different names at different times" do
    first_time = Time.parse("2025-09-29 14:30:15 UTC")
    second_time = Time.parse("2025-09-29 14:30:16 UTC")

    travel_to(first_time)
    first_name = Mission.generate_name

    travel_to(second_time)
    second_name = Mission.generate_name

    assert_not_equal first_name, second_name

    travel_back  # Reset time
  end

  test "draft scope should return only draft missions" do
    draft_missions = Mission.draft
    draft_missions.each do |mission|
      assert_equal "draft", mission.status
    end
  end

  test "should save mission with auto-generated timestamp" do
    mission = Mission.create!(name: "Test Mission", status: "draft")
    assert mission.persisted?
    assert mission.created_at.present?
    assert mission.updated_at.present?
  end

  test "should create mission with generated name matching expected format" do
    frozen_time = Time.parse("2025-09-29 14:30:15 UTC")
    travel_to(frozen_time) do
      mission = Mission.create!(
        name: Mission.generate_name,
        status: "draft"
      )

      assert_equal "Mission - 2025-09-29 14:30:15", mission.name
      assert_equal "draft", mission.status
    end
  end

  # Test UC002 Business Rules: BR01, BR02, BR03, BR04

  test "should allow nil jql_query for draft missions" do
    mission = Mission.new(name: "Test Mission", status: "draft", jql_query: nil)
    assert mission.valid?
  end

  test "should require jql_query when status is in_progress" do
    mission = Mission.new(name: "Test Mission", status: "in_progress", jql_query: nil)
    assert_not mission.valid?
    assert_includes mission.errors[:jql_query], "can't be blank"
  end

  test "should allow empty jql_query for draft missions" do
    mission = Mission.new(name: "Test Mission", status: "draft", jql_query: "")
    assert mission.valid?
  end

  test "should be valid with jql_query for in_progress missions" do
    mission = Mission.new(
      name: "Test Mission",
      status: "in_progress",
      jql_query: 'project = "TEST" AND issuetype = Bug'
    )
    assert mission.valid?
  end

  test "save_jql_query! should save query and update status to in_progress" do
    mission = Mission.create!(name: "Test Mission", status: "draft")
    query = 'project = "TEST" AND issuetype = Bug'

    mission.save_jql_query!(query)
    mission.reload

    assert_equal query, mission.jql_query
    assert_equal "in_progress", mission.status
  end

  test "save_jql_query! should save query and keep status if already in_progress" do
    mission = Mission.create!(
      name: "Test Mission",
      status: "in_progress",
      jql_query: 'old query'
    )
    new_query = 'project = "TEST" AND issuetype = Bug'

    mission.save_jql_query!(new_query)
    mission.reload

    assert_equal new_query, mission.jql_query
    assert_equal "in_progress", mission.status
  end

  test "save_jql_query! should raise error with empty query" do
    mission = Mission.create!(name: "Test Mission", status: "draft")

    assert_raises(ActiveRecord::RecordInvalid) do
      mission.save_jql_query!("")
    end
  end

  test "in_progress scope should return only in_progress missions" do
    draft_mission = Mission.create!(name: "Draft Mission", status: "draft")
    in_progress_mission = Mission.create!(
      name: "In Progress Mission",
      status: "in_progress",
      jql_query: 'project = "TEST"'
    )

    in_progress_missions = Mission.in_progress
    assert_includes in_progress_missions, in_progress_mission
    assert_not_includes in_progress_missions, draft_mission
  end
end
