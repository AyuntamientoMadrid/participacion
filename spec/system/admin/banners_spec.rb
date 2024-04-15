require "rails_helper"

describe "Admin banners magement", :admin do
  context "Index" do
    before do
      create(:banner, title: "Banner number one",
                      description: "This is the text of banner number one and is not active yet",
                      target_url: "http://www.url.com",
                      post_started_at: (Date.current + 4.days),
                      post_ended_at: (Date.current + 10.days),
                      background_color: "#FF0000",
                      font_color: "#FFFFFF")

      create(:banner, title: "Banner number two",
                      description: "This is the text of banner number two and is not longer active",
                      target_url: "http://www.url.com",
                      post_started_at: (Date.current - 10.days),
                      post_ended_at: (Date.current - 3.days),
                      background_color: "#00FF00",
                      font_color: "#FFFFFF")

      create(:banner, title: "Banner number three",
                      description: "This is the text of banner number three",
                      target_url: "http://www.url.com",
                      post_started_at: (Date.current - 1.day),
                      post_ended_at: (Date.current + 10.days),
                      background_color: "#0000FF",
                      font_color: "#FFFFFF")

      create(:banner, title: "Banner number four",
                      description: "This is the text of banner number four",
                      target_url: "http://www.url.com",
                      post_started_at: (Date.current - 10.days),
                      post_ended_at: (Date.current + 10.days),
                      background_color: "#FFF000",
                      font_color: "#FFFFFF")

      create(:banner, title: "Banner number five",
                      description: "This is the text of banner number five",
                      target_url: "http://www.url.com",
                      post_started_at: (Date.current - 10.days),
                      post_ended_at: (Date.current + 10.days),
                      background_color: "#FFFF00",
                      font_color: "#FFFFFF")
    end

    scenario "Index show active banners" do
      visit admin_banners_path(filter: "with_active")
      expect(page).to have_content("There are 3 banners")
    end

    scenario "Index show inactive banners" do
      visit admin_banners_path(filter: "with_inactive")
      expect(page).to have_content("There are 2 banners")
    end

    scenario "Index show all banners" do
      visit admin_banners_path
      expect(page).to have_content("There are 5 banners")
    end
  end

  scenario "Publish a banner" do
    visit admin_root_path

    within("#side_menu") do
      click_button "Site content"
      click_link "Banners"
    end

    click_link "Create banner"

    fill_in "Title", with: "Such banner"
    fill_in "Description", with: "many text wow link"
    fill_in "Link", with: "https://www.url.com"
    fill_in "Post started at", with: Date.current - 7.days
    fill_in "Post ended at", with: Date.current + 7.days
    fill_in "Background color", with: "#850000"
    fill_in "Font color", with: "#ffb2b2"
    within_fieldset("Sections where it will appear") { check "Proposals" }

    click_button "Save changes"

    expect(page).to have_content "Banner created successfully"

    visit proposals_path

    expect(page).to have_content "Such banner"
    expect(page).to have_link "Such banner", href: "https://www.url.com"
  end

  scenario "Publish a banner with a translation different than the current locale" do
    visit new_admin_banner_path

    expect_to_have_language_selected "English"

    click_link "Remove language"
    select "Français", from: "Add language"

    fill_in "Title", with: "En Français"
    fill_in "Description", with: "Link en Français"
    fill_in "Link", with: "https://www.url.com"
    fill_in "Post started at", with: Date.current - 1.week
    fill_in "Post ended at", with: Date.current + 1.week

    click_button "Save changes"
    click_link "Edit"

    expect_to_have_language_selected "Français"
    expect(page).to have_field "Title", with: "En Français"
  end

  scenario "Update banner color when changing from color picker or text_field" do
    visit new_admin_banner_path

    fill_in "background_color_input", with: "#850000"
    fill_in "font_color_input", with: "#ffb2b2"
    fill_in "Title", with: "Fun with flags"

    expect(find("#background_color_input").value).to eq("#850000")
    expect(find("#font_color_input").value).to eq("#ffb2b2")
  end

  scenario "Edit banner with live refresh" do
    create(:banner, title: "Hello",
                    description: "Wrong text",
                    target_url: "http://www.url.com",
                    post_started_at: (Date.current + 4.days),
                    post_ended_at: (Date.current + 10.days),
                    background_color: "#FF0000",
                    font_color: "#FFFFFF")

    visit admin_root_path

    within("#side_menu") do
      click_button "Site content"
      click_link "Banners"
    end

    click_link "Edit"

    fill_in "Title", with: "Modified title"
    fill_in "Description", with: "Edited text"

    page.find("body").click

    within(".banner") do
      expect(page).to have_css "h2", text: "Modified title"
      expect(page).to have_css "h3", text: "Edited text"
    end

    click_button "Save changes"

    expect(page).to have_content "Banner updated successfully"

    expect(page).to have_content "Modified title"
    expect(page).to have_content "Edited text"

    expect(page).not_to have_content "Hello"
    expect(page).not_to have_content "Wrong text"
  end

  scenario "Delete a banner" do
    create(:banner, title: "Ugly banner",
                    description: "Bad text",
                    target_url: "http://www.url.com",
                    post_started_at: (Date.current + 4.days),
                    post_ended_at: (Date.current + 10.days),
                    background_color: "#FF0000",
                    font_color: "#FFFFFF")

    visit admin_banners_path

    expect(page).to have_content "Ugly banner"

    accept_confirm("Are you sure? This action will delete \"Ugly banner\" and can't be undone.") do
      click_button "Delete"
    end

    expect(page).to have_content "Banner deleted successfully"

    visit admin_root_path
    expect(page).not_to have_content "Ugly banner"
  end
end
