class TicketComplexityAnalyzer
  BASE_SCORE = 3

  def initialize(ticket)
    @ticket = ticket
  end

  def analyze!
    score = calculate_complexity_score
    category = determine_category(score)
    factors = calculate_factors

    @ticket.update!(
      complexity_score: score,
      complexity_category: category,
      complexity_factors: factors,
      analyzed_at: Time.current
    )
  end

  private

  def calculate_complexity_score
    score = BASE_SCORE
    score += description_length_factor
    score += comments_factor
    score += linked_issues_factor
    score += issue_type_factor
    score += labels_factor
    score += time_in_backlog_factor
    score.clamp(1, 10)
  end

  def description_length_factor
    text = extract_text_from_description
    return 2 if text.nil? || text.length < 100
    return 1 if text.length < 500
    return 0 if text.length < 2000
    1
  end

  def extract_text_from_description
    return nil if @ticket.raw_data.blank?

    # Get description from raw_data (already parsed as Hash from JSON column)
    doc = @ticket.raw_data.dig("fields", "description")
    return nil unless doc

    # Extract text from ADF structure
    extract_text_from_adf(doc)
  end

  def extract_text_from_adf(node)
    return "" unless node.is_a?(Hash)

    text = ""

    # If this node has text, collect it
    text += node["text"] if node["text"]

    # Recursively process content array
    if node["content"].is_a?(Array)
      node["content"].each do |child|
        text += extract_text_from_adf(child)
        text += " " # Add space between nodes
      end
    end

    text.strip
  end

  def comments_factor
    count = get_comments_count
    return 0 if count <= 2
    return 1 if count <= 5
    return 2 if count <= 10
    3
  end

  def get_comments_count
    @ticket.raw_data&.dig("fields", "comment", "total") || 0
  end

  def linked_issues_factor
    count = get_linked_issues_count
    return 0 if count == 0
    return 1 if count <= 2
    return 2 if count <= 5
    3
  end

  def get_linked_issues_count
    @ticket.raw_data&.dig("fields", "issuelinks")&.length || 0
  end

  def issue_type_factor
    issue_type = get_issue_type
    case issue_type&.downcase
    when "bug" then 0
    when "task" then 1
    when "story" then 2
    when "epic" then 3
    else 1
    end
  end

  def get_issue_type
    @ticket.raw_data&.dig("fields", "issuetype", "name")
  end

  def labels_factor
    labels = get_labels
    return 0 if labels.empty?

    adjustment = 0
    adjustment -= 2 if labels.include?("quick-win")
    adjustment += 0 if labels.include?("technical-debt")
    adjustment += 3 if labels.include?("complex")
    adjustment += 2 if labels.include?("needs-investigation")
    adjustment
  end

  def get_labels
    @ticket.raw_data&.dig("fields", "labels") || []
  end

  def time_in_backlog_factor
    return 0 unless @ticket.jira_created_at

    days_old = (Date.current - @ticket.jira_created_at.to_date).to_i
    return 0 if days_old < 31
    return 1 if days_old < 90
    1
  end

  def determine_category(score)
    return "low" if score <= 3
    return "medium" if score <= 7
    "high"
  end

  def calculate_factors
    {
      description_length: description_length_factor,
      comments: comments_factor,
      linked_issues: linked_issues_factor,
      issue_type: issue_type_factor,
      labels: labels_factor,
      time_in_backlog: time_in_backlog_factor
    }
  end
end