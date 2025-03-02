class Admin::BudgetInvestments::InvestmentsComponent < ApplicationComponent
  attr_reader :budget, :investments
  use_helpers :set_direction, :set_sorting_icon

  def initialize(budget, investments)
    @budget = budget
    @investments = investments
  end

  private

    def csv_params
      csv_params = params.clone.merge(format: :csv)
      csv_params = csv_params.to_unsafe_h.transform_keys(&:to_sym)
      csv_params.delete(:page)
      csv_params
    end

    def link_to_investments_sorted_by(column)
      direction = set_direction(params[:direction])
      icon = set_sorting_icon(direction, column)

      translation = t("admin.budget_investments.index.list.#{column}")

      link_to(
        safe_join([translation, tag.span(class: "icon-sortable #{icon}")]),
        admin_budget_budget_investments_path(sort_by: column, direction: direction)
      )
    end

    def cookie
      "investments-columns-#{budget.current_phase.kind}"
    end

    def default_columns
      base_columns = ["id", "title", "geozone", "price", "selected", "incompatible"]
      if budget.selecting? || budget.valuating? || budget.publishing_prices?
        base_columns += ["supports"]
      end
      if budget.accepting? || budget.reviewing? || budget.selecting? ||
         budget.valuating? || budget.publishing_prices?
        base_columns += ["feasibility", "admin", "valuator", "valuation_finished", "visible_to_valuators"]
      end
      if budget.balloting? || budget.reviewing_ballots? || budget.finished?
        base_columns += ["ballot_lines_count"]
      end
      if budget.reviewing_ballots? || budget.finished?
        base_columns += ["winner"]
      end
      base_columns
    end
end
