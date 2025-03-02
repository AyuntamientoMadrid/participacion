require "rails_helper"

describe Admin::BudgetInvestmentsController, :admin do
  describe "GET index" do
    it "raises an exception when the feature is disabled" do
      Setting["process.budgets"] = false

      expect do
        get :index, params: { budget_id: create(:budget).id }
      end.to raise_exception(FeatureFlags::FeatureDisabled)
    end

    it "raises an error if budget slug is not found" do
      expect do
        get :index, params: { budget_id: "wrong_budget" }
      end.to raise_error ActiveRecord::RecordNotFound
    end

    it "raises an error if budget id is not found" do
      expect do
        get :index, params: { budget_id: 0 }
      end.to raise_error ActiveRecord::RecordNotFound
    end
  end

  describe "PATCH show_to_valuators" do
    let(:investment) { create(:budget_investment, :invisible_to_valuators) }

    it "marks the investment as visible to valuators" do
      expect do
        patch :show_to_valuators, xhr: true, params: { id: investment, budget_id: investment.budget }
      end.to change { investment.reload.visible_to_valuators? }.from(false).to(true)

      expect(response).to be_successful
    end

    it "does not modify investments visible to valuators" do
      investment.update!(visible_to_valuators: true)

      expect do
        patch :show_to_valuators, xhr: true, params: { id: investment, budget_id: investment.budget }
      end.not_to change { investment.reload.visible_to_valuators? }
    end

    it "redirects admins without JavaScript to the same page" do
      request.env["HTTP_REFERER"] = admin_budget_budget_investments_path(investment.budget)

      patch :show_to_valuators, params: { id: investment, budget_id: investment.budget }

      expect(response).to redirect_to admin_budget_budget_investments_path(investment.budget)
      expect(flash[:notice]).to eq "Investment project updated successfully."
    end
  end

  describe "PATCH hide_from_valuators" do
    let(:investment) { create(:budget_investment, :visible_to_valuators) }

    it "marks the investment as visible to valuators" do
      expect do
        patch :hide_from_valuators, xhr: true, params: { id: investment, budget_id: investment.budget }
      end.to change { investment.reload.visible_to_valuators? }.from(true).to(false)

      expect(response).to be_successful
    end

    it "does not modify investments visible to valuators" do
      investment.update!(visible_to_valuators: false)

      expect do
        patch :hide_from_valuators, xhr: true, params: { id: investment, budget_id: investment.budget }
      end.not_to change { investment.reload.visible_to_valuators? }
    end

    it "redirects admins without JavaScript to the same page" do
      request.env["HTTP_REFERER"] = admin_budget_budget_investments_path(investment.budget)

      patch :hide_from_valuators, params: { id: investment, budget_id: investment.budget }

      expect(response).to redirect_to admin_budget_budget_investments_path(investment.budget)
      expect(flash[:notice]).to eq "Investment project updated successfully."
    end
  end

  describe "PATCH mark_as_winner" do
    let(:budget) { create(:budget, :reviewing_ballots) }
    let(:investment) { create(:budget_investment, :feasible, :valuation_finished, budget: budget) }

    it "marks the investment as winner" do
      expect do
        patch :mark_as_winner, xhr: true, params: { id: investment, budget_id: investment.budget }
      end.to change { investment.reload.winner? }.from(false).to(true)

      expect(response).to be_successful
    end

    it "does not modify investments that are already winners" do
      investment.update!(winner: true)

      expect do
        patch :mark_as_winner, xhr: true, params: { id: investment, budget_id: investment.budget }
      end.not_to change { investment.reload.winner? }
    end

    it "redirects admins without JavaScript to the same page" do
      request.env["HTTP_REFERER"] = admin_budget_budget_investments_path(investment.budget)

      patch :mark_as_winner, params: { id: investment, budget_id: investment.budget }

      expect(response).to redirect_to admin_budget_budget_investments_path(investment.budget)
      expect(flash[:notice]).to eq "Investment project updated successfully."
    end

    it "does not mark investments with unfinished valuation" do
      investment.update!(valuation_finished: false)

      expect do
        patch :mark_as_winner, xhr: true, params: { id: investment, budget_id: investment.budget }
      end.not_to change { investment.reload.winner? }

      expect(flash[:alert]).to eq(
        "You do not have permission to carry out the action 'mark_as_winner' on Investment."
      )
    end

    it "does not mark investments when the phase is not reviewing ballots" do
      %w[finished balloting informing accepting reviewing selecting valuating].each do |phase|
        budget.update!(phase: phase)

        expect do
          patch :mark_as_winner, xhr: true, params: { id: investment, budget_id: investment.budget }
        end.not_to change { investment.reload.winner? }

        expect(flash[:alert]).to eq(
          "You do not have permission to carry out the action 'mark_as_winner' on Investment."
        )
      end
    end
  end

  describe "PATCH unmark_as_winner" do
    let(:budget) { create(:budget, :reviewing_ballots) }
    let(:investment) { create(:budget_investment, :feasible, :valuation_finished, :winner, budget: budget) }

    it "unmarks the investment as winner" do
      expect do
        patch :unmark_as_winner, xhr: true, params: { id: investment, budget_id: investment.budget }
      end.to change { investment.reload.winner? }.from(true).to(false)

      expect(response).to be_successful
    end

    it "does not modify investments that are not winners" do
      investment.update!(winner: false)

      expect do
        patch :unmark_as_winner, xhr: true, params: { id: investment, budget_id: investment.budget }
      end.not_to change { investment.reload.winner? }
    end

    it "redirects admins without JavaScript to the same page" do
      request.env["HTTP_REFERER"] = admin_budget_budget_investments_path(investment.budget)

      patch :unmark_as_winner, params: { id: investment, budget_id: investment.budget }

      expect(response).to redirect_to admin_budget_budget_investments_path(investment.budget)
      expect(flash[:notice]).to eq "Investment project updated successfully."
    end
  end

  describe "PATCH select" do
    let(:investment) { create(:budget_investment, :feasible, :finished) }

    it "selects the investment" do
      expect do
        patch :select, xhr: true, params: { id: investment, budget_id: investment.budget }
      end.to change { investment.reload.selected? }.from(false).to(true)

      expect(response).to be_successful
    end

    it "does not modify already selected investments" do
      investment.update!(selected: true)

      expect do
        patch :select, xhr: true, params: { id: investment, budget_id: investment.budget }
      end.not_to change { investment.reload.selected? }
    end

    it "uses the select/deselect authorization rules" do
      investment.update!(valuation_finished: false)

      patch :select, xhr: true, params: { id: investment, budget_id: investment.budget }

      expect(flash[:alert]).to eq "You do not have permission to carry out the action " \
                                  "'select' on Investment."
      expect(investment).not_to be_selected
    end

    it "redirects admins without JavaScript to the same page" do
      request.env["HTTP_REFERER"] = admin_budget_budget_investments_path(investment.budget)

      patch :select, params: { id: investment, budget_id: investment.budget }

      expect(response).to redirect_to admin_budget_budget_investments_path(investment.budget)
      expect(flash[:notice]).to eq "Investment project updated successfully."
    end
  end

  describe "PATCH deselect" do
    let(:investment) { create(:budget_investment, :feasible, :finished, :selected) }

    it "deselects the investment" do
      expect do
        patch :deselect, xhr: true, params: { id: investment, budget_id: investment.budget }
      end.to change { investment.reload.selected? }.from(true).to(false)

      expect(response).to be_successful
    end

    it "does not modify non-selected investments" do
      investment.update!(selected: false)

      expect do
        patch :deselect, xhr: true, params: { id: investment, budget_id: investment.budget }
      end.not_to change { investment.reload.selected? }
    end

    it "uses the select/deselect authorization rules" do
      investment.update!(valuation_finished: false)

      patch :deselect, xhr: true, params: { id: investment, budget_id: investment.budget }

      expect(flash[:alert]).to eq "You do not have permission to carry out the action " \
                                  "'deselect' on Investment."
      expect(investment).to be_selected
    end

    it "redirects admins without JavaScript to the same page" do
      request.env["HTTP_REFERER"] = admin_budget_budget_investments_path(investment.budget)

      patch :deselect, params: { id: investment, budget_id: investment.budget }

      expect(response).to redirect_to admin_budget_budget_investments_path(investment.budget)
      expect(flash[:notice]).to eq "Investment project updated successfully."
    end
  end
end
