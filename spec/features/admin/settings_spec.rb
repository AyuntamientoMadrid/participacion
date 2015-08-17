require 'rails_helper'

feature 'Admin settings' do

  background do
    @setting1 = create(:setting)
    @setting2 = create(:setting)
    @setting3 = create(:setting)
    login_as(create(:administrator).user)
  end

  scenario 'Index' do
    visit admin_settings_path

    expect(page).to have_content @setting1.key.classify
    expect(page).to have_content @setting2.key.classify
    expect(page).to have_content @setting3.key.classify
  end

  scenario 'Update' do
    visit admin_settings_path

    within("#edit_setting_#{@setting2.id}") do
      fill_in "setting_#{@setting2.id}", with: 'Super Users of level 2'
      click_button 'Update Setting'
    end

    expect(page).to have_content 'Setting updated!'
  end
end