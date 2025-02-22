require "rails_helper"

RSpec.describe "welcome#index" do
  it "displays images on the orbit carrousel when recommendations have an image" do
    proposal = create(:proposal, :with_image)

    render template: "welcome/_recommended_carousel",
           locals: { key: "debates",
                     recommendeds: [proposal],
                     image_field: nil,
                     image_version: nil,
                     carousel_size: "medium-6 large-6 medium-centered large-centered",
                     btn_text_link: t("welcome.recommended.proposals.btn_text_link"),
                     btn_path_link: proposals_path(order: "recommendations") }

    within 'li[data-slide="0"] .card' do
      expect(page).to have_css "img"
    end
  end

  it "does not display images on the orbit carrousel when recommendations don't have an image" do
    proposal = create(:proposal)

    render template: "welcome/_recommended_carousel",
           locals: { key: "debates",
                     recommendeds: [proposal],
                     image_field: nil,
                     image_version: nil,
                     carousel_size: "medium-6 large-6 medium-centered large-centered",
                     btn_text_link: t("welcome.recommended.proposals.btn_text_link"),
                     btn_path_link: proposals_path(order: "recommendations") }

    within 'li[data-slide="0"] .card' do
      expect(page).not_to have_css "img"
    end
  end
end
