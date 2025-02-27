require "rails_helper"

describe "Legislation" do
  context "process summary page" do
    scenario "summary tab is not shown for open processes" do
      process = create(:legislation_process, :open)

      visit legislation_process_path(process)

      expect(page).not_to have_content "Summary"
    end

    scenario "summary tab is shown por past processes" do
      process = create(:legislation_process, :past)

      visit legislation_process_path(process)

      expect(page).to have_content "Summary"
    end
  end

  scenario "empty process" do
    process = create(:legislation_process, :empty,
                     result_publication_enabled: true,
                     result_publication_date: 1.day.ago,
                     end_date: Date.current - 1.day)

    visit summary_legislation_process_path(process)

    expect(page).to have_content "This process didn't have any participation phases"
  end

  scenario "empty phases" do
    process = create(:legislation_process, end_date: Date.current - 1.day)
    visit summary_legislation_process_path(process)

    expect(page).to have_content "Debate phase"
    expect(page).to have_content "No debates"
    expect(page).to have_content "There aren't any questions"

    expect(page).to have_content "Proposals phase"
    expect(page).to have_content "No proposals"
    expect(page).to have_content "There are no proposals"

    expect(page).to have_content "Comments phase"
    expect(page).to have_content "No comments"
    expect(page).to have_content "There are no comments"
  end

  context "only debates exist" do
    let(:process) { create(:legislation_process, end_date: Date.current - 1.day) }
    let(:user) { create(:user, :level_two) }

    before do
      create(:legislation_question, process: process, title: "Question 1") do |question|
        create(:comment, user: user, commentable: question, body: "Answer 1")
        create(:comment, user: user, commentable: question, body: "Answer 2")
      end

      create(:legislation_question, process: process, title: "Question 2") do |question|
        create(:comment, user: user, commentable: question, body: "Answer 3")
        create(:comment, user: user, commentable: question, body: "Answer 4")
      end
    end

    scenario "shows debates list" do
      visit summary_legislation_process_path(process)

      expect(page).to have_content "Debate phase"
      expect(page).to have_content "2 debates"
      expect(page).to have_link "Question 1"
      expect(page).to have_content "Answer 1"
      expect(page).to have_content "Answer 2"
      expect(page).to have_link "Question 2"
      expect(page).to have_content "Answer 3"
      expect(page).to have_content "Answer 4"

      expect(page).to have_content "Proposals phase"
      expect(page).to have_content "No proposals"
      expect(page).to have_content "There are no proposals"

      expect(page).to have_content "Comments phase"
      expect(page).to have_content "No comments"
      expect(page).to have_content "There are no comments"
    end
  end

  context "only proposals exist" do
    let(:process) { create(:legislation_process, end_date: Date.current - 1.day) }

    before do
      create(:legislation_proposal, legislation_process_id: process.id,
                                    title: "Legislation proposal 1", selected: true)
      create(:legislation_proposal, legislation_process_id: process.id,
                                    title: "Legislation proposal 2", selected: false)
      create(:legislation_proposal, legislation_process_id: process.id,
                                    title: "Legislation proposal 3", selected: true)
      create(:legislation_proposal, legislation_process_id: process.id,
                                    title: "Legislation proposal 4", selected: false)
    end

    scenario "shows proposals list" do
      visit summary_legislation_process_path(process)

      expect(page).to have_content "Debate phase"
      expect(page).to have_content "No debates"
      expect(page).to have_content "There aren't any questions"

      expect(page).to have_content "Proposals phase"
      expect(page).to have_content "2 proposals"
      expect(page).to have_link "Legislation proposal 1"
      expect(page).not_to have_content "Legislation proposal 2"
      expect(page).to have_link "Legislation proposal 3"
      expect(page).not_to have_content "Legislation proposal 4"

      expect(page).to have_content "Comments phase"
      expect(page).to have_content "No comments"
      expect(page).to have_content "There are no comments"
    end
  end

  context "only text comments exist" do
    let(:process) { create(:legislation_process, end_date: Date.current - 1.day) }

    before do
      user = create(:user, :level_two)
      draft_version_1 = create(:legislation_draft_version,
                               process: process,
                               title: "Version 1",
                               body: "Body of the first version",
                               status: "published")
      draft_version_2 = create(:legislation_draft_version,
                               process: process,
                               title: "Version 2",
                               body: "Body of the second version and that's it all of it",
                               status: "published")
      annotation0 = create(:legislation_annotation,
                           draft_version: draft_version_1, text: "my annotation123",
                           ranges: annotation_ranges(5, 10))
      annotation1 = create(:legislation_annotation,
                           draft_version: draft_version_2, text: "hola",
                           ranges: annotation_ranges(5, 10))
      annotation2 = create(:legislation_annotation,
                           draft_version: draft_version_2,
                           ranges: annotation_ranges(12, 19))

      create(:comment, user: user, commentable: annotation0, body: "Comment 0")
      create(:comment, user: user, commentable: annotation1, body: "Comment 1")
      create(:comment, user: user, commentable: annotation2, body: "Comment 2")
      create(:comment, user: user, commentable: annotation2, body: "Comment 3")
    end

    scenario "shows coments list" do
      visit summary_legislation_process_path(process)

      expect(page).to have_content "Debate phase"
      expect(page).to have_content "No debates"
      expect(page).to have_content "There aren't any questions"

      expect(page).to have_content "Proposals phase"
      expect(page).to have_content "No proposals"
      expect(page).to have_content "There are no proposals"

      expect(page).to have_content "Comments phase"
      expect(page).to have_content "Top comments"
      expect(page).not_to have_content "Comment 0"
      expect(page).to have_link "Comment 1"
      expect(page).to have_link "Comment 2"
      expect(page).to have_link "Comment 3"
    end

    scenario "excel download", :no_js do
      visit summary_legislation_process_path(process)
      click_link "Download summary"

      expect(page.response_headers["Content-Type"]).to match(/officedocument.spreadsheetml/)
    end
  end

  def annotation_ranges(start_offset, end_offset)
    [{ "start" => "/p[1]", "startOffset" => start_offset, "end" => "/p[1]", "endOffset" => end_offset }]
  end
end
