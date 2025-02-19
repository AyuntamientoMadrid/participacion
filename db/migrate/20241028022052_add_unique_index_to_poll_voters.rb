class AddUniqueIndexToPollVoters < ActiveRecord::Migration[7.0]
  def change
    add_index :poll_voters, [:user_id, :poll_id], unique: true
  end
end
