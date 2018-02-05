require 'rails_helper'

describe 'Admin settings' do

  before do
    @setting1 = create(:setting)
    @setting2 = create(:setting)
    @setting3 = create(:setting)
    login_as(create(:administrator).user)
  end

  it 'Index' do
    visit admin_settings_path

    expect(page).to have_content @setting1.key
    expect(page).to have_content @setting2.key
    expect(page).to have_content @setting3.key
  end

  it 'Update' do
    visit admin_settings_path

    within("#edit_setting_#{@setting2.id}") do
      fill_in "setting_#{@setting2.id}", with: 'Super Users of level 2'
      click_button 'Update'
    end

    expect(page).to have_content 'Value updated'
  end

  describe "Update map" do

    it "is not able when map feature deactivated" do
      Setting['feature.map'] = false
      admin = create(:administrator).user
      login_as(admin)
      visit admin_settings_path

      expect(page).not_to have_content "Map configuration"
    end

    it "is able when map feature activated" do
      Setting['feature.map'] = true
      admin = create(:administrator).user
      login_as(admin)
      visit admin_settings_path

      expect(page).to have_content "Map configuration"
    end

    it "shows successful notice" do
      Setting['feature.map'] = true
      admin = create(:administrator).user
      login_as(admin)
      visit admin_settings_path

      within "#map-form" do
        click_on "Update"
      end

      expect(page).to have_content "Map configuration updated succesfully"
    end

    it "displays marker by default", :js do
      Setting['feature.map'] = true
      admin = create(:administrator).user
      login_as(admin)

      visit admin_settings_path

      expect(find("#latitude", visible: false).value).to eq "51.48"
      expect(find("#longitude", visible: false).value).to eq "0.0"
    end

    it "updates marker", :js do
      Setting['feature.map'] = true
      admin = create(:administrator).user
      login_as(admin)

      visit admin_settings_path
      find("#admin-map").click
      within "#map-form" do
        click_on "Update"
      end

      expect(find("#latitude", visible: false).value).not_to eq "51.48"
      expect(page).to have_content "Map configuration updated succesfully"
    end

  end

end
