require "rails_helper"

describe Shared::BannerComponent do
  it "renders given a banner" do
    banner = create(:banner,
                    title: "Vote now!",
                    description: "Banner description",
                    target_url: "http://www.url.com",
                    post_started_at: (Date.current - 4.days),
                    post_ended_at: (Date.current + 10.days),
                    background_color: "#FF0000",
                    font_color: "#FFFFFF")

    render_inline Shared::BannerComponent.new(banner)

    expect(page.find(".banner")).to have_content "Vote now!"
    expect(page.find(".banner")).to have_content "Banner description"
    expect(page.find(".banner")[:style]).to eq("background-color:#FF0000;")
    expect(page.find("h2")[:style]).to eq("color:#FFFFFF;")
    expect(page.find("h3")[:style]).to eq("color:#FFFFFF;")
    expect(page).to have_link href: "http://www.url.com"
  end

  it "renders given a section" do
    create(:banner, web_sections: [WebSection.find_by!(name: "debates")], title: "Debate banner")
    create(:banner, web_sections: [WebSection.find_by!(name: "proposals")], title: "Proposal banner")

    render_inline Shared::BannerComponent.new("debates")

    expect(page.find(".banner")).to have_content "Debate banner"
    expect(page).not_to have_content "Proposal banner"
  end

  it "does not render an empty banner" do
    banner = build(:banner, title: "", description: "")

    render_inline Shared::BannerComponent.new(banner)

    expect(page).not_to be_rendered
  end

  context "several banners available in the same section" do
    before do
      create(:banner,
             web_sections: [WebSection.find_by!(name: "debates")],
             title: "First banner",
             description: "First description",
             target_url: "/first_target")

      create(:banner,
             web_sections: [WebSection.find_by!(name: "debates")],
             title: "Second banner",
             description: "Second description",
             target_url: "/second_target")
    end

    it "only renders one banner" do
      render_inline Shared::BannerComponent.new("debates")

      expect(page).to have_css ".banner", count: 1
    end

    it "consistently renders one banner" do
      render_inline Shared::BannerComponent.new("debates")

      if page.has_content?("First banner")
        expect(page).to have_content "First description"
        expect(page).to have_css "[href='/first_target']"
        expect(page).not_to have_content "Second banner"
      else
        expect(page).to have_content "Second description"
        expect(page).to have_css "[href='/second_target']"
      end
    end

    it "only renders active banners" do
      Banner.first.update!(post_ended_at: Date.current - 1.day)

      render_inline Shared::BannerComponent.new("debates")

      expect(page).to have_content "Second banner"
      expect(page).not_to have_content "First banner"
    end

    it "does not render anything with no active banners" do
      Banner.find_each { |banner| banner.update!(post_ended_at: Date.current - 1.day) }

      render_inline Shared::BannerComponent.new("debates")

      expect(page).not_to be_rendered
    end
  end

  it "does not render anything given nil" do
    render_inline Shared::BannerComponent.new(nil)

    expect(page).not_to be_rendered
  end
end
