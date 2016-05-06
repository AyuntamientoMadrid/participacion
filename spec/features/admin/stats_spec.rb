require 'rails_helper'

feature 'Stats' do

  background do
    admin = create(:administrator)
    login_as(admin.user)
    visit root_path
  end

  context 'Summary' do

    scenario 'General' do
      create(:debate)
      2.times { create(:proposal) }
      3.times { create(:comment, commentable: Debate.first) }
      4.times { create(:visit) }
      5.times { create(:survey_answer) }
      6.times { create(:spending_proposal) }

      visit admin_stats_path

      expect(page).to have_content "Debates 1"
      expect(page).to have_content "Proposals 2"
      expect(page).to have_content "Comments 3"
      expect(page).to have_content "Visits 4"
      expect(page).to have_content "Surveys completed 5"
      expect(page).to have_content "Investment projects 6"
    end

    scenario 'Votes' do
      debate = create(:debate)
      create(:vote, votable: debate)

      proposal = create(:proposal)
      2.times { create(:vote, votable: proposal) }

      comment = create(:comment)
      3.times { create(:vote, votable: comment) }

      open_answer = create(:open_answer)
      4.times { create(:vote, votable: open_answer) }

      spending_proposal = create(:spending_proposal)
      5.times { create(:vote, votable: spending_proposal) }

      visit admin_stats_path

      expect(page).to have_content "Debate votes 1"
      expect(page).to have_content "Proposal votes 2"
      expect(page).to have_content "Comment votes 3"
      expect(page).to have_content "Open answer votes 4"
      expect(page).to have_content "Investment project votes 5"
      expect(page).to have_content "Total votes 15"
    end

    scenario 'Users' do
      1.times { create(:user, :level_three) }
      2.times { create(:user, :level_two) }
      3.times { create(:user) }

      visit admin_stats_path

      expect(page).to have_content "Level three users 1"
      expect(page).to have_content "Level two users 2"
      expect(page).to have_content "Verified users 3"
      expect(page).to have_content "Unverified users 4"
      expect(page).to have_content "Total users 7"
    end

  end

  scenario 'Level 2 user' do
    create(:geozone)
    visit account_path
    click_link 'Verify my account'
    verify_residence
    confirm_phone

    visit admin_stats_path

    expect(page).to have_content "Level 2 User (1)"
  end

end
