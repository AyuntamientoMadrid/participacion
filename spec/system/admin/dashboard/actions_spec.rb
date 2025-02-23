require "rails_helper"

describe "Admin dashboard actions", :admin do
  it_behaves_like "nested documentable",
                  "administrator",
                  "dashboard_action",
                  "new_admin_dashboard_action_path",
                  {},
                  "documentable_fill_new_valid_dashboard_action",
                  "Save",
                  "Action created successfully"

  context "when visiting index" do
    context "and no actions defined" do
      before do
        visit admin_dashboard_actions_path
      end

      scenario "shows only default actions" do
        expect(page).to have_content("Polls")
        expect(page).to have_content("Email")
        expect(page).to have_content("Poster")

        expect(page).to have_link "Edit", count: 3
      end
    end

    context "and actions defined" do
      let!(:action) { create(:dashboard_action) }

      before do
        visit admin_dashboard_actions_path
      end

      scenario "shows the action data" do
        expect(page).to have_content(action.title)
      end
    end
  end

  context "when creating an action" do
    let(:action) { build(:dashboard_action) }

    before do
      visit admin_dashboard_actions_path
      click_link "Create resource or action"
    end

    scenario "Creates a new action" do
      fill_in "Title", with: action.title
      fill_in_ckeditor "Description", with: action.description

      click_button "Save"

      expect(page).to have_content(action.title)
    end

    scenario "Renders create form in case data is invalid" do
      click_button "Save"

      expect(page).to have_content("error prevented this Dashboard/Action from being saved.")
    end
  end

  context "when editing an action" do
    let!(:action) { create(:dashboard_action) }

    before do
      visit admin_dashboard_actions_path
      within "#dashboard_action_#{action.id}" do
        click_link "Edit"
      end
    end

    scenario "Updates the action" do
      expect(page).to have_checked_field "Proposed action"
      expect(page).to have_unchecked_field "Resource"
      expect(page).not_to have_field "Short description"
      expect(page).not_to have_field "Include in the resource a button to " \
                                     "request the resource from administrators"

      choose "Resource"
      check "Include in the resource a button to request the resource from administrators"

      fill_in "Title", with: "Great action!"
      fill_in "Short description", with: "And awesome too!"
      click_button "Save"

      expect(page).to have_content "Great action!"
    end

    scenario "Renders edit form in case data is invalid" do
      fill_in "Title", with: "x"
      click_button "Save"
      expect(page).to have_content("error prevented this Dashboard/Action from being saved.")
    end
  end

  context "when destroying an action" do
    let!(:action) { create(:dashboard_action) }

    scenario "deletes the action" do
      visit admin_dashboard_actions_path

      accept_confirm("Are you sure? This action will delete \"#{action.title}\" and can't be undone.") do
        click_button "Delete"
      end

      expect(page).not_to have_content(action.title)
    end

    scenario "cannot delete actions that have been executed" do
      create(:dashboard_executed_action, action: action)

      visit admin_dashboard_actions_path

      accept_confirm("Are you sure? This action will delete \"#{action.title}\" and can't be undone.") do
        click_button "Delete"
      end

      expect(page).to have_content("Cannot delete record because dependent executed actions exist")
    end
  end
end
