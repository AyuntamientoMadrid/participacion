class Admin::Proposals::SuccessfulComponent < ApplicationComponent
  include Header
  attr_reader :proposals

  def initialize(proposals)
    @proposals = proposals
  end

  def title
    t("admin.questions.index.successful_proposals_tab")
  end
end
