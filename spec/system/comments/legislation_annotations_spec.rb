require "rails_helper"

describe "Commenting legislation annotations" do
  let(:user) { create(:user) }
  let(:annotation) { create(:legislation_annotation, author: user) }

  describe "Merged comment threads" do
    let!(:draft_version) { create(:legislation_draft_version, :published) }
    let!(:annotation1) do
      create(:legislation_annotation,
             draft_version: draft_version,
             text: "my annotation",
             ranges: [{ "start" => "/p[1]", "startOffset" => 1, "end" => "/p[1]", "endOffset" => 5 }])
    end
    let!(:annotation2) do
      create(:legislation_annotation,
             draft_version: draft_version,
             text: "my other annotation",
             ranges: [{ "start" => "/p[1]", "startOffset" => 1, "end" => "/p[1]", "endOffset" => 10 }])
    end
    let!(:comment1) { annotation1.comments.first }
    let!(:comment2) { annotation2.comments.first }

    before do
      login_as user

      visit legislation_process_draft_version_path(draft_version.process, draft_version)

      expect(page).to have_css ".annotator-hl"
      first(:css, ".annotator-hl").click

      within(".comment-box") do
        expect(page).to have_content "my annotation"
        expect(page).to have_content "my other annotation"
      end
    end

    scenario "View comments of annotations in an included range" do
      within("#annotation-link") do
        find(".icon-expand").click
      end

      expect(page).to have_content "Comments about"
      expect(page).to have_css ".comment", count: 2
      expect(page).to have_content "my annotation"
      expect(page).to have_content "my other annotation"
    end

    scenario "Reply on a single annotation thread and display it in the merged annotation thread" do
      within(".comment-box #annotation-#{annotation1.id}-comments") do
        first(:link, "0 replies").click
      end

      click_link "Reply"

      within "#js-comment-form-comment_#{comment1.id}" do
        fill_in "Leave your comment", with: "replying in single annotation thread"
        click_button "Publish reply"
      end

      within "#comment_#{comment1.id}" do
        expect(page).to have_content "replying in single annotation thread"
      end

      visit legislation_process_draft_version_path(draft_version.process, draft_version)

      expect(page).to have_css ".annotator-hl"
      first(:css, ".annotator-hl").click

      within(".comment-box") do
        expect(page).to have_content "my annotation"
        expect(page).to have_content "my other annotation"
      end

      within("#annotation-link") do
        find(".icon-expand").click
      end

      expect(page).to have_css(".comment", count: 3)
      expect(page).to have_content("my annotation")
      expect(page).to have_content("my other annotation")
      expect(page).to have_content("replying in single annotation thread")
    end

    scenario "Reply on a multiple annotation thread and display it in the single annotation thread" do
      within("#annotation-link") do
        find(".icon-expand").click
      end

      within("#comment_#{comment2.id}") do
        click_link "Reply"
      end

      within "#js-comment-form-comment_#{comment2.id}" do
        fill_in "Leave your comment", with: "replying in multiple annotation thread"
        click_button "Publish reply"
      end

      within "#comment_#{comment2.id}" do
        expect(page).to have_content "replying in multiple annotation thread"
      end

      visit legislation_process_draft_version_path(draft_version.process, draft_version)

      expect(page).to have_css ".annotator-hl"
      first(:css, ".annotator-hl").click

      within(".comment-box #annotation-#{annotation2.id}-comments") do
        first(:link, "1 reply").click
      end

      expect(page).to have_css(".comment", count: 2)
      expect(page).to have_content("my other annotation")
      expect(page).to have_content("replying in multiple annotation thread")
    end
  end
end
