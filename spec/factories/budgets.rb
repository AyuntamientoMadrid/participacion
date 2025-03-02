FactoryBot.define do
  factory :budget do
    sequence(:name) { |n| "#{Faker::Lorem.word} #{n}" }
    currency_symbol { "€" }
    published { true }
    phase { "accepting" }
    description_drafting  { "This budget is drafting" }
    description_informing { "This budget is informing" }
    description_accepting { "This budget is accepting" }
    description_reviewing { "This budget is reviewing" }
    description_selecting { "This budget is selecting" }
    description_valuating { "This budget is valuating" }
    description_publishing_prices { "This budget is publishing prices" }
    description_balloting { "This budget is balloting" }
    description_reviewing_ballots { "This budget is reviewing ballots" }
    description_finished { "This budget is finished" }

    trait :drafting do
      published { false }
    end

    trait :informing do
      phase { "informing" }
    end

    trait :accepting do
      phase { "accepting" }
    end

    trait :reviewing do
      phase { "reviewing" }
    end

    trait :selecting do
      phase { "selecting" }
    end

    trait :valuating do
      phase { "valuating" }
    end

    trait :publishing_prices do
      phase { "publishing_prices" }
    end

    trait :balloting do
      phase { "balloting" }
    end

    trait :reviewing_ballots do
      phase { "reviewing_ballots" }
    end

    trait :finished do
      phase { "finished" }
      results_enabled { true }
      stats_enabled { true }
    end

    trait :knapsack do
      voting_style { "knapsack" }
    end

    trait :approval do
      voting_style { "approval" }
    end

    trait :with_image do
      after(:create) { |budget| create(:image, imageable: budget) }
    end

    trait :with_winner do
      after(:create) { |budget| create(:budget_investment, :winner, budget: budget) }
    end

    trait :hide_money do
      hide_money { true }
    end
  end

  factory :budget_group, class: "Budget::Group" do
    budget
    sequence(:name) { |n| "Group #{n}" }

    trait :drafting_budget do
      budget factory: [:budget, :drafting]
    end
  end

  factory :budget_heading, class: "Budget::Heading" do
    sequence(:name) { |n| "Heading #{n}" }
    price { 1000000 }
    population { 1234 }
    latitude { Setting["map.latitude"] }
    longitude { Setting["map.longitude"] }

    transient { budget { nil } }
    group { association :budget_group, budget: budget || association(:budget) }

    trait :drafting_budget do
      group factory: [:budget_group, :drafting_budget]
    end

    trait :with_investment_with_milestone do
      after(:create) do |heading|
        investment = create(:budget_investment, :winner, heading: heading)
        create(:milestone, milestoneable: investment)
      end
    end
  end

  factory :budget_investment, class: "Budget::Investment" do
    sequence(:title) { |n| "Budget Investment #{n} title" }
    heading { budget&.headings&.reload&.sample || association(:budget_heading, budget: budget) }

    author factory: :user
    description          { "Spend money on this" }
    price                { 10 }
    unfeasibility_explanation { "" }
    terms_of_service     { "1" }
    incompatible         { false }

    trait :with_confidence_score do
      before(:save, &:calculate_confidence_score)
    end

    trait :feasible do
      feasibility { "feasible" }
    end

    trait :unfeasible do
      feasibility { "unfeasible" }
      unfeasibility_explanation { "set to unfeasible on creation" }
    end

    trait :undecided do
      feasibility { "undecided" }
    end

    trait :finished do
      valuation_finished { true }
    end

    trait :open do
      valuation_finished { false }
    end

    trait :selected do
      selected { true }
      feasibility { "feasible" }
      valuation_finished { true }
    end

    trait :winner do
      selected
      winner { true }
    end

    trait :visible_to_valuators do
      visible_to_valuators { true }
    end

    trait :invisible_to_valuators do
      visible_to_valuators { false }
    end

    trait :incompatible do
      selected
      incompatible { true }
    end

    trait :selected_with_price do
      selected
      price { 1000 }
      price_explanation { "Because of reasons" }
    end

    trait :unselected do
      selected { false }
      feasibility { "feasible" }
      valuation_finished { true }
    end

    trait :hidden do
      hidden_at { Time.current }
    end

    trait :with_ignored_flag do
      ignored_flag_at { Time.current }
    end

    trait :with_administrator do
      administrator
    end

    trait :with_valuator do
      valuators { [create(:valuator)] }
    end

    trait :with_map_location do
      map_location do
        association :map_location,
                    longitude: heading.longitude.to_f + rand(-0.0001..0.0001),
                    latitude: heading.latitude.to_f + rand(-0.0001..0.0001)
      end
    end

    trait :flagged do
      after :create do |investment|
        Flag.flag(create(:user), investment)
      end
    end

    trait :with_confirmed_hide do
      confirmed_hide_at { Time.current }
    end

    trait :with_milestone_tags do
      after(:create) { |investment| investment.milestone_tags << create(:tag, :milestone) }
    end

    trait :with_image do
      after(:create) { |investment| create(:image, imageable: investment) }
    end

    trait :valuation_finished do
      valuation_finished { true }
    end

    transient do
      voters { [] }
      followers { [] }
      ballots { [] }
      balloters { [] }
    end

    after(:create) do |investment, evaluator|
      evaluator.voters.each { |voter| create(:vote, votable: investment, voter: voter) }
      evaluator.followers.each { |follower| create(:follow, followable: investment, user: follower) }

      evaluator.ballots.each do |ballot|
        create(:budget_ballot_line, investment: investment, ballot: ballot)
      end

      evaluator.balloters.each do |balloter|
        create(:budget_ballot_line, investment: investment, user: balloter)
      end
    end
  end

  factory :budget_phase, class: "Budget::Phase" do
    budget
    kind        { :balloting }
    summary     { Faker::Lorem.sentence(word_count: 3) }
    description { Faker::Lorem.sentence(word_count: 10) }
    starts_at   { Date.yesterday }
    ends_at     { Date.tomorrow }
    enabled     { true }
  end

  factory :budget_ballot, class: "Budget::Ballot" do
    user
    budget

    transient { investments { [] } }

    after(:create) do |ballot, evaluator|
      evaluator.investments.each do |investment|
        create(:budget_ballot_line, investment: investment, ballot: ballot)
      end
    end
  end

  factory :budget_ballot_line, class: "Budget::Ballot::Line" do
    investment factory: :budget_investment

    transient { user { nil } }

    ballot do
      association :budget_ballot, budget: investment.budget.reload, user: user || association(:user)
    end
  end

  factory :budget_reclassified_vote, class: "Budget::ReclassifiedVote" do
    user
    investment factory: :budget_investment
    reason { "unfeasible" }
  end

  factory :valuator_group, class: "ValuatorGroup" do
    sequence(:name) { |n| "Valuator Group #{n}" }
  end

  factory :heading_content_block, class: "Budget::ContentBlock" do
    heading factory: :budget_heading
    locale { "en" }
    body { "Some heading contents" }
  end
end
