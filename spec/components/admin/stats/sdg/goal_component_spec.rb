require "rails_helper"

describe Admin::Stats::SDG::GoalComponent do
  let(:component) { Admin::Stats::SDG::GoalComponent.new(goal: goal) }
  let(:goal) { SDG::Goal.sample }

  it "shows goal stats" do
    create_list(:poll, 2, sdg_goals: [goal])
    create_list(:proposal, 3, sdg_goals: [goal])
    create_list(:debate, 1, sdg_goals: [goal])
    past = create(:budget, name: "Past year budget")
    create_list(:budget_investment, 1, :winner, sdg_goals: [goal], price: 1000, budget: past)
    current = create(:budget, name: "Current budget")
    create_list(:budget_investment, 2, sdg_goals: [goal], price: 1000, budget: current)

    render_inline component

    expect(page).to have_text "Proposals 3", normalize_ws: true
    expect(page).to have_text "Polls 2", normalize_ws: true
    expect(page).to have_text "Debates 1", normalize_ws: true
    expect("Current budget").to appear_before("Past year budget")
    expect(page).to have_text "Investment projects sent 2", normalize_ws: true
    expect(page).to have_text "Winner investment projects 0", normalize_ws: true
    expect(page).to have_text "Approved amount $0", normalize_ws: true
    expect(page).to have_text "Investment projects sent 1", normalize_ws: true
    expect(page).to have_text "Winner investment projects 1", normalize_ws: true
    expect(page).to have_text "Approved amount $1,000", normalize_ws: true
  end
end
