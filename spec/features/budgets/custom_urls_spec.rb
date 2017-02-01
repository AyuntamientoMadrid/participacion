require 'rails_helper'

feature 'Custom urls' do

  let(:budget)      { create(:budget,            name:  "Big Budget") }
  let(:group)       { create(:budget_group,      name:  "Health",               budget: budget) }
  let!(:heading1)   { create(:budget_heading,    name:  "More hospitals",       group:  group)  }
  let!(:heading2)   { create(:budget_heading,    name:  "More medical centers", group:  group)  }
  let!(:investment) { create(:budget_investment, title: "Pediatric's hospital", heading: heading1) }

  scenario "budgets" do
    visit budgets_path
    click_link "Presenta tu proyecto"

    expect(current_path).to eq("/presupuestos/big-budget")
  end

  scenario "groups" do
    visit budgets_path
    click_link "Presenta tu proyecto"
    click_link "Health"

    expect(current_path).to eq("/presupuestos/big-budget/health")
  end

  scenario "headings" do
    visit budgets_path
    click_link "Presenta tu proyecto"
    click_link "Health"
    click_link "More hospitals"

    expect(current_path).to eq("/presupuestos/big-budget/health/more-hospitals")
  end

  scenario "group with single heading" do
    heading2.destroy

    visit budgets_path
    click_link "Presenta tu proyecto"
    click_link "Health"

    expect(current_path).to eq("/presupuestos/big-budget/health/more-hospitals")
  end

  scenario "investments" do
    visit budgets_path
    click_link "Presenta tu proyecto"
    click_link "Health"
    click_link "More hospitals"
    click_link "Pediatric's hospital"

    expect(current_path).to eq("/presupuestos/big-budget/proyecto/#{investment.id}")
  end

end