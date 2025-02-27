class Milestones::ProgressBarsComponent < ApplicationComponent
  attr_reader :milestoneable

  def initialize(milestoneable)
    @milestoneable = milestoneable
  end

  def render?
    primary_progress_bar
  end

  private

    def primary_progress_bar
      milestoneable.primary_progress_bar
    end

    def secondary_progress_bars
      milestoneable.secondary_progress_bars
    end

    def progress_tag_for(progress_bar, label:)
      text = number_to_percentage(progress_bar.percentage, precision: 0)

      tag.div class: "progress",
              role: "progressbar",
              "aria-label": label,
              "aria-valuenow": progress_bar.percentage,
              "aria-valuetext": "#{progress_bar.percentage}%",
              "aria-valuemax": ProgressBar::RANGE.max,
              "aria-valuemin": "0",
              tabindex: "0" do
        tag.span(class: "progress-meter", style: "width: #{progress_bar.percentage}%;") +
          tag.p(text, class: "progress-meter-text")
      end
    end
end
