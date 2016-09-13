require 'rails_helper'

feature 'Budget Investments' do

  background do
    login_as_manager
    @budget = create(:budget)
  end

  context "Select a budget" do
    budget2 = create(:budget)
    budget3 = create(:budget)

    click_link "Create budget investment"

  end

  context "Create" do

    scenario 'Creating budget investments on behalf of someone' do
      user = create(:user, :level_two)
      login_managed_user(user)

      click_link "Create budget investment"

      within(".account-info") do
        expect(page).to have_content "Identified as"
        expect(page).to have_content "#{user.username}"
        expect(page).to have_content "#{user.email}"
        expect(page).to have_content "#{user.document_number}"
      end

      fill_in 'budget_investment_title', with: 'Build a park in my neighborhood'
      fill_in 'budget_investment_description', with: 'There is no parks here...'
      fill_in 'budget_investment_external_url', with: 'http://moarparks.com'
      check 'budget_investment_terms_of_service'

      click_button 'Create'

      expect(page).to have_content 'budget investment created successfully.'

      expect(page).to have_content 'Build a park in my neighborhood'
      expect(page).to have_content 'There is no parks here...'
      expect(page).to have_content 'All city'
      expect(page).to have_content 'http://moarparks.com'
      expect(page).to have_content user.name
      expect(page).to have_content I18n.l(Budget::Investment.last.created_at.to_date)

      expect(current_path).to eq(management_budget_investment_path(Budget::Investment.last))
    end

    scenario "Should not allow unverified users to create budget investments" do
      user = create(:user)
      login_managed_user(user)

      click_link "Create budget investment"

      expect(page).to have_content "User is not verified"
    end
  end

  context "Searching" do
    scenario "by title" do
      budget_investment1 = create(:budget_investment, title: "Show me what you got")
      budget_investment2 = create(:budget_investment, title: "Get Schwifty")

      user = create(:user, :level_two)
      login_managed_user(user)

      click_link "Support budget investments"

      fill_in "search", with: "what you got"
      click_button "Search"

      expect(current_path).to eq(management_budget_investments_path)

      within("#investment-projects") do
        expect(page).to have_css('.investment-project', count: 1)
        expect(page).to have_content(budget_investment1.title)
        expect(page).to_not have_content(budget_investment2.title)
        expect(page).to have_css("a[href='#{management_budget_investment_path(budget_investment1)}']", text: budget_investment1.title)
        expect(page).to have_css("a[href='#{management_budget_investment_path(budget_investment1)}']", text: budget_investment1.description)
      end
    end

    scenario "by district" do
      budget_investment1 = create(:budget_investment, title: "Hey ho", geozone_id: create(:geozone, name: "District 9").id)
      budget_investment2 = create(:budget_investment, title: "Let's go", geozone_id: create(:geozone, name: "Area 52").id)

      user = create(:user, :level_two)
      login_managed_user(user)

      click_link "Support budget investments"

      fill_in "search", with: "Area 52"
      click_button "Search"

      expect(current_path).to eq(management_budget_investments_path)

      within("#investment-projects") do
        expect(page).to have_css('.investment-project', count: 1)
        expect(page).to_not have_content(budget_investment1.title)
        expect(page).to have_content(budget_investment2.title)
        expect(page).to have_css("a[href='#{management_budget_investment_path(budget_investment2)}']", text: budget_investment2.title)
        expect(page).to have_css("a[href='#{management_budget_investment_path(budget_investment2)}']", text: budget_investment2.description)
      end
    end
  end

  scenario "Listing" do
    budget_investment1 = create(:budget_investment, title: "Show me what you got")
    budget_investment2 = create(:budget_investment, title: "Get Schwifty")

    user = create(:user, :level_two)
    login_managed_user(user)

    click_link "Support budget investments"

    expect(current_path).to eq(management_budget_investments_path)

    within(".account-info") do
      expect(page).to have_content "Identified as"
      expect(page).to have_content "#{user.username}"
      expect(page).to have_content "#{user.email}"
      expect(page).to have_content "#{user.document_number}"
    end

    within("#investment-projects") do
      expect(page).to have_css('.investment-project', count: 2)
      expect(page).to have_css("a[href='#{management_budget_investment_path(budget_investment1)}']", text: budget_investment1.title)
      expect(page).to have_css("a[href='#{management_budget_investment_path(budget_investment1)}']", text: budget_investment1.description)
      expect(page).to have_css("a[href='#{management_budget_investment_path(budget_investment2)}']", text: budget_investment2.title)
      expect(page).to have_css("a[href='#{management_budget_investment_path(budget_investment2)}']", text: budget_investment2.description)
    end
  end

  context "Voting" do

    scenario 'Voting budget investments on behalf of someone in index view', :js do
      budget_investment = create(:budget_investment)

      user = create(:user, :level_two)
      login_managed_user(user)

      click_link "Support budget investments"

      within("#investment-projects") do
        find('.in-favor a').click

        expect(page).to have_content "1 support"
        expect(page).to have_content "You have already supported this. Share it!"
      end
      expect(current_path).to eq(management_budget_investments_path)
    end

    scenario 'Voting budget investments on behalf of someone in show view', :js do
      budget_investment = create(:budget_investment)

      user = create(:user, :level_two)
      login_managed_user(user)

      click_link "Support budget investments"

      within("#investment-projects") do
        click_link budget_investment.title
      end

      find('.in-favor a').click
      expect(page).to have_content "1 support"
      expect(page).to have_content "You have already supported this. Share it!"
      expect(current_path).to eq(management_budget_investment_path(budget_investment))
    end

    scenario "Should not allow unverified users to vote proposals" do
      budget_investment = create(:budget_investment)

      user = create(:user)
      login_managed_user(user)

      click_link "Support budget investments"

      expect(page).to have_content "User is not verified"
    end
  end

  context "Printing" do

    scenario 'Printing budget investments' do
      16.times { create(:budget_investment, geozone_id: nil) }

      click_link "Print budget investments"

      expect(page).to have_css('.investment-project', count: 15)
      expect(page).to have_css("a[href='javascript:window.print();']", text: 'Print')
    end

    scenario "Filtering budget investments by geozone to be printed", :js do
      district_9 = create(:geozone, name: "District Nine")
      create(:budget_investment, title: 'Change district 9', geozone: district_9, cached_votes_up: 10)
      create(:budget_investment, title: 'Destroy district 9', geozone: district_9, cached_votes_up: 100)
      create(:budget_investment, title: 'Nuke district 9', geozone: district_9, cached_votes_up: 1)
      create(:budget_investment, title: 'Add new districts to the city', geozone_id: nil)

      user = create(:user, :level_two)
      login_managed_user(user)

      click_link "Print budget investments"

      expect(page).to have_content "Budget investments with scope: All city"

      within '#investment-projects' do
        expect(page).to have_content('Add new districts to the city')
        expect(page).to_not have_content('Change district 9')
        expect(page).to_not have_content('Destroy district 9')
        expect(page).to_not have_content('Nuke district 9')
      end

      select 'District Nine', from: 'geozone'

      expect(page).to have_content "Investment projects with scope: District Nine"
      expect(current_url).to include("geozone=#{district_9.id}")

      within '#investment-projects' do
        expect(page).to_not have_content('Add new districts to the city')
        expect('Destroy district 9').to appear_before('Change district 9')
        expect('Change district 9').to appear_before('Nuke district 9')
      end
    end

  end

end
