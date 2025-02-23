require "rails_helper"

describe Admin::Proposals::IndexComponent, controller: Admin::ProposalsController do
  around do |example|
    with_request_url(Rails.application.routes.url_helpers.admin_proposals_path) { example.run }
  end

  describe "#successful_proposals_link" do
    it "is shown when there are successful proposals" do
      create(:proposal, :successful)

      render_inline Admin::Proposals::IndexComponent.new(Proposal.page(1))

      expect(page).to have_link "Successful proposals"
    end

    it "is not shown when there aren't any successful proposals" do
      create(:proposal)

      render_inline Admin::Proposals::IndexComponent.new(Proposal.page(1))

      expect(page).not_to have_link "Successful proposals"
    end

    it "is shown when there are successful proposals on a previous page" do
      allow(Proposal).to receive(:default_per_page).and_return(1)
      create(:proposal, :successful)
      create(:proposal)

      render_inline Admin::Proposals::IndexComponent.new(Proposal.order(:id).page(2))

      expect(page).to have_link "Successful proposals"
    end
  end
end
