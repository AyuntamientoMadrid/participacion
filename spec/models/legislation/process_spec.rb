require "rails_helper"

describe Legislation::Process do
  let(:process) { create(:legislation_process) }

  it_behaves_like "acts as paranoid", :legislation_process
  it_behaves_like "globalizable", :legislation_process

  it "is valid" do
    expect(process).to be_valid
  end

  it "dynamically validates the color format" do
    stub_const("#{Legislation::Process}::CSS_HEX_COLOR", /[G-H]{2}/)

    expect(build(:legislation_process, font_color: "GG", background_color: "GH")).to be_valid
    expect(build(:legislation_process, font_color: "#ff0", background_color: "#00f")).not_to be_valid
  end

  it "assigns default values to new processes" do
    process = Legislation::Process.new

    expect(process.background_color).to be_present
    expect(process.font_color).to be_present
  end

  describe "dates validations" do
    it "is invalid if draft is enabled but draft_start_date is not present" do
      process = build(:legislation_process, draft_phase_enabled: true, draft_start_date: nil)

      expect(process).not_to be_valid
      expect(process.errors.messages[:draft_start_date]).to include("can't be blank")
    end

    it "is invalid if draft is enabled but draft_end_date is not present" do
      process = build(:legislation_process, draft_phase_enabled: true, draft_end_date: "")

      expect(process).not_to be_valid
      expect(process.errors.messages[:draft_end_date]).to include("can't be blank")
    end

    it "is invalid if debate phase is enabled but debate_start_date is not present" do
      process = build(:legislation_process, debate_phase_enabled: true, debate_start_date: nil)

      expect(process).not_to be_valid
      expect(process.errors.messages[:debate_start_date]).to include("can't be blank")
    end

    it "is invalid if debate phase is enabled but debate_end_date is not present" do
      process = build(:legislation_process, debate_phase_enabled: true, debate_end_date: "")

      expect(process).not_to be_valid
      expect(process.errors.messages[:debate_end_date]).to include("can't be blank")
    end

    it "is invalid if proposals phase is enabled but proposals_phase_start_date is not present" do
      process = build(:legislation_process, proposals_phase_enabled: true, proposals_phase_start_date: nil)

      expect(process).not_to be_valid
      expect(process.errors.messages[:proposals_phase_start_date]).to include("can't be blank")
    end

    it "is invalid if proposals phase is enabled but proposals_phase_end_date is not present" do
      process = build(:legislation_process, proposals_phase_enabled: true, proposals_phase_end_date: "")

      expect(process).not_to be_valid
      expect(process.errors.messages[:proposals_phase_end_date]).to include("can't be blank")
    end

    it "is invalid if allegations phase is enabled but allegations_start_date is not present" do
      process = build(:legislation_process, allegations_phase_enabled: true,
                                            allegations_start_date: nil,)

      expect(process).not_to be_valid
      expect(process.errors.messages[:allegations_start_date]).to include("can't be blank")
    end

    it "is invalid if allegations phase is enabled but allegations_end_date is not present" do
      process = build(:legislation_process, allegations_phase_enabled: true, allegations_end_date: "")

      expect(process).not_to be_valid
      expect(process.errors.messages[:allegations_end_date]).to include("can't be blank")
    end

    it "is valid if start dates are missing and the phase is disabled" do
      draft_disabled = build(:legislation_process,
                             draft_phase_enabled: false,
                             draft_start_date: nil)

      debate_disabled = build(:legislation_process,
                              debate_phase_enabled: false,
                              debate_start_date: nil)

      proposals_disabled = build(:legislation_process,
                                 proposals_phase_enabled: false,
                                 proposals_phase_start_date: nil)

      allegations_disabled = build(:legislation_process,
                                   allegations_phase_enabled: false,
                                   allegations_start_date: nil)

      expect(draft_disabled).to be_valid
      expect(debate_disabled).to be_valid
      expect(proposals_disabled).to be_valid
      expect(allegations_disabled).to be_valid
    end

    it "is valid if end dates are missing and the phase is disabled" do
      draft_disabled = build(:legislation_process,
                             draft_phase_enabled: false,
                             draft_end_date: nil)

      debate_disabled = build(:legislation_process,
                              debate_phase_enabled: false,
                              debate_end_date: nil)

      proposals_disabled = build(:legislation_process,
                                 proposals_phase_enabled: false,
                                 proposals_phase_end_date: nil)

      allegations_disabled = build(:legislation_process,
                                   allegations_phase_enabled: false,
                                   allegations_end_date: nil)

      expect(draft_disabled).to be_valid
      expect(debate_disabled).to be_valid
      expect(proposals_disabled).to be_valid
      expect(allegations_disabled).to be_valid
    end

    it "is valid if start and end dates are missing and the phase is disabled" do
      draft_disabled = build(:legislation_process,
                             draft_phase_enabled: false,
                             draft_start_date: nil,
                             draft_end_date: nil)

      debate_disabled = build(:legislation_process,
                              debate_phase_enabled: false,
                              debate_start_date: nil,
                              debate_end_date: nil)

      proposals_disabled = build(:legislation_process,
                                 proposals_phase_enabled: false,
                                 proposals_phase_start_date: nil,
                                 proposals_phase_end_date: nil)

      allegations_disabled = build(:legislation_process,
                                   allegations_phase_enabled: false,
                                   allegations_start_date: nil,
                                   allegations_end_date: nil)

      expect(draft_disabled).to be_valid
      expect(debate_disabled).to be_valid
      expect(proposals_disabled).to be_valid
      expect(allegations_disabled).to be_valid
    end

    it "is invalid if result publication is enabled but result_publication_date is not present" do
      process = build(:legislation_process, result_publication_enabled: true, result_publication_date: "")

      expect(process).not_to be_valid
      expect(process.errors.messages[:result_publication_date]).to include("can't be blank")
    end

    it "is valid if result publication is enabled and result_publication_date is present" do
      process = build(:legislation_process,
                      result_publication_enabled: true,
                      result_publication_date: Date.tomorrow)

      expect(process).to be_valid
    end
  end

  describe "date ranges validations" do
    it "is invalid if end_date is before start_date" do
      process = build(:legislation_process, start_date: Date.current,
                                            end_date: Date.current - 1.day)
      expect(process).not_to be_valid
      expect(process.errors.messages[:end_date]).to include("must be on or after the start date")
    end

    it "is valid if end_date is the same as start_date" do
      process = build(:legislation_process, start_date: Date.current - 1.day,
                                            end_date: Date.current - 1.day)
      expect(process).to be_valid
    end

    it "is valid if debate_end_date is the same as debate_start_date" do
      process = build(:legislation_process, debate_start_date: Date.current - 1.day,
                                            debate_end_date: Date.current - 1.day)
      expect(process).to be_valid
    end

    it "is invalid if debate_end_date is before debate_start_date" do
      process = build(:legislation_process, debate_start_date: Date.current,
                                            debate_end_date: Date.current - 1.day)
      expect(process).not_to be_valid
      expect(process.errors.messages[:debate_end_date])
        .to include("must be on or after the debate start date")
    end

    it "is valid if draft_end_date is the same as draft_start_date" do
      process = build(:legislation_process, draft_start_date: Date.current - 1.day,
                                            draft_end_date: Date.current - 1.day)
      expect(process).to be_valid
    end

    it "is invalid if draft_end_date is before draft_start_date" do
      process = build(:legislation_process, draft_start_date: Date.current,
                                            draft_end_date: Date.current - 1.day)
      expect(process).not_to be_valid
      expect(process.errors.messages[:draft_end_date])
        .to include("must be on or after the draft start date")
    end

    it "is invalid if allegations_end_date is before allegations_start_date" do
      process = build(:legislation_process, allegations_start_date: Date.current,
                                            allegations_end_date: Date.current - 1.day)
      expect(process).not_to be_valid
      expect(process.errors.messages[:allegations_end_date])
        .to include("must be on or after the comments start date")
    end

    it "is valid if allegations_end_date is the same as allegations_start_date" do
      process = build(:legislation_process, allegations_start_date: Date.current - 1.day,
                                            allegations_end_date: Date.current - 1.day)
      expect(process).to be_valid
    end
  end

  describe "filter scopes" do
    describe "open and past filters" do
      let!(:process_1) do
        create(:legislation_process, start_date: Date.current - 2.days, end_date: Date.current + 1.day)
      end

      let!(:process_2) do
        create(:legislation_process, start_date: Date.current + 1.day, end_date: Date.current + 3.days)
      end

      let!(:process_3) do
        create(:legislation_process, start_date: Date.current - 4.days, end_date: Date.current - 3.days)
      end

      it "filters open" do
        open_processes = ::Legislation::Process.open

        expect(open_processes).to eq [process_1]
        expect(open_processes).not_to include [process_2]
      end

      it "filters past" do
        past_processes = ::Legislation::Process.past

        expect(past_processes).to eq [process_3]
      end
    end

    it "filters draft phase" do
      process_before_draft = create(
        :legislation_process,
        draft_start_date: Date.current - 3.days,
        draft_end_date: Date.current - 2.days
      )

      process_with_draft_disabled = create(
        :legislation_process,
        draft_start_date: Date.current - 2.days,
        draft_end_date: Date.current + 2.days,
        draft_phase_enabled: false
      )

      process_with_draft_enabled = create(
        :legislation_process,
        draft_start_date: Date.current - 2.days,
        draft_end_date: Date.current + 2.days,
        draft_phase_enabled: true
      )

      process_with_draft_only_today = create(
        :legislation_process,
        draft_start_date: Date.current,
        draft_end_date: Date.current,
        draft_phase_enabled: true
      )

      processes_not_in_draft = ::Legislation::Process.not_in_draft

      expect(processes_not_in_draft).to match_array [process_before_draft, process_with_draft_disabled]
      expect(processes_not_in_draft).not_to include(process_with_draft_enabled)
      expect(processes_not_in_draft).not_to include(process_with_draft_only_today)
    end
  end

  describe "#status" do
    it "detects planned phase" do
      process.update!(start_date: Date.current + 2.days)
      expect(process.status).to eq(:planned)
    end

    it "detects closed phase" do
      process.update!(end_date: Date.current - 2.days)
      expect(process.status).to eq(:closed)
    end

    it "detects open phase" do
      expect(process.status).to eq(:open)
    end
  end

  describe "Header colors" do
    it "valid format colors" do
      process1 = create(:legislation_process, background_color: "123", font_color: "#fff")
      process2 = create(:legislation_process, background_color: "#fff", font_color: "123")
      process3 = create(:legislation_process, background_color: "", font_color: "")
      process4 = create(:legislation_process, background_color: "#abf123", font_color: "fff123")
      expect(process1).to be_valid
      expect(process2).to be_valid
      expect(process3).to be_valid
      expect(process4).to be_valid
    end

    it "invalid format colors" do
      expect do
        create(:legislation_process, background_color: "#123ghi", font_color: "#fff")
      end.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Background color is invalid")

      expect do
        create(:legislation_process, background_color: "#fff", font_color: "ggg")
      end.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Font color is invalid")
    end
  end

  describe "milestone_tags" do
    context "without milestone_tags" do
      let(:process) { create(:legislation_process) }

      it "do not have milestone_tags" do
        expect(process.milestone_tag_list).to eq([])
        expect(process.milestone_tags).to eq([])
      end

      it "add a new milestone_tag" do
        process.milestone_tag_list = "tag1,tag2"

        expect(process.milestone_tag_list).to eq(["tag1", "tag2"])
      end
    end

    context "with milestone_tags" do
      let(:process) { create(:legislation_process, :with_milestone_tags) }

      it "has milestone_tags" do
        expect(process.reload.milestone_tag_list.count).to eq(1)
      end
    end
  end

  describe ".search" do
    let!(:traffic) do
      create(:legislation_process,
             title: "Traffic regulation",
             summary: "Lane structure",
             description: "From top to bottom")
    end

    let!(:animal_farm) do
      create(:legislation_process,
             title: "Hierarchy structure",
             summary: "Pigs at the top",
             description: "Napoleon in charge of the traffic")
    end

    it "returns only matching polls" do
      expect(Legislation::Process.search("lane")).to eq [traffic]
      expect(Legislation::Process.search("pigs")).to eq [animal_farm]
      expect(Legislation::Process.search("nothing here")).to be_empty
    end

    it "gives more weight to name" do
      expect(Legislation::Process.search("traffic")).to eq [traffic, animal_farm]
      expect(Legislation::Process.search("structure")).to eq [animal_farm, traffic]
    end

    it "gives more weight to summary than description" do
      expect(Legislation::Process.search("top")).to eq [animal_farm, traffic]
    end
  end
end
