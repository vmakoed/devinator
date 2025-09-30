require "test_helper"
require "webmock/minitest"

class JiraServiceTest < ActiveSupport::TestCase
  # Test UC003 JIRA API Integration
  # Test error handling and response parsing

  setup do
    @base_url = "https://test.atlassian.net"
    @jql_query = 'project = "TEST" AND issuetype = Bug'

    # Set environment variables before creating service
    ENV["JIRA_BASE_URL"] = @base_url
    ENV["JIRA_EMAIL"] = "test@example.com"
    ENV["JIRA_API_TOKEN"] = "test_token_123"

    @jira_service = JiraService.new
  end

  teardown do
    WebMock.reset!
  end

  # Test successful ticket fetch
  test "should fetch tickets successfully from JIRA" do
    mock_response = {
      "total" => 2,
      "issues" => [
        {
          "key" => "TEST-123",
          "fields" => {
            "summary" => "Fix login bug",
            "description" => "Users cannot login to the system",
            "status" => { "name" => "Open" },
            "priority" => { "name" => "High" },
            "assignee" => { "displayName" => "John Doe", "emailAddress" => "john@example.com" },
            "labels" => ["bug", "urgent"],
            "created" => "2025-09-01T10:00:00.000+0000"
          }
        },
        {
          "key" => "TEST-456",
          "fields" => {
            "summary" => "Update documentation",
            "description" => nil,
            "status" => { "name" => "In Progress" },
            "priority" => { "name" => "Medium" },
            "assignee" => nil,
            "labels" => [],
            "created" => "2025-09-02T11:00:00.000+0000"
          }
        }
      ]
    }

    stub_request(:get, "#{@base_url}/rest/api/3/search/jql")
      .with(query: hash_including({ "jql" => @jql_query }))
      .to_return(status: 200, body: mock_response.to_json, headers: { "Content-Type" => "application/json" })

    result = @jira_service.fetch_tickets(@jql_query)

    assert_equal 2, result[:total]
    assert_equal 2, result[:tickets].count

    # Check first ticket
    first_ticket = result[:tickets][0]
    assert_equal "TEST-123", first_ticket[:jira_key]
    assert_equal "Fix login bug", first_ticket[:summary]
    assert_equal "Users cannot login to the system", first_ticket[:description]
    assert_equal "Open", first_ticket[:status]
    assert_equal "High", first_ticket[:priority]
    assert_equal "John Doe", first_ticket[:assignee]
    assert_equal "bug, urgent", first_ticket[:labels]
    assert_instance_of Time, first_ticket[:jira_created_at]

    # Check second ticket (with nil assignee and empty labels)
    second_ticket = result[:tickets][1]
    assert_equal "TEST-456", second_ticket[:jira_key]
    assert_nil second_ticket[:assignee]
    assert_equal "", second_ticket[:labels]
  end

  # Test empty results
  test "should handle empty JIRA results" do
    mock_response = {
      "total" => 0,
      "issues" => []
    }

    stub_request(:get, "#{@base_url}/rest/api/3/search/jql")
      .with(query: hash_including({ "jql" => @jql_query }))
      .to_return(status: 200, body: mock_response.to_json, headers: { "Content-Type" => "application/json" })

    result = @jira_service.fetch_tickets(@jql_query)

    assert_equal 0, result[:total]
    assert_equal [], result[:tickets]
  end

  # UC003 AF3: Invalid JQL Query
  test "should raise InvalidQueryError for invalid JQL syntax" do
    error_response = {
      "errorMessages" => ["Error in JQL query near 'AND'. Expected one of: '(', ')', ',', etc."]
    }

    invalid_query = "invalid JQL AND"
    stub_request(:get, "#{@base_url}/rest/api/3/search/jql")
      .with(query: hash_including({ "jql" => invalid_query }))
      .to_return(status: 400, body: error_response.to_json, headers: { "Content-Type" => "application/json" })

    error = assert_raises(JiraService::InvalidQueryError) do
      @jira_service.fetch_tickets(invalid_query)
    end

    assert_match /Invalid JQL query/, error.message
    assert_match /Error in JQL query near 'AND'/, error.message
  end

  # UC003 AF2: JIRA API Error - Authentication
  test "should raise ApiError for authentication failure" do
    stub_request(:get, "#{@base_url}/rest/api/3/search/jql")
      .with(query: hash_including({ "jql" => @jql_query }))
      .to_return(status: 401, body: "", headers: {})

    error = assert_raises(JiraService::ApiError) do
      @jira_service.fetch_tickets(@jql_query)
    end

    assert_equal "Authentication failed. Please check your JIRA credentials.", error.message
  end

  # UC003 AF2: JIRA API Error - Permission denied
  test "should raise ApiError for permission denied" do
    stub_request(:get, "#{@base_url}/rest/api/3/search/jql")
      .with(query: hash_including({ "jql" => @jql_query }))
      .to_return(status: 403, body: "", headers: {})

    error = assert_raises(JiraService::ApiError) do
      @jira_service.fetch_tickets(@jql_query)
    end

    assert_equal "Access denied. You don't have permission to view these tickets.", error.message
  end

  # UC003 AF2: JIRA API Error - Rate limit
  test "should raise ApiError for rate limit exceeded" do
    stub_request(:get, "#{@base_url}/rest/api/3/search/jql")
      .with(query: hash_including({ "jql" => @jql_query }))
      .to_return(status: 429, body: "", headers: {})

    error = assert_raises(JiraService::ApiError) do
      @jira_service.fetch_tickets(@jql_query)
    end

    assert_equal "JIRA rate limit exceeded. Please wait and try again.", error.message
  end

  # Test generic server error
  test "should raise ApiError for server errors" do
    stub_request(:get, "#{@base_url}/rest/api/3/search/jql")
      .with(query: hash_including({ "jql" => @jql_query }))
      .to_return(status: 500, body: "", headers: {})

    error = assert_raises(JiraService::ApiError) do
      @jira_service.fetch_tickets(@jql_query)
    end

    assert_match /JIRA API error \(500\)/, error.message
  end

  # Test network timeout
  test "should raise ApiError for network timeout" do
    stub_request(:get, "#{@base_url}/rest/api/3/search/jql")
      .with(query: hash_including({ "jql" => @jql_query }))
      .to_timeout

    error = assert_raises(JiraService::ApiError) do
      @jira_service.fetch_tickets(@jql_query)
    end

    assert_match /Failed to fetch tickets/, error.message
  end

  # Test invalid JSON response
  test "should raise ApiError for invalid JSON response" do
    stub_request(:get, "#{@base_url}/rest/api/3/search/jql")
      .with(query: hash_including({ "jql" => @jql_query }))
      .to_return(status: 200, body: "invalid json {{{", headers: { "Content-Type" => "application/json" })

    error = assert_raises(JiraService::ApiError) do
      @jira_service.fetch_tickets(@jql_query)
    end

    assert_match /Invalid JSON response from JIRA/, error.message
  end

  # Test request headers are set correctly
  test "should send correct authorization headers" do
    mock_response = { "total" => 0, "issues" => [] }

    stub = stub_request(:get, "#{@base_url}/rest/api/3/search/jql")
      .with(
        query: hash_including({ "jql" => @jql_query }),
        headers: {
          "Authorization" => /Basic/,
          "Content-Type" => "application/json",
          "Accept" => "application/json"
        }
      )
      .to_return(status: 200, body: mock_response.to_json, headers: { "Content-Type" => "application/json" })

    @jira_service.fetch_tickets(@jql_query)

    assert_requested stub
  end

  # Test query parameters are encoded correctly
  test "should properly encode JQL query in URL" do
    complex_query = 'project = "TEST PROJECT" AND status IN ("Open", "In Progress")'
    mock_response = { "total" => 0, "issues" => [] }

    stub = stub_request(:get, "#{@base_url}/rest/api/3/search/jql")
      .with(query: hash_including({
        "jql" => complex_query
      }))
      .to_return(status: 200, body: mock_response.to_json, headers: { "Content-Type" => "application/json" })

    @jira_service.fetch_tickets(complex_query)

    assert_requested stub
  end

  # Test maxResults parameter
  test "should include maxResults in query parameters" do
    mock_response = { "total" => 0, "issues" => [] }

    stub = stub_request(:get, "#{@base_url}/rest/api/3/search/jql")
      .with(query: hash_including({
        "maxResults" => "100"
      }))
      .to_return(status: 200, body: mock_response.to_json, headers: { "Content-Type" => "application/json" })

    @jira_service.fetch_tickets(@jql_query)

    assert_requested stub
  end

  # Test fields parameter
  test "should request correct fields from JIRA" do
    mock_response = { "total" => 0, "issues" => [] }

    stub = stub_request(:get, "#{@base_url}/rest/api/3/search/jql")
      .with(query: hash_including({
        "fields" => "key,summary,status,priority,assignee,created,labels,description,issuetype,comment,issuelinks"
      }))
      .to_return(status: 200, body: mock_response.to_json, headers: { "Content-Type" => "application/json" })

    @jira_service.fetch_tickets(@jql_query)

    assert_requested stub
  end

  # Test parsing ticket with email fallback for assignee
  test "should use email as assignee when displayName is not available" do
    mock_response = {
      "total" => 1,
      "issues" => [
        {
          "key" => "TEST-789",
          "fields" => {
            "summary" => "Test ticket",
            "status" => { "name" => "Open" },
            "priority" => { "name" => "Low" },
            "assignee" => { "emailAddress" => "user@example.com" },
            "labels" => [],
            "created" => "2025-09-01T10:00:00.000+0000"
          }
        }
      ]
    }

    stub_request(:get, "#{@base_url}/rest/api/3/search/jql")
      .with(query: hash_including({ "jql" => @jql_query }))
      .to_return(status: 200, body: mock_response.to_json, headers: { "Content-Type" => "application/json" })

    result = @jira_service.fetch_tickets(@jql_query)

    assert_equal "user@example.com", result[:tickets][0][:assignee]
  end

  # Test raw_data includes full issue object
  test "should include raw issue data in ticket" do
    mock_response = {
      "total" => 1,
      "issues" => [
        {
          "key" => "TEST-RAW",
          "id" => "12345",
          "self" => "https://test.atlassian.net/rest/api/3/issue/12345",
          "fields" => {
            "summary" => "Test ticket",
            "status" => { "name" => "Open" },
            "customfield_123" => "custom value"
          }
        }
      ]
    }

    stub_request(:get, "#{@base_url}/rest/api/3/search/jql")
      .with(query: hash_including({ "jql" => @jql_query }))
      .to_return(status: 200, body: mock_response.to_json, headers: { "Content-Type" => "application/json" })

    result = @jira_service.fetch_tickets(@jql_query)

    raw_data = result[:tickets][0][:raw_data]
    assert_equal "TEST-RAW", raw_data["key"]
    assert_equal "12345", raw_data["id"]
    assert_equal "custom value", raw_data["fields"]["customfield_123"]
  end

  # Test error message parsing
  test "should parse error message from JIRA error response" do
    error_response = {
      "errorMessages" => ["Custom error message from JIRA"]
    }

    stub_request(:get, "#{@base_url}/rest/api/3/search/jql")
      .with(query: hash_including({ "jql" => @jql_query }))
      .to_return(status: 400, body: error_response.to_json, headers: { "Content-Type" => "application/json" })

    error = assert_raises(JiraService::InvalidQueryError) do
      @jira_service.fetch_tickets(@jql_query)
    end

    assert_match /Custom error message from JIRA/, error.message
  end

  # Test when total is not present in response (use issues length)
  test "should use issues length when total is missing" do
    mock_response = {
      "issues" => [
        {
          "key" => "TEST-1",
          "fields" => {
            "summary" => "Test",
            "status" => { "name" => "Open" }
          }
        }
      ]
    }

    stub_request(:get, "#{@base_url}/rest/api/3/search/jql")
      .with(query: hash_including({ "jql" => @jql_query }))
      .to_return(status: 200, body: mock_response.to_json, headers: { "Content-Type" => "application/json" })

    result = @jira_service.fetch_tickets(@jql_query)

    assert_equal 1, result[:total]
  end
end