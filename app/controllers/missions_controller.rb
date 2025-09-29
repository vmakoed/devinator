class MissionsController < ApplicationController
  def index
    @missions = Mission.order(created_at: :desc)
  end

  def create
    begin
      mission = Mission.create!(
        name: Mission.generate_name,
        status: "draft"
      )

      flash[:notice] = "Mission '#{mission.name}' created successfully!"
      # TODO: Redirect to UC002 (JQL Query input) when implemented
      redirect_to root_path
    rescue => e
      Rails.logger.error "Mission creation failed: #{e.message}"
      flash[:alert] = "Unable to create mission. Please try again."
      redirect_to root_path
    end
  end
end
