class Admin::Poll::PollsController < Admin::Poll::BaseController
  include Translatable
  include ImageAttributes
  include ReportAttributes
  load_and_authorize_resource

  before_action :load_search, only: [:search_booths, :search_officers]
  before_action :load_geozones, only: [:new, :create, :edit, :update]

  # new
  before_action :load_all, only: [:new]
  before_action :load_components, only: [:edit, :update]
  before_action :actual_users, only: [:show, :edit, :update]
  # --

  def load_all
    @users = User.all
    @polls_users = []
  end

  def load_components
    arr_users = []
    @except_users = actual_users()
    @except_users.each do |item|
      arr_users << item.id
    end
    @users = User.where.not(id: arr_users).order(id: :asc)
  end

  def actual_users
    @polls_users = []
    @users_actuales = PollParticipant.where(poll_id: @poll.id).order(user_id: :asc)
    @users_actuales.each do |item|
      @polls_users += User.where(id: item.user_id)
    end
    @polls_users
  end

  def index
    @polls = Poll.not_budget.created_by_admin.order(starts_at: :desc)
  end

  def show
    @poll = Poll.find(params[:id])
  end

  def new
  end

  def create
    @poll = Poll.new(poll_params.merge(author: current_user))

    if @poll.save
      user_elements = params[:user_ids]
      @poll.save_component(user_elements)

      notice = t("flash.actions.create.poll")
      if @poll.budget.present?
        redirect_to admin_poll_booth_assignments_path(@poll), notice: notice
      else
        redirect_to [:admin, @poll], notice: notice
      end
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @poll.update(poll_params)

      user_elements = params[:user_ids]
      @poll.save_component(user_elements)

      delete_user_elements = params[:delete_user_ids]
      @poll.delete_component(delete_user_elements)

      redirect_to [:admin, @poll], notice: t("flash.actions.update.poll")
    else
      render :edit
    end
  end

  def add_question
    question = ::Poll::Question.find(params[:question_id])

    if question.present?
      @poll.questions << question
      notice = t("admin.polls.flash.question_added")
    else
      notice = t("admin.polls.flash.error_on_question_added")
    end
    redirect_to admin_poll_path(@poll), notice: notice
  end

  def booth_assignments
    @polls = Poll.current.created_by_admin
  end

  def destroy
    if ::Poll::Voter.where(poll: @poll).any?
      redirect_to admin_poll_path(@poll), alert: t("admin.polls.destroy.unable_notice")
    else
      @poll.destroy_component
      @poll.destroy!

      redirect_to admin_polls_path, notice: t("admin.polls.destroy.success_notice")
    end
  end

  private

    def load_geozones
      @geozones = Geozone.all.order(:name)
    end

    def poll_params
      attributes = [:name, :starts_at, :ends_at, :geozone_restricted, :budget_id, :related_sdg_list,
                    geozone_ids: [], image_attributes: image_attributes]

      params.require(:poll).permit(*attributes, *report_attributes, translation_params(Poll), delete_user_ids: [], user_ids: [])
    end

    def search_params
      params.permit(:poll_id, :search)
    end

    def load_search
      @search = search_params[:search]
    end

    def resource
      @poll ||= Poll.find(params[:id])
    end
end
