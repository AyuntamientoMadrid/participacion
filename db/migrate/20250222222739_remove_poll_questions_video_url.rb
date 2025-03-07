class RemovePollQuestionsVideoUrl < ActiveRecord::Migration[7.0]
  def change
    remove_column :poll_questions, :video_url, :string
  end
end
