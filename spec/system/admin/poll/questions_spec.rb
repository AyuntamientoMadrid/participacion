require "rails_helper"

describe "Admin poll questions", :admin do
  scenario "Index" do
    poll1 = create(:poll, :future)
    poll2 = create(:poll, :future)
    proposal = create(:proposal)
    question1 = create(:poll_question, poll: poll1)
    question2 = create(:poll_question, poll: poll2, proposal: proposal)

    visit admin_poll_path(poll1)
    expect(page).to have_content(poll1.name)

    within("#poll_question_#{question1.id}") do
      expect(page).to have_content(question1.title)
      expect(page).to have_link "Edit answers"
      expect(page).to have_link "Edit"
      expect(page).to have_button "Delete"
    end

    visit admin_poll_path(poll2)
    expect(page).to have_content(poll2.name)

    within("#poll_question_#{question2.id}") do
      expect(page).to have_content question2.title
      expect(page).to have_link "(See proposal)", href: proposal_path(question2.proposal)
      expect(page).to have_link "Edit answers"
      expect(page).to have_link "Edit"
      expect(page).to have_button "Delete"
    end
  end

  scenario "Show" do
    geozone = create(:geozone)
    poll = create(:poll, geozone_restricted_to: [geozone])
    question = create(:poll_question, poll: poll)

    visit admin_poll_path(poll)
    click_link "Edit answers"

    expect(page).to have_link "Go back", href: admin_poll_path(poll)
    expect(page).to have_content question.title
    expect(page).to have_content question.author.name
  end

  describe "Create" do
    scenario "Is possible for a not started poll" do
      poll = create(:poll, :future, name: "Movies")

      visit admin_poll_path(poll)
      click_link "Create question"

      expect(page).to have_content("Create question to poll Movies")
      expect(page).to have_css "input[id='poll_question_poll_id'][value='#{poll.id}']",
                               visible: :hidden

      fill_in "Question", with: "Star Wars: Episode IV - A New Hope"
      click_button "Save"

      expect(page).to have_content "Star Wars: Episode IV - A New Hope"
    end

    scenario "Is not possible for an already started poll" do
      visit admin_poll_path(create(:poll))

      expect(page).not_to have_link "Create question"
    end

    describe "With votation type" do
      before do
        poll = create(:poll, :future)
        visit admin_poll_path(poll)
        click_link "Create question"
      end

      scenario "Unique" do
        fill_in "Question", with: "Question with unique answer"
        select "Unique answer", from: "Votation type"

        click_button "Save"

        expect(page).to have_content "Question with unique answer"
        expect(page).to have_content "Unique answer"
      end

      scenario "Multiple" do
        fill_in "Question", with: "Question with multiple answers"
        select "Multiple answers", from: "Votation type"
        fill_in "Maximum number of votes", with: 6
        click_button "Save"

        expect(page).to have_content "Question with multiple answers"
        expect(page).to have_content "Multiple answers"
      end
    end
  end

  scenario "Create from proposal" do
    create(:poll, :future, name: "Proposals")
    proposal = create(:proposal)

    visit admin_proposal_path(proposal)

    expect(page).not_to have_content("This proposal has reached the required supports")
    click_link "Add this proposal to a poll to be voted"

    expect(page).to have_current_path(new_admin_question_path, ignore_query: true)
    expect(page).to have_field("Question", with: proposal.title)

    select "Proposals", from: "Poll"

    click_button "Save"

    expect(page).to have_content(proposal.title)
  end

  scenario "Create from successful proposal" do
    create(:poll, :future, name: "Proposals")
    proposal = create(:proposal, :successful)

    visit admin_proposals_path
    click_link "Successful proposals"
    click_link "Create question"

    expect(page).to have_current_path(new_admin_question_path, ignore_query: true)
    expect(page).to have_field("Question", with: proposal.title)

    select "Proposals", from: "Poll"

    click_button "Save"

    expect(page).to have_content proposal.title
  end

  scenario "Update" do
    poll = create(:poll, :future)
    question = create(:poll_question, poll: poll)
    old_title = question.title
    new_title = "Vegetables are great and everyone should have one"

    visit admin_poll_path(poll)

    within("#poll_question_#{question.id}") do
      click_link "Edit"
    end

    expect(page).to have_link "Go back", href: admin_poll_path(poll)
    fill_in "Question", with: new_title

    click_button "Save"

    expect(page).to have_content "Changes saved"
    expect(page).to have_content new_title
    expect(page).not_to have_content old_title
  end

  scenario "Destroy" do
    poll = create(:poll, :future)
    question1 = create(:poll_question, poll: poll)
    question2 = create(:poll_question, poll: poll)

    visit admin_poll_path(poll)

    within("#poll_question_#{question1.id}") do
      accept_confirm("Are you sure? This action will delete \"#{question1.title}\" and can't be undone.") do
        click_button "Delete"
      end
    end

    expect(page).not_to have_content question1.title
    expect(page).to have_content question2.title
    expect(page).to have_current_path admin_poll_path(poll)
  end

  context "Poll select box" do
    scenario "translates the poll name in options" do
      poll = create(:poll, :future, name_en: "Name in English", name_es: "Nombre en Español")
      proposal = create(:proposal)

      visit admin_proposal_path(proposal)
      click_link "Add this proposal to a poll to be voted"

      expect(page).to have_select("poll_question_poll_id", options: ["Select Poll", poll.name_en])

      select "Español", from: "Language:"

      expect(page).to have_select("poll_question_poll_id",
                                  options: ["Seleccionar votación", poll.name_es])
    end

    scenario "uses fallback if name is not translated to current locale",
             if: Globalize.fallbacks(:fr).reject { |locale| locale.match(/fr/) }.first == :es do
      poll = create(:poll, :future, name_en: "Name in English", name_es: "Nombre en Español")
      proposal = create(:proposal)

      visit admin_proposal_path(proposal)
      click_link "Add this proposal to a poll to be voted"

      expect(page).to have_select("poll_question_poll_id", options: ["Select Poll", poll.name_en])

      select "Français", from: "Language:"

      expect(page).to have_select("poll_question_poll_id",
                                  options: ["Sélectionner un vote", poll.name_es])
    end
  end
end
