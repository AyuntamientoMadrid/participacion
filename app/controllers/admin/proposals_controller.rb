class Admin::ProposalsController < Admin::BaseController
  include HasOrders
  include CommentableActions
  include FeatureFlags
  feature_flag :proposals
  include DownloadSettingsHelper

  has_orders %w[created_at]

  before_action :load_proposal, except: :index

  def index
    super

    respond_to do |format|
      format.html
      format.csv do
        send_data to_csv(@resources, resource_model),
                  type: "text/csv",
                  disposition: "attachment",
                  filename: "proposals.csv"
      end
    end
  end

  def show
  end

  def update
    if @proposal.update(proposal_params)
      redirect_to admin_proposal_path(@proposal), notice: t("admin.proposals.update.notice")
    else
      render :show
    end
  end

  def toggle_selection
    @proposal.toggle :selected
    @proposal.save!
  end

  private

    def resource_model
      Proposal
    end

    def load_proposal
      @proposal = Proposal.find(params[:id])
    end

    def proposal_params
      params.require(:proposal).permit(:selected)
    end
end
