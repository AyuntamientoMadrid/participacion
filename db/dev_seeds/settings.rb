section "Creating Settings" do
  Setting.reset_defaults

  {
    "facebook_handle": "CONSULDEMOCRACY",
    "feature.featured_proposals": "true",
    "feature.map": "true",
    "instagram_handle": "CONSULDEMOCRACY",
    "meta_description": "Citizen participation tool for an open, " \
                        "transparent and democratic government",
    "meta_keywords": "citizen participation, open government",
    "meta_title": "CONSUL DEMOCRACY",
    "proposal_code_prefix": "MAD",
    "proposal_notification_minimum_interval_in_days": 0,
    "telegram_handle": "CONSULDEMOCRACY",
    "twitter_handle": "@consuldemocracy_dev",
    "twitter_hashtag": "#consuldemocracy_dev",
    "votes_for_proposal_success": "100",
    "youtube_handle": "CONSULDEMOCRACY"
  }.each do |name, value|
    Setting[name] = value
  end
end
