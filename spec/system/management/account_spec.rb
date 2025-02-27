require "rails_helper"

describe "Account" do
  scenario "Should not allow unverified users to edit their account" do
    user = create(:user)
    login_managed_user(user)

    login_as_manager
    click_link "Reset password via email"

    expect(page).to have_content "No verified user logged in yet"
  end

  scenario "Send reset password email to currently managed user session" do
    user = create(:user, :level_three)
    login_managed_user(user)

    login_as_manager
    click_link "Reset password via email"

    click_link "Send reset password email"

    expect(page).to have_content "Email correctly sent."

    email = ActionMailer::Base.deliveries.last

    expect(email).to have_text "Change your password"
  end

  scenario "Manager manually writes the new password" do
    user = create(:user, :level_three)
    login_managed_user(user)

    login_as_manager
    click_link "Reset password manually"

    fill_in "Password", with: "new_password"

    click_button "Save password"

    expect(page).to have_content "Password reseted successfully"
    expect(page).to have_link "Print password", href: "javascript:window.print();"
    expect(page).to have_css "div.for-print-only", text: "new_password", visible: :hidden

    logout

    login_through_form_with_email_and_password(user.email, "new_password")

    expect(page).to have_content "You have been signed in successfully."
  end

  scenario "Manager generates random password" do
    user = create(:user, :level_three)
    login_managed_user(user)

    login_as_manager
    click_link "Reset password manually"
    click_link "Generate random password"

    new_password = find_field("user_password").value

    click_button "Save password"

    expect(page).to have_content "Password reseted successfully"

    logout

    login_through_form_with_email_and_password(user.username, new_password)

    expect(page).to have_content "You have been signed in successfully."
  end

  describe "When a user has not been selected" do
    before do
      Setting["feature.user.skip_verification"] = "true"
    end

    scenario "we can't reset password via email" do
      login_as_manager

      click_link "Reset password via email"

      expect(page).to have_content "To perform this action you must select a user"
      expect(page).to have_current_path management_document_verifications_path
    end

    scenario "we can't reset password manually" do
      login_as_manager

      click_link "Reset password manually"

      expect(page).to have_content "To perform this action you must select a user"
      expect(page).to have_current_path management_document_verifications_path
    end
  end
end
