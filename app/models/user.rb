class User < ActiveRecord::Base
  include ActsAsParanoidAliases
  apply_simple_captcha
  devise :database_authenticatable, :registerable, :confirmable,
         :recoverable, :rememberable, :trackable, :validatable

  acts_as_voter
  acts_as_paranoid column: :hidden_at

  has_one :administrator
  has_one :moderator
  has_one :organization
  has_many :inappropiate_flags

  validates :username,   presence: true, unless: :organization?
  validates :official_level, inclusion: {in: 0..5}

  validates_associated :organization, message: false

  accepts_nested_attributes_for :organization

  scope :administrators, -> { joins(:administrators) }
  scope :moderators,     -> { joins(:moderator) }
  scope :organizations,  -> { joins(:organization) }
  scope :officials,      -> { where("official_level > 0") }

  def name
    organization? ? organization.name : username
  end

  def debate_votes(debates)
    voted = votes.for_debates.in(debates)
    voted.each_with_object({}) { |v, _| _[v.votable_id] = v.value }
  end

  def administrator?
    administrator.present?
  end

  def moderator?
    moderator.present?
  end

  def organization?
    organization.present?
  end

  def verified_organization?
    organization && organization.verified?
  end

  def official?
    official_level && official_level > 0
  end

  def add_official_position!(position, level)
    return if position.blank? || level.blank?
    update official_position: position, official_level: level.to_i
  end

  def remove_official_position!
    update official_position: nil, official_level: 0
  end

  def self.with_email(e)
    e.present? ? where(email: e) : none
  end

end
