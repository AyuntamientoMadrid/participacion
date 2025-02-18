class Admin::ProposalsController < Admin::BaseController
  include HasOrders
  include CommentableActions
  include FeatureFlags
  feature_flag :proposals

  has_orders %w[created_at]

  before_action :load_proposal, except: [:index, :download_csv]

  def show
  end

  def update
    if @proposal.update(proposal_params)
      redirect_to admin_proposal_path(@proposal), notice: t("admin.proposals.update.notice")
    else
      render :show
    end
  end

  def select
    @proposal.update!(selected: true)

    respond_to do |format|
      format.html { redirect_to request.referer, notice: t("flash.actions.update.proposal") }
      format.js { render :toggle_selection }
    end
  end

  def deselect
    @proposal.update!(selected: false)

    respond_to do |format|
      format.html { redirect_to request.referer, notice: t("flash.actions.update.proposal") }
      format.js { render :toggle_selection }
    end
  end

  def download_csv
    @proposals = Proposal.all.order(created_at: :asc)
    respond_to do |format|
      format.csv do
        send_data Proposal::Exporter.new(@proposals).to_csv,
                  filename: "proposals.csv" 
      end
    end
  end

  private

    def resource_model
      Proposal
    end

    def load_proposal
      @proposal = Proposal.find(params[:id])
    end

    def load_proposals
      @proposals = Proposal.all
    end

    def proposal_params
      params.require(:proposal).permit(allowed_params)
    end

    def allowed_params
      [:selected]
    end
end
