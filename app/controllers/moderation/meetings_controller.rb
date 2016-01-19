class Moderation::MeetingsController < Moderation::BaseController
  include ModerateActions

  before_action :load_resources, only: [:index]

  load_and_authorize_resource

  def index
    @resources = @resources.page(params[:page]).per(50)
    set_resources_instance
  end


  def new
    @resource = resource_model.new
    set_resource_instance
  end

  def create
    @resource = resource_model.new(strong_params)
    @resource.author = current_user

    if @resource.save
      redirect_to moderation_meetings_url, notice: t('flash.actions.create.notice', resource_name: "#{resource_name.capitalize}")
    else
      set_resource_instance
      render :new
    end
  end

  def edit
  end

  def update
    resource.assign_attributes(strong_params)
    if resource.save
      redirect_to moderation_meetings_url, notice: t('flash.actions.update.notice', resource_name: "#{resource_name.capitalize}")
    else
      set_resource_instance
      render :edit
    end
  end

  private

  def meeting_params
    params.require(:meeting).permit(:title, :description, :address, :address_longitude, :address_latitude, :address_details, :held_at, :start_at, :end_at)
  end

  def resource_model
    Meeting
  end

  def load_resources
    @resources = resource_model.accessible_by(current_ability, :read)
  end
end
