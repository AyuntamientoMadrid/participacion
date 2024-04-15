require "factory_bot_rails"
require "email_spec"
require "devise"
require "knapsack_pro"

Dir["./spec/factory_bot/**/*.rb"].sort.each { |f| require f }
Dir["./spec/models/concerns/*.rb"].each { |f| require f }
Dir["./spec/support/**/*.rb"].sort.each { |f| require f }
Dir["./spec/shared/**/*.rb"].sort.each  { |f| require f }

RSpec.configure do |config|
  config.use_transactional_fixtures = true
  config.fixture_paths = ["spec/fixtures/files"]

  config.filter_run_when_matching :focus
  config.include RequestSpecHelper, type: :request
  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include Devise::Test::ControllerHelpers, type: :view
  config.include FactoryBot::Syntax::Methods
  config.include(EmailSpec::Helpers)
  config.include(EmailSpec::Matchers)
  config.include(CommonActions)
  config.include(ActiveSupport::Testing::TimeHelpers)
  config.include GraphQL::Testing::Helpers.for(ConsulSchema)

  config.define_derived_metadata(file_path: Regexp.new("/spec/components/")) do |metadata|
    metadata[:type] = :component
  end

  config.before(:suite) do
    Rails.application.load_seed
  end

  config.before do |example|
    Globalize.set_fallbacks_to_all_available_locales
    Setting["feature.user.skip_verification"] = nil
  end

  config.around do |example|
    I18n.with_locale(:en) do
      example.run
    end
  end

  config.around(:each, :race_condition) do |example|
    self.use_transactional_tests = false
    example.run
    self.use_transactional_tests = true

    ActiveRecord::Tasks::DatabaseTasks.truncate_all
    Rails.application.load_seed
  end

  config.before(:each, type: :system) do
    Capybara::Webmock.start
  end

  config.after(:suite) do
    Capybara::Webmock.stop
  end

  config.before(:each, type: :system) do |example|
    driven_by :headless_chrome
    Capybara.default_set_options = { clear: :backspace }
  end

  config.before(:each, :no_js, type: :system) do
    driven_by :rack_test
    Capybara.default_set_options = {}
  end

  config.before(:each, type: :system) do
    allow(InvisibleCaptcha).to receive(:timestamp_threshold).and_return(0)
  end

  config.before(:each, :admin, type: :system) do
    login_as(create(:administrator).user)
  end

  config.before(:each, :admin, type: :controller) do
    sign_in(create(:administrator).user)
  end

  config.before(:each, type: :component) do
    sign_in(nil)
  end

  config.before(:each, :admin, type: :component) do
    sign_in(create(:administrator).user)
  end

  config.around(:each, :admin, type: :component) do |example|
    with_controller_class(Admin::BaseController) { example.run }
  end

  config.around(:each, :controller, type: :component) do |example|
    with_controller_class(example.metadata[:controller]) { example.run }
  end

  config.before(:each, :show_exceptions) do
    config = Rails.application.env_config

    allow(Rails.application).to receive(:env_config) do
      config.merge(
        "action_dispatch.show_exceptions" => :all,
        "action_dispatch.show_detailed_exceptions" => false,
        "consider_all_requests_local" => false
      )
    end
  end

  config.before(:each, :delay_jobs) do
    Delayed::Worker.delay_jobs = true
  end

  config.after(:each, :delay_jobs) do
    Delayed::Worker.delay_jobs = false
  end

  config.before(:each, :seed_tenants) do
    Apartment.seed_after_create = true
  end

  config.after(:each, :seed_tenants) do
    Apartment.seed_after_create = false
  end

  config.before(:each, :small_window) do
    @window_size = Capybara.current_window.size
    Capybara.current_window.resize_to(320, 640)
  end

  config.after(:each, :small_window) do
    Capybara.current_window.resize_to(*@window_size)
  end

  config.before(:each, :remote_translations) do
    allow(RemoteTranslations::Microsoft::AvailableLocales)
      .to receive(:locales).and_return(I18n.available_locales.map(&:to_s))
  end

  config.before(:each, :with_frozen_time) { freeze_time }

  config.before(:each, :application_zone_west_of_system_zone) do
    application_zone = ActiveSupport::TimeZone.new("Quito")
    system_zone = ActiveSupport::TimeZone.new("Madrid")
    system_time_at_application_end_of_day = Date.current.end_of_day.in_time_zone(system_zone)

    allow(Time).to receive_messages(zone: application_zone, now: system_time_at_application_end_of_day)
    allow(Date).to receive(:today).and_return(system_time_at_application_end_of_day.to_date)
  end

  config.before(:each, :with_non_utc_time_zone) do
    application_zone = ActiveSupport::TimeZone.new("Madrid")

    allow(Time).to receive(:zone).and_return(application_zone)
  end

  config.before(:each, :remote_census) do |example|
    allow_any_instance_of(RemoteCensusApi).to receive(:end_point_defined?).and_return(true)
    Setting["feature.remote_census"] = true
    Setting["remote_census.request.method_name"] = "verify_residence"
    Setting["remote_census.request.structure"] = '{ "request":
      {
        "document_type": "null",
        "document_number": "nil",
        "date_of_birth": "null",
        "postal_code": "nil"
      }
    }'

    Setting["remote_census.request.document_type"] = "request.document_type"
    Setting["remote_census.request.document_number"] = "request.document_number"
    Setting["remote_census.request.date_of_birth"] = "request.date_of_birth"
    Setting["remote_census.request.postal_code"] = "request.postal_code"
    Setting["remote_census.response.date_of_birth"] = "response.data.date_of_birth"
    Setting["remote_census.response.postal_code"] = "response.data.postal_code"
    Setting["remote_census.response.district"] = "response.data.district_code"
    Setting["remote_census.response.gender"] = "response.data.gender"
    Setting["remote_census.response.name"] = "response.data.name"
    Setting["remote_census.response.surname"] = "response.data.surname"
    Setting["remote_census.response.valid"] = "response.data.document_number"

    savon.mock!
  end

  config.after(:each, :remote_census) do
    savon.unmock!
  end

  config.before(:each, :with_cache) do
    allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache.lookup_store(:memory_store))
    Rails.cache.clear
  end

  # Allows RSpec to persist some state between runs in order to support
  # the `--only-failures` and `--next-failure` CLI options.
  config.example_status_persistence_file_path = "spec/examples.txt"

  # Many RSpec users commonly either run the entire suite or an individual
  # file, and it's useful to allow more verbose output when running an
  # individual spec file.
  if config.files_to_run.one?
    # Use the documentation formatter for detailed output,
    # unless a formatter has already been configured
    # (e.g. via a command-line flag).
    config.default_formatter = "doc"
  end

  # Print the 10 slowest examples and example groups at the
  # end of the spec run, to help surface which specs are running
  # particularly slow.
  # config.profile_examples = 10

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = :random

  # Seed global randomization in this process using the `--seed` CLI option.
  # Setting this allows you to use `--seed` to deterministically reproduce
  # test failures related to randomization by passing the same `--seed` value
  # as the one that triggered the failure.
  Kernel.srand config.seed

  config.expect_with(:rspec) { |c| c.syntax = :expect }
end

# Parallel build helper configuration for CI
KnapsackPro::Adapters::RSpecAdapter.bind
