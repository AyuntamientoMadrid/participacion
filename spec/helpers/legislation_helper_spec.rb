require "rails_helper"

describe LegislationHelper do
  let(:process) { build(:legislation_process) }

  it "is valid" do
    expect(process).to be_valid
  end

  describe "banner colors presence" do
    it "background and font color exist" do
      process = build(:legislation_process, background_color: "#944949", font_color: "#ffffff")
      expect(banner_color?(process)).to be true
    end

    it "background color exist and font color not exist" do
      process = build(:legislation_process, background_color: "#944949", font_color: "")
      expect(banner_color?(process)).to be false
    end

    it "background color not exist and font color exist" do
      process = build(:legislation_process, background_color: "", font_color: "#944949")
      expect(banner_color?(process)).to be false
    end

    it "background and font color not exist" do
      process = build(:legislation_process, background_color: "", font_color: "")
      expect(banner_color?(process)).to be false
    end
  end
end
