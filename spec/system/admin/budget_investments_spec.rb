require "rails_helper"

describe "Admin budget investments", :admin do
  let(:budget) { create(:budget) }
  let(:administrator) do
    create(:administrator, user: create(:user, username: "Ana", email: "ana@admins.org"))
  end

  it_behaves_like "admin_milestoneable", :budget_investment, "admin_polymorphic_path"

  context "Load" do
    let!(:investment) { create(:budget_investment, budget: budget) }

    before { budget.update(slug: "budget_slug") }

    scenario "finds investments using budget slug" do
      visit admin_budget_budget_investments_path("budget_slug")

      expect(page).to have_link investment.title
    end
  end

  context "Index" do
    scenario "Displaying investments" do
      budget.update!(phase: "selecting")
      budget_investment = create(:budget_investment, budget: budget, cached_votes_up: 77)
      visit admin_budget_budget_investments_path(budget_id: budget.id)
      expect(page).to have_content(budget_investment.title)
      expect(page).to have_content(budget_investment.heading.name)
      expect(page).to have_content(budget_investment.id)
      expect(page).to have_content(budget_investment.total_votes)
    end

    scenario "Do not show price column on budgets with hide money" do
      budget_hide_money = create(:budget, :hide_money)
      budget_investment = create(:budget_investment, budget: budget_hide_money)

      visit admin_budget_budget_investments_path(budget_hide_money)

      expect(page).to have_content(budget_investment.title)
      expect(page).to have_content(budget_investment.heading.name)
      expect(page).to have_content(budget_investment.id)
      expect(page).not_to have_content("Price")
      expect(page).not_to have_content("€")
    end

    scenario "Display admin and valuator assignments" do
      budget.update!(phase: "valuating")
      olga = create(:user, username: "Olga")
      miriam = create(:user, username: "Miriam")
      valuator1 = create(:valuator, user: olga, description: "Valuator Olga")
      valuator2 = create(:valuator, user: miriam, description: "Valuator Miriam")
      valuator_group = create(:valuator_group, name: "Health")
      admin = create(:administrator, user: create(:user, username: "Gema"))

      budget_investment1 = create(:budget_investment, budget: budget, valuators: [valuator1])
      budget_investment2 = create(:budget_investment, budget: budget,
                                                      valuators: [valuator1, valuator2],
                                                      valuator_groups: [valuator_group])
      budget_investment3 = create(:budget_investment, budget: budget)

      visit admin_budget_budget_investments_path(budget_id: budget.id)

      within("#budget_investment_#{budget_investment1.id}") do
        expect(page).to have_content("No admin assigned")
        expect(page).to have_content("Valuator Olga")
      end

      within("#budget_investment_#{budget_investment2.id}") do
        expect(page).to have_content("No admin assigned")
        expect(page).to have_content("Valuator Olga")
        expect(page).to have_content("Valuator Miriam")
        expect(page).to have_content("Health")
      end

      budget_investment3.update!(administrator_id: admin.id)
      visit admin_budget_budget_investments_path(budget_id: budget.id)

      within("#budget_investment_#{budget_investment3.id}") do
        expect(page).to have_content("Gema")
        expect(page).to have_content("No valuators assigned")
      end
    end

    scenario "Filtering by budget heading" do
      group1 = create(:budget_group, name: "Streets", budget: budget)
      group2 = create(:budget_group, name: "Parks", budget: budget)

      group1_heading1 = create(:budget_heading, group: group1, name: "Main Avenue")
      group1_heading2 = create(:budget_heading, group: group1, name: "Mercy Street")
      group2_heading1 = create(:budget_heading, group: group2, name: "Central Park")

      create(:budget_investment, title: "Realocate visitors", heading: group1_heading1)
      create(:budget_investment, title: "Change name", heading: group1_heading2)
      create(:budget_investment, title: "Plant trees", heading: group2_heading1)

      visit admin_budget_budget_investments_path(budget_id: budget.id)

      expect(page).to have_link("Realocate visitors")
      expect(page).to have_link("Change name")
      expect(page).to have_link("Plant trees")

      select "Parks: Central Park", from: "Heading"
      click_button "Filter"

      expect(page).not_to have_link("Realocate visitors")
      expect(page).not_to have_link("Change name")
      expect(page).to have_link("Plant trees")

      select "All headings", from: "Heading"
      click_button "Filter"

      expect(page).to have_link("Realocate visitors")
      expect(page).to have_link("Change name")
      expect(page).to have_link("Plant trees")

      select "Streets: Main Avenue", from: "Heading"
      click_button "Filter"

      expect(page).to have_link("Realocate visitors")
      expect(page).not_to have_link("Change name")
      expect(page).not_to have_link("Plant trees")

      select "Streets: Mercy Street", from: "Heading"
      click_button "Filter"

      expect(page).not_to have_link("Realocate visitors")
      expect(page).to have_link("Change name")
      expect(page).not_to have_link("Plant trees")
    end

    scenario "Filtering by admin" do
      user = create(:user, username: "Admin 1")
      user2 = create(:user, username: "Admin 2")
      administrator = create(:administrator, user: user)
      administrator2 = create(:administrator, user: user2, description: "Alias")
      budget.administrators = [administrator, administrator2]
      create(:budget_investment, title: "Realocate visitors",
                                 budget: budget,
                                 administrator: administrator)
      create(:budget_investment, title: "Destroy the city", budget: budget)

      visit admin_budget_budget_investments_path(budget_id: budget.id)
      expect(page).to have_link("Realocate visitors")
      expect(page).to have_link("Destroy the city")

      select "Admin 1", from: "Administrator"
      click_button "Filter"

      expect(page).to have_content("There is 1 investment")
      expect(page).not_to have_link("Destroy the city")
      expect(page).to have_link("Realocate visitors")

      select "Alias", from: "Administrator"
      click_button "Filter"

      expect(page).to have_content("There are no investment projects")
      expect(page).not_to have_link("Destroy the city")
      expect(page).not_to have_link("Realocate visitors")

      select "All administrators", from: "Administrator"
      click_button "Filter"

      expect(page).to have_content("There are 2 investments")
      expect(page).to have_link("Destroy the city")
      expect(page).to have_link("Realocate visitors")

      select "Admin 1", from: "Administrator"
      click_button "Filter"

      expect(page).to have_content("There is 1 investment")
      expect(page).not_to have_link("Destroy the city")
      expect(page).to have_link("Realocate visitors")
    end

    scenario "Filtering by valuator" do
      user = create(:user)
      valuator = create(:valuator, user: user, description: "Valuator 1")
      budget.valuators = [valuator]

      create(:budget_investment, title: "Realocate visitors", budget: budget, valuators: [valuator])
      create(:budget_investment, title: "Destroy the city", budget: budget)

      visit admin_budget_budget_investments_path(budget_id: budget.id)
      expect(page).to have_link("Realocate visitors")
      expect(page).to have_link("Destroy the city")

      select "Valuator 1", from: "Valuator or group"
      click_button "Filter"

      expect(page).to have_content("There is 1 investment")
      expect(page).not_to have_link("Destroy the city")
      expect(page).to have_link("Realocate visitors")

      select "All valuators", from: "Valuator or group"
      click_button "Filter"

      expect(page).to have_content("There are 2 investments")
      expect(page).to have_link("Destroy the city")
      expect(page).to have_link("Realocate visitors")

      select "Valuator 1", from: "Valuator or group"
      click_button "Filter"
      expect(page).to have_content("There is 1 investment")
      expect(page).not_to have_link("Destroy the city")
      expect(page).to have_link("Realocate visitors")
    end

    scenario "Filtering by valuator group" do
      health_group = create(:valuator_group, name: "Health")
      culture_group = create(:valuator_group, name: "Culture")

      create(:budget_investment, title: "Build a hospital", budget: budget, valuator_groups: [health_group])
      create(:budget_investment, title: "Build a theatre", budget: budget, valuator_groups: [culture_group])

      visit admin_budget_budget_investments_path(budget_id: budget)
      expect(page).to have_link("Build a hospital")
      expect(page).to have_link("Build a theatre")

      select "Health", from: "Valuator or group"
      click_button "Filter"

      expect(page).to have_content("There is 1 investment")
      expect(page).to have_link("Build a hospital")
      expect(page).not_to have_link("Build a theatre")

      select "All valuators", from: "Valuator or group"
      click_button "Filter"

      expect(page).to have_content("There are 2 investments")
      expect(page).to have_link("Build a hospital")
      expect(page).to have_link("Build a theatre")

      select "Culture", from: "Valuator or group"
      click_button "Filter"

      expect(page).to have_content("There is 1 investment")
      expect(page).to have_link("Build a theatre")
      expect(page).not_to have_link("Build a hospital")
    end

    scenario "Filtering by without assigned admin" do
      create(:budget_investment, title: "Investment without admin", budget: budget)
      create(:budget_investment, :with_administrator, title: "Investment with admin", budget: budget)

      visit admin_budget_budget_investments_path(budget_id: budget)
      expect(page).to have_link("Investment without admin")
      expect(page).to have_link("Investment with admin")

      click_button "Advanced filters"
      check("Without assigned admin")
      click_button "Filter"

      expect(page).to have_content("There is 1 investment")
      expect(page).to have_link("Investment without admin")
      expect(page).not_to have_link("Investment with admin")

      uncheck("Without assigned admin")
      click_button "Filter"

      expect(page).to have_content("There are 2 investments")
      expect(page).to have_link("Investment without admin")
      expect(page).to have_link("Investment with admin")
    end

    scenario "Filtering by without assigned valuator" do
      create(:budget_investment, title: "Investment without valuator", budget: budget)
      create(:budget_investment, :with_valuator, title: "Investment with valuator", budget: budget)

      visit admin_budget_budget_investments_path(budget_id: budget)
      expect(page).to have_link("Investment without valuator")
      expect(page).to have_link("Investment with valuator")

      click_button "Advanced filters"
      check "Without assigned valuator"
      click_button "Filter"

      expect(page).to have_content("There is 1 investment")
      expect(page).to have_link("Investment without valuator")
      expect(page).not_to have_link("Investment with valuator")

      uncheck "Without assigned valuator"
      click_button "Filter"

      expect(page).to have_content("There are 2 investments")
      expect(page).to have_link("Investment without valuator")
      expect(page).to have_link("Investment with valuator")
    end

    scenario "Filtering by under valuation" do
      create(
        :budget_investment,
        :with_administrator,
        :with_valuator,
        :open,
        title: "Investment without valuation",
        budget: budget
      )
      create(
        :budget_investment,
        :with_administrator,
        title: "Investment with valuation",
        budget: budget
      )

      visit admin_budget_budget_investments_path(budget_id: budget)
      expect(page).to have_link("Investment without valuation")
      expect(page).to have_link("Investment with valuation")

      click_button "Advanced filters"
      check "Under valuation"
      click_button "Filter"

      expect(page).to have_content("There is 1 investment")
      expect(page).to have_link("Investment without valuation")
      expect(page).not_to have_link("Investment with valuation")

      uncheck "Under valuation"
      click_button "Filter"

      expect(page).to have_content("There are 2 investments")
      expect(page).to have_link("Investment without valuation")
      expect(page).to have_link("Investment with valuation")
    end

    scenario "Filtering by valuation finished" do
      create(:budget_investment, title: "Investment valuation open", budget: budget)
      create(:budget_investment, :finished, title: "Investment valuation finished", budget: budget)

      visit admin_budget_budget_investments_path(budget_id: budget)
      expect(page).to have_link("Investment valuation open")
      expect(page).to have_link("Investment valuation finished")

      click_button "Advanced filters"
      check "Valuation finished"
      click_button "Filter"

      expect(page).to have_content("There is 1 investment")
      expect(page).not_to have_link("Investment valuation open")
      expect(page).to have_link("Investment valuation finished")

      uncheck "Valuation finished"
      click_button "Filter"

      expect(page).to have_content("There are 2 investments")
      expect(page).to have_link("Investment valuation open")
      expect(page).to have_link("Investment valuation finished")
    end

    scenario "Filtering by winners" do
      create(:budget_investment, :winner, :finished, title: "Investment winner", budget: budget)
      create(:budget_investment, title: "Investment without winner", budget: budget)

      visit admin_budget_budget_investments_path(budget_id: budget)
      expect(page).to have_link("Investment winner")
      expect(page).to have_link("Investment without winner")

      click_button "Advanced filters"
      check "Winners"
      click_button "Filter"

      expect(page).to have_content("There is 1 investment")
      expect(page).to have_link("Investment winner")
      expect(page).not_to have_link("Investment without winner")

      uncheck "Winners"
      click_button "Filter"

      expect(page).to have_content("There are 2 investments")
      expect(page).to have_link("Investment winner")
      expect(page).to have_link("Investment without winner")
    end

    scenario "Current filter is properly highlighted" do
      filters_links = { "all" => "All" }

      visit admin_budget_budget_investments_path(budget_id: budget.id)

      expect(page).not_to have_link(filters_links.values.first)
      filters_links.keys.drop(1).each { |filter| expect(page).to have_link(filters_links[filter]) }

      filters_links.each_pair do |current_filter, link|
        visit admin_budget_budget_investments_path(budget_id: budget.id, filter: current_filter)

        expect(page).not_to have_link(link)

        (filters_links.keys - [current_filter]).each do |filter|
          expect(page).to have_link(filters_links[filter])
        end
      end
    end

    scenario "Filtering by assignment status" do
      create(:budget_investment, :with_administrator, title: "Assigned idea", budget: budget)
      create(:budget_investment, :with_valuator, title: "Evaluating...", budget: budget)
      create(:budget_investment, title: "With group",
                                 budget: budget,
                                 valuator_groups: [create(:valuator_group)])

      visit admin_budget_budget_investments_path(budget_id: budget.id, filter: "valuation_open")

      expect(page).to have_content("Assigned idea")
      expect(page).to have_content("Evaluating...")
      expect(page).to have_content("With group")

      visit admin_budget_budget_investments_path(budget_id: budget.id,
                                                 advanced_filters: ["without_admin"])

      expect(page).to have_content("Evaluating...")
      expect(page).to have_content("With group")
      expect(page).not_to have_content("Assigned idea")

      visit admin_budget_budget_investments_path(budget_id: budget.id,
                                                 advanced_filters: ["without_valuator"])

      expect(page).to have_content("Assigned idea")
      expect(page).not_to have_content("Evaluating...")
      expect(page).not_to have_content("With group")
    end

    scenario "Filtering by valuation status" do
      valuating = create(:budget_investment, :with_administrator, budget: budget, title: "Ongoing valuation")
      valuated = create(:budget_investment, :finished, budget: budget, title: "Old idea")
      valuating.valuators.push(create(:valuator))
      valuated.valuators.push(create(:valuator))

      query_params = { budget_id: budget.id, advanced_filters: ["under_valuation"] }

      visit admin_budget_budget_investments_path(query_params)

      expect(page).to have_content("Ongoing valuation")
      expect(page).not_to have_content("Old idea")

      visit admin_budget_budget_investments_path(budget_id: budget.id,
                                                 advanced_filters: ["valuation_finished"])

      expect(page).not_to have_content("Ongoing valuation")
      expect(page).to have_content("Old idea")

      visit admin_budget_budget_investments_path(budget_id: budget.id, advanced_filters: ["filter"])
      expect(page).to have_content("Ongoing valuation")
      expect(page).to have_content("Old idea")
    end

    scenario "Filtering by tag" do
      create(:budget_investment, budget: budget, title: "Educate children", tag_list: "Education")
      create(:budget_investment, budget: budget, title: "More schools",     tag_list: "Education")
      create(:budget_investment, budget: budget, title: "More hospitals",   tag_list: "Health")

      visit admin_budget_budget_investments_path(budget_id: budget.id)

      expect(page).to have_css(".budget_investment", count: 3)
      expect(page).to have_content("Educate children")
      expect(page).to have_content("More schools")
      expect(page).to have_content("More hospitals")

      visit admin_budget_budget_investments_path(budget_id: budget.id, tag_name: "Education")

      expect(page).not_to have_content("More hospitals")
      expect(page).to have_css(".budget_investment", count: 2)
      expect(page).to have_content("Educate children")
      expect(page).to have_content("More schools")
    end

    scenario "Filtering by tag, display only valuation tags" do
      investment1 = create(:budget_investment, budget: budget, tag_list: "Education")
      investment2 = create(:budget_investment, budget: budget, tag_list: "Health")

      investment1.set_tag_list_on(:valuation_tags, "Teachers")
      investment2.set_tag_list_on(:valuation_tags, "Hospitals")

      investment1.save!
      investment2.save!

      visit admin_budget_budget_investments_path(budget_id: budget.id)

      expect(page).to have_select("tag_name", options: ["All tags", "Hospitals", "Teachers"])
    end

    scenario "Filtering by tag, display only valuation tags of the current budget" do
      new_budget = create(:budget)
      investment1 = create(:budget_investment, budget: budget, tag_list: "Roads")
      investment2 = create(:budget_investment, budget: new_budget, tag_list: "Accessibility")

      investment1.set_tag_list_on(:valuation_tags, "Roads")
      investment2.set_tag_list_on(:valuation_tags, "Accessibility")

      investment1.save!
      investment2.save!

      visit admin_budget_budget_investments_path(budget_id: budget.id)

      expect(page).to have_select("tag_name", options: ["All tags", "Roads"])
      expect(page).not_to have_select("tag_name", options: ["All tags", "Accessibility"])
    end

    scenario "Disable 'Calculate winner' button if incorrect phase" do
      budget.update!(phase: "reviewing_ballots")

      visit admin_budget_budget_investments_path(budget)

      click_button "Advanced filters"
      check "Winners"
      click_button "Filter"

      expect(page).to have_button "Calculate Winner Investments"

      visit admin_budget_path(budget)

      expect(page).to have_button "Calculate Winner Investments"

      click_link "Edit budget"
      select "Accepting projects", from: "Active phase"
      click_button "Update Budget"

      expect(page).to have_content "Participatory budget updated successfully"

      visit admin_budget_budget_investments_path(budget)

      click_button "Advanced filters"
      check "Winners"
      click_button "Filter"

      expect(page).not_to have_button "Calculate Winner Investments"
      expect(page).to have_content 'The budget has to stay on phase "Reviewing voting" ' \
                                   "in order to calculate winners projects"

      visit admin_budget_path(budget)

      expect(page).not_to have_button "Calculate Winner Investments"
    end

    scenario "Filtering by minimum number of votes" do
      group_1 = create(:budget_group, budget: budget)
      group_2 = create(:budget_group, budget: budget)
      parks   = create(:budget_heading, group: group_1)
      roads   = create(:budget_heading, group: group_2)
      streets = create(:budget_heading, group: group_2)

      create(:budget_investment, heading: parks, cached_votes_up: 40, title: "Park 40 supports")
      create(:budget_investment, heading: parks, cached_votes_up: 99, title: "Park 99 supports")
      create(:budget_investment, heading: roads, cached_votes_up: 100, title: "Road 100 supports")
      create(:budget_investment, heading: roads, cached_votes_up: 199, title: "Road 199 supports")
      create(:budget_investment, heading: streets, cached_votes_up: 200, title: "St. 200 supports")
      create(:budget_investment, heading: streets, cached_votes_up: 300, title: "St. 300 supports")

      visit admin_budget_budget_investments_path(budget)

      expect(page).to have_link("Park 40 supports")
      expect(page).to have_link("Park 99 supports")
      expect(page).to have_link("Road 100 supports")
      expect(page).to have_link("Road 199 supports")
      expect(page).to have_link("St. 200 supports")
      expect(page).to have_link("St. 300 supports")

      click_button "Advanced filters"
      fill_in "min_total_supports", with: 180
      click_button "Filter"

      expect(page).to have_content("There are 3 investments")
      expect(page).to have_link("Road 199 supports")
      expect(page).to have_link("St. 200 supports")
      expect(page).to have_link("St. 300 supports")
      expect(page).not_to have_link("Park 40 supports")
      expect(page).not_to have_link("Park 99 supports")
      expect(page).not_to have_link("Road 100 supports")
    end

    scenario "Filtering by maximum number of votes" do
      group_1 = create(:budget_group, budget: budget)
      group_2 = create(:budget_group, budget: budget)
      parks   = create(:budget_heading, group: group_1)
      roads   = create(:budget_heading, group: group_2)
      streets = create(:budget_heading, group: group_2)

      create(:budget_investment, heading: parks, cached_votes_up: 40, title: "Park 40 supports")
      create(:budget_investment, heading: parks, cached_votes_up: 99, title: "Park 99 supports")
      create(:budget_investment, heading: roads, cached_votes_up: 100, title: "Road 100 supports")
      create(:budget_investment, heading: roads, cached_votes_up: 199, title: "Road 199 supports")
      create(:budget_investment, heading: streets, cached_votes_up: 200, title: "St. 200 supports")
      create(:budget_investment, heading: streets, cached_votes_up: 300, title: "St. 300 supports")

      visit admin_budget_budget_investments_path(budget)

      expect(page).to have_link("Park 40 supports")
      expect(page).to have_link("Park 99 supports")
      expect(page).to have_link("Road 100 supports")
      expect(page).to have_link("Road 199 supports")
      expect(page).to have_link("St. 200 supports")
      expect(page).to have_link("St. 300 supports")

      click_button "Advanced filters"
      fill_in "max_total_supports", with: 180
      click_button "Filter"

      expect(page).to have_content("There are 3 investments")
      expect(page).not_to have_link("Road 199 supports")
      expect(page).not_to have_link("St. 200 supports")
      expect(page).not_to have_link("St. 300 supports")
      expect(page).to have_link("Park 40 supports")
      expect(page).to have_link("Park 99 supports")
      expect(page).to have_link("Road 100 supports")
    end

    scenario "Combination of checkbox with text search" do
      user = create(:user, username: "Admin 1")
      administrator = create(:administrator, user: user)
      budget.administrators = [administrator]

      educate_children = create(:budget_investment, budget: budget,
                                                    title: "Educate the children",
                                                    administrator: administrator)
      create(:budget_investment, budget: budget, title: "More schools",
                                 administrator: administrator)
      create(:budget_investment, budget: budget, title: "More hospitals")

      visit admin_budget_budget_investments_path(budget_id: budget.id)

      expect(page).to have_css(".budget_investment", count: 3)
      expect(page).to have_content("Educate the children")
      expect(page).to have_content("More schools")
      expect(page).to have_content("More hospitals")

      select "Admin 1", from: "Administrator"
      click_button "Filter"

      expect(page).to have_css(".budget_investment", count: 2)
      expect(page).to have_content("Educate the children")
      expect(page).to have_content("More schools")
      expect(page).not_to have_content("More hospitals")

      fill_in "Title or ID", with: educate_children.id
      click_button "Filter"

      expect(page).to have_css(".budget_investment", count: 1)
      expect(page).to have_content("Educate the children")
      expect(page).not_to have_content("More schools")
      expect(page).not_to have_content("More hospitals")

      expect(page).to have_content("Selected")
    end

    scenario "Combination of select with text search" do
      educate_children = create(:budget_investment, :feasible, :finished,
                                budget: budget, title: "Educate the children")
      create(:budget_investment, :feasible, :finished, budget: budget, title: "More schools")
      create(:budget_investment, budget: budget, title: "More hospitals")

      visit admin_budget_budget_investments_path(budget_id: budget.id)

      expect(page).to have_css(".budget_investment", count: 3)
      expect(page).to have_content("Educate the children")
      expect(page).to have_content("More schools")
      expect(page).to have_content("More hospitals")

      click_button "Advanced filters"

      check("Feasible")
      click_button "Filter"

      expect(page).to have_css(".budget_investment", count: 2)
      expect(page).to have_content("Educate the children")
      expect(page).to have_content("More schools")
      expect(page).not_to have_content("More hospitals")

      fill_in "Title or ID", with: educate_children.id
      click_button "Filter"

      expect(page).to have_css(".budget_investment", count: 1)
      expect(page).to have_content("Educate the children")
      expect(page).not_to have_content("More schools")
      expect(page).not_to have_content("More hospitals")

      expect(page).to have_content("Selected")
    end

    scenario "Combination of checkbox with text search and checkbox" do
      user = create(:user, username: "Admin 1")
      administrator = create(:administrator, user: user)
      budget.administrators = [administrator]

      educate_children = create(:budget_investment, :feasible, :finished,
                                budget: budget, title: "Educate the children", administrator: administrator)
      create(:budget_investment, :feasible, :finished, budget: budget,
                                                       title: "More schools",
                                                       administrator: administrator)
      create(:budget_investment, budget: budget, title: "More hospitals",
                                 administrator: administrator)
      create(:budget_investment, budget: budget, title: "More hostals")

      visit admin_budget_budget_investments_path(budget_id: budget.id)

      expect(page).to have_css(".budget_investment", count: 4)
      expect(page).to have_content("Educate the children")
      expect(page).to have_content("More schools")
      expect(page).to have_content("More hospitals")
      expect(page).to have_content("More hostals")

      select "Admin 1", from: "Administrator"
      click_button "Filter"

      expect(page).to have_css(".budget_investment", count: 3)
      expect(page).to have_content("Educate the children")
      expect(page).to have_content("More schools")
      expect(page).to have_content("More hospitals")
      expect(page).not_to have_content("More hostals")

      click_button "Advanced filters"

      within("#advanced_filters") { check("Feasible") }
      click_button("Filter")

      expect(page).to have_css(".budget_investment", count: 2)
      expect(page).to have_content("Educate the children")
      expect(page).to have_content("More schools")
      expect(page).not_to have_content("More hospitals")
      expect(page).not_to have_content("More hostals")

      fill_in "Title or ID", with: educate_children.id
      click_button "Filter"

      expect(page).to have_css(".budget_investment", count: 1)
      expect(page).to have_content("Educate the children")
      expect(page).not_to have_content("More schools")
      expect(page).not_to have_content("More hospitals")
      expect(page).not_to have_content("More hostals")

      expect(page).to have_content("Selected")
    end

    scenario "See results button appears when budget status is finished" do
      finished_budget = create(:budget, :finished)
      create(:budget_investment, :winner, budget: finished_budget, title: "Winner project")

      visit admin_budget_budget_investments_path(budget_id: finished_budget.id)
      expect(page).to have_content "See results"
    end

    scenario "See results button does not appear for unfinished budgets" do
      not_finished_budget = create(:budget, :valuating)

      visit admin_budget_budget_investments_path(budget_id: not_finished_budget.id)
      expect(page).not_to have_content "See results"
    end
  end

  context "Search" do
    let!(:first_investment) do
      create(:budget_investment, title: "Some other investment", budget: budget)
    end

    before do
      I18n.with_locale(:es) do
        create(:budget_investment, title: "Proyecto de inversión", budget: budget)
      end
    end

    scenario "Search investments by title" do
      visit admin_budget_budget_investments_path(budget)

      expect(page).to have_content("Proyecto de inversión")
      expect(page).to have_content("Some other investment")

      fill_in "Title or ID", with: "Proyecto de inversión"
      click_button "Filter"

      expect(page).to have_content("Proyecto de inversión")
      expect(page).not_to have_content("Some other investment")

      fill_in "Title or ID", with: "Some other investment"
      click_button "Filter"

      expect(page).not_to have_content("Proyecto de inversión")
      expect(page).to have_content("Some other investment")
    end

    scenario "Search investments by ID" do
      visit admin_budget_budget_investments_path(budget)

      expect(page).to have_content("Proyecto de inversión")
      expect(page).to have_content("Some other investment")

      fill_in "Title or ID", with: first_investment.id
      click_button "Filter"

      expect(page).to have_content("Some other investment")
      expect(page).not_to have_content("Proyecto de inversión")
    end
  end

  context "Sorting" do
    before do
      create(:budget_investment, title: "B First Investment",
                                 budget: budget, cached_votes_up: 50, ballot_lines_count: 40)
      create(:budget_investment, title: "A Second Investment",
                                 budget: budget, cached_votes_up: 25, ballot_lines_count: 20)
      create(:budget_investment, title: "C Third Investment",
                                 budget: budget, cached_votes_up: 10, ballot_lines_count: 30)
    end

    scenario "Default" do
      create(:budget_investment, title: "D Fourth Investment", cached_votes_up: 50, budget: budget)

      visit admin_budget_budget_investments_path(budget)

      expect("D Fourth Investment").to appear_before("B First Investment")
      expect("B First Investment").to appear_before("A Second Investment")
      expect("A Second Investment").to appear_before("C Third Investment")
    end

    context "Ascending" do
      scenario "Sort by ID" do
        visit admin_budget_budget_investments_path(budget, sort_by: "id", direction: "asc")

        expect("B First Investment").to appear_before("A Second Investment")
        expect("A Second Investment").to appear_before("C Third Investment")
        within("th", text: "ID") do
          expect(page).to have_css ".icon-sortable.desc", visible: :all
        end
      end

      scenario "Sort by title" do
        visit admin_budget_budget_investments_path(budget, sort_by: "title", direction: "asc")

        expect("A Second Investment").to appear_before("B First Investment")
        expect("B First Investment").to appear_before("C Third Investment")
        within("th", text: "Title") do
          expect(page).to have_css ".icon-sortable.desc", visible: :all
        end
      end

      scenario "Sort by supports" do
        budget.update!(phase: "valuating")
        visit admin_budget_budget_investments_path(budget, sort_by: "supports", direction: "asc")

        expect("C Third Investment").to appear_before("A Second Investment")
        expect("A Second Investment").to appear_before("B First Investment")
        within("th", text: "Supports") do
          expect(page).to have_css ".icon-sortable.desc", visible: :all
        end
      end

      scenario "Sort by votes" do
        budget.update!(phase: "reviewing_ballots")
        visit admin_budget_budget_investments_path(budget, sort_by: "ballot_lines_count", direction: "asc")

        expect("A Second Investment").to appear_before("C Third Investment")
        expect("C Third Investment").to appear_before("B First Investment")
        within("th", text: "Votes") do
          expect(page).to have_css ".icon-sortable.desc", visible: :all
        end
      end
    end

    context "Descending" do
      scenario "Sort by ID" do
        visit admin_budget_budget_investments_path(budget, sort_by: "id", direction: "desc")

        expect("C Third Investment").to appear_before("A Second Investment")
        expect("A Second Investment").to appear_before("B First Investment")
        within("th", text: "ID") do
          expect(page).to have_css ".icon-sortable.asc", visible: :all
        end
      end

      scenario "Sort by title" do
        visit admin_budget_budget_investments_path(budget, sort_by: "title", direction: "desc")

        expect("C Third Investment").to appear_before("B First Investment")
        expect("B First Investment").to appear_before("A Second Investment")
        within("th", text: "Title") do
          expect(page).to have_css ".icon-sortable.asc", visible: :all
        end
      end

      scenario "Sort by supports" do
        budget.update!(phase: "valuating")
        visit admin_budget_budget_investments_path(budget, sort_by: "supports", direction: "desc")

        expect("B First Investment").to appear_before("A Second Investment")
        expect("A Second Investment").to appear_before("C Third Investment")
        within("th", text: "Supports") do
          expect(page).to have_css ".icon-sortable.asc", visible: :all
        end
      end

      scenario "Sort by votes" do
        budget.update!(phase: "reviewing_ballots")
        visit admin_budget_budget_investments_path(budget, sort_by: "ballot_lines_count", direction: "desc")

        expect("B First Investment").to appear_before("C Third Investment")
        expect("C Third Investment").to appear_before("A Second Investment")
        within("th", text: "Votes") do
          expect(page).to have_css ".icon-sortable.asc", visible: :all
        end
      end
    end

    context "With no direction provided sorts ascending" do
      scenario "Sort by ID" do
        visit admin_budget_budget_investments_path(budget, sort_by: "id")

        expect("B First Investment").to appear_before("A Second Investment")
        expect("A Second Investment").to appear_before("C Third Investment")
        within("th", text: "ID") do
          expect(page).to have_css ".icon-sortable.desc", visible: :all
        end
      end

      scenario "Sort by title" do
        visit admin_budget_budget_investments_path(budget, sort_by: "title")

        expect("A Second Investment").to appear_before("B First Investment")
        expect("B First Investment").to appear_before("C Third Investment")
        within("th", text: "Title") do
          expect(page).to have_css ".icon-sortable.desc", visible: :all
        end
      end

      scenario "Sort by supports" do
        budget.update!(phase: "valuating")
        visit admin_budget_budget_investments_path(budget, sort_by: "supports")

        expect("C Third Investment").to appear_before("A Second Investment")
        expect("A Second Investment").to appear_before("B First Investment")
        within("th", text: "Supports") do
          expect(page).to have_css ".icon-sortable.desc", visible: :all
        end
      end

      scenario "Sort by votes" do
        budget.update!(phase: "reviewing_ballots")
        visit admin_budget_budget_investments_path(budget, sort_by: "ballot_lines_count")

        expect("A Second Investment").to appear_before("C Third Investment")
        expect("C Third Investment").to appear_before("B First Investment")
        within("th", text: "Votes") do
          expect(page).to have_css ".icon-sortable.desc", visible: :all
        end
      end
    end

    context "With incorrect direction provided sorts ascending" do
      scenario "Sort by ID" do
        visit admin_budget_budget_investments_path(budget, sort_by: "id", direction: "incorrect")

        expect("B First Investment").to appear_before("A Second Investment")
        expect("A Second Investment").to appear_before("C Third Investment")
        within("th", text: "ID") do
          expect(page).to have_css ".icon-sortable.desc", visible: :all
        end
      end
    end
  end

  context "Show" do
    scenario "Show the investment details" do
      user = create(:user, username: "Rachel", email: "rachel@valuators.org")
      valuator = create(:valuator, user: user)
      budget_investment = create(:budget_investment,
                                 :unfeasible,
                                 unfeasibility_explanation: "It is impossible",
                                 price: 1234,
                                 price_first_year: 1000,
                                 administrator: administrator,
                                 valuators: [valuator])

      visit admin_budget_budget_investments_path(budget_investment.budget)

      within_window(window_opened_by { click_link budget_investment.title }) do
        expect(page).to have_content("Investment preview")
        expect(page).to have_content(budget_investment.title)
        expect(page).to have_content(budget_investment.description)
        expect(page).to have_content(budget_investment.author.name)
        expect(page).to have_content(budget_investment.heading.name)
        expect(page).to have_content("1234")
        expect(page).to have_content("1000")
        expect(page).to have_content("Unfeasible")
        expect(page).to have_content("It is impossible")
        expect(page).to have_content("Ana (ana@admins.org)")

        within("#assigned_valuators") do
          expect(page).to have_content("Rachel (rachel@valuators.org)")
        end

        expect(page).to have_button "Publish comment"
      end
    end

    scenario "Show image and documents on investment details" do
      budget_investment = create(:budget_investment,
                                 :with_image,
                                 :unfeasible,
                                 unfeasibility_explanation: "It is impossible",
                                 price: 1234,
                                 price_first_year: 1000,
                                 administrator: administrator)
      document = create(:document, documentable: budget_investment)

      visit admin_budget_budget_investments_path(budget_investment.budget)

      within_window(window_opened_by { click_link budget_investment.title }) do
        expect(page).to have_content(budget_investment.title)
        expect(page).to have_content(budget_investment.description)
        expect(page).to have_content(budget_investment.author.name)
        expect(page).to have_content(budget_investment.heading.name)
        expect(page).to have_content("Investment preview")
        expect(page).to have_content(budget_investment.image.title)
        expect(page).to have_content("Documents (1)")
        expect(page).to have_link text: document.title
        expect(page).to have_content("1234")
        expect(page).to have_content("1000")
        expect(page).to have_content("Unfeasible")
        expect(page).to have_content("It is impossible")
        expect(page).to have_content("Ana (ana@admins.org)")
      end
    end

    scenario "Does not show related content or hide links on preview" do
      budget_investment = create(:budget_investment,
                                 :unfeasible,
                                 price: 1234,
                                 price_first_year: 1000,
                                 administrator: administrator)

      visit admin_budget_budget_investments_path(budget_investment.budget)

      click_link budget_investment.title

      expect(page).not_to have_content("Add related content")
      expect(page).not_to have_content("Hide")
    end

    scenario "If budget is finished, investment cannot be edited or valuation comments created" do
      finished_budget = create(:budget, :finished)
      budget_investment = create(:budget_investment,
                                 budget: finished_budget,
                                 administrator: administrator)
      visit admin_budget_budget_investments_path(budget_investment.budget)

      within_window(window_opened_by { click_link budget_investment.title }) do
        expect(page).not_to have_link "Edit"
        expect(page).not_to have_link "Edit classification"
        expect(page).not_to have_link "Edit dossier"
        expect(page).to have_link "Create new milestone"

        expect(page).not_to have_button "Publish comment"
      end
    end
  end

  context "Edit" do
    scenario "Change title, incompatible, description or heading" do
      budget_investment = create(:budget_investment, :incompatible)
      create(:budget_heading, group: budget_investment.group, name: "Barbate")

      visit admin_budget_budget_investment_path(budget_investment.budget, budget_investment)
      click_link "Edit"

      fill_in "Title", with: "Potatoes"
      fill_in_ckeditor "Description", with: "Carrots"
      select "Barbate", from: "budget_investment[heading_id]"
      uncheck "budget_investment_incompatible"
      check "budget_investment_selected"

      click_button "Update"

      expect(page).to have_content "Potatoes"
      expect(page).to have_content "Carrots"
      expect(page).to have_content "Barbate"
      expect(page).to have_content "Compatibility: Compatible"
      expect(page).to have_content "Selected"
    end

    scenario "Compatible non-winner can't edit incompatibility" do
      budget_investment = create(:budget_investment, :selected)
      create(:budget_heading, group: budget_investment.group, name: "Tetuan")

      visit admin_budget_budget_investment_path(budget_investment.budget, budget_investment)
      click_link "Edit"

      expect(page).not_to have_content "Compatibility"
      expect(page).not_to have_content "Mark as incompatible"
    end

    scenario "Add administrator" do
      budget_investment = create(:budget_investment)
      user = create(:user, username: "Marta", email: "marta@admins.org")
      create(:administrator, user: user, description: "Marta desc")

      visit edit_admin_budget_path(budget_investment.budget)

      click_link "Select administrators"
      check "Marta"
      click_button "Update Budget"

      expect(page).to have_content "Participatory budget updated successfully"

      visit admin_budget_budget_investment_path(budget_investment.budget, budget_investment)
      click_link "Edit classification"

      select "Marta desc (marta@admins.org)", from: "budget_investment[administrator_id]"
      click_button "Update"

      expect(page).to have_content "Investment project updated successfully."
      expect(page).to have_content "Assigned administrator: Marta"
    end

    scenario "Add valuators" do
      budget_investment = create(:budget_investment)

      user1 = create(:user, username: "Valentina", email: "v1@valuators.org")
      user2 = create(:user, username: "Valerian",  email: "v2@valuators.org")
      user3 = create(:user, username: "Val",       email: "v3@valuators.org")

      valuator1 = create(:valuator, user: user1)
      valuator3 = create(:valuator, user: user3)
      create(:valuator, user: user2)

      visit edit_admin_budget_path(budget_investment.budget)

      click_link "Select valuators"

      check "Valentina"
      check "Val"
      click_button "Update Budget"

      expect(page).to have_content "Participatory budget updated successfully"

      visit admin_budget_budget_investment_path(budget_investment.budget, budget_investment)
      click_link "Edit classification"

      check "budget_investment_valuator_ids_#{valuator1.id}"
      check "budget_investment_valuator_ids_#{valuator3.id}"

      click_button "Update"

      expect(page).to have_content "Investment project updated successfully."

      within("#assigned_valuators") do
        expect(page).to have_content("Valentina (v1@valuators.org)")
        expect(page).to have_content("Val (v3@valuators.org)")
        expect(page).not_to have_content("Undefined")
        expect(page).not_to have_content("Valerian (v2@valuators.org)")
      end
    end

    scenario "Add valuator group" do
      budget_investment = create(:budget_investment)

      health_group = create(:valuator_group, name: "Health")
      culture_group = create(:valuator_group, name: "Culture")
      create(:valuator_group, name: "Economy")

      visit admin_budget_budget_investment_path(budget_investment.budget, budget_investment)
      click_link "Edit classification"

      check "budget_investment_valuator_group_ids_#{health_group.id}"
      check "budget_investment_valuator_group_ids_#{culture_group.id}"

      click_button "Update"

      expect(page).to have_content "Investment project updated successfully."

      within("#assigned_valuator_groups") do
        expect(page).to have_content("Health")
        expect(page).to have_content("Culture")
        expect(page).not_to have_content("Undefined")
        expect(page).not_to have_content("Economy")
      end
    end

    scenario "Do not display valuators of an assigned group" do
      budget_investment = create(:budget_investment)

      health_group = create(:valuator_group, name: "Health")
      user = create(:user, username: "Valentina", email: "v1@valuators.org")
      create(:valuator, user: user, valuator_group: health_group)

      visit admin_budget_budget_investment_path(budget_investment.budget, budget_investment)
      click_link "Edit classification"

      check "budget_investment_valuator_group_ids_#{health_group.id}"

      click_button "Update"

      expect(page).to have_content "Investment project updated successfully."

      within("#assigned_valuator_groups") { expect(page).to have_content("Health") }
      within("#assigned_valuators") do
        expect(page).to have_content("Undefined")
        expect(page).not_to have_content("Valentina (v1@valuators.org)")
      end
    end

    scenario "Adds existing valuation tags" do
      budget_investment1 = create(:budget_investment)
      budget_investment1.set_tag_list_on(:valuation_tags, "Education, Health")
      budget_investment1.save!

      budget_investment2 = create(:budget_investment)

      visit edit_admin_budget_budget_investment_path(budget_investment2.budget, budget_investment2)

      find(".js-add-tag-link", text: "Education").click

      click_button "Update"

      expect(page).to have_content "Investment project updated successfully."

      within "#tags" do
        expect(page).to have_content "Education"
        expect(page).not_to have_content "Health"
      end
    end

    scenario "Adds non existent valuation tags" do
      budget_investment = create(:budget_investment)

      visit admin_budget_budget_investment_path(budget_investment.budget, budget_investment)
      click_link "Edit classification"

      fill_in "budget_investment_valuation_tag_list", with: "Refugees, Solidarity"
      click_button "Update"

      expect(page).to have_content "Investment project updated successfully."

      within "#tags" do
        expect(page).to have_content "Refugees"
        expect(page).to have_content "Solidarity"
      end
    end

    scenario "Changes valuation and user generated tags" do
      budget_investment = create(:budget_investment, tag_list: "Park")
      budget_investment.set_tag_list_on(:valuation_tags, "Education")
      budget_investment.save!

      visit admin_budget_budget_investment_path(budget_investment.budget, budget_investment)

      within("#tags_budget_investment_#{budget_investment.id}") do
        expect(page).not_to have_content "Education"
        expect(page).to have_content "Park"
      end

      click_link "Edit classification"

      fill_in "budget_investment_tag_list", with: "Park, Trees"
      fill_in "budget_investment_valuation_tag_list", with: "Education, Environment"
      click_button "Update"

      expect(page).to have_content "Investment project updated successfully"

      visit admin_budget_budget_investment_path(budget_investment.budget, budget_investment)

      within("#tags_budget_investment_#{budget_investment.id}") do
        expect(page).not_to have_content "Education"
        expect(page).not_to have_content "Environment"
        expect(page).to have_content "Park"
        expect(page).to have_content "Trees"
      end

      within("#tags") do
        expect(page).to have_content "Education, Environment"
        expect(page).not_to have_content "Park"
        expect(page).not_to have_content "Trees"
      end
    end

    scenario "Maintains user tags" do
      budget_investment = create(:budget_investment, tag_list: "Park")

      visit admin_budget_budget_investment_path(budget_investment.budget, budget_investment)

      click_link "Edit classification"

      fill_in "budget_investment_valuation_tag_list", with: "Refugees, Solidarity"
      click_button "Update"

      expect(page).to have_content "Investment project updated successfully."

      visit budget_investment_path(budget_investment.budget, budget_investment)
      expect(page).to have_content "Park"
      expect(page).not_to have_content "Refugees, Solidarity"
    end

    scenario "Shows alert when 'Valuation finished' is checked" do
      budget_investment = create(:budget_investment)

      visit admin_budget_budget_investment_path(budget_investment.budget, budget_investment)
      click_link "Edit dossier"

      expect(page).to have_content("Valuation finished")

      accept_confirm { check("Valuation finished") }

      expect(find("#js-investment-report-alert")).to be_checked
    end

    scenario "Shows alert with unfeasible status when 'Valuation finished' is checked" do
      budget_investment = create(:budget_investment, :unfeasible)

      visit admin_budget_budget_investment_path(budget_investment.budget, budget_investment)
      click_link "Edit dossier"

      expect(page).to have_field "Valuation finished", checked: false

      accept_confirm { check("Valuation finished") }

      expect(page).to have_field "Valuation finished", checked: true
    end

    scenario "Undoes check in 'Valuation finished' if user clicks 'cancel' on alert" do
      budget_investment = create(:budget_investment)

      visit admin_budget_budget_investment_path(budget_investment.budget, budget_investment)
      click_link "Edit dossier"

      dismiss_confirm { check("Valuation finished") }

      expect(find("#js-investment-report-alert")).not_to be_checked
    end

    scenario "Errors on update" do
      budget_investment = create(:budget_investment)

      visit admin_budget_budget_investment_path(budget_investment.budget, budget_investment)
      click_link "Edit"

      fill_in "Title", with: ""

      click_button "Update"

      expect(page).to have_content "can't be blank"
    end

    scenario "Add milestone tags" do
      budget_investment = create(:budget_investment)

      visit admin_budget_budget_investment_path(budget_investment.budget, budget_investment)

      expect(page).not_to have_content("Milestone Tags:")

      click_link "Edit classification"

      fill_in "budget_investment_milestone_tag_list", with: "tag1, tag2"

      click_button "Update"

      expect(page).to have_content "Investment project updated successfully."
      expect(page).to have_content("Milestone Tags: tag1, tag2")
    end
  end

  context "Selecting" do
    let!(:unfeasible_bi) do
      create(:budget_investment, :unfeasible, budget: budget, title: "Unfeasible project")
    end

    let!(:feasible_bi) do
      create(:budget_investment, :feasible, budget: budget, title: "Feasible project")
    end

    let!(:feasible_vf_bi) do
      create(:budget_investment, :feasible, :finished, budget: budget, title: "Feasible, VF project")
    end

    let!(:selected_bi) do
      create(:budget_investment, :selected, budget: budget, title: "Selected project")
    end

    let!(:winner_bi) do
      create(:budget_investment, :winner, budget: budget, title: "Winner project")
    end

    let!(:undecided_bi) do
      create(:budget_investment, :undecided, budget: budget, title: "Undecided project")
    end

    scenario "Filtering by valuation and selection" do
      visit admin_budget_budget_investments_path(budget)

      click_button "Advanced filters"
      check "Valuation finished"
      click_button "Filter"

      expect(page).not_to have_content(unfeasible_bi.title)
      expect(page).not_to have_content(feasible_bi.title)
      expect(page).to have_content(feasible_vf_bi.title)
      expect(page).to have_content(selected_bi.title)
      expect(page).to have_content(winner_bi.title)

      within("#advanced_filters") { check("Feasible") }
      click_button("Filter")

      expect(page).not_to have_content(unfeasible_bi.title)
      expect(page).not_to have_content(feasible_bi.title)
      expect(page).to have_content(feasible_vf_bi.title)
      expect(page).to have_content(selected_bi.title)
      expect(page).to have_content(winner_bi.title)

      within("#advanced_filters") do
        check("Selected")
        uncheck("Feasible")
      end

      click_button("Filter")

      expect(page).not_to have_content(unfeasible_bi.title)
      expect(page).not_to have_content(feasible_bi.title)
      expect(page).not_to have_content(feasible_vf_bi.title)
      expect(page).to have_content(selected_bi.title)
      expect(page).to have_content(winner_bi.title)

      check "Winners"
      click_button "Filter"

      expect(page).not_to have_content(unfeasible_bi.title)
      expect(page).not_to have_content(feasible_bi.title)
      expect(page).not_to have_content(feasible_vf_bi.title)
      expect(page).not_to have_content(selected_bi.title)
      expect(page).to have_content(winner_bi.title)
    end

    scenario "Aggregating results" do
      visit admin_budget_budget_investments_path(budget)

      click_button "Advanced filters"

      within("#advanced_filters") { check("Undecided") }
      click_button("Filter")

      expect(page).to have_content(undecided_bi.title)
      expect(page).not_to have_content(winner_bi.title)
      expect(page).not_to have_content(selected_bi.title)
      expect(page).not_to have_content(feasible_bi.title)
      expect(page).not_to have_content(unfeasible_bi.title)
      expect(page).not_to have_content(feasible_vf_bi.title)

      within("#advanced_filters") { check("Unfeasible") }
      click_button("Filter")

      expect(page).to have_content(undecided_bi.title)
      expect(page).to have_content(unfeasible_bi.title)
      expect(page).not_to have_content(winner_bi.title)
      expect(page).not_to have_content(selected_bi.title)
      expect(page).not_to have_content(feasible_bi.title)
      expect(page).not_to have_content(feasible_vf_bi.title)
    end

    scenario "Selecting an investment" do
      visit admin_budget_budget_investments_path(budget)

      expect(page).to have_content "Unfeasible project"

      within("tr", text: "Feasible, VF project") do
        within("[data-field=selected]") do
          expect(page).to have_content "No"

          click_button "Select Feasible, VF project"

          expect(page).to have_content "Yes"
        end
      end

      click_button "Advanced filters"

      within("#advanced_filters") { check("Selected") }
      click_button("Filter")

      expect(page).not_to have_content "Unfeasible project"

      within("tr", text: "Feasible, VF project") do
        within("[data-field=selected]") do
          expect(page).to have_content "Yes"
        end
      end
    end

    scenario "Unselecting an investment" do
      visit admin_budget_budget_investments_path(budget)
      click_button "Advanced filters"

      within("#advanced_filters") { check("Selected") }
      click_button("Filter")

      expect(page).to have_content("There are 2 investments")

      within("tr", text: "Selected project") do
        within("[data-field=selected]") do
          expect(page).to have_content "Yes"

          click_button "Select Selected project"

          expect(page).to have_content "No"
        end
      end

      click_button "Filter"
      expect(page).not_to have_content "Selected project"
      expect(page).to have_content "There is 1 investment"

      visit admin_budget_budget_investments_path(budget)

      within("tr", text: "Selected project") do
        within("[data-field=selected]") do
          expect(page).to have_content "No"
        end
      end
    end

    describe "Pagination" do
      before { selected_bi.update(cached_votes_up: 50) }

      scenario "After unselecting an investment" do
        allow(Budget::Investment).to receive(:default_per_page).and_return(3)

        visit admin_budget_budget_investments_path(budget)

        within("tr", text: "Selected project") do
          within("[data-field=selected]") do
            click_button "Select Selected project"

            expect(page).to have_content "No"
          end
        end

        click_link("Next")

        expect(page).to have_link("Previous")
      end
    end
  end

  context "Mark as winner" do
    let!(:selected_bi) do
      create(:budget_investment, :selected, budget: budget, title: "Selected project")
    end

    let!(:winner_bi) do
      create(:budget_investment, :winner, budget: budget, title: "Winning project")
    end

    scenario "Marking an investment as winner" do
      budget.update!(phase: "reviewing_ballots")
      visit admin_budget_budget_investments_path(budget)

      expect(page).to have_content "Winner"

      within("tr", text: "Selected project") do
        within("[data-field=winner]") do
          expect(page).to have_content "No"
          expect(page).not_to have_content "Yes"

          click_button "No"

          expect(page).to have_content "Yes"
          expect(page).not_to have_content "No"

          expect(selected_bi.reload).to be_winner
        end
      end
    end

    scenario "Unmarking an investment as winner" do
      budget.update!(phase: "reviewing_ballots")
      visit admin_budget_budget_investments_path(budget)

      within("tr", text: "Winning project") do
        within("[data-field=winner]") do
          expect(page).to have_content "Yes"
          expect(page).not_to have_content "No"

          click_button "Yes"

          expect(page).to have_content "No"
          expect(page).not_to have_content "Yes"

          expect(winner_bi.reload).not_to be_winner
        end
      end
    end

    scenario "Cannot mark unselected investment as winner" do
      create(:budget_investment, budget: budget, title: "Unselected project")
      budget.update!(phase: "reviewing_ballots")
      visit admin_budget_budget_investments_path(budget)

      within("tr", text: "Unselected project") do
        within("[data-field=winner]") do
          expect(page).not_to have_content "Yes"
          expect(page).not_to have_content "No"
          expect(page).not_to have_button
        end
      end
    end

    scenario "Cannot mark as winner on finished budgets" do
      budget.update!(phase: "finished")
      visit admin_budget_budget_investments_path(budget)

      within("tr", text: "Winning project") do
        within("[data-field=winner]") do
          expect(page).to have_content "Winner"
          expect(page).not_to have_button
        end
      end

      within("tr", text: "Selected project") do
        within("[data-field=winner]") do
          expect(page).not_to have_content "Winner"
          expect(page).not_to have_button
        end
      end
    end
  end

  context "Mark as visible to valuators" do
    let(:valuator) { create(:valuator) }
    let(:admin) { create(:administrator) }

    let(:heading) { create(:budget_heading, budget: budget) }

    let(:investment1) { create(:budget_investment, heading: heading, title: "Investment 1") }
    let(:investment2) { create(:budget_investment, heading: heading, title: "Investment 2") }

    scenario "Mark as visible to valuator" do
      investment1.valuators << valuator
      investment2.valuators << valuator
      investment1.update!(administrator: admin)
      investment2.update!(administrator: admin)

      visit admin_budget_budget_investments_path(budget)
      click_button "Advanced filters"
      check "Under valuation"
      click_button "Filter"

      within("tr", text: "Investment 1") do
        within("[data-field=visible_to_valuators]") do
          expect(page).to have_content "No"

          click_button "Show Investment 1 to valuators"

          expect(page).to have_content "Yes"
        end
      end

      refresh

      within("tr", text: "Investment 1") do
        within("[data-field=visible_to_valuators]") do
          expect(page).to have_content "Yes"
        end
      end
    end

    scenario "Shows the correct investments to valuators" do
      budget.update!(phase: :valuating)
      investment1.update!(visible_to_valuators: true)
      investment2.update!(visible_to_valuators: false)

      investment1.valuators << valuator
      investment2.valuators << valuator
      investment1.update!(administrator: admin)
      investment2.update!(administrator: admin)

      login_as(valuator.user)
      visit valuation_root_path

      within "#budget_#{budget.id}" do
        click_link "Evaluate"
      end

      expect(page).to     have_content investment1.title
      expect(page).not_to have_content investment2.title
    end

    scenario "Unmark as visible to valuator" do
      budget.update!(phase: "valuating")

      investment1.valuators << valuator
      investment2.valuators << valuator
      investment1.update!(administrator: admin, visible_to_valuators: true)
      investment2.update!(administrator: admin, visible_to_valuators: true)

      visit admin_budget_budget_investments_path(budget)

      click_button "Advanced filters"
      check "Under valuation"
      click_button "Filter"

      within("tr", text: "Investment 1") do
        within("[data-field=visible_to_valuators]") do
          expect(page).to have_content "Yes"

          click_button "Show Investment 1 to valuators"

          expect(page).to have_content "No"
        end
      end

      refresh

      within("tr", text: "Investment 1") do
        within("[data-field=visible_to_valuators]") do
          expect(page).to have_content "No"
        end
      end
    end

    scenario "Cannot mark/unmark visible to valuators on finished budgets" do
      budget.update!(phase: "finished")
      create(:budget_investment, budget: budget, title: "Visible", visible_to_valuators: true)
      create(:budget_investment, budget: budget, title: "Invisible", visible_to_valuators: false)

      visit admin_budget_budget_investments_path(budget)

      click_button "Columns"
      within("#js-columns-selector-wrapper") do
        check "Show to valuators"
      end

      within "tr", text: "Visible" do
        within "[data-field=visible_to_valuators]" do
          expect(page).to have_text "Yes"
          expect(page).not_to have_button
        end
      end

      within "tr", text: "Invisible" do
        within "[data-field=visible_to_valuators]" do
          expect(page).to have_text "No"
          expect(page).not_to have_button
        end
      end
    end

    scenario "Showing the valuating checkbox" do
      investment1.valuators << valuator
      investment2.valuators << valuator
      investment1.update!(administrator: admin, visible_to_valuators: true)
      investment2.update!(administrator: admin, visible_to_valuators: false)

      visit admin_budget_budget_investments_path(budget)

      click_button "Advanced filters"
      check "Under valuation"
      click_button "Filter"

      within "tr", text: "Investment 1" do
        within "[data-field=visible_to_valuators]" do
          expect(page).to have_content "Yes"
          expect(page).to have_css "button[aria-pressed='true']"
        end
      end

      within "tr", text: "Investment 2" do
        within "[data-field=visible_to_valuators]" do
          expect(page).to have_content "No"
          expect(page).to have_css "button[aria-pressed='false']"
        end
      end
    end

    scenario "Keeps the valuation tags" do
      investment1.set_tag_list_on(:valuation_tags, %w[Possimpible Truthiness])
      investment1.save!

      visit admin_budget_budget_investments_path(budget)

      within "tr", text: "Investment 1" do
        within "[data-field=visible_to_valuators]" do
          expect(page).to have_content "No"

          click_button "Show Investment 1 to valuators"

          expect(page).to have_content "Yes"
        end
      end

      visit edit_admin_budget_budget_investment_path(budget, investment1)

      expect(page).to have_content "Possimpible"
      expect(page).to have_content "Truthiness"
    end
  end

  context "Selecting csv", :no_js do
    scenario "Downloading CSV file" do
      admin = create(:administrator, user: create(:user, username: "Admin"))
      valuator = create(:valuator, user: create(:user, username: "Valuator"))
      valuator_group = create(:valuator_group, name: "Valuator Group")
      budget_group = create(:budget_group, name: "Budget Group", budget: budget)
      first_budget_heading = create(:budget_heading, group: budget_group, name: "Budget Heading")
      second_budget_heading = create(:budget_heading, group: budget_group, name: "Other Heading")
      first_investment = create(:budget_investment, :feasible, :selected, title: "Le Investment",
                                                                          budget: budget, group: budget_group,
                                                                          heading: first_budget_heading,
                                                                          cached_votes_up: 88, price: 99,
                                                                          valuators: [],
                                                                          valuator_groups: [valuator_group],
                                                                          administrator: admin,
                                                                          visible_to_valuators: true)
      second_investment = create(:budget_investment, :unfeasible, title: "Alt Investment",
                                                                  budget: budget, group: budget_group,
                                                                  heading: second_budget_heading,
                                                                  cached_votes_up: 66, price: 88,
                                                                  valuators: [valuator],
                                                                  valuator_groups: [],
                                                                  visible_to_valuators: false)

      visit admin_budget_budget_investments_path(budget)

      click_link "Download current selection"

      header = page.response_headers["Content-Disposition"]
      expect(header).to match(/^attachment/)
      expect(header).to match(/filename="budget_investments.csv"/)

      csv_contents = "ID,Title,Supports,Administrator,Valuator,Valuation Group,Scope of operation," \
                     "Feasibility,Val. Fin.,Selected,Show to valuators,Author username\n" \
                     "#{first_investment.id},Le Investment,88,Admin,-,Valuator Group," \
                     "Budget Heading,Feasible (€99),Yes,Yes,Yes," \
                     "#{first_investment.author.username}\n#{second_investment.id}," \
                     "Alt Investment,66,No admin assigned,Valuator,-,Other Heading," \
                     "Unfeasible,No,No,No,#{second_investment.author.username}\n"

      expect(page.body).to eq(csv_contents)
    end

    scenario "Downloading CSV file with applied filter" do
      create(:budget_investment, :unfeasible, budget: budget, title: "Unfeasible one")
      create(:budget_investment, :finished, budget: budget, title: "Finished Investment")

      visit admin_budget_budget_investments_path(budget)
      click_button "Advanced filters"
      check "Valuation finished"
      click_button "Filter"

      expect(page).to have_content "Finished Investment"
      expect(page).not_to have_content "Unfeasible one"

      click_link "Download current selection"

      expect(page).to have_content("Finished Investment")
      expect(page).not_to have_content("Unfeasible one")
    end
  end

  context "Columns chooser" do
    let!(:investment) do
      create(:budget_investment,
             :winner,
             :visible_to_valuators,
             budget: budget,
             author: create(:user, username: "Jon Doe"))
    end
    let(:all_columns) do
      %w[id title supports admin author valuator geozone feasibility price
         valuation_finished visible_to_valuators selected incompatible ballot_lines_count winner]
    end
    let(:selectable_columns) do
      %w[title supports admin author valuator geozone feasibility price
         valuation_finished visible_to_valuators selected ballot_lines_count winner]
    end

    scenario "Display default columns for each phase" do
      {
        "informing" => %w[id title geozone price selected],
        "accepting" => %w[id title geozone price selected feasibility admin valuator valuation_finished \
                          visible_to_valuators],
        "reviewing" => %w[id title geozone price selected feasibility admin valuator valuation_finished \
                          visible_to_valuators],
        "selecting" => %w[id title geozone price selected feasibility admin valuator valuation_finished \
                          visible_to_valuators supports],
        "valuating" => %w[id title geozone price selected feasibility admin valuator valuation_finished \
                          visible_to_valuators supports],
        "publishing_prices" => %w[id title geozone price selected feasibility admin valuator \
                                  valuation_finished visible_to_valuators supports],
        "balloting" => %w[id title geozone price selected ballot_lines_count],
        "reviewing_ballots" => %w[id title geozone price selected ballot_lines_count winner],
        "finished" => %w[id title geozone price selected ballot_lines_count winner]
      }.each do |phase, columns|
        budget.update!(phase: phase)
        visit admin_budget_budget_investments_path(budget)

        within("table.column-selectable") do
          all_columns.each do |column|
            header = I18n.t("admin.budget_investments.index.list.#{column}")
            if columns.include?(column)
              expect(page).to have_content(header)
            else
              expect(page).not_to have_content(header)
            end
          end

          expect(page).to have_content(investment.title)
        end
      end
    end

    scenario "Display incompatible column as default if and only if selected filter was set" do
      visit admin_budget_budget_investments_path(budget, advanced_filters: ["selected"])

      within("table.column-selectable") do
        expect(page).to have_content("Incompatible")
      end

      expect(page).to have_content(investment.title)
    end

    scenario "Do not set cookie if column selector is not used" do
      visit admin_budget_budget_investments_path(budget)

      expect(cookie_by_name("investments-columns")).to be(nil)
    end

    scenario "Use column selector to display visible columns" do
      visit admin_budget_budget_investments_path(budget)

      click_button "Columns"

      within("#js-columns-selector-wrapper") do
        selectable_columns.each do |column|
          check_text = I18n.t("admin.budget_investments.index.list.#{column}")

          expect(page).to have_content(check_text)
        end
      end

      within("#js-columns-selector-wrapper") do
        uncheck "Title"
        uncheck "Price"
        check "Author"
      end

      within("table.column-selectable") do
        expect(page).not_to have_content("Title")
        expect(page).not_to have_content("Price")
        expect(page).to have_content("Author")

        expect(page).not_to have_content(investment.title)
        expect(page).not_to have_content(investment.formatted_price)
        expect(page).to have_content("Jon Doe")
      end
    end

    scenario "Cookie will be updated after change columns selection" do
      budget.update!(phase: "balloting")
      # default columns: id title geozone price selected ballot_lines_count
      visit admin_budget_budget_investments_path(budget)

      click_button "Columns"

      within("#js-columns-selector-wrapper") do
        uncheck "Title"
        uncheck "Price"
        check "Author"
      end

      cookie_value = cookie_by_name("investments-columns-balloting")[:value]

      expect(cookie_value).to eq("id,author,geozone,selected,ballot_lines_count")

      visit admin_budget_budget_investments_path(budget)

      cookie_value = cookie_by_name("investments-columns-balloting")[:value]

      expect(cookie_value).to eq("id,author,geozone,selected,ballot_lines_count")
    end

    scenario "Select an investment when some columns are not displayed" do
      investment.update!(title: "Don't display me, please!")

      visit admin_budget_budget_investments_path(budget)
      click_button "Columns"
      within("#js-columns-selector-wrapper") { uncheck "Title" }

      within("#budget_investment_#{investment.id}") do
        within("[data-field=selected]") do
          expect(page).to have_content "Yes"

          click_button "Select Don't display me, please!"

          expect(page).to have_content "No"
        end
      end

      expect(page).not_to have_content "Don't display me, please!"
    end

    scenario "When restoring the page from browser history renders columns selectors only once" do
      visit admin_budget_budget_investments_path(budget)

      click_link "Proposals"

      expect(page).to have_content("There are no proposals.")

      go_back

      click_button "Columns"

      within("#js-columns-selector-wrapper") do
        selectable_columns.each do |column|
          check_text = I18n.t("admin.budget_investments.index.list.#{column}")

          expect(page).to have_content(check_text, count: 1)
        end
      end
    end
  end
end
