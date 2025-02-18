class User < ApplicationRecord
  devise :two_factor_authenticatable
  include Verification
  attribute :registering_from_web, default: false

  devise :registerable, :confirmable, :recoverable, :rememberable,
         :trackable, :validatable, :omniauthable, :password_expirable, :secure_validatable,
         authentication_keys: [:login]
  devise :lockable if Rails.application.config.devise_lockable

  devise :two_factor_authenticatable,
         :two_factor_backupable,
         otp_number_of_backup_codes: 10,
         otp_secret_encryption_key: ENV["DEVISE_OTP_ENCRYPTION_KEY"]

  # If you want to use backup codes
  #  serialize :otp_backup_codes, JSON

  acts_as_voter
  acts_as_paranoid column: :hidden_at
  include ActsAsParanoidAliases

  include Graphqlable

  has_one :administrator
  has_one :moderator
  has_one :valuator
  has_one :manager
  has_one :sdg_manager, class_name: "SDG::Manager", dependent: :destroy
  has_one :poll_officer, class_name: "Poll::Officer"
  has_one :organization
  has_one :lock
  has_many :flags
  has_many :identities, dependent: :destroy
  has_many :debates, -> { with_hidden }, foreign_key: :author_id, inverse_of: :author
  has_many :proposals, -> { with_hidden }, foreign_key: :author_id, inverse_of: :author
  has_many :activities
  has_many :budget_investments, -> { with_hidden },
           class_name: "Budget::Investment",
           foreign_key: :author_id,
           inverse_of: :author
  has_many :comments, -> { with_hidden }, inverse_of: :user
  has_many :failed_census_calls
  has_many :notifications
  has_many :direct_messages_sent,
           class_name: "DirectMessage",
           foreign_key: :sender_id,
           inverse_of: :sender
  has_many :direct_messages_received,
           class_name: "DirectMessage",
           foreign_key: :receiver_id,
           inverse_of: :receiver
  has_many :legislation_answers, class_name: "Legislation::Answer", dependent: :destroy, inverse_of: :user
  has_many :follows
  has_many :legislation_annotations,
           class_name: "Legislation::Annotation",
           foreign_key: :author_id,
           inverse_of: :author
  has_many :legislation_proposals,
           class_name: "Legislation::Proposal",
           foreign_key: :author_id,
           inverse_of: :author
  has_many :legislation_questions,
           class_name: "Legislation::Question",
           foreign_key: :author_id,
           inverse_of: :author
  has_many :polls, foreign_key: :author_id, inverse_of: :author
  has_many :poll_answers,
           class_name: "Poll::Answer",
           foreign_key: :author_id,
           inverse_of: :author
  has_many :poll_partial_results,
           class_name: "Poll::PartialResult",
           foreign_key: :author_id,
           inverse_of: :author
  has_many :poll_questions,
           class_name: "Poll::Question",
           foreign_key: :author_id,
           inverse_of: :author
  has_many :poll_recounts,
           class_name: "Poll::Recount",
           foreign_key: :author_id,
           inverse_of: :author
  has_many :related_contents, foreign_key: :author_id, inverse_of: :author, dependent: nil
  has_many :topics, foreign_key: :author_id, inverse_of: :author
  belongs_to :geozone

  validates :username, presence: true, if: :username_required?
  validates :username, uniqueness: { scope: :registering_with_oauth }, if: :username_required?
  validates :document_number, uniqueness: { scope: :document_type }, allow_nil: true

  validate :validate_username_length

  validates :official_level, inclusion: { in: 0..5 }
  validates :terms_of_service, acceptance: { allow_nil: false }, on: :create

  validates_associated :organization, message: false

  accepts_nested_attributes_for :organization, update_only: true

  attr_accessor :skip_password_validation, :use_redeemable_code, :login
  attr_accessor :otp_backup_codes
  attr_accessor :otp_plain_backup_codes

  scope :administrators, -> { joins(:administrator) }
  scope :moderators,     -> { joins(:moderator) }
  scope :organizations,  -> { joins(:organization) }
  scope :sdg_managers,   -> { joins(:sdg_manager) }
  scope :officials,      -> { where(official_level: 1..) }
  scope :male,           -> { where(gender: "male") }
  scope :female,         -> { where(gender: "female") }
  scope :newsletter,     -> { where(newsletter: true) }
  scope :for_render,     -> { includes(:organization) }
  scope :by_document,    ->(document_type, document_number) do
    where(document_type: document_type, document_number: document_number)
  end
  scope :email_digest,   -> { where(email_digest: true) }
  scope :erased,         -> { where.not(erased_at: nil) }
  scope :active,         -> { excluding(erased) }
  scope :public_for_api, -> { all }
  scope :by_authors,     ->(author_ids) { where(id: author_ids) }
  scope :by_comments,    ->(commentables) do
    joins(:comments).where("comments.commentable": commentables).distinct
  end
  scope :by_username_email_or_document_number, ->(search_string) do
    search = "%#{search_string.strip}%"
    where("username ILIKE ? OR email ILIKE ? OR document_number ILIKE ?", search, search, search)
  end
  scope :between_ages, ->(from, to, at_time: Time.current) do
    start_date = at_time - (to + 1).years + 1.day
    end_date = at_time - from.years

    where(date_of_birth: start_date.beginning_of_day..end_date.end_of_day)
  end

  before_validation :clean_document_number

  # Get the existing user by email if the provider gives us a verified email.
  def self.first_or_initialize_for_oauth(auth)
    oauth_email           = auth.info.email
    oauth_verified        = auth.info.verified || auth.info.verified_email || auth.info.email_verified
    oauth_email_confirmed = oauth_email.present? && oauth_verified
    oauth_user            = User.find_by(email: oauth_email) if oauth_email_confirmed

    oauth_user || User.new(
      username: auth.info.name || auth.uid,
      email: oauth_email,
      oauth_email: oauth_email,
      password: Devise.friendly_token[0, 20],
      terms_of_service: "1",
      confirmed_at: oauth_email_confirmed ? DateTime.current : nil
    )
  end

  def name
    organization? ? organization.name : username
  end

  def comment_flags(comments)
    comment_flags = flags.for_comments(comments)
    comment_flags.each_with_object({}) { |f, h| h[f.flaggable_id] = true }
  end

  def voted_in_group?(group)
    votes.where(votable: Budget::Investment.where(group: group)).exists?
  end

  def headings_voted_within_group(group)
    Budget::Heading.where(id: voted_investments.by_group(group).pluck(:heading_id))
  end

  def voted_investments
    Budget::Investment.where(id: votes.where(votable: Budget::Investment.all).pluck(:votable_id))
  end

  def administrator?
    administrator.present?
  end

  def moderator?
    moderator.present?
  end

  def valuator?
    valuator.present?
  end

  def manager?
    manager.present?
  end

  def sdg_manager?
    sdg_manager.present?
  end

  def poll_officer?
    poll_officer.present?
  end

  def organization?
    organization.present?
  end

  def verified_organization?
    organization&.verified?
  end

  def official?
    official_level && official_level > 0
  end

  def add_official_position!(position, level)
    return if position.blank? || level.blank?

    update! official_position: position, official_level: level.to_i
  end

  def remove_official_position!
    update! official_position: nil, official_level: 0
  end

  def has_official_email?
    domain = Setting["email_domain_for_officials"]
    email.present? && ((email.end_with? "@#{domain}") || (email.end_with? ".#{domain}"))
  end

  def display_official_position_badge?
    return true if official_level > 1

    official_position_badge? && official_level == 1
  end

  def block
    hide

    Debate.hide_all debate_ids
    Comment.hide_all comment_ids
    Legislation::Proposal.hide_all legislation_proposal_ids
    Proposal.hide_all proposal_ids
    Budget::Investment.hide_all budget_investment_ids
    ProposalNotification.hide_all ProposalNotification.where(author_id: id).ids
    remove_roles
  end

  def full_restore
    ActiveRecord::Base.transaction do
      Debate.restore_all debates.where(hidden_at: hidden_at..)
      Comment.restore_all comments.where(hidden_at: hidden_at..)
      Legislation::Proposal.restore_all legislation_proposals.only_hidden.where(hidden_at: hidden_at..)
      Proposal.restore_all proposals.where(hidden_at: hidden_at..)
      Budget::Investment.restore_all budget_investments.where(hidden_at: hidden_at..)
      ProposalNotification.restore_all(
        ProposalNotification.only_hidden.where(hidden_at: hidden_at..).where(author_id: id)
      )

      restore
    end
  end

  def erase(erase_reason = nil)
    update!(
      erased_at: Time.current,
      erase_reason: erase_reason,
      username: nil,
      email: nil,
      unconfirmed_email: nil,
      phone_number: nil,
      encrypted_password: "",
      confirmation_token: nil,
      reset_password_token: nil,
      email_verification_token: nil,
      confirmed_phone: nil,
      unconfirmed_phone: nil
    )
    identities.destroy_all
    remove_roles
  end

  def erased?
    erased_at.present?
  end

  def remove_roles
    administrator&.destroy!
    valuator&.destroy!
    moderator&.destroy!
    manager&.destroy!
    sdg_manager&.destroy!
  end

  def take_votes_if_erased_document(document_number, document_type)
    erased_user = User.erased.find_by(document_number: document_number,
                                      document_type: document_type)
    if erased_user.present?
      take_votes_from(erased_user)
      erased_user.update!(document_number: nil, document_type: nil)
    end
  end

  def take_votes_from(other_user)
    return if other_user.blank?

    with_lock do
      Poll::Voter.where(user_id: other_user.id).find_each do |poll_voter|
        if Poll::Voter.where(poll: poll_voter.poll, user_id: id).any?
          poll_voter.delete
        else
          poll_voter.update_column(:user_id, id)
        end
      end
    end

    Budget::Ballot.where(user_id: other_user.id).update_all(user_id: id)
    Vote.where("voter_id = ? AND voter_type = ?", other_user.id, "User").update_all(voter_id: id)
    data_log = "id: #{other_user.id} - #{Time.current.strftime("%Y-%m-%d %H:%M:%S")}"
    update!(former_users_data_log: "#{former_users_data_log} | #{data_log}")
  end

  def locked?
    Lock.find_or_create_by!(user: self).locked?
  end

  def self.search(term)
    return none if term.blank?

    search = term.strip
    where("email = ? OR username ILIKE ?", search, "%#{search}%")
  end

  def self.username_max_length
    @username_max_length ||= columns.find { |c| c.name == "username" }.limit || 60
  end

  def self.minimum_required_age
    (Setting["min_age_to_participate"] || 16).to_i
  end

  def show_welcome_screen?
    verification = Setting["feature.user.skip_verification"].present? ? true : unverified?
    sign_in_count == 1 && verification && !organization && !administrator?
  end

  def password_required?
    return false if skip_password_validation

    super
  end

  def username_required?
    !organization? && !erased?
  end

  def email_required?
    !erased? && (unverified? || registering_from_web)
  end

  def locale
    self[:locale] || Setting.default_locale.to_s
  end

  def confirmation_required?
    super && !registering_with_oauth
  end

  def send_oauth_confirmation_instructions
    if oauth_email != email || confirmed_at.nil?
      update(confirmed_at: nil)
      send_confirmation_instructions
    end
    update(oauth_email: nil) if oauth_email.present?
  end

  def name_and_email
    "#{name} (#{email})"
  end

  def age
    Age.in_years(date_of_birth)
  end

  def save_requiring_finish_signup
    begin
      self.registering_with_oauth = true
      save!(validate: false)
    # Devise puts unique constraints for the email the db, so we must detect & handle that
    rescue ActiveRecord::RecordNotUnique
      self.email = nil
      save!(validate: false)
    end
    true
  end

  def ability
    @ability ||= Ability.new(self)
  end
  delegate :can?, :cannot?, to: :ability

  def public_proposals
    public_activity? ? proposals : proposals.none
  end

  def public_debates
    public_activity? ? debates : debates.none
  end

  def public_comments
    public_activity? ? comments : comments.none
  end

  # overwritting of Devise method to allow login using email OR username
  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    login = conditions.delete(:login)
    where(conditions.to_hash).find_by(["lower(email) = ?", login.downcase]) ||
      where(conditions.to_hash).find_by(["username = ?", login])
  end

  def self.find_by_manager_login(manager_login)
    find_by(id: manager_login.split("_").last)
  end

  def interests
    followables = follows.map(&:followable)
    followables.compact.map { |followable| followable.tags.map(&:name) }.flatten.compact.uniq
  end

  def send_devise_notification(notification, *)
    devise_mailer.send(notification, self, *).deliver_later
  end

  def add_subscriptions_token
    update!(subscriptions_token: SecureRandom.base58(32)) if subscriptions_token.blank?
  end

  def self.password_complexity
    if Tenant.current_secrets.dig(:security, :password_complexity)
      { digit: 1, lower: 1, symbol: 0, upper: 1 }
    else
      { digit: 0, lower: 0, symbol: 0, upper: 0 }
    end
  end

  def self.maximum_attempts
    (Tenant.current_secrets.dig(:security, :lockable, :maximum_attempts) || 20).to_i
  end

  def self.unlock_in
    (Tenant.current_secrets.dig(:security, :lockable, :unlock_in) || 1).to_f.hours
  end

  def to_param
    "#{id}-#{slug}"
  end

  def slug
    username.to_s.parameterize
  end

  def otp_provisioning_uri(account, options = {})
    issuer = options[:issuer]
    secret = self.otp_secret
    "otpauth://totp/#{issuer}:#{account}?secret=#{secret}&issuer=#{issuer}"
  end

  def otp_qr_code
    issuer = Tenant.current_secrets.server_name.to_s #this needs changed to server name
    label = "#{issuer}:#{email}"
    uri = otp_provisioning_uri(label, issuer: issuer)
    RQRCode::QRCode.new(uri).as_png(size: 200).to_data_url
  end

  def requires_2fa?
    administrator?
  end

  def generate_otp_secret
    self.otp_secret = ROTP::Base32.random_base32
  end

  # Generate an OTP secret it it does not already exist
  def generate_two_factor_secret_if_missing!
    return unless otp_secret.nil?

    update!(otp_secret: User.generate_otp_secret)
  end

  def otp_two_factor_enabled?
    otp_required_for_login
  end

  # Ensure that the user is prompted for their OTP when they login
  def enable_two_factor!
    update!(otp_required_for_login: true)
  end

  # Disable the use of OTP-based two-factor.
  def disable_two_factor!
    update!(
      otp_required_for_login: false,
      otp_secret: nil,
      otp_backup_codes: nil
    )
  end

  # Determine if backup codes have been generated
  def two_factor_backup_codes_generated?
    otp_backup_codes.present?
  end

  def can_be_administrator?
    self.otp_required_for_login
  end   
  
  private

    def clean_document_number
      return if document_number.blank?

      self.document_number = document_number.gsub(/[^a-z0-9]+/i, "").upcase
    end

    def validate_username_length
      validator = ActiveModel::Validations::LengthValidator.new(
        attributes: :username,
        maximum: User.username_max_length
      )
      validator.validate(self)
    end
end
