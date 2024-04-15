require "rails_helper"

describe "Debates" do
  context "Concerns" do
    it_behaves_like "notifiable in-app", :debate
    it_behaves_like "relationable", Debate
    it_behaves_like "remotely_translatable", :debate, "debates_path", {}
    it_behaves_like "remotely_translatable", :debate, "debate_path", { id: "id" }
    it_behaves_like "flaggable", :debate
  end

  scenario "Index" do
    debates = [create(:debate), create(:debate), create(:debate)]

    visit debates_path

    expect(page).to have_css "#debates .debate", count: 3
    debates.each do |debate|
      within("#debates") do
        expect(page).to have_content debate.title
        expect(page).to have_content debate.description
        expect(page).to have_link debate.title, href: debate_path(debate)
      end
    end
  end

  scenario "Paginated Index" do
    per_page = 3
    allow(Debate).to receive(:default_per_page).and_return(per_page)
    (per_page + 2).times { create(:debate) }

    visit debates_path

    expect(page).to have_css "#debates .debate", count: per_page

    within("ul.pagination") do
      expect(page).to have_content("1")
      expect(page).to have_content("2")
      expect(page).not_to have_content("3")
      click_link "Next", exact: false
    end

    expect(page).to have_css "#debates .debate", count: 2
  end

  scenario "Index view mode" do
    debates = [create(:debate), create(:debate), create(:debate)]

    visit debates_path

    click_button "View mode"

    click_link "List"

    debates.each do |debate|
      within("#debates") do
        expect(page).to     have_link debate.title
        expect(page).not_to have_content debate.description
      end
    end

    click_button "View mode"

    click_link "Cards"

    debates.each do |debate|
      within("#debates") do
        expect(page).to have_link debate.title
        expect(page).to have_content debate.description
      end
    end
  end

  scenario "Show" do
    debate = create(:debate, author: create(:user, username: "Charles Dickens"))

    visit debate_path(debate)

    expect(page).to have_content debate.title
    expect(page).to have_content "Debate description"
    expect(page).to have_content "Charles Dickens"
    expect(page).to have_content I18n.l(debate.created_at.to_date)
    expect(page).to have_avatar "C"
    expect(page.html).to include "<title>#{debate.title}</title>"
  end

  describe "Social share buttons" do
    context "On desktop browsers" do
      scenario "Shows links to share on facebook and twitter" do
        visit debate_path(create(:debate))

        within(".social-share-button") do
          expect(page.all("a").count).to be(2)
          expect(page).to have_link "Share to Facebook"
          expect(page).to have_link "Share to Twitter"
        end
      end
    end

    context "On small devices", :small_window do
      scenario "Shows links to share on telegram and whatsapp too" do
        visit debate_path(create(:debate))

        within(".social-share-button") do
          expect(page.all("a").count).to be(4)
          expect(page).to have_link "Share to Facebook"
          expect(page).to have_link "Share to Twitter"
          expect(page).to have_link "Share to Telegram"
          expect(page).to have_link "Share to WhatsApp"
        end
      end
    end
  end

  scenario "Show: 'Back' link directs to previous page" do
    debate = create(:debate, title: "Test Debate 1")

    visit debates_path(order: :hot_score, page: 1)

    within("#debate_#{debate.id}") do
      click_link debate.title
    end

    link_text = find_link("Go back")[:href]

    expect(link_text).to include(debates_path(order: :hot_score, page: 1))
  end

  context "Show" do
    scenario "When path matches the friendly url" do
      debate = create(:debate)

      right_path = debate_path(debate)
      visit right_path

      expect(page).to have_current_path(right_path)
    end

    scenario "When path does not match the friendly url" do
      debate = create(:debate)

      right_path = debate_path(debate)
      old_path = "#{debates_path}/#{debate.id}-something-else"
      visit old_path

      expect(page).not_to have_current_path(old_path)
      expect(page).to have_current_path(right_path)
    end
  end

  scenario "Show votes score on index and show" do
    debate_positive = create(:debate, title: "Debate positive")
    debate_zero = create(:debate, title: "Debate zero")
    debate_negative = create(:debate, title: "Debate negative")

    10.times { create(:vote, votable: debate_positive, vote_flag: true) }
    3.times  { create(:vote, votable: debate_positive, vote_flag: false) }

    5.times { create(:vote, votable: debate_zero, vote_flag: true) }
    5.times  { create(:vote, votable: debate_zero, vote_flag: false) }

    6.times  { create(:vote, votable: debate_negative, vote_flag: false) }

    visit debates_path

    within "#debate_#{debate_positive.id}" do
      expect(page).to have_content("7 votes")
    end

    within "#debate_#{debate_zero.id}" do
      expect(page).to have_content("No votes")
    end

    within "#debate_#{debate_negative.id}" do
      expect(page).to have_content("-6 votes")
    end

    visit debate_path(debate_positive)
    expect(page).to have_content("7 votes")

    visit debate_path(debate_zero)
    expect(page).to have_content("No votes")

    visit debate_path(debate_negative)
    expect(page).to have_content("-6 votes")
  end

  scenario "Create", :with_frozen_time do
    author = create(:user)
    login_as(author)

    visit new_debate_path
    fill_in_new_debate_title with: "A title for a debate"
    fill_in_ckeditor "Initial debate text", with: "This is very important because..."
    check "debate_terms_of_service"

    click_button "Start a debate"

    expect(page).to have_content "A title for a debate"
    expect(page).to have_content "Debate created successfully."
    expect(page).to have_content "This is very important because..."
    expect(page).to have_content author.name
    expect(page).to have_content I18n.l(Date.current)
  end

  scenario "Create with invisible_captcha honeypot field", :no_js do
    author = create(:user)
    login_as(author)

    visit new_debate_path
    fill_in "Debate title", with: "I am a bot"
    fill_in "debate_subtitle", with: "This is a honeypot field"
    fill_in "Initial debate text", with: "This is the description"
    check "debate_terms_of_service"

    click_button "Start a debate"

    expect(page.status_code).to eq(200)
    expect(page.html).to be_empty
    expect(page).to have_current_path(debates_path)
  end

  scenario "Create debate too fast" do
    allow(InvisibleCaptcha).to receive(:timestamp_threshold).and_return(Float::INFINITY)

    author = create(:user)
    login_as(author)

    visit new_debate_path
    fill_in_new_debate_title with: "I am a bot"
    fill_in_ckeditor "Initial debate text", with: "This is the description"
    check "debate_terms_of_service"

    click_button "Start a debate"

    expect(page).to have_content "Sorry, that was too quick! Please resubmit"

    expect(page).to have_current_path(new_debate_path)
  end

  scenario "Errors on create" do
    author = create(:user)
    login_as(author)

    visit new_debate_path
    click_button "Start a debate"
    expect(page).to have_content error_message
  end

  scenario "Short description errors" do
    login_as(create(:user))

    visit new_debate_path
    fill_in_ckeditor "Initial debate text", with: "Go!"
    click_button "Start a debate"

    within ".form-error.html-area" do
      expect(page).to have_content "is too short"
    end
  end

  scenario "JS injection is prevented but safe html is respected", :no_js do
    author = create(:user)
    login_as(author)

    visit new_debate_path
    fill_in "Debate title", with: "Testing an attack"
    fill_in "Initial debate text", with: "<p>This is a JS <script>alert('an attack');</script></p>"
    check "debate_terms_of_service"

    click_button "Start a debate"

    expect(page).to have_content "Debate created successfully."
    expect(page).to have_content "Testing an attack"
    expect(page.html).to include "<p>This is a JS alert('an attack');</p>"
    expect(page.html).not_to include "<script>alert('an attack');</script>"
    expect(page.html).not_to include "&lt;p&gt;This is"
  end

  scenario "Autolinking is applied to description" do
    author = create(:user)
    login_as(author)

    visit new_debate_path
    fill_in_new_debate_title with: "Testing auto link"
    fill_in_ckeditor "Initial debate text", with: "This is a link www.example.org"
    check "debate_terms_of_service"

    click_button "Start a debate"

    expect(page).to have_content "Debate created successfully."
    expect(page).to have_content "Testing auto link"
    expect(page).to have_link("www.example.org", href: "http://www.example.org")
  end

  scenario "JS injection is prevented but autolinking is respected", :no_js do
    author = create(:user)
    js_injection_string = "<script>alert('hey')</script> " \
                          "<a href=\"javascript:alert('surprise!')\">click me</a> " \
                          "http://example.org"
    login_as(author)

    visit new_debate_path
    fill_in "Debate title", with: "Testing auto link"
    fill_in "Initial debate text", with: js_injection_string
    check "debate_terms_of_service"

    click_button "Start a debate"

    expect(page).to have_content "Debate created successfully."
    expect(page).to have_content "Testing auto link"
    expect(page).to have_link("http://example.org", href: "http://example.org")
    expect(page).not_to have_link("click me")
    expect(page.html).not_to include "<script>alert('hey')</script>"

    click_link "Edit"

    expect(page).to have_css "h1", exact_text: "Edit debate"
    expect(page).to have_field "Debate title", with: "Testing auto link"
    expect(page).not_to have_link("click me")
    expect(page.html).not_to include "<script>alert('hey')</script>"
  end

  scenario "Update should not be posible if logged user is not the author" do
    debate = create(:debate)
    expect(debate).to be_editable
    login_as(create(:user))

    visit edit_debate_path(debate)
    expect(page).not_to have_current_path(edit_debate_path(debate))
    expect(page).to have_current_path(root_path)
    expect(page).to have_content "You do not have permission to carry out the action 'edit' on Debate."
  end

  scenario "Update should not be posible if debate is not editable" do
    Setting["max_votes_for_debate_edit"] = 2
    debate = create(:debate, voters: Array.new(3) { create(:user) })

    expect(debate).not_to be_editable
    login_as(debate.author)

    visit edit_debate_path(debate)

    expect(page).not_to have_current_path(edit_debate_path(debate))
    expect(page).to have_current_path(root_path)
    expect(page).to have_content "You do not have permission to"
  end

  scenario "Update should be posible for the author of an editable debate" do
    debate = create(:debate)
    login_as(debate.author)

    visit edit_debate_path(debate)
    expect(page).to have_current_path(edit_debate_path(debate))

    fill_in "Debate title", with: "End child poverty"
    fill_in_ckeditor "Initial debate text", with: "Let's do something to end child poverty"

    click_button "Save changes"

    expect(page).to have_content "Debate updated successfully."
    expect(page).to have_content "End child poverty"
    expect(page).to have_content "Let's do something to end child poverty"
  end

  scenario "Errors on update" do
    debate = create(:debate)
    login_as(debate.author)

    visit edit_debate_path(debate)
    fill_in "Debate title", with: ""
    click_button "Save changes"

    expect(page).to have_content error_message
  end

  describe "Debate index order filters" do
    scenario "Default order is hot_score" do
      best_debate = create(:debate, title: "Best")
      best_debate.update_column(:hot_score, 10)
      worst_debate = create(:debate, title: "Worst")
      worst_debate.update_column(:hot_score, 2)
      medium_debate = create(:debate, title: "Medium")
      medium_debate.update_column(:hot_score, 5)

      visit debates_path

      expect(best_debate.title).to appear_before(medium_debate.title)
      expect(medium_debate.title).to appear_before(worst_debate.title)
    end

    scenario "Debates are ordered by confidence_score" do
      best_debate = create(:debate, title: "Best")
      best_debate.update_column(:confidence_score, 10)
      worst_debate = create(:debate, title: "Worst")
      worst_debate.update_column(:confidence_score, 2)
      medium_debate = create(:debate, title: "Medium")
      medium_debate.update_column(:confidence_score, 5)

      visit debates_path
      click_link "highest rated"

      expect(page).to have_css "a.is-active", text: "highest rated"

      within "#debates" do
        expect(best_debate.title).to appear_before(medium_debate.title)
        expect(medium_debate.title).to appear_before(worst_debate.title)
      end

      expect(page).to have_current_path(/order=confidence_score/)
      expect(page).to have_current_path(/page=1/)
    end

    scenario "Debates are ordered by newest" do
      best_debate = create(:debate, title: "Best", created_at: Time.current)
      medium_debate = create(:debate, title: "Medium", created_at: 1.hour.ago)
      worst_debate = create(:debate, title: "Worst", created_at: 1.day.ago)

      visit debates_path
      click_link "newest"

      expect(page).to have_css "a.is-active", text: "newest"

      within "#debates" do
        expect(best_debate.title).to appear_before(medium_debate.title)
        expect(medium_debate.title).to appear_before(worst_debate.title)
      end

      expect(page).to have_current_path(/order=created_at/)
      expect(page).to have_current_path(/page=1/)
    end

    context "Recommendations" do
      let!(:best_debate)   { create(:debate, title: "Best",   cached_votes_total: 10, tag_list: "Sport") }
      let!(:medium_debate) { create(:debate, title: "Medium", cached_votes_total: 5,  tag_list: "Sport") }
      let!(:worst_debate)  { create(:debate, title: "Worst",  cached_votes_total: 1,  tag_list: "Sport") }

      scenario "can't be sorted if there's no logged user" do
        visit debates_path
        expect(page).not_to have_css "a", text: "recommendations"
      end

      scenario "are shown on index header when account setting is enabled" do
        proposal = create(:proposal, tag_list: "Sport")
        user     = create(:user, followables: [proposal])

        login_as(user)
        visit debates_path

        expect(page).to have_css(".recommendation", count: 3)
        expect(page).to have_link "Best"
        expect(page).to have_link "Medium"
        expect(page).to have_link "Worst"
        expect(page).to have_link "See more recommendations"
      end

      scenario "should display text when there are no results" do
        proposal = create(:proposal, tag_list: "Distinct_to_sport")
        user     = create(:user, followables: [proposal])

        login_as(user)
        visit debates_path

        click_link "recommendations"

        expect(page).to have_content "There are no debates related to your interests"
      end

      scenario "should display text when user has no related interests" do
        user = create(:user)

        login_as(user)
        visit debates_path

        click_link "recommendations"

        expect(page).to have_content "Follow proposals so we can give you recommendations"
      end

      scenario "can be sorted when there's a logged user" do
        proposal = create(:proposal, tag_list: "Sport")
        user     = create(:user, followables: [proposal])

        login_as(user)
        visit debates_path

        click_link "recommendations"

        expect(page).to have_css "a.is-active", text: "recommendations"

        within "#debates" do
          expect(best_debate.title).to appear_before(medium_debate.title)
          expect(medium_debate.title).to appear_before(worst_debate.title)
        end

        expect(page).to have_current_path(/order=recommendations/)
        expect(page).to have_current_path(/page=1/)
      end

      scenario "are not shown if account setting is disabled" do
        proposal = create(:proposal, tag_list: "Sport")
        user     = create(:user, recommended_debates: false, followables: [proposal])

        login_as(user)
        visit debates_path

        expect(page).not_to have_css(".recommendation", count: 3)
        expect(page).not_to have_link("recommendations")
      end

      scenario "are automatically disabled when dismissed from index" do
        proposal = create(:proposal, tag_list: "Sport")
        user     = create(:user, followables: [proposal])

        login_as(user)
        visit debates_path

        within("#recommendations") do
          expect(page).to have_content("Best")
          expect(page).to have_content("Worst")
          expect(page).to have_content("Medium")
          expect(page).to have_css(".recommendation", count: 3)

          accept_confirm { click_button "Hide recommendations" }
        end

        expect(page).not_to have_link("recommendations")
        expect(page).not_to have_css(".recommendation", count: 3)
        expect(page).to have_content("Recommendations for debates are now disabled for this account")

        visit account_path

        expect(find("#account_recommended_debates")).not_to be_checked
      end
    end
  end

  context "Search" do
    context "Basic search" do
      scenario "Search by text" do
        debate1 = create(:debate, title: "Get Schwifty")
        debate2 = create(:debate, title: "Schwifty Hello")
        debate3 = create(:debate, title: "Do not show me")

        visit debates_path

        within "#search_form" do
          fill_in "search", with: "Schwifty"
          click_button "Search"
        end

        within("#debates") do
          expect(page).to have_css(".debate", count: 2)

          expect(page).to have_content(debate1.title)
          expect(page).to have_content(debate2.title)
          expect(page).not_to have_content(debate3.title)
        end
      end

      scenario "Maintain search criteria" do
        visit debates_path

        within "#search_form" do
          fill_in "search", with: "Schwifty"
          click_button "Search"
        end

        expect(page).to have_css "input[name='search'][value='Schwifty']"
      end
    end

    scenario "Order by relevance by default" do
      create(:debate, title: "Show you got",      cached_votes_up: 10)
      create(:debate, title: "Show what you got", cached_votes_up: 1)
      create(:debate, title: "Show you got",      cached_votes_up: 100)

      visit debates_path
      fill_in "search", with: "Show you got"
      click_button "Search"

      expect(page).to have_css "a.is-active", text: "relevance"

      within("#debates") do
        expect(all(".debate")[0].text).to match "Show you got"
        expect(all(".debate")[1].text).to match "Show you got"
        expect(all(".debate")[2].text).to match "Show what you got"
      end
    end

    scenario "Reorder results maintaing search" do
      create(:debate, title: "Show you got",      cached_votes_up: 10,  created_at: 1.week.ago)
      create(:debate, title: "Show what you got", cached_votes_up: 1,   created_at: 1.month.ago)
      create(:debate, title: "Show you got",      cached_votes_up: 100, created_at: Time.current)
      create(:debate, title: "Do not display",    cached_votes_up: 1,   created_at: 1.week.ago)

      visit debates_path
      fill_in "search", with: "Show you got"
      click_button "Search"
      click_link "newest"
      expect(page).to have_css "a.is-active", text: "newest"

      within("#debates") do
        expect(all(".debate")[0].text).to match "Show you got"
        expect(all(".debate")[1].text).to match "Show you got"
        expect(all(".debate")[2].text).to match "Show what you got"
        expect(page).not_to have_content "Do not display"
      end
    end

    scenario "Reorder by recommendations results maintaing search" do
      proposal = create(:proposal, tag_list: "Sport")
      user = create(:user, recommended_debates: true, followables: [proposal])

      create(:debate, title: "Show you got",      cached_votes_total: 10,  tag_list: "Sport")
      create(:debate, title: "Show what you got", cached_votes_total: 1,   tag_list: "Sport")
      create(:debate, title: "Do not display with same tag", cached_votes_total: 100, tag_list: "Sport")
      create(:debate, title: "Do not display",    cached_votes_total: 1)

      login_as(user)
      visit debates_path
      fill_in "search", with: "Show you got"
      click_button "Search"
      click_link "recommendations"
      expect(page).to have_css "a.is-active", text: "recommendations"

      within("#debates") do
        expect(all(".debate")[0].text).to match "Show you got"
        expect(all(".debate")[1].text).to match "Show what you got"
        expect(page).not_to have_content "Do not display with same tag"
        expect(page).not_to have_content "Do not display"
      end
    end

    scenario "After a search do not show featured debates" do
      create_featured_debates
      create(:debate, title: "Abcdefghi")

      visit debates_path
      within "#search_form" do
        fill_in "search", with: "Abcdefghi"
        click_button "Search"
      end

      expect(page).not_to have_css "#debates .debate-featured"
      expect(page).not_to have_css "#featured-debates"
    end
  end

  scenario "Conflictive" do
    good_debate = create(:debate)
    conflictive_debate = create(:debate, :conflictive)

    visit debate_path(conflictive_debate)
    expect(page).to have_content "This debate has been flagged as inappropriate by several users."

    visit debate_path(good_debate)
    expect(page).not_to have_content "This debate has been flagged as inappropriate by several users."
  end

  scenario "Erased author" do
    user = create(:user)
    debate = create(:debate, author: user)
    user.erase

    visit debates_path
    expect(page).to have_content("User deleted")

    visit debate_path(debate)
    expect(page).to have_content("User deleted")
  end

  context "Suggesting debates" do
    scenario "Shows up to 5 suggestions" do
      create(:debate, title: "First debate has 1 vote", cached_votes_up: 1)
      create(:debate, title: "Second debate has 2 votes", cached_votes_up: 2)
      create(:debate, title: "Third debate has 3 votes", cached_votes_up: 3)
      create(:debate,
             title: "This one has 4 votes",
             description: "This is the fourth debate",
             cached_votes_up: 4)
      create(:debate, title: "Fifth debate has 5 votes", cached_votes_up: 5)
      create(:debate,
             title: "Sixth debate has 6 votes",
             description: "This is the sixth debate",
             cached_votes_up: 6)
      create(:debate,
             title: "This has seven votes, and is not suggest",
             description: "This is the seven",
             cached_votes_up: 7)

      login_as(create(:user))
      visit new_debate_path
      fill_in "Debate title", with: "debate"
      check "debate_terms_of_service"

      within("div.js-suggest") do
        expect(page).to have_content "You are seeing 5 of 6 debates containing the term 'debate'"
      end
    end

    scenario "No found suggestions" do
      create(:debate, title: "First debate has 10 vote", cached_votes_up: 10)
      create(:debate, title: "Second debate has 2 votes", cached_votes_up: 2)

      login_as(create(:user))
      visit new_debate_path
      fill_in "Debate title", with: "proposal"
      check "debate_terms_of_service"

      within("div.js-suggest") do
        expect(page).not_to have_content "You are seeing"
      end
    end

    describe "Don't show suggestions" do
      let(:user) { create(:user) }
      let(:debate) { create(:debate, title: "Debate title, has search term", author: user) }

      before do
        login_as(user)
        visit edit_debate_path(debate)
      end

      scenario "for edit action" do
        fill_in "Debate title", with: "search"

        expect(page).not_to have_content "There is a debate with the term 'search'"
      end

      scenario "for update action" do
        fill_in "Debate title", with: ""

        click_button "Save changes"
        fill_in "Debate title", with: "search"

        expect(page).not_to have_content "There is a debate with the term 'search'"
      end
    end
  end

  scenario "Mark/Unmark a debate as featured", :admin do
    debate = create(:debate)

    visit debates_path
    within("#debates") do
      expect(page).not_to have_content "FEATURED"
    end

    click_link debate.title
    accept_confirm("Are you sure? Featured") { click_button "Featured" }

    within("#debates") do
      expect(page).to have_content "FEATURED"
    end

    within("#featured-debates") do
      expect(page).to have_content debate.title

      click_link debate.title
    end

    accept_confirm("Are you sure? Unmark featured") { click_button "Unmark featured" }

    within("#debates") do
      expect(page).not_to have_content "FEATURED"
    end
  end

  scenario "Index include featured debates", :admin do
    create(:debate, featured_at: Time.current)
    create(:debate)

    visit debates_path

    within("#debates") do
      expect(page).to have_content("FEATURED")
    end
  end

  scenario "Index do not show featured debates if none is marked as featured", :admin do
    create(:debate)
    create(:debate)

    visit debates_path
    within("#debates") do
      expect(page).not_to have_content("Featured")
    end
  end

  describe "SDG related list" do
    let(:user) { create(:user) }

    before do
      Setting["feature.sdg"] = true
      Setting["sdg.process.debates"] = true
    end

    scenario "create debate with sdg related list" do
      login_as(user)
      visit new_debate_path
      fill_in_new_debate_title with: "A title for a debate related with SDG related content"
      fill_in_ckeditor "Initial debate text", with: "This is very important because..."
      click_sdg_goal(1)
      check "debate_terms_of_service"

      click_button "Start a debate"

      within(".sdg-goal-tag-list") { expect(page).to have_link "1. No Poverty" }
    end

    scenario "edit debate with sdg related list" do
      debate = create(:debate, author: user)
      debate.sdg_goals = [SDG::Goal[1], SDG::Goal[2]]
      login_as(user)
      visit edit_debate_path(debate)

      remove_sdg_goal_or_target_tag(1)
      click_button "Save changes"

      within(".sdg-goal-tag-list") do
        expect(page).not_to have_link "1. No Poverty"
        expect(page).to have_link "2. Zero Hunger"
      end
    end
  end
end
