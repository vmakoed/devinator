class JqlValidator
  # JQL keywords and operators for validation
  JQL_KEYWORDS = %w[
    AND OR NOT IN NOT IN ORDER BY ASC DESC GROUP BY HAVING
    project issuetype status priority assignee reporter creator
    resolution fixVersion affectedVersion component labels
    created updated resolved due summary description environment
    comment worklogAuthor worklogDate timeSpent originalEstimate
    remainingEstimate aggregatetimeoriginalestimate aggregatetimespent
    duedate lastViewed voter watcher issuekey parent epic
    sprint team rank cf custom field
  ].freeze

  JQL_OPERATORS = %w[
    = != > >= < <= ~ !~ IS IS NOT WAS WAS NOT IN NOT IN
    CHANGED CHANGED FROM CHANGED TO NOT CHANGED
  ].freeze

  JQL_FUNCTIONS = %w[
    now startOfDay startOfWeek startOfMonth startOfYear
    endOfDay endOfWeek endOfMonth endOfYear
    currentUser membersOf projectsLeadByUser
    releasedVersions unreleasedVersions
  ].freeze

  def self.validate(query_text)
    new(query_text).validate
  end

  def initialize(query_text)
    @query_text = query_text.to_s.strip
    @errors = []
    @warnings = []
  end

  def validate
    return { valid: false, error: "Query cannot be empty" } if @query_text.blank?

    perform_validation

    {
      valid: @errors.empty?,
      error: @errors.first,
      warnings: @warnings,
      suggestions: generate_suggestions
    }
  end

  private

  def perform_validation
    check_basic_syntax
    check_parentheses_balance
    check_quote_balance
    check_field_operators
    check_logical_operators
    check_length_limit
    check_security_patterns
  end

  def check_basic_syntax
    # Check for common JQL patterns - allow quoted values, parentheses for IN clause, and dates/functions
    unless @query_text.match?(/\w+\s*(=|!=|~|!~|>|>=|<|<=|IS|IS NOT|WAS|WAS NOT|IN|NOT IN)\s*[\w"'(-]/i)
      @errors << "Query must contain at least one field-operator-value combination"
    end

    # Check for invalid characters - be less restrictive
    if @query_text.match?(/[{}$%^&*]/)
      @errors << "Query contains invalid characters"
    end
  end

  def check_parentheses_balance
    open_count = @query_text.count('(')
    close_count = @query_text.count(')')

    if open_count != close_count
      @errors << "Unbalanced parentheses in query"
    end
  end

  def check_quote_balance
    single_quotes = @query_text.count("'")
    double_quotes = @query_text.count('"')

    if single_quotes.odd?
      @errors << "Unmatched single quotes in query"
    end

    if double_quotes.odd?
      @errors << "Unmatched double quotes in query"
    end
  end

  def check_field_operators
    # Look for field-operator patterns and validate them
    @query_text.scan(/(\w+)\s*(=|!=|~|!~|>|>=|<|<=|IS|IS NOT|WAS|WAS NOT|IN|NOT IN)\s*/i) do |field, operator|
      next if JQL_KEYWORDS.map(&:downcase).include?(field.downcase)

      # Check if it might be a custom field
      unless field.match?(/^(cf\[\d+\]|customfield_\d+)$/i)
        @warnings << "Field '#{field}' may not be a standard JIRA field"
      end
    end
  end

  def check_logical_operators
    # Check for proper logical operator usage
    if @query_text.match?(/\b(AND|OR)\s+(AND|OR)\b/i)
      @errors << "Invalid logical operator sequence"
    end

    # Check for missing logical operators between conditions
    conditions = @query_text.split(/\b(AND|OR)\b/i).map(&:strip).reject(&:empty?)
    conditions.each do |condition|
      next if condition.match?(/^(AND|OR)$/i)

      if condition.scan(/\w+\s*(=|!=|~|!~|>|>=|<|<=|IS|IS NOT|WAS|WAS NOT|IN|NOT IN)\s*/i).length > 1
        @warnings << "Multiple conditions may need explicit logical operators"
      end
    end
  end

  def check_length_limit
    if @query_text.length > 2000
      @errors << "Query exceeds maximum length of 2000 characters"
    elsif @query_text.length > 1500
      @warnings << "Query is very long and may impact performance"
    end
  end

  def check_security_patterns
    # Check for potentially malicious patterns
    dangerous_patterns = [
      /\bUNION\s+SELECT\b/i,
      /\bDROP\s+TABLE\b/i,
      /\bINSERT\s+INTO\b/i,
      /\bUPDATE\s+SET\b/i,
      /\bDELETE\s+FROM\b/i,
      /<script\b/i,
      /javascript:/i
    ]

    dangerous_patterns.each do |pattern|
      if @query_text.match?(pattern)
        @errors << "Query contains potentially unsafe content"
        break
      end
    end
  end

  def generate_suggestions
    suggestions = []

    # Suggest project specification if missing
    unless @query_text.match?(/\bproject\s*=/i)
      suggestions << "Consider specifying a project: project = \"YOUR_PROJECT\""
    end

    # Suggest status filter if missing
    unless @query_text.match?(/\bstatus\s*(=|!=|IN|NOT IN)/i)
      suggestions << "Consider filtering by status to get more relevant results"
    end

    # Suggest ordering if missing
    unless @query_text.match?(/\bORDER BY\b/i)
      suggestions << "Consider adding ORDER BY for consistent results"
    end

    # Suggest common improvements
    if @query_text.match?(/\bassignee\s*=\s*EMPTY\b/i)
      suggestions << "Use 'assignee IS EMPTY' instead of 'assignee = EMPTY'"
    end

    suggestions
  end
end