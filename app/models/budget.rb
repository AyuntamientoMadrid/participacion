class Budget < ActiveRecord::Base

  include Sanitizable

  VALID_PHASES = %W{on_hold accepting selecting balloting finished}
  CURRENCY_SYMBOLS = %W{€ $ £ ¥}

  validates :name, presence: true
  validates :phase, inclusion: { in: VALID_PHASES }
  validates :currency_symbol, presence: true

  has_many :investments, dependent: :destroy
  has_many :ballots, dependent: :destroy
  has_many :groups, dependent: :destroy
  has_many :headings, through: :groups

  scope :open,      -> { where.not(phase: "finished") }
  scope :finished,  -> { where(phase: "finished") }
  scope :valuating, -> { where(valuating: true) }

  def on_hold?
    phase == "on_hold"
  end

  def accepting?
    phase == "accepting"
  end

  def selecting?
    phase == "selecting"
  end

  def balloting?
    phase == "balloting"
  end

  def finished?
    phase == "finished"
  end

  def heading_price(heading)
    heading_ids.include?(heading.id) ? heading.price : -1
  end
end

