class Admin::Proposals::IndexComponent < ApplicationComponent
  include Header
  attr_reader :proposals

  def initialize(proposals)
    @proposals = proposals
  end

  def title
    t("admin.proposals.index.title")
  end

  private

    def successful_proposals_link
      if proposals.unscope(:offset).successful.any?
        link_to t("admin.questions.index.successful_proposals_tab"), successful_admin_proposals_path
      end
    end
end
