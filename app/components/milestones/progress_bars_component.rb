class Milestones::ProgressBarsComponent < ApplicationComponent
  attr_reader :milestoneable

  def initialize(milestoneable)
    @milestoneable = milestoneable
  end

  def render?
    milestoneable.primary_progress_bar
  end

  private

    def progress_tag_for(progress_bar)
      text = number_to_percentage(progress_bar.percentage, precision: 0)

      tag.div class: "progress",
              role: "progressbar",
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
