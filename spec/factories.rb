FactoryGirl.define do

  factory :user do
    sequence(:username) { |n| "Manuela#{n}" }
    sequence(:email)    { |n| "manuela#{n}@madrid.es" }
    password            'judgmentday'
    terms_of_service     '1'
    confirmed_at        { Time.now }

    trait :level_two do
      residence_verified_at Time.now
      confirmed_phone "611111111"
      document_number "12345678Z"
    end

    trait :level_three do
      verified_at Time.now
      document_number "12345678Z"
    end

    trait :hidden do
      hidden_at Time.now
    end

    trait :with_confirmed_hide do
      confirmed_hide_at Time.now
    end
  end

  factory :identity do
    user nil
    provider "Twitter"
    uid "MyString"
  end

  factory :verification_residence, class: Verification::Residence do
    user
    document_number  '12345678Z'
    document_type    1
    date_of_birth    Date.new(1980, 12, 31)
    postal_code      "28013"
    terms_of_service '1'

    trait :invalid do
      postal_code "12345"
    end
  end

  factory :verification_sms, class: Verification::Sms do
    phone "699999999"
  end

  factory :verification_letter, class: Verification::Letter do
    user
    address
  end

  factory :lock do
    user
    tries 0
    locked_until Time.now
  end

  factory :address do
    street_type   "Calle"
    street        "Alcalá"
    number        "1"
  end

  factory :verified_user do
    document_number  '12345678Z'
    document_type    'dni'
  end

  factory :debate do
    sequence(:title)     { |n| "Debate #{n} title" }
    description          'Debate description'
    terms_of_service     '1'
    association :author, factory: :user

    trait :hidden do
      hidden_at Time.now
    end

    trait :with_ignored_flag do
      ignored_flag_at Time.now
    end

    trait :with_confirmed_hide do
      confirmed_hide_at Time.now
    end

    trait :flagged do
      after :create do |debate|
        Flag.flag(FactoryGirl.create(:user), debate)
      end
    end

    trait :with_hot_score do
      before(:save) { |d| d.calculate_hot_score }
    end

    trait :with_confidence_score do
      before(:save) { |d| d.calculate_confidence_score }
    end

    trait :conflictive do
      after :create do |debate|
        Flag.flag(FactoryGirl.create(:user), debate)
        4.times { create(:vote, votable: debate) }
      end
    end
  end

  factory :proposal do
    sequence(:title)     { |n| "Proposal #{n} title" }
    summary              'In summary, what we want is...'
    description          'Proposal description'
    question             'Proposal question'
    external_url         'http://external_documention.es'
    responsible_name     'John Snow'
    terms_of_service     '1'
    association :author, factory: :user

    trait :hidden do
      hidden_at Time.now
    end

    trait :with_ignored_flag do
      ignored_flag_at Time.now
    end

    trait :with_confirmed_hide do
      confirmed_hide_at Time.now
    end

    trait :flagged do
      after :create do |debate|
        Flag.flag(FactoryGirl.create(:user), debate)
      end
    end

    trait :with_hot_score do
      before(:save) { |d| d.calculate_hot_score }
    end

    trait :with_confidence_score do
      before(:save) { |d| d.calculate_confidence_score }
    end

    trait :conflictive do
      after :create do |debate|
        Flag.flag(FactoryGirl.create(:user), debate)
        4.times { create(:vote, votable: debate) }
      end
    end
  end

  factory :vote do
    association :votable, factory: :debate
    association :voter,   factory: :user
    vote_flag true
    after(:create) do |vote, _|
      vote.votable.update_cached_votes
    end
  end

  factory :flag do
    association :flaggable, factory: :debate
    association :user, factory: :user
  end

  factory :comment do
    association :commentable, factory: :debate
    user
    body 'Comment body'

    trait :hidden do
      hidden_at Time.now
    end

    trait :with_ignored_flag do
      ignored_flag_at Time.now
    end

    trait :with_confirmed_hide do
      confirmed_hide_at Time.now
    end

    trait :flagged do
      after :create do |debate|
        Flag.flag(FactoryGirl.create(:user), debate)
      end
    end
  end

  factory :administrator do
    user
  end

  factory :moderator do
    user
  end

  factory :organization do
    user
    responsible_name "Johnny Utah"
    sequence(:name) { |n| "org#{n}" }

    trait :verified do
      verified_at Time.now
    end

    trait :rejected do
      rejected_at Time.now
    end
  end

  factory :tag, class: 'ActsAsTaggableOn::Tag' do
    sequence(:name) { |n| "Tag #{n} name" }

    trait :featured do
      featured true
    end

    trait :unfeatured do
      featured false
    end
  end

  factory :setting do
    sequence(:key) { |n| "Setting Key #{n}" }
    sequence(:value) { |n| "Setting #{n} Value" }
  end

  factory :ahoy_event, :class => Ahoy::Event do
    id { SecureRandom.uuid }
    time DateTime.now
    sequence(:name) {|n| "Event #{n} type"}
  end

  factory :visit  do
    id { SecureRandom.uuid }
    started_at DateTime.now
  end

  factory :activity do
    association :user, factory: :user
    association :trackable, factory: :comment
  end

end
