class JqlQueriesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_session
  before_action :set_jql_query, only: [:edit, :update, :destroy]
  before_action :ensure_can_create_queries, only: [:new, :create]

  def index
    @jql_queries = @session.jql_queries.order(created_at: :desc)
  end

  def new
    @jql_query = @session.jql_queries.build
    @query_templates = load_query_templates
    @user_query_history = current_user.jql_queries.distinct.pluck(:query_text).last(10)
  end

  def create
    @jql_query = @session.jql_queries.build(jql_query_params)

    if @jql_query.save
      # Log query creation for audit
      log_query_action('create', @jql_query)

      redirect_to session_jql_queries_path(@session),
                  notice: "JQL query '#{@jql_query.display_name}' created successfully"
    else
      @query_templates = load_query_templates
      @user_query_history = current_user.jql_queries.distinct.pluck(:query_text).last(10)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @query_templates = load_query_templates
    @user_query_history = current_user.jql_queries.distinct.pluck(:query_text).last(10)
  end

  def update
    if @jql_query.update(jql_query_params)
      log_query_action('update', @jql_query)
      redirect_to session_jql_queries_path(@session),
                  notice: "JQL query updated successfully"
    else
      @query_templates = load_query_templates
      @user_query_history = current_user.jql_queries.distinct.pluck(:query_text).last(10)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    query_name = @jql_query.display_name
    @jql_query.destroy
    log_query_action('destroy', @jql_query)
    redirect_to session_jql_queries_path(@session),
                notice: "JQL query '#{query_name}' deleted successfully"
  end

  # AJAX endpoint for real-time query validation
  def validate
    query_text = params[:query_text]

    if query_text.blank?
      render json: { valid: false, error: "Query cannot be empty" }
      return
    end

    validation_result = JqlValidator.validate(query_text)
    render json: validation_result
  end

  private

  def authenticate_user!
    @current_user ||= User.active.first

    unless @current_user
      redirect_to root_path, alert: "Please log in to continue"
      return false
    end
  end

  def current_user
    @current_user
  end

  def set_session
    @session = current_user.sessions.find(params[:session_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to sessions_path, alert: 'Session not found'
  end

  def set_jql_query
    @jql_query = @session.jql_queries.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to session_jql_queries_path(@session), alert: 'JQL query not found'
  end

  def ensure_can_create_queries
    unless current_user.can_create_sessions?
      redirect_to root_path, alert: 'You do not have permission to create JQL queries.'
    end
  end

  def jql_query_params
    params.require(:jql_query).permit(:query_text, :name, :description)
  end

  def load_query_templates
    [
      {
        name: "Open Bugs",
        description: "All open bug tickets",
        query: 'project = "YOUR_PROJECT" AND issuetype = Bug AND status != Done'
      },
      {
        name: "High Priority Issues",
        description: "High priority issues across all types",
        query: 'project = "YOUR_PROJECT" AND priority = High AND status != Done'
      },
      {
        name: "Recent Bugs",
        description: "Bugs created in the last 30 days",
        query: 'project = "YOUR_PROJECT" AND issuetype = Bug AND created >= -30d'
      },
      {
        name: "Unassigned Issues",
        description: "Issues without assignee",
        query: 'project = "YOUR_PROJECT" AND assignee is EMPTY AND status != Done'
      },
      {
        name: "Ready for Development",
        description: "Issues ready to be picked up by developers",
        query: 'project = "YOUR_PROJECT" AND status = "Ready for Development"'
      }
    ]
  end

  def log_query_action(action, query)
    @session.audit_logs.create!(
      entity_type: 'JqlQuery',
      entity_id: query.id.to_s,
      action: action,
      new_values: query.attributes.to_json,
      user: current_user
    )
  rescue => e
    Rails.logger.warn "Failed to log JQL query action: #{e.message}"
  end
end