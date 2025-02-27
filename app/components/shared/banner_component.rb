class Shared::BannerComponent < ApplicationComponent
  attr_reader :banner_or_section

  def initialize(banner_or_section)
    @banner_or_section = banner_or_section
  end

  def banner
    @banner ||= if banner_or_section.respond_to?(:sections)
                  banner_or_section
                else
                  Banner.in_section(banner_or_section).with_active.sample
                end
  end

  def render?
    banner && (banner.title.present? || banner.description.present?)
  end

  private

    def link
      link_to banner.target_url do
        tag.h2(banner.title, style: "color:#{banner.font_color}") +
          tag.h3(banner.description, style: "color:#{banner.font_color}")
      end
    end
end
