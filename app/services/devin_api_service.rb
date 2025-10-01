require "net/http"
require "uri"
require "json"

class DevinApiService
  class TimeoutError < StandardError; end
  class AuthenticationError < StandardError; end
  class ApiError < StandardError; end

  TIMEOUT = 30 # seconds
  MAX_RETRIES = 3
  BASE_DELAY = 1 # second

  attr_accessor :sleep_enabled

  def initialize
    @api_key = ENV["DEVIN_API_KEY"]
    @api_url = ENV["DEVIN_API_URL"] || "https://api.devin.ai"
    @sleep_enabled = true
  end

  def create_session(ticket)
    validate_credentials!

    payload = build_payload(ticket)
    response = make_request_with_retry(payload)

    parse_response(response)
  rescue TimeoutError => e
    Rails.logger.error "Devin API timeout for ticket #{ticket.jira_key}: #{e.message}"
    raise
  rescue AuthenticationError => e
    Rails.logger.error "Devin API authentication failed: #{e.message}"
    { success: false, error: "Authentication failed. Please check API credentials." }
  rescue ApiError => e
    Rails.logger.error "Devin API error for ticket #{ticket.jira_key}: #{e.message}"
    { success: false, error: e.message }
  rescue => e
    Rails.logger.error "Unexpected error calling Devin API: #{e.message}"
    { success: false, error: "Unexpected error: #{e.message}" }
  end

  private

  def validate_credentials!
    raise AuthenticationError, "DEVIN_API_KEY not configured" if @api_key.blank?
  end

  def build_payload(ticket)
    # Build a prompt for Devin with all the ticket information
    prompt = <<~PROMPT
      Please review and fix the following JIRA ticket:

      **Ticket ID**: #{ticket.jira_key}
      **Summary**: #{ticket.summary}
      **Status**: #{ticket.status}
      **Priority**: #{ticket.raw_data&.dig("fields", "priority", "name") || "Medium"}
      **JIRA URL**: #{ticket.jira_url}
      **Complexity**: #{ticket.complexity_category} (score: #{ticket.complexity_score})

      **Description**:
      #{ticket.raw_data&.dig("fields", "description")}

      Please analyze this ticket, implement a fix, and create a pull request.
    PROMPT

    {
      prompt: prompt,
      title: ticket.jira_key
    }
  end

  def extract_labels(ticket)
    labels = ticket.raw_data&.dig("fields", "labels") || []
    labels << "bug" if ticket.raw_data&.dig("fields", "issuetype", "name") == "Bug"
    labels << "low-complexity" if ticket.complexity_category == "low"
    labels.compact.uniq
  end

  def make_request_with_retry(payload)
    retries = 0

    begin
      make_request(payload)
    rescue Timeout::Error, Net::OpenTimeout, Net::ReadTimeout => e
      if retries < MAX_RETRIES
        retries += 1
        delay = BASE_DELAY * (2 ** (retries - 1)) # Exponential backoff
        Rails.logger.warn "Devin API timeout, retry #{retries}/#{MAX_RETRIES} after #{delay}s"
        sleep(delay) if @sleep_enabled
        retry
      else
        raise TimeoutError, "Request timed out after #{MAX_RETRIES} retries"
      end
    end
  end

  def make_request(payload)
    uri = URI("#{@api_url}/v1/sessions")

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == "https"
    http.open_timeout = TIMEOUT
    http.read_timeout = TIMEOUT

    request = Net::HTTP::Post.new(uri.path)
    request["Authorization"] = "Bearer #{@api_key}"
    request["Content-Type"] = "application/json"
    request.body = payload.to_json

    response = http.request(request)

    handle_response(response)
  end

  def handle_response(response)
    case response.code.to_i
    when 200..299
      response
    when 401
      raise AuthenticationError, "Invalid API credentials"
    when 403
      raise ApiError, "API quota exceeded or forbidden"
    when 429
      raise ApiError, "Rate limit exceeded"
    when 500..599
      raise ApiError, "Devin service error (#{response.code})"
    else
      raise ApiError, "Unexpected response (#{response.code}): #{response.body}"
    end
  end

  def parse_response(response)
    data = JSON.parse(response.body)

    {
      success: true,
      session_id: data["session_id"],
      session_url: data["url"], # Devin API returns "url" not "session_url"
      status: data["status"],
      created_at: data["created_at"]
    }
  rescue JSON::ParserError => e
    Rails.logger.error "Failed to parse Devin API response: #{e.message}"
    { success: false, error: "Invalid response from Devin API" }
  end
end
