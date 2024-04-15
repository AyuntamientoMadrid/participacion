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

  private

    def banner_content
      tag.h2(link_to(banner.title, banner.target_url), style: "color:#{banner.font_color}") +
        tag.h3(banner.description, style: "color:#{banner.font_color}")
    end
end
