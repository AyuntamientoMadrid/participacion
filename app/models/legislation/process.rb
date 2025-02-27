class Legislation::Process < ApplicationRecord
  include ActsAsParanoidAliases
  include Taggable
  include Milestoneable
  include Imageable
  include Documentable
  include SDG::Relatable
  include Searchable

  acts_as_paranoid column: :hidden_at
  acts_as_taggable_on :customs

  attribute :background_color, default: "#e7f2fc"
  attribute :font_color, default: "#222222"

  translates :title,              touch: true
  translates :summary,            touch: true
  translates :description,        touch: true
  translates :additional_info,    touch: true
  translates :milestones_summary, touch: true
  translates :homepage,           touch: true
  include Globalizable

  PHASES_AND_PUBLICATIONS = %i[homepage_phase draft_phase debate_phase allegations_phase
                               proposals_phase draft_publication result_publication].freeze

  CSS_HEX_COLOR = /\A#?(?:[A-F0-9]{3}){1,2}\z/i

  has_many :draft_versions, -> { order(:id) },
           foreign_key: "legislation_process_id",
           inverse_of: :process,
           dependent: :destroy
  has_one :final_draft_version, -> { where final_version: true, status: "published" },
          class_name: "Legislation::DraftVersion",
          foreign_key: "legislation_process_id",
          inverse_of: :process
  has_many :questions, -> { order(:id) },
           foreign_key: "legislation_process_id",
           inverse_of: :process,
           dependent: :destroy
  has_many :proposals, -> { order(:id) },
           foreign_key: "legislation_process_id",
           inverse_of: :process,
           dependent: :destroy

  validates_translation :title, presence: true
  validates :start_date, presence: true
  validates :end_date, presence: true
  validates :result_publication_date, presence: true, if: :result_publication_enabled?

  %i[draft debate proposals_phase allegations].each do |phase_name|
    enabled_attribute = :"#{phase_name.to_s.gsub("_phase", "")}_phase_enabled?"

    validates :"#{phase_name}_start_date", presence: true, if: enabled_attribute
    validates :"#{phase_name}_end_date", presence: true, if: enabled_attribute
  end

  validates :end_date,
            comparison: {
              greater_than_or_equal_to: :start_date,
              message: :invalid_date_range
            },
            allow_blank: true,
            if: -> { start_date }
  validates :debate_end_date,
            comparison: {
              greater_than_or_equal_to: :debate_start_date,
              message: :invalid_date_range
            },
            allow_blank: true,
            if: -> { debate_start_date }
  validates :draft_end_date,
            comparison: {
              greater_than_or_equal_to: :draft_start_date,
              message: :invalid_date_range
            },
            allow_blank: true,
            if: -> { draft_start_date }
  validates :allegations_end_date,
            comparison: {
              greater_than_or_equal_to: :allegations_start_date,
              message: :invalid_date_range
            },
            allow_blank: true,
            if: -> { allegations_start_date }

  validates :background_color, format: { allow_blank: true, with: ->(*) { CSS_HEX_COLOR }}
  validates :font_color, format: { allow_blank: true, with: ->(*) { CSS_HEX_COLOR }}

  class << self; undef :open; end
  scope :active, -> { where(end_date: Date.current..) }
  scope :open, -> { active.where(start_date: ..Date.current) }
  scope :past, -> { where(end_date: ...Date.current) }

  scope :published, -> { where(published: true) }

  def self.not_in_draft
    where("draft_phase_enabled = false or (draft_start_date IS NOT NULL and
           draft_end_date IS NOT NULL and (draft_start_date > ? or
           draft_end_date < ?))", Date.current, Date.current)
  end

  def homepage_phase
    Legislation::Process::Phase.new(start_date, end_date, homepage_enabled)
  end

  def draft_phase
    Legislation::Process::Phase.new(draft_start_date, draft_end_date, draft_phase_enabled)
  end

  def debate_phase
    Legislation::Process::Phase.new(debate_start_date, debate_end_date, debate_phase_enabled)
  end

  def allegations_phase
    Legislation::Process::Phase.new(allegations_start_date,
                                    allegations_end_date, allegations_phase_enabled)
  end

  def proposals_phase
    Legislation::Process::Phase.new(proposals_phase_start_date,
                                    proposals_phase_end_date, proposals_phase_enabled)
  end

  def draft_publication
    Legislation::Process::Publication.new(draft_publication_date, draft_publication_enabled)
  end

  def result_publication
    Legislation::Process::Publication.new(result_publication_date, result_publication_enabled)
  end

  def enabled_phases?
    PHASES_AND_PUBLICATIONS.any? { |process| send(process).enabled? }
  end

  def enabled_phases_and_publications_count
    PHASES_AND_PUBLICATIONS.count { |process| send(process).enabled? }
  end

  def total_comments
    questions.sum(:comments_count) + draft_versions.sum(&:total_comments)
  end

  def status
    today = Date.current

    if today < start_date
      :planned
    elsif end_date < today
      :closed
    else
      :open
    end
  end

  def searchable_translations_definitions
    {
      title => "A",
      summary => "C",
      description => "D"
    }
  end

  def searchable_values
    searchable_globalized_values
  end

  def self.search(terms)
    pg_search(terms)
  end
end
