class Admin::BudgetsWizard::Headings::GroupSwitcherComponent < ApplicationComponent
  attr_reader :group
  use_helpers :link_list

  def initialize(group)
    @group = group
  end

  def render?
    other_groups.any?
  end

  private

    def budget
      group.budget
    end

    def other_groups
      @other_groups ||= budget.groups.sort_by_name - [group]
    end

    def headings_path(group)
      admin_budgets_wizard_budget_group_headings_path(budget, group)
    end

    def currently_showing_text
      sanitize(t("admin.budget_headings.group_switcher.currently_showing", group: group.name))
    end

    def link_to_group(group)
      link_to(link_to_group_text(group), headings_path(group))
    end

    def link_to_group_text(group)
      sanitize(t("admin.budget_headings.group_switcher.the_other_group", group: tag.strong(group.name)))
    end
end
