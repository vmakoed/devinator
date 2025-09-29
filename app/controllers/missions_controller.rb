class MissionsController < ApplicationController
  before_action :set_mission, only: [:show, :query]

  def index
    @missions = Mission.order(created_at: :desc)
  end

  def show
    # Mission details page
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

  private

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
      @mission.save_jql_query!(jql_query)
      flash[:notice] = "JQL query saved successfully!"
      # TODO: Redirect to UC003 (Preview Tickets) when implemented
      redirect_to mission_path(@mission)
    rescue => e
      Rails.logger.error "Failed to save JQL query: #{e.message}"
      flash[:alert] = "Unable to save query. Please try again."
      render :query
    end
  end
end
