module WelcomeHelper
  def is_active_class(index)
    "is-active is-in" if index.zero?
  end

  def slide_display(index)
    "display: none;" if index.positive?
  end

  def render_recommendation_image(recommended, image_default)
    image_path = calculate_image_path(recommended, image_default)
    image_tag(image_path) if image_path.present?
  end

  def calculate_image_path(recommended, image_default)
    if recommended.respond_to?(:image) && recommended.image.present? &&
       recommended.image.attachment.attached?
      recommended.image.variant(:medium)
    elsif image_default.present?
      image_default
    end
  end

  def calculate_carousel_size(debates, proposals, apply_offset)
    offset = calculate_offset(debates, proposals, apply_offset)
    centered = calculate_centered(debates, proposals)
    "#{offset} #{centered}"
  end

  def calculate_centered(debates, proposals)
    if (debates.blank? && proposals.any?) ||
       (debates.any? && proposals.blank?)
      "medium-centered large-centered"
    end
  end

  def calculate_offset(debates, proposals, apply_offset)
    if debates.any? && proposals.any?
      if apply_offset
        "medium-offset-2 large-offset-2"
      else
        "end"
      end
    end
  end
end
