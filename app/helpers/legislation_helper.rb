module LegislationHelper
  def format_date(date)
    l(date, format: "%d %b %Y") if date
  end

  def new_legislation_proposal_link_text(process)
    t("proposals.index.start_proposal")
  end

  def legislation_process_tabs(process)
    {
      "info" => edit_admin_legislation_process_path(process),
      "homepage" => edit_admin_legislation_process_homepage_path(process),
      "questions" => admin_legislation_process_questions_path(process),
      "proposals" => admin_legislation_process_proposals_path(process),
      "draft_versions" => admin_legislation_process_draft_versions_path(process),
      "milestones" => admin_legislation_process_milestones_path(process)
    }
  end

  def banner_color?(process)
    process.background_color.present? && process.font_color.present?
  end

  def css_for_process_header(process)
    if banner_color?(process)
      "background: #{process.background_color};color: #{process.font_color};"
    end
  end
end
