class SessionsController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_can_create_sessions, only: [:new, :create]
  before_action :set_session, only: [:show, :edit, :update, :destroy, :workspace]

  helper_method :current_user

  def index
    @sessions = current_user.sessions.order(created_at: :desc)
    @active_sessions = @sessions.active
  end

  def new
    @session = current_user.sessions.build
    @session_configurations = current_user.session_configurations.order(:configuration_name)
  end

  def create
    @session = current_user.sessions.build(session_params)

    # Apply configuration if selected
    if params[:session][:configuration_id].present?
      config = current_user.session_configurations.find(params[:session][:configuration_id])
      @session.apply_configuration(config)
    end

    if @session.save
      redirect_to workspace_session_path(@session),
                  notice: "Session '#{@session.name}' created successfully"
    else
      @session_configurations = current_user.session_configurations.order(:configuration_name)
      render :new, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to new_session_path, alert: 'Selected configuration not found'
  end

  def show
    @jql_queries = @session.jql_queries.order(created_at: :desc)
    @tickets_count = @session.tickets.count
    @recommendations_count = @session.recommendations.count
  end

  def edit
    @session_configurations = current_user.session_configurations.order(:configuration_name)
  end

  def update
    if @session.update(session_params)
      redirect_to workspace_session_path(@session),
                  notice: "Session '#{@session.name}' updated successfully"
    else
      @session_configurations = current_user.session_configurations.order(:configuration_name)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    session_name = @session.name
    @session.destroy
    redirect_to sessions_path, notice: "Session '#{session_name}' deleted successfully"
  end

  def workspace
    @active_queries = @session.jql_queries.where(status: 'pending')
    @recent_tickets = @session.tickets.order(created_at: :desc).limit(10)
    @pending_recommendations = @session.recommendations.where(is_suitable_for_devin: true).limit(5)
  end

  private

  def authenticate_user!
    # Placeholder for authentication logic
    # In a real app, this would check if user is logged in
    @current_user ||= User.active.first

    unless @current_user
      redirect_to root_path, alert: "Please log in to continue"
      return false
    end
  end

  def current_user
    @current_user
  end

  def ensure_can_create_sessions
    unless current_user.can_create_new_session?
      if current_user.can_create_sessions?
        redirect_to sessions_path,
                    alert: 'Maximum active sessions reached. Please complete or archive an existing session first.'
      else
        redirect_to root_path, alert: 'You do not have permission to create sessions.'
      end
    end
  end

  def set_session
    @session = current_user.sessions.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to sessions_path, alert: 'Session not found'
  end

  def session_params
    params.require(:session).permit(:name, :description)
  end
end
