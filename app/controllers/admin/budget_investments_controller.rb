class Admin::BudgetInvestmentsController < Admin::BaseController
  include FeatureFlags
  include CommentableActions
  include Translatable

  feature_flag :budgets

  has_orders %w[oldest], only: [:show, :edit]
  has_filters %w[all], only: :index

  before_action :load_budget
  before_action :load_investment, except: [:index]
  before_action :load_ballot, only: [:show, :index]
  before_action :parse_valuation_filters
  before_action :load_investments, only: :index

  def index
    load_tags
    respond_to do |format|
      format.html
      format.csv do
        send_data Budget::Investment::Exporter.new(@investments).to_csv,
                  filename: "budget_investments.csv"
      end
    end
  end

  def show
    load_comments
  end

  def edit
    authorize! :admin_update, @investment
    load_staff
    load_valuator_groups
    load_tags
  end

  def update
    authorize! :admin_update, @investment

    if @investment.update(budget_investment_params)
      redirect_to admin_budget_budget_investment_path(@budget,
                                                      @investment,
                                                      Budget::Investment.filter_params(params).to_h),
                  notice: t("flash.actions.update.budget_investment")
    else
      load_staff
      load_valuator_groups
      load_tags
      render :edit
    end
  end

  def show_to_valuators
    authorize! :admin_update, @investment
    @investment.update!(visible_to_valuators: true)

    respond_to do |format|
      format.html { redirect_to request.referer, notice: t("flash.actions.update.budget_investment") }
      format.js { render :toggle_visible_to_valuators }
    end
  end

  def hide_from_valuators
    authorize! :admin_update, @investment
    @investment.update!(visible_to_valuators: false)

    respond_to do |format|
      format.html { redirect_to request.referer, notice: t("flash.actions.update.budget_investment") }
      format.js { render :toggle_visible_to_valuators }
    end
  end

  def select
    authorize! :select, @investment
    @investment.update!(selected: true)

    respond_to do |format|
      format.html { redirect_to request.referer, notice: t("flash.actions.update.budget_investment") }
      format.js { render :toggle_selection }
    end
  end

  def deselect
    authorize! :deselect, @investment
    @investment.update!(selected: false)

    respond_to do |format|
      format.html { redirect_to request.referer, notice: t("flash.actions.update.budget_investment") }
      format.js { render :toggle_selection }
    end
  end

  def mark_as_winner
    authorize! :mark_as_winner, @investment
    @investment.update!(winner: true)

    respond_to do |format|
      format.html { redirect_to request.referer, notice: t("flash.actions.update.budget_investment") }
      format.js { render :toggle_winner }
    end
  end

  def unmark_as_winner
    authorize! :unmark_as_winner, @investment
    @investment.update!(winner: false)

    respond_to do |format|
      format.html { redirect_to request.referer, notice: t("flash.actions.update.budget_investment") }
      format.js { render :toggle_winner }
    end
  end

  private

    def load_comments
      @commentable = @investment
      @comment_tree = CommentTree.new(@commentable, params[:page], @current_order, valuations: true)
      set_comment_flags(@comment_tree.comments)
    end

    def resource_model
      Budget::Investment
    end

    def resource_name
      resource_model.parameterize(separator: "_")
    end

    def load_investments
      @investments = Budget::Investment.scoped_filter(params, @current_filter).order_filter(params)
      @investments = Kaminari.paginate_array(@investments) if @investments.is_a?(Array)
      @investments = @investments.page(params[:page]) unless request.format.csv?
    end

    def budget_investment_params
      params.require(:budget_investment).permit(allowed_params)
    end

    def allowed_params
      attributes = [:external_url, :heading_id, :administrator_id, :tag_list,
                    :valuation_tag_list, :incompatible, :selected,
                    :milestone_tag_list, valuator_ids: [], valuator_group_ids: []]
      [*attributes, translation_params(Budget::Investment)]
    end

    def load_budget
      @budget = Budget.find_by_slug_or_id! params[:budget_id]
    end

    def load_investment
      @investment = @budget.investments.find(params[:id])
    end

    def load_staff
      @admins = @budget.administrators.includes(:user)
      @valuators = @budget.valuators.includes(:user).order(description: :asc).order("users.email ASC")
    end

    def load_valuator_groups
      @valuator_groups = ValuatorGroup.order(name: :asc)
    end

    def load_tags
      @tags = Budget::Investment.tags_on(:valuation_tags).order(:name).distinct
    end

    def load_ballot
      query = Budget::Ballot.where(user: current_user, budget: @budget)
      @ballot = @budget.balloting? ? query.first_or_create! : query.first_or_initialize
    end

    def parse_valuation_filters
      if params[:valuator_or_group_id]
        model, id = params[:valuator_or_group_id].split("_")

        if model == "group"
          params[:valuator_group_id] = id
        else
          params[:valuator_id] = id
        end
      end
    end
end
