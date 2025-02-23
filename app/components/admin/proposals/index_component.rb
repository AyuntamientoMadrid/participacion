class Admin::Proposals::IndexComponent < ApplicationComponent
  include Header
  attr_reader :proposals

  def initialize(proposals)
    @proposals = proposals
  end

  def title
    t("admin.proposals.index.title")
  end
end
