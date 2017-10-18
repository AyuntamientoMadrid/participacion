module BudgetInvestmentsHelper

  def investments_minimal_view_path
    custom_budget_investments_path(id: @heading.group.to_param,
                                   heading_id: @heading.to_param,
                                   filter: @current_filter,
                                   view: investments_secondary_view)
  end

  def investments_default_view?
    @view == "default"
  end

  def investments_current_view
    @view
  end

  def investments_secondary_view
    investments_current_view == "default" ? "minimal" : "default"
  end

end