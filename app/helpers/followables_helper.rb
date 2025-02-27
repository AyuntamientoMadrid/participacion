module FollowablesHelper
  def find_or_build_follow(user, followable)
    Follow.find_or_initialize_by(user: user, followable: followable)
  end
end
