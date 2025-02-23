module Admin::ProposalDashboardActionsHelper
  def active_human_readable(active)
    return t("admin.dashboard.actions.index.active") if active

    t("admin.dashboard.actions.index.inactive")
  end

  def default_actions
    %w[polls email poster]
  end
end
