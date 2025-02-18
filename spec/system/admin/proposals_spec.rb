require "rails_helper"

describe "Admin proposals", :admin do
  it_behaves_like "admin_milestoneable", :proposal, "admin_polymorphic_path"

  context "Index" do
    scenario "Search" do
      create(:proposal, title: "Make Pluto a planet again")
      create(:proposal, title: "Build a monument to honour CONSUL developers")

      visit admin_root_path
      within("#side_menu") { click_link "Proposals" }

      expect(page).to have_content "Make Pluto a planet again"
      expect(page).to have_content "Build a monument"

      fill_in "search", with: "Pluto"
      click_button "Search"

      expect(page).to have_content "Make Pluto a planet again"
      expect(page).not_to have_content "Build a monument"
    end

    scenario "Select a proposal" do
      proposal = create(:proposal, title: "Forbid door-to-door sales")

      visit admin_proposals_path

      within("#proposal_#{proposal.id}") do
        expect(page).to have_content "No"

        click_button "Select Forbid door-to-door sales"

        expect(page).to have_content "Yes"
      end

      refresh

      within("#proposal_#{proposal.id}") { expect(page).to have_content "Yes" }
    end

    scenario "Unselect a proposal" do
      proposal = create(:proposal, :selected, title: "Allow door-to-door sales")

      visit admin_proposals_path

      within("#proposal_#{proposal.id}") do
        expect(page).to have_content "Yes"

        click_button "Select Allow door-to-door sales"

        expect(page).to have_content "No"
      end

      refresh

      within("#proposal_#{proposal.id}") { expect(page).to have_content "No" }
    end
  end

  context "Show" do
    scenario "View proposal" do
      create(:proposal, title: "Create a chaotic future", summary: "Chaos isn't controlled")

      visit admin_proposals_path
      click_link "Create a chaotic future"

      expect(page).to have_content "Chaos isn't controlled"
      expect(page).not_to have_content "This proposal has reached the required supports"
      expect(page).not_to have_link "Create question"
    end

    scenario "Successful proposals show create question button" do
      successful_proposals = create_successful_proposals

      visit admin_proposals_path

      successful_proposals.each do |proposal|
        visit admin_proposal_path(proposal)
        expect(page).to have_content "This proposal has reached the required supports"
        expect(page).to have_link "Add this proposal to a poll to be voted"
      end
    end

    scenario "Select a proposal" do
      proposal = create(:proposal)

      visit admin_proposal_path(proposal)

      check "Mark as selected"
      click_button "Update proposal"

      expect(page).to have_content "Proposal updated successfully"
      expect(find_field("Mark as selected")).to be_checked
    end

    scenario "Unselect a proposal" do
      proposal = create(:proposal, :selected)

      visit admin_proposal_path(proposal)

      uncheck "Mark as selected"
      click_button "Update proposal"

      expect(page).to have_content "Proposal updated successfully"
      expect(find_field("Mark as selected")).not_to be_checked
    end
  end
  
  context "Selecting csv", :no_js do
    scenario "Downloading CSV file" do
      first_proposal = create(:proposal, title: "Make Pluto a planet again", summary: "summary 1")
      second_proposal = create(:proposal, title: "Build a monument to honour CONSUL developers", summary: "summary 2")
      third_proposal = create(:proposal, title: "Build another monument just because", summary: "summary 3")
      
      visit admin_proposals_path

      click_link "Download proposals"

      header = page.response_headers["Content-Disposition"]
      expect(header).to match(/^attachment/)
      expect(header).to match(/filename="proposals.csv"/)

      csv_contents = "ID,Proposal,Author,Summary,Description\n" \
                     "#{first_proposal.id},#{first_proposal.title},#{first_proposal.author.email},#{first_proposal.summary},#{first_proposal.description}\n" \
                     "#{second_proposal.id},#{second_proposal.title},#{second_proposal.author.email},#{second_proposal.summary},#{first_proposal.description}\n" \
                     "#{third_proposal.id},#{third_proposal.title},#{third_proposal.author.email},#{third_proposal.summary},#{first_proposal.description}\n" 

      expect(page.body).to eq(csv_contents)
    end
  end
end
