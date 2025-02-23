class Admin::Poll::QuestionsController < Admin::Poll::BaseController
  include CommentableActions
  include Translatable

  load_and_authorize_resource :poll
  load_resource class: "Poll::Question"
  authorize_resource except: :new

  def new
    proposal = Proposal.find(params[:proposal_id]) if params[:proposal_id].present?
    @question.copy_attributes_from_proposal(proposal)
    @question.poll = @poll
    @question.votation_type = VotationType.new

    authorize! :create, @question
  end

  def create
    @question.author = @question.proposal&.author || current_user

    if @question.save
      redirect_to admin_question_path(@question)
    else
      render :new
    end
  end

  def show
  end

  def edit
  end

  def update
    if @question.update(question_params)
      redirect_to admin_question_path(@question), notice: t("flash.actions.save_changes.notice")
    else
      render :edit
    end
  end

  def destroy
    @question.destroy!
    redirect_to admin_poll_path(@question.poll), notice: t("admin.questions.destroy.notice")
  end

  private

    def question_params
      params.require(:poll_question).permit(allowed_params)
    end

    def allowed_params
      attributes = [:poll_id, :question, :proposal_id, votation_type_attributes: [:vote_type, :max_votes]]
      [*attributes, translation_params(Poll::Question)]
    end

    def search_params
      params.permit(:poll_id, :search)
    end
end
