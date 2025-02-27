class Users::FollowingComponent < ApplicationComponent
  attr_reader :user, :follows

  def initialize(user, follows:)
    @user = user
    @follows = follows
  end

  private

    def followable_type_title(followable_type)
      t("activerecord.models.#{followable_type.underscore}.other")
    end

    def followable_icon(followable)
      { proposals: "Proposal", budget: "Budget::Investment" }.invert[followable]
    end

    def render_follow(follow)
      return if follow.followable.blank?

      followable = follow.followable
      partial = "#{followable_class_name(followable)}_follow"
      locals = { followable_class_name(followable).to_sym => followable }

      render partial, locals
    end

    def followable_class_name(followable)
      followable.class.to_s.parameterize(separator: "_")
    end
end
