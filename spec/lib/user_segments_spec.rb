require "rails_helper"

describe UserSegments do
  let(:user1) { create(:user) }
  let(:user2) { create(:user) }
  let(:user3) { create(:user) }

  describe ".segment_name" do
    it "returns a readable name of the segment" do
      expect(UserSegments.segment_name("all_users")).to eq "All users"
      expect(UserSegments.segment_name("administrators")).to eq "Administrators"
      expect(UserSegments.segment_name("proposal_authors")).to eq "Proposal authors"
    end

    it "accepts symbols as parameters" do
      expect(UserSegments.segment_name(:all_users)).to eq "All users"
    end

    it "returns nil for invalid segments" do
      expect(UserSegments.segment_name("invalid")).to be nil
    end

    context "with geozones in the database" do
      before do
        create(:geozone, name: "Lands and Borderlands")
        create(:geozone, name: "Lowlands and Highlands")
      end

      it "returns geozone names when the geozone exists" do
        expect(UserSegments.segment_name("lands_and_borderlands")).to eq "Lands and Borderlands"
        expect(UserSegments.segment_name("lowlands_and_highlands")).to eq "Lowlands and Highlands"
      end

      it "supports international alphabets" do
        create(:geozone, name: "Česká republika")
        create(:geozone, name: "България")
        create(:geozone, name: "日本")

        expect(UserSegments.segment_name("ceska_republika")).to eq "Česká republika"
        expect(UserSegments.segment_name("България")).to eq "България"
        expect(UserSegments.segment_name("日本")).to eq "日本"
      end

      it "returns regular segments when the geozone doesn't exist" do
        expect(UserSegments.segment_name("all_users")).to eq "All users"
      end

      it "returns nil for invalid segments" do
        expect(UserSegments.segment_name("invalid")).to be nil
      end
    end
  end

  describe ".valid_segment?" do
    it "returns true when the segment exists" do
      expect(UserSegments.valid_segment?("all_proposal_authors")).to be true
      expect(UserSegments.valid_segment?("investment_authors")).to be true
      expect(UserSegments.valid_segment?("feasible_and_undecided_investment_authors")).to be true
    end

    it "accepts symbols as parameters" do
      expect(UserSegments.valid_segment?(:selected_investment_authors)).to be true
      expect(UserSegments.valid_segment?(:winner_investment_authors)).to be true
      expect(UserSegments.valid_segment?(:not_supported_on_current_budget)).to be true
    end

    it "is falsey when the segment doesn't exist" do
      expect(UserSegments.valid_segment?("imaginary_segment")).to be_falsey
    end

    it "is falsey when nil is passed" do
      expect(UserSegments.valid_segment?(nil)).to be_falsey
    end

    context "with geozones in the database" do
      before do
        create(:geozone, name: "Lands and Borderlands")
        create(:geozone, name: "Lowlands and Highlands")
      end

      it "returns true when the geozone exists" do
        expect(UserSegments.valid_segment?("lands_and_borderlands")).to be true
        expect(UserSegments.valid_segment?("lowlands_and_highlands")).to be true
      end

      it "returns true when the segment exists" do
        expect(UserSegments.valid_segment?("all_users")).to be true
      end

      it "is falsey when the segment doesn't exist" do
        expect(UserSegments.valid_segment?("imaginary_segment")).to be_falsey
      end

      it "is falsey when nil is passed" do
        expect(UserSegments.valid_segment?(nil)).to be_falsey
      end
    end
  end

  describe ".all_users" do
    it "returns all active users enabled" do
      active_user = create(:user)
      erased_user = create(:user, erased_at: Time.current)

      expect(UserSegments.all_users).to eq [active_user]
      expect(UserSegments.all_users).not_to include erased_user
    end
  end

  describe ".administrators" do
    it "returns all active administrators users" do
      active_user = create(:user)
      active_admin = create(:administrator).user
      erased_user = create(:user, erased_at: Time.current)

      expect(UserSegments.administrators).to eq [active_admin]
      expect(UserSegments.administrators).not_to include active_user
      expect(UserSegments.administrators).not_to include erased_user
    end
  end

  describe ".all_proposal_authors" do
    it "returns users that have created a proposal even if is archived or retired" do
      create(:proposal, author: user1)
      create(:proposal, :archived, author: user2)
      create(:proposal, :retired, author: user3)

      all_proposal_authors = UserSegments.all_proposal_authors

      expect(all_proposal_authors).to match_array [user1, user2, user3]
    end

    it "does not return duplicated users" do
      create(:proposal, author: user1)
      create(:proposal, :archived, author: user1)
      create(:proposal, :retired, author: user1)

      all_proposal_authors = UserSegments.all_proposal_authors

      expect(all_proposal_authors).to eq [user1]
    end
  end

  describe ".proposal_authors" do
    it "returns users that have created a proposal" do
      create(:proposal, author: user1)

      proposal_authors = UserSegments.proposal_authors

      expect(proposal_authors).to eq [user1]
    end

    it "does not return duplicated users" do
      create(:proposal, author: user1)
      create(:proposal, author: user1)

      proposal_authors = UserSegments.proposal_authors
      expect(proposal_authors).to contain_exactly(user1)
    end
  end

  describe ".investment_authors" do
    it "returns users that have created a budget investment" do
      investment = create(:budget_investment, author: user1)
      budget = create(:budget)
      investment.update!(budget: budget)

      investment_authors = UserSegments.investment_authors

      expect(investment_authors).to eq [user1]
    end

    it "does not return duplicated users" do
      investment1 = create(:budget_investment, author: user1)
      investment2 = create(:budget_investment, author: user1)
      budget = create(:budget)
      investment1.update!(budget: budget)
      investment2.update!(budget: budget)

      investment_authors = UserSegments.investment_authors
      expect(investment_authors).to contain_exactly(user1)
    end
  end

  describe ".feasible_and_undecided_investment_authors" do
    it "returns authors of a feasible or an undecided budget investment" do
      user4 = create(:user)
      user5 = create(:user)
      user6 = create(:user)

      feasible_investment_finished = create(:budget_investment, :feasible, :finished, author: user1)
      undecided_investment_finished = create(:budget_investment, :undecided, :finished, author: user2)
      feasible_investment_unfinished = create(:budget_investment, :feasible, author: user3)
      undecided_investment_unfinished = create(:budget_investment, :undecided, author: user4)
      unfeasible_investment_unfinished = create(:budget_investment, :unfeasible, author: user5)
      unfeasible_investment_finished = create(:budget_investment, :unfeasible, :finished, author: user6)

      budget = create(:budget)
      feasible_investment_finished.update!(budget: budget)
      undecided_investment_finished.update!(budget: budget)
      feasible_investment_unfinished.update!(budget: budget)
      undecided_investment_unfinished.update!(budget: budget)
      unfeasible_investment_unfinished.update!(budget: budget)
      unfeasible_investment_finished.update!(budget: budget)

      investment_authors = UserSegments.feasible_and_undecided_investment_authors
      expect(investment_authors).to match_array [user1, user2, user3, user4, user5]
      expect(investment_authors).not_to include user6
    end

    it "does not return duplicated users" do
      feasible_investment = create(:budget_investment, :feasible, author: user1)
      undecided_investment = create(:budget_investment, :undecided, author: user1)
      budget = create(:budget)
      feasible_investment.update!(budget: budget)
      undecided_investment.update!(budget: budget)

      investment_authors = UserSegments.feasible_and_undecided_investment_authors
      expect(investment_authors).to contain_exactly(user1)
    end
  end

  describe ".selected_investment_authors" do
    it "returns authors of selected budget investments" do
      selected_investment = create(:budget_investment, :selected, author: user1)
      unselected_investment = create(:budget_investment, :unselected, author: user2)
      budget = create(:budget)
      selected_investment.update!(budget: budget)
      unselected_investment.update!(budget: budget)

      investment_authors = UserSegments.selected_investment_authors

      expect(investment_authors).to eq [user1]
    end

    it "does not return duplicated users" do
      selected_investment1 = create(:budget_investment, :selected, author: user1)
      selected_investment2 = create(:budget_investment, :selected, author: user1)
      budget = create(:budget)
      selected_investment1.update!(budget: budget)
      selected_investment2.update!(budget: budget)

      investment_authors = UserSegments.selected_investment_authors
      expect(investment_authors).to contain_exactly(user1)
    end
  end

  describe ".winner_investment_authors" do
    it "returns authors of winner budget investments" do
      winner_investment = create(:budget_investment, :winner, author: user1)
      selected_investment = create(:budget_investment, :selected, author: user2)
      budget = create(:budget)
      winner_investment.update!(budget: budget)
      selected_investment.update!(budget: budget)

      investment_authors = UserSegments.winner_investment_authors

      expect(investment_authors).to eq [user1]
    end

    it "does not return duplicated users" do
      winner_investment1 = create(:budget_investment, :winner, author: user1)
      winner_investment2 = create(:budget_investment, :winner, author: user1)
      budget = create(:budget)
      winner_investment1.update!(budget: budget)
      winner_investment2.update!(budget: budget)

      investment_authors = UserSegments.winner_investment_authors
      expect(investment_authors).to contain_exactly(user1)
    end
  end

  describe ".current_budget_investments" do
    it "only returns investments from the current budget" do
      investment1 = create(:budget_investment, author: create(:user))
      investment2 = create(:budget_investment, author: create(:user))
      budget = create(:budget)
      investment1.update!(budget: budget)

      current_budget_investments = UserSegments.current_budget_investments

      expect(current_budget_investments).to eq [investment1]
      expect(current_budget_investments).not_to include investment2
    end
  end

  describe ".not_supported_on_current_budget" do
    it "only returns users that haven't supported investments on current budget" do
      investment1 = create(:budget_investment)
      investment2 = create(:budget_investment)
      budget = create(:budget)
      investment1.vote_by(voter: user1, vote: "yes")
      investment2.vote_by(voter: user2, vote: "yes")
      investment1.update!(budget: budget)
      investment2.update!(budget: budget)

      not_supported_on_current_budget = UserSegments.not_supported_on_current_budget
      expect(not_supported_on_current_budget).to include user3
      expect(not_supported_on_current_budget).not_to include user1
      expect(not_supported_on_current_budget).not_to include user2
    end
  end

  describe ".recipients" do
    it "does not return any recipients when given an invalid segment" do
      create(:user, email: "first@email.com")

      recipients = UserSegments.recipients(:invalid_segment)

      expect(recipients).to eq []
    end

    it "does not return any recipients when given a method name as a segment" do
      create(:user, email: "first@email.com")

      recipients = UserSegments.recipients(:ancestors)

      expect(recipients).to eq []
    end
  end

  describe ".user_segment_emails" do
    it "returns list of emails sorted by user creation date" do
      create(:user, email: "first@email.com", created_at: 1.day.ago)
      create(:user, email: "last@email.com")

      emails = UserSegments.user_segment_emails(:all_users)
      expect(emails).to eq ["first@email.com", "last@email.com"]
    end

    it "returns an empty list when given an invalid segment" do
      create(:user, email: "first@email.com")

      emails = UserSegments.user_segment_emails(:invalid_segment)

      expect(emails).to eq []
    end
  end

  context "Geozones" do
    let!(:new_york) { create(:geozone, name: "New York") }
    let!(:california) { create(:geozone, name: "California") }
    let!(:user1) { create(:user, geozone: new_york) }
    let!(:user2) { create(:user, geozone: new_york) }
    let!(:user3) { create(:user, geozone: california) }

    before do
      create(:geozone, name: "Mars")
      create(:user, geozone: nil)
    end

    it "includes geozones in available segments" do
      expect(UserSegments.segments).to include("new_york")
      expect(UserSegments.segments).to include("california")
      expect(UserSegments.segments).to include("mars")
      expect(UserSegments.segments).not_to include("jupiter")
    end

    it "returns users of a geozone" do
      expect(UserSegments.recipients("new_york")).to match_array [user1, user2]
      expect(UserSegments.recipients("california")).to eq [user3]
    end

    it "accepts symbols as parameters" do
      expect(UserSegments.recipients(:new_york)).to match_array [user1, user2]
      expect(UserSegments.recipients(:california)).to eq [user3]
    end

    it "only returns active users of a geozone" do
      user2.update!(erased_at: Time.current)

      expect(UserSegments.recipients("new_york")).to eq [user1]
    end
  end
end
