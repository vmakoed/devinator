class MissionsController < ApplicationController
  before_action :set_mission, only: [:show, :query, :analyze]

  def index
    @missions = Mission.order(created_at: :desc)
  end

  def show
    # Redirect to appropriate view based on mission state
    if @mission.tickets.any?
      redirect_to preview_mission_tickets_path(@mission)
    elsif @mission.jql_query.present?
      redirect_to query_mission_path(@mission)
    end
    # Otherwise render the show view (mission details page)
  end

  def create
    begin
      mission = Mission.create!(
        name: Mission.generate_name,
        status: "draft"
      )

      flash[:notice] = "Mission '#{mission.name}' created successfully!"
      redirect_to query_mission_path(mission)
    rescue => e
      Rails.logger.error "Mission creation failed: #{e.message}"
      flash[:alert] = "Unable to create mission. Please try again."
      redirect_to root_path
    end
  end

  def query
    if request.patch?
      handle_query_save
    else
      # GET request - show the query form
    end
  end

  def analyze
    @tickets = @mission.tickets.includes(:mission)

    if @tickets.empty?
      flash[:alert] = "No tickets to analyze. Please fetch tickets first."
      redirect_to preview_mission_tickets_path(@mission) and return
    end

    # Check if already analyzed
    if @tickets.all?(&:analyzed?)
      # Already analyzed, just display results
      calculate_summary_stats
    else
      # Perform analysis
      @tickets.each do |ticket|
        TicketComplexityAnalyzer.new(ticket).analyze!
      end
      @mission.update!(status: "analyzed")
      calculate_summary_stats
      flash[:notice] = "#{@tickets.count} tickets analyzed successfully!"
    end
  end

  private

  def calculate_summary_stats
    @total_count = @tickets.count
    @low_count = @tickets.low_complexity.count
    @medium_count = @tickets.medium_complexity.count
    @high_count = @tickets.high_complexity.count

    # Count low-complexity bugs by checking raw_data
    @low_bugs_count = @tickets.low_complexity.count do |ticket|
      ticket.raw_data&.dig("fields", "issuetype", "name") == "Bug"
    end
  end

  def set_mission
    @mission = Mission.find(params[:id])
  end

  def handle_query_save
    jql_query = params[:mission][:jql_query]

    if jql_query.blank?
      flash[:alert] = "JQL query cannot be empty"
      render :query and return
    end

    begin
      # Clear existing tickets if query has changed
      if @mission.jql_query != jql_query
        @mission.tickets.destroy_all
      end

      @mission.save_jql_query!(jql_query)
      flash[:notice] = "JQL query saved successfully!"
      redirect_to preview_mission_tickets_path(@mission)
    rescue => e
      Rails.logger.error "Failed to save JQL query: #{e.message}"
      flash[:alert] = "Unable to save query. Please try again."
      render :query
    end
  end
end
