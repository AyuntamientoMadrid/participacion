class Budget
  class Ballot < ActiveRecord::Base
    belongs_to :user
    belongs_to :budget
    belongs_to :heading

    has_many :lines, dependent: :destroy
    has_many :investments, through: :lines
  end
end
