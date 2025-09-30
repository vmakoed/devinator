require 'net/http'
require 'uri'
require 'json'

class JiraService
  class JiraError < StandardError; end
  class InvalidQueryError < JiraError; end
  class ApiError < JiraError; end

  def initialize
    @base_url = ENV.fetch('JIRA_BASE_URL', '')
    @email = ENV.fetch('JIRA_EMAIL', '')
    @api_token = ENV.fetch('JIRA_API_TOKEN', '')
  end

  def fetch_tickets(jql_query)
    response = make_request(jql_query)
    parse_response(response)
  rescue JiraError
    raise
  rescue JSON::ParserError => e
    raise ApiError, "Invalid JSON response from JIRA: #{e.message}"
  rescue StandardError => e
    raise ApiError, "Failed to fetch tickets: #{e.message}"
  end

  private

  def make_request(jql_query)
    query_params = URI.encode_www_form({
      jql: jql_query,
      maxResults: 100,
      fields: 'key,summary,status,priority,assignee,created,labels,description,issuetype,comment,issuelinks'
    })

    uri = URI("#{@base_url}/rest/api/3/search/jql?#{query_params}")

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 10

    request = Net::HTTP::Get.new(uri.request_uri, headers)

    response = http.request(request)
    handle_response(response)
  end

  def headers
    auth_string = Base64.strict_encode64("#{@email}:#{@api_token}")
    {
      'Authorization' => "Basic #{auth_string}",
      'Content-Type' => 'application/json',
      'Accept' => 'application/json'
    }
  end


  def handle_response(response)
    case response.code.to_i
    when 200
      response.body
    when 400
      error_message = parse_error_message(response.body)
      raise InvalidQueryError, "Invalid JQL query: #{error_message}"
    when 401
      raise ApiError, "Authentication failed. Please check your JIRA credentials."
    when 403
      raise ApiError, "Access denied. You don't have permission to view these tickets."
    when 429
      raise ApiError, "JIRA rate limit exceeded. Please wait and try again."
    else
      raise ApiError, "JIRA API error (#{response.code}): #{response.message}"
    end
  end

  def parse_error_message(body)
    error_data = JSON.parse(body)
    error_data.dig('errorMessages', 0) || error_data['error'] || 'Unknown error'
  rescue JSON::ParserError
    'Unknown error'
  end

  def parse_response(json_string)
    data = JSON.parse(json_string)

    Rails.logger.info("JIRA Response: #{data.inspect}")

    issues = data['issues'] || []
    {
      total: data['total'] || issues.length,
      tickets: issues.map { |issue| parse_ticket(issue) }
    }
  end

  def parse_ticket(issue)
    fields = issue['fields']

    {
      jira_key: issue['key'],
      summary: fields['summary'],
      description: fields['description'],
      status: fields.dig('status', 'name'),
      priority: fields.dig('priority', 'name'),
      assignee: fields.dig('assignee', 'displayName') || fields.dig('assignee', 'emailAddress'),
      labels: fields['labels']&.join(', '),
      jira_created_at: fields['created'] ? Time.parse(fields['created']) : nil,
      raw_data: issue
    }
  end
end