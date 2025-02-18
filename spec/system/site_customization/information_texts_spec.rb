require "rails_helper"

describe "Custom information texts", :admin do
  scenario "Show custom texts instead of default ones" do
    debate_key = "debates.index.section_footer.title"
    proposal_key = "proposals.index.section_footer.title"

    visit admin_site_customization_information_texts_path(tab: "debates")
    fill_in "contents[content_#{debate_key}]values[value_en]", with: "Custom help with debates"
    click_button "Save"

    visit admin_site_customization_information_texts_path(tab: "proposals")
    fill_in "contents[content_#{proposal_key}]values[value_en]", with: "Custom help with proposals"
    click_button "Save"

    visit debates_path

    within("#section_help") do
      expect(page).to have_content "Custom help with debates"
      expect(page).not_to have_content "Help with debates"
    end

    visit proposals_path

    within("#section_help") do
      expect(page).to have_content "Custom help with proposals"
      expect(page).not_to have_content "Help with proposals"
    end
  end

  scenario "Show custom text with options" do
    user = create(:user, username: "Rachel")
    create(:budget_investment, author_id: user.id)

    intro_key = "mailers.budget_investment_created.hi"
    create(:i18n_content, key: intro_key, value_en: "Hi %{author}")

    visit admin_site_customization_information_texts_path(tab: "mailers")

    expect(page).to have_content "Hi %{author}"

    fill_in "contents[content_#{intro_key}]values[value_en]", with: "Custom hi to %{author}"
    click_button "Save"

    visit admin_system_email_view_path("budget_investment_created")

    expect(page).to have_content "Custom hi to Rachel"
    expect(page).not_to have_content "%{author}"
  end
end
