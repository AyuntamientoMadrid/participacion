class Budgets::BudgetComponent < ApplicationComponent
  attr_reader :budget
  use_helpers :attached_background_css

  def initialize(budget)
    @budget = budget
  end

  private

    def html_attributes
      if budget.image.present?
        {
          class: "budget-header with-background-image",
          style: attached_background_css(polymorphic_path(budget.image.variant(:large)))
        }
      else
        { class: "budget-header" }
      end
    end
end
