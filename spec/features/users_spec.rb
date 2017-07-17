require 'rails_helper'

feature 'Users' do

  feature 'Show (public page)' do

    background do
      @user = create(:user)
      1.times {create(:debate, author: @user)}
      2.times {create(:proposal, author: @user)}
      3.times {create(:budget_investment, author: @user)}
      4.times {create(:comment, user: @user)}

      visit user_path(@user)
    end

    scenario 'shows user public activity' do
      expect(page).to have_content('1 Debate')
      expect(page).to have_content('2 Proposals')
      expect(page).to have_content('3 Investments')
      expect(page).to have_content('4 Comments')
    end

    scenario 'shows only items where user has activity' do
      @user.proposals.destroy_all

      expect(page).to_not have_content('0 Proposals')
      expect(page).to have_content('1 Debate')
      expect(page).to have_content('3 Investments')
      expect(page).to have_content('4 Comments')
    end

    scenario 'default filter is proposals' do
      @user.proposals.each do |proposal|
        expect(page).to have_content(proposal.title)
      end

      @user.debates.each do |debate|
        expect(page).to_not have_content(debate.title)
      end

      @user.comments.each do |comment|
        expect(page).to_not have_content(comment.body)
      end
    end

    scenario 'shows debates by default if user has no proposals' do
      @user.proposals.destroy_all
      visit user_path(@user)

      expect(page).to have_content(@user.debates.first.title)
    end

    scenario 'shows investments by default if user has no proposals nor debates' do
      @user.proposals.destroy_all
      @user.debates.destroy_all
      visit user_path(@user)

      expect(page).to have_content(@user.budget_investments.first.title)
    end

    scenario 'shows comments by default if user has no proposals nor debates nor investments' do
      @user.proposals.destroy_all
      @user.debates.destroy_all
      @user.budget_investments.destroy_all
      visit user_path(@user)

      @user.comments.each do |comment|
        expect(page).to have_content(comment.body)
      end
    end

    scenario 'filters' do
      click_link '1 Debate'

      @user.debates.each do |debate|
        expect(page).to have_content(debate.title)
      end

      @user.proposals.each do |proposal|
        expect(page).to_not have_content(proposal.title)
      end

      @user.comments.each do |comment|
        expect(page).to_not have_content(comment.body)
      end

      click_link '4 Comments'

      @user.comments.each do |comment|
        expect(page).to have_content(comment.body)
      end

      @user.proposals.each do |proposal|
        expect(page).to_not have_content(proposal.title)
      end

      @user.debates.each do |debate|
        expect(page).to_not have_content(debate.title)
      end

      click_link '2 Proposals'

      @user.proposals.each do |proposal|
        expect(page).to have_content(proposal.title)
      end

      @user.comments.each do |comment|
        expect(page).to_not have_content(comment.body)
      end

      @user.debates.each do |debate|
        expect(page).to_not have_content(debate.title)
      end
    end

  end

  feature 'Public activity' do
    background do
      @user = create(:user)
    end

    scenario 'visible by default' do
      visit user_path(@user)

      expect(page).to have_content(@user.username)
      expect(page).to_not have_content('activity list private')
    end

    scenario 'user can hide public page' do
      login_as(@user)
      visit account_path

      uncheck 'account_public_activity'
      click_button 'Save changes'

      logout

      visit user_path(@user)
      expect(page).to have_content('activity list private')
    end

    scenario 'is always visible for the owner' do
      login_as(@user)
      visit account_path

      uncheck 'account_public_activity'
      click_button 'Save changes'

      visit user_path(@user)
      expect(page).to_not have_content('activity list private')
    end

    scenario 'is always visible for admins' do
      login_as(@user)
      visit account_path

      uncheck 'account_public_activity'
      click_button 'Save changes'

      logout

      login_as(create(:administrator).user)
      visit user_path(@user)
      expect(page).to_not have_content('activity list private')
    end

    scenario 'is always visible for moderators' do
      login_as(@user)
      visit account_path

      uncheck 'account_public_activity'
      click_button 'Save changes'

      logout

      login_as(create(:moderator).user)
      visit user_path(@user)
      expect(page).to_not have_content('activity list private')
    end

    feature 'User email' do

      background do
        @user = create(:user)
      end

      scenario 'is not shown if no user logged in' do
        visit user_path(@user)
        expect(page).to_not have_content(@user.email)
      end

      scenario 'is not shown if logged in user is a regular user' do
        login_as(create(:user))
        visit user_path(@user)
        expect(page).to_not have_content(@user.email)
      end

      scenario 'is not shown if logged in user is moderator' do
        login_as(create(:moderator).user)
        visit user_path(@user)
        expect(page).to_not have_content(@user.email)
      end

      scenario 'is shown if logged in user is admin' do
        login_as(create(:administrator).user)
        visit user_path(@user)
        expect(page).to have_content(@user.email)
      end

    end

    feature 'Spending proposals' do

      background do
        @author = create(:user, :level_two)
        @spending_proposal = create(:spending_proposal, author: @author, title: 'Build a school')
      end

      scenario 'is not shown if no user logged in' do
        visit user_path(@author)
        expect(page).to_not have_content('Build a school')
      end

      scenario 'is not shown if no user logged in (filtered url)' do
        visit user_path(@author, filter: 'spending_proposals')
        expect(page).to_not have_content('Build a school')
      end

      scenario 'is not shown if logged in user is a regular user' do
        login_as(create(:user))
        visit user_path(@author)
        expect(page).to_not have_content('Build a school')
      end

      scenario 'is not shown if logged in user is moderator' do
        login_as(create(:moderator).user)
        visit user_path(@author)
        expect(page).to_not have_content('Build a school')
      end

      xscenario 'is shown if logged in user is admin' do
        login_as(create(:administrator).user)
        visit user_path(@author)
        expect(page).to have_content('Build a school')
      end

      xscenario 'is shown if logged in user is author' do
        login_as(@author)
        visit user_path(@author)
        expect(page).to have_content('Build a school')
      end

      xscenario 'delete button is not shown if logged in user is author' do
        login_as(@author)
        visit user_path(@author)
        within("#spending_proposal_#{@spending_proposal.id}") do
          expect(page).to_not have_content('Delete')
        end
      end

      xscenario 'delete button is not shown if logged in user is admin' do
        login_as(create(:administrator).user)
        visit user_path(@author)
        within("#spending_proposal_#{@spending_proposal.id}") do
          expect(page).to_not have_content('Delete')
        end
      end

    end

    feature 'Ballot' do
      background do
        Setting["feature.spending_proposal_features.phase3"] = true
        @author = create(:user, :level_two)
        create(:spending_proposal, author: @author, title: 'Build a school')
        spending_proposal = create(:spending_proposal, price: 1234567, feasible: true, valuation_finished: true)
        create(:ballot, user: @author, spending_proposals: [spending_proposal])
      end

      scenario 'link is not shown if no user logged in' do
        visit user_path(@author)
        within(".activity") do
          expect(page).to_not have_content('Participatory budget')
        end
      end

      scenario 'is not shown if no user logged in (filtered url)' do
        visit user_path(@author, filter: 'ballot')
        within(".activity") do
          expect(page).to_not have_content('Participatory budget')
        end
        expect(page).to_not have_content('You voted one proposal')
      end

      scenario 'is not shown if author is not the current_user' do
        login_as(create(:user))
        visit user_path(@author)
        within(".activity") do
          expect(page).to_not have_content('Participatory budget')
        end

        visit user_path(@author, filter: 'ballot')
        expect(page).to_not have_content('You voted one proposal')
      end

      xscenario 'is shown if logged in user is author' do
        login_as(@author)
        visit user_path(@author)

        within(".activity") do
          click_link 'Participatory budget'
        end
        expect(page).to have_content('You voted one proposal')
      end

      scenario 'link is not shown if participatory budget phase 3 is not active' do
        Setting["feature.spending_proposal_features.phase3"] = nil
        login_as(@author)
        visit user_path(@author)

        within(".activity") do
          expect(page).to_not have_content('Participatory budget')
        end
      end
    end
  end

  feature 'Public interest' do
    background do
      @user = create(:user)
    end

    scenario 'Display interests' do
      proposal =  create(:proposal, tag_list: "Sport")
      create(:follow, :followed_proposal, followable: proposal, user: @user)

      login_as(@user)
      visit account_path

      check 'account_public_interests'
      click_button 'Save changes'

      logout

      visit user_path(@user)
      expect(page).to have_content("Sport")
    end

    scenario 'Not display interests when proposal has been destroyed' do
      proposal =  create(:proposal, tag_list: "Sport")
      create(:follow, :followed_proposal, followable: proposal, user: @user)
      proposal.destroy

      login_as(@user)
      visit account_path

      check 'account_public_interests'
      click_button 'Save changes'

      logout

      visit user_path(@user)
      expect(page).not_to have_content("Sport")
    end

    scenario 'No visible by default' do
      visit user_path(@user)

      expect(page).to have_content(@user.username)
      expect(page).not_to have_css('#public_interests')
    end

    scenario 'User can display public page' do
      login_as(@user)
      visit account_path

      check 'account_public_interests'
      click_button 'Save changes'

      logout

      visit user_path(@user)
      expect(page).to have_css('#public_interests')
    end

    scenario 'Is always visible for the owner' do
      login_as(@user)
      visit account_path

      uncheck 'account_public_interests'
      click_button 'Save changes'

      visit user_path(@user)
      expect(page).to have_css('#public_interests')
    end

    scenario 'Is always visible for admins' do
      login_as(@user)
      visit account_path

      uncheck 'account_public_interests'
      click_button 'Save changes'

      logout

      login_as(create(:administrator).user)
      visit user_path(@user)
      expect(page).to have_css('#public_interests')
    end

    scenario 'Is always visible for moderators' do
      login_as(@user)
      visit account_path

      uncheck 'account_public_interests'
      click_button 'Save changes'

      logout

      login_as(create(:moderator).user)
      visit user_path(@user)
      expect(page).to have_css('#public_interests')
    end

  end

  feature 'Special comments' do

    scenario 'comments posted as moderator are not visible in user activity' do
      moderator = create(:administrator).user
      comment = create(:comment, user: moderator)
      moderator_comment = create(:comment, user: moderator, moderator_id: moderator.id)

      visit user_path(moderator)
      expect(page).to have_content("1 Comment")
      expect(page).to have_content(comment.body)
      expect(page).to_not have_content(moderator_comment.body)
    end

    scenario 'comments posted as admin are not visible in user activity' do
      admin = create(:administrator).user
      comment = create(:comment, user: admin)
      admin_comment = create(:comment, user: admin, administrator_id: admin.id)

      visit user_path(admin)
      expect(page).to have_content(comment.body)
      expect(page).to_not have_content(admin_comment.body)
    end

    scenario 'shows only comments from active features' do
      user = create(:user)
      1.times {create(:comment, user: user, commentable: create(:debate))}
      2.times {create(:comment, user: user, commentable: create(:budget_investment))}
      4.times {create(:comment, user: user, commentable: create(:proposal))}

      visit user_path(user)
      expect(page).to have_content('7 Comments')

      Setting['feature.debates'] = nil
      visit user_path(user)
      expect(page).to have_content('6 Comments')

      Setting['feature.budgets'] = nil
      visit user_path(user)
      expect(page).to have_content('4 Comments')

      Setting['feature.debates'] = true
      Setting['feature.budgets'] = true
    end
  end

end
