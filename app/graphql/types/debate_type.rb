module Types
  class DebateType < Types::BaseObject
    field :cached_votes_down, Integer, null: true
    field :cached_votes_total, Integer, null: true
    field :cached_votes_up, Integer, null: true
    collection_field :comments, Types::CommentType, null: true
    field :comments_count, Integer, null: true
    field :confidence_score, Integer, null: true
    field :description, String, null: true
    field :hot_score, Integer, null: true
    field :id, ID, null: false
    field :public_author, Types::UserType, null: true
    field :public_created_at, String, null: true
    collection_field :tags, Types::TagType, null: true
    field :title, String, null: true
    collection_field :votes_for, Types::VoteType, null: true

    def tags
      object.tags.public_for_api
    end
  end
end
