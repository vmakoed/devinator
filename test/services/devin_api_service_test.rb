require "test_helper"

class DevinApiServiceTest < ActiveSupport::TestCase
  # Test UC006 Devin API Integration
  # Tests for API request format, response handling, error handling, and retry logic

  def setup
    @mission = Mission.create!(name: "Test Mission", status: "analyzed", jql_query: "test")
    @ticket = Ticket.create!(
      mission: @mission,
      jira_key: "TEST-123",
      summary: "Test ticket",
      status: "Open",
      complexity_score: 2,
      complexity_category: "low",
      raw_data: {
        "fields" => {
          "issuetype" => { "name" => "Bug" },
          "priority" => { "name" => "Medium" },
          "description" => "Test description",
          "labels" => ["quick-win"]
        }
      }
    )
    ENV["DEVIN_API_KEY"] = "test_key_123"
    ENV["DEVIN_API_URL"] = "https://api.devin.ai"
  end

  def teardown
    WebMock.reset!
  end

  # Test successful API call
  test "should successfully create Devin session" do
    response_body = {
      "session_id" => "devin_abc123",
      "url" => "https://devin.ai/sessions/abc123",
      "status" => "created",
      "created_at" => "2025-09-30T14:30:00Z"
    }

    stub_request(:post, "https://api.devin.ai/v1/sessions")
      .to_return(status: 200, body: response_body.to_json, headers: { "Content-Type" => "application/json" })

    service = DevinApiService.new
    result = service.create_session(@ticket)

    assert result[:success]
    assert_equal "devin_abc123", result[:session_id]
    assert_equal "https://devin.ai/sessions/abc123", result[:session_url]
    assert_equal "created", result[:status]
  end

  # Test missing API key
  test "should handle missing API key" do
    ENV["DEVIN_API_KEY"] = nil
    service = DevinApiService.new

    result = service.create_session(@ticket)

    assert_not result[:success]
    assert_equal "Authentication failed. Please check API credentials.", result[:error]
  end

  # Test 401 Unauthorized response
  test "should handle 401 unauthorized error" do
    stub_request(:post, "https://api.devin.ai/v1/sessions")
      .to_return(status: 401, body: "Unauthorized")

    service = DevinApiService.new
    result = service.create_session(@ticket)

    assert_not result[:success]
    assert_equal "Authentication failed. Please check API credentials.", result[:error]
  end

  # Test 403 Forbidden response
  test "should handle 403 forbidden error" do
    stub_request(:post, "https://api.devin.ai/v1/sessions")
      .to_return(status: 403, body: "Forbidden")

    service = DevinApiService.new
    result = service.create_session(@ticket)

    assert_not result[:success]
    assert_equal "API quota exceeded or forbidden", result[:error]
  end

  # Test 429 Rate Limit response
  test "should handle 429 rate limit error" do
    stub_request(:post, "https://api.devin.ai/v1/sessions")
      .to_return(status: 429, body: "Too Many Requests")

    service = DevinApiService.new
    result = service.create_session(@ticket)

    assert_not result[:success]
    assert_equal "Rate limit exceeded", result[:error]
  end

  # Test 500 Server Error response
  test "should handle 500 server error" do
    stub_request(:post, "https://api.devin.ai/v1/sessions")
      .to_return(status: 500, body: "Internal Server Error")

    service = DevinApiService.new
    result = service.create_session(@ticket)

    assert_not result[:success]
    assert_equal "Devin service error (500)", result[:error]
  end

  # Test timeout with retry logic
  test "should retry on timeout and eventually raise TimeoutError" do
    stub_request(:post, "https://api.devin.ai/v1/sessions")
      .to_timeout.times(3)

    service = DevinApiService.new
    service.sleep_enabled = false

    assert_raises DevinApiService::TimeoutError do
      service.create_session(@ticket)
    end
  end

  # Test successful retry after initial timeout
  test "should succeed on retry after initial timeout" do
    response_body = {
      "session_id" => "devin_retry",
      "url" => "https://devin.ai/sessions/retry",
      "status" => "created",
      "created_at" => "2025-09-30T14:30:00Z"
    }

    # First call times out, second succeeds
    stub_request(:post, "https://api.devin.ai/v1/sessions")
      .to_timeout.times(1).then
      .to_return(status: 200, body: response_body.to_json, headers: { "Content-Type" => "application/json" })

    service = DevinApiService.new
    result = service.create_session(@ticket)

    assert result[:success]
    assert_equal "devin_retry", result[:session_id]
  end

  # Test invalid JSON response
  test "should handle invalid JSON response" do
    stub_request(:post, "https://api.devin.ai/v1/sessions")
      .to_return(status: 200, body: "invalid json {", headers: { "Content-Type" => "application/json" })

    service = DevinApiService.new
    result = service.create_session(@ticket)

    assert_not result[:success]
    assert_equal "Invalid response from Devin API", result[:error]
  end

  # Test payload structure
  test "should build proper payload with ticket details" do
    service = DevinApiService.new

    # Access private method for testing
    payload = service.send(:build_payload, @ticket)

    assert payload.key?(:prompt)
    assert payload.key?(:idempotent)
    assert_equal true, payload[:idempotent]

    # Verify prompt includes ticket information
    prompt = payload[:prompt]
    assert_includes prompt, @ticket.jira_key
    assert_includes prompt, @ticket.summary
    assert_includes prompt, @ticket.jira_url
  end

  # Test API URL configuration
  test "should use configured API URL" do
    ENV["DEVIN_API_URL"] = "https://custom.devin.ai"

    stub_request(:post, "https://custom.devin.ai/v1/sessions")
      .to_return(status: 200, body: { session_id: "test", url: "test", status: "created" }.to_json)

    service = DevinApiService.new
    result = service.create_session(@ticket)

    assert result[:success]
  end

  # Test default API URL
  test "should use default API URL when not configured" do
    ENV["DEVIN_API_URL"] = nil

    stub_request(:post, "https://api.devin.ai/v1/sessions")
      .to_return(status: 200, body: { session_id: "test", url: "test", status: "created" }.to_json)

    service = DevinApiService.new
    result = service.create_session(@ticket)

    assert result[:success]
  end

  # Test timeout constants
  test "should have proper timeout and retry constants" do
    assert_equal 30, DevinApiService::TIMEOUT
    assert_equal 3, DevinApiService::MAX_RETRIES
    assert_equal 1, DevinApiService::BASE_DELAY
  end

  # Test that retry logic attempts multiple times
  test "should retry 3 times after initial attempt before failing" do
    stub = stub_request(:post, "https://api.devin.ai/v1/sessions")
      .to_timeout

    service = DevinApiService.new
    service.sleep_enabled = false

    assert_raises DevinApiService::TimeoutError do
      service.create_session(@ticket)
    end

    # Verify the stub was called exactly 4 times (1 initial + 3 retries = MAX_RETRIES)
    assert_requested stub, times: 4
  end

  # Test that ticket metadata is included in request
  test "should include all ticket metadata in API request" do
    stub = stub_request(:post, "https://api.devin.ai/v1/sessions")
      .with { |request|
        body = JSON.parse(request.body)
        body["prompt"].include?(@ticket.jira_key) &&
        body["prompt"].include?(@ticket.summary) &&
        body["prompt"].include?(@ticket.complexity_category) &&
        body["idempotent"] == true
      }
      .to_return(status: 200, body: { session_id: "test", url: "test", status: "created" }.to_json)

    service = DevinApiService.new
    service.create_session(@ticket)

    assert_requested stub
  end

  # Test custom API URL with different domain
  test "should support custom API domains" do
    ENV["DEVIN_API_URL"] = "https://devin.example.com"

    stub_request(:post, "https://devin.example.com/v1/sessions")
      .to_return(status: 200, body: { session_id: "custom", url: "https://custom.url", status: "created" }.to_json)

    service = DevinApiService.new
    result = service.create_session(@ticket)

    assert result[:success]
    assert_equal "custom", result[:session_id]
  end

  # Test authentication header is properly set
  test "should include authorization header in request" do
    ENV["DEVIN_API_KEY"] = "my_secret_key"

    stub = stub_request(:post, "https://api.devin.ai/v1/sessions")
      .with(headers: { "Authorization" => "Bearer my_secret_key" })
      .to_return(status: 200, body: { session_id: "test", url: "test", status: "created" }.to_json)

    service = DevinApiService.new
    service.create_session(@ticket)

    assert_requested stub
  end
end