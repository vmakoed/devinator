class TicketsController < ApplicationController
  before_action :set_mission

  def preview
    if @mission.tickets.any?
      # Tickets already fetched, display them
      @tickets = @mission.tickets
      @ticket_count = @tickets.count
    else
      # Fetch tickets from JIRA
      fetch_tickets_from_jira
    end
  rescue JiraService::InvalidQueryError => e
    flash.now[:error] = e.message
    @error_type = :invalid_query
  rescue JiraService::ApiError => e
    flash.now[:error] = e.message
    @error_type = :api_error
  rescue StandardError => e
    flash.now[:error] = "An unexpected error occurred: #{e.message}"
    @error_type = :unknown
    Rails.logger.error("Ticket preview error: #{e.message}\n#{e.backtrace.join("\n")}")
  end

  def confirm
    @mission = Mission.find(params[:mission_id])
    redirect_to analyze_mission_path(@mission), notice: "Tickets confirmed. Ready for analysis."
  end

  private

  def set_mission
    @mission = Mission.find(params[:mission_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to missions_path, alert: "Mission not found."
  end

  def fetch_tickets_from_jira
    jira_service = JiraService.new
    result = jira_service.fetch_tickets(@mission.jql_query)

    if result[:total].to_i.zero?
      @tickets = []
      @ticket_count = 0
      flash.now[:warning] = "No tickets found matching your query."
    else
      @tickets = save_tickets(result[:tickets])
      @ticket_count = @tickets.count
      flash.now[:success] = "Successfully fetched #{@ticket_count} ticket#{'s' unless @ticket_count == 1}."
    end
  end

  def save_tickets(ticket_data)
    tickets = ticket_data.map do |data|
      @mission.tickets.create!(data)
    end
    tickets
  end
end
