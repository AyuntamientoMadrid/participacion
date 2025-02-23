require "rails_helper"

describe "Budgets wizard, headings step", :admin do
  let(:budget) { create(:budget, :drafting) }
  let(:group) { create(:budget_group, budget: budget, name: "Default group") }

  describe "Index" do
    scenario "back to a previous step" do
      visit admin_budgets_wizard_budget_group_headings_path(budget, group)

      within "#side_menu" do
        expect(page).to have_css "[aria-current]", exact_text: "Participatory budgets"
      end

      click_link "Go back to groups"

      expect(page).to have_css "tr", text: "Default group"
      expect(page).to have_css ".creation-timeline"
    end

    scenario "change to another group" do
      economy = create(:budget_group, budget: budget, name: "Economy")
      health = create(:budget_group, budget: budget, name: "Health")
      create(:budget_group, budget: budget, name: "Technology")

      create(:budget_heading, group: economy, name: "Banking")
      create(:budget_heading, group: health, name: "Hospitals")

      visit admin_budgets_wizard_budget_group_headings_path(budget, economy)

      within(".heading") do
        expect(page).to have_content "Banking"
        expect(page).not_to have_content "Hospitals"
      end

      expect(page).not_to have_link "Health"

      click_link "Manage headings from the Health group."

      within(".heading") do
        expect(page).to have_content "Hospitals"
        expect(page).not_to have_content "Banking"
      end
      expect(page).to have_css ".creation-timeline"
    end
  end

  describe "New" do
    scenario "cancel creating a heading" do
      visit admin_budgets_wizard_budget_group_headings_path(budget, group)

      expect(page).not_to have_field "Heading name"
      expect(page).not_to have_button "Cancel"
      expect(page).to have_content "Continue to phases"

      click_button "Add new heading"

      expect(page).to have_field "Heading name"
      expect(page).not_to have_button "Add new heading"
      expect(page).not_to have_content "Continue to phases"

      click_button "Cancel"

      expect(page).to have_button "Add new heading"
      expect(page).not_to have_field "Heading name"
      expect(page).not_to have_button "Cancel"
      expect(page).to have_content "Continue to phases"
    end

    scenario "submit the form with errors" do
      visit admin_budgets_wizard_budget_group_headings_path(budget, group)
      click_button "Add new heading"

      click_button "Create new heading"

      expect(page).not_to have_content "Heading created successfully!"
      expect(page).to have_css(".is-invalid-label", text: "Heading name")
      expect(page).to have_content "can't be blank"
      expect(page).to have_button "Create new heading"
      expect(page).to have_button "Cancel"
      expect(page).not_to have_button "Add new heading"
      expect(page).not_to have_content "Continue to phases"

      within ".budgets-help" do
        expect(page).to have_content "Headings are meant"
        expect(page).not_to have_content "{"
      end
    end
  end

  describe "Edit" do
    scenario "update heading" do
      create(:budget_heading, group: group, name: "Heading wiht a typo")

      visit admin_budgets_wizard_budget_group_headings_path(budget, group)

      expect(page).to have_css ".creation-timeline"

      within("tr", text: "Heading wiht a typo") { click_link "Edit" }
      fill_in "Heading name", with: "Heading without typos"
      click_button "Save heading"

      expect(page).to have_content "Heading updated successfully"
      expect(page).to have_css ".creation-timeline"
      expect(page).to have_css "td", exact_text: "Heading without typos"
    end

    scenario "submit the form with errors and then without errors" do
      heading = create(:budget_heading, group: group, name: "Heading wiht a typo")

      visit edit_admin_budgets_wizard_budget_group_heading_path(budget, group, heading)
      fill_in "Heading name", with: ""
      click_button "Save heading"

      expect(page).to have_css "#error_explanation"
      expect(page).to have_css ".creation-timeline"

      fill_in "Heading name", with: "Heading without typos"
      click_button "Save heading"

      expect(page).to have_content "Heading updated successfully"
      expect(page).to have_css ".creation-timeline"
      expect(page).to have_css "td", exact_text: "Heading without typos"
    end

    scenario "update heading in single heading budget" do
      visit admin_budgets_wizard_budget_group_headings_path(budget, group, mode: "single")
      fill_in "Heading name", with: "Heading wiht typo"
      fill_in "Money amount", with: "300000"
      click_button "Continue to phases"

      expect(page).to have_content "Heading created successfully"

      click_link "Go back to edit heading"

      expect(page).to have_field "Heading name", with: "Heading wiht typo"

      fill_in "Heading name", with: "Heading without typos"
      click_button "Continue to phases"

      expect(page).to have_content "Heading updated successfully"

      visit admin_budget_path(budget)

      within "section", text: "Heading groups" do
        within("tbody tr") { expect(page).to have_content "Heading without typos" }
      end
    end
  end

  describe "Destroy" do
    scenario "delete a heading without investments" do
      create(:budget_heading, group: group, name: "Delete me!")

      visit admin_budgets_wizard_budget_group_headings_path(budget, group)
      within("tr", text: "Delete me!") { accept_confirm { click_button "Delete" } }

      expect(page).to have_content "Heading deleted successfully"
      expect(page).not_to have_content "Delete me!"
      expect(page).to have_css ".creation-timeline"
    end

    scenario "try to delete a heading with investments" do
      heading = create(:budget_heading, group: group, name: "Don't delete me!")
      create(:budget_investment, heading: heading)

      visit admin_budgets_wizard_budget_group_headings_path(budget, group)

      within("tr", text: "Don't delete me!") { accept_confirm { click_button "Delete" } }

      expect(page).to have_content "You cannot delete a Heading that has associated investments"
      expect(page).to have_content "Don't delete me!"
      expect(page).to have_css ".creation-timeline"
    end
  end
end
