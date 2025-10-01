class MissionsController < ApplicationController
  before_action :set_mission, only: [ :show, :query, :analyze, :save_selection, :assign ]

  def index
    @missions = Mission.order(created_at: :desc)
  end

  def show
    # Redirect to appropriate view based on mission state
    if @mission.status == "assigned" && @mission.tickets.selected_for_assignment.any?
      redirect_to assign_mission_path(@mission)
    elsif @mission.tickets.any?
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
      calculate_selection_stats
      @apply_preselection = should_apply_preselection?
    else
      # Perform analysis
      @tickets.each do |ticket|
        TicketComplexityAnalyzer.new(ticket).analyze!
      end
      @mission.update!(status: "analyzed")
      calculate_summary_stats
      calculate_selection_stats
      @apply_preselection = should_apply_preselection?
      flash[:notice] = "#{@tickets.count} tickets analyzed successfully!"
    end
  end

  def save_selection
    selected_ticket_ids = params[:selected_tickets] || []

    if selected_ticket_ids.empty?
      respond_to do |format|
        format.html do
          flash[:alert] = "Please select at least one ticket to assign"
          redirect_to analyze_mission_path(@mission)
        end
        format.json { render json: { error: "Please select at least one ticket to assign" }, status: :unprocessable_entity }
      end
      return
    end

    if selected_ticket_ids.length > 100
      respond_to do |format|
        format.html do
          flash[:alert] = "Cannot select more than 100 tickets at once"
          redirect_to analyze_mission_path(@mission)
        end
        format.json { render json: { error: "Cannot select more than 100 tickets at once" }, status: :unprocessable_entity }
      end
      return
    end

    # Update all tickets in a transaction
    ActiveRecord::Base.transaction do
      @mission.tickets.update_all(selected_for_assignment: false, selected_at: nil)
      @mission.tickets.where(id: selected_ticket_ids).update_all(
        selected_for_assignment: true,
        selected_at: Time.current
      )
    end

    respond_to do |format|
      format.html do
        flash[:notice] = "#{selected_ticket_ids.length} ticket(s) selected for assignment"
        redirect_to assign_mission_path(@mission)
      end
      format.json { render json: { success: true, count: selected_ticket_ids.length } }
    end
  end

  def assign
    @selected_tickets = @mission.tickets.selected_for_assignment.includes(:mission)

    if @selected_tickets.empty?
      flash[:alert] = "No tickets selected for assignment. Please select tickets first."
      redirect_to analyze_mission_path(@mission) and return
    end

    # Check if tickets are already assigned
    if @mission.status == "assigned" && @selected_tickets.all?(&:assigned_to_devin?)
      # Show results of existing assignments
      @assignment_results = {
        success: @selected_tickets.select(&:assigned_to_devin?),
        failed: @mission.tickets.assignment_failed.map { |t| { ticket: t, error: t.assignment_error } },
        timeout: @mission.tickets.assignment_timeout.map { |t| { ticket: t, error: "Request timed out" } }
      }
      render :assign_results and return
    end

    if request.post?
      handle_assignment
    end
  end

  private

  def handle_assignment
    results = {
      success: [],
      failed: [],
      timeout: []
    }

    @selected_tickets.each do |ticket|
      begin
        result = DevinApiService.new.create_session(ticket)

        if result[:success]
          ticket.assign_to_devin!(
            session_id: result[:session_id],
            session_url: result[:session_url]
          )
          results[:success] << ticket
        else
          ticket.mark_assignment_failed!(result[:error])
          results[:failed] << { ticket: ticket, error: result[:error] }
        end
      rescue DevinApiService::TimeoutError => e
        ticket.mark_assignment_timeout!
        results[:timeout] << { ticket: ticket, error: e.message }
      rescue => e
        Rails.logger.error "Assignment failed for ticket #{ticket.jira_key}: #{e.message}"
        ticket.mark_assignment_failed!(e.message)
        results[:failed] << { ticket: ticket, error: e.message }
      end
    end

    # Update mission stats
    @mission.update_assignment_stats!(
      total_assigned: results[:success].count,
      failed_count: results[:failed].count + results[:timeout].count
    )

    # Change mission status to assigned if at least one ticket was successfully assigned
    if results[:success].any?
      @mission.update!(status: "assigned", assigned_at: Time.current)
    end

    @assignment_results = results
    render :assign_results
  end

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

  def calculate_selection_stats
    @selected_count = @tickets.selected_for_assignment.count
    @selected_low_count = @tickets.selected_for_assignment.low_complexity.count
    @selected_medium_count = @tickets.selected_for_assignment.medium_complexity.count
    @selected_high_count = @tickets.selected_for_assignment.high_complexity.count
  end

  def should_apply_preselection?
    # Only apply automatic preselection if no tickets have been selected yet
    @mission.tickets.selected_for_assignment.none?
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
