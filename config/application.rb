require "sassc-embedded"
require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
# require "action_mailbox/engine"
# require "action_text/engine"
require "action_view/railtie"
require "action_cable/engine"
require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Consul
  class Application < Rails::Application
    def secrets
      Rails.deprecator.silence { super }
    end

    def secret_key_base
      Rails.deprecator.silence { super }
    end

    config.load_defaults 7.1

    # Keep belongs_to fields optional by default, because that's the way
    # Rails 4 models worked
    config.active_record.belongs_to_required_by_default = false

    # Don't enable has_many_inversing because it doesn't seem to currently
    # work with the _count database columns we use for caching purposes
    config.active_record.has_many_inversing = false

    # Disable Sprockets AssetUrlProcessor for CKEditor compatibility
    config.assets.resolve_assets_in_css_urls = false

    # Keep adding media="screen" attribute to stylesheets, just like
    # Rails 4, 5 and 6 did, until we change the print stylesheet so it
    # works when loading all the styles
    config.action_view.apply_stylesheet_media_default = true

    # Keep using ImageMagick instead of libvips for image processing in
    # order to make upgrades easier.
    config.active_storage.variant_processor = :mini_magick

    # Keep using YAML to serialize the legislation_annotations ranges column
    config.active_record.default_column_serializer = YAML

    # Keep reading existing data in the legislation_annotations ranges column
    config.active_record.yaml_column_permitted_classes = [ActiveSupport::HashWithIndifferentAccess, Symbol]

    # Handle custom exceptions
    config.action_dispatch.rescue_responses["FeatureFlags::FeatureDisabled"] = :forbidden
    config.action_dispatch.rescue_responses["Apartment::TenantNotFound"] = :not_found

    # Store uploaded files on the local file system (see config/storage.yml for options).
    config.active_storage.service = :local

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    config.time_zone = Rails.application.secrets.time_zone.presence || "Madrid"

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    config.i18n.default_locale = :en
    available_locales = [
      "ar",
      "bg",
      "bs",
      "ca",
      "cs",
      "da",
      "de",
      "el",
      "en",
      "es",
      "es-PE",
      "eu",
      "fa",
      "fr",
      "gd",
      "gl",
      "he",
      "hr",
      "id",
      "it",
      "ka",
      "ne",
      "nl",
      "oc",
      "pl",
      "pt",
      "pt-BR",
      "ro",
      "ru",
      "sl",
      "sq",
      "so",
      "sr",
      "sv",
      "tr",
      "uk-UA",
      "val",
      "zh-CN",
      "zh-TW"
    ]
    config.i18n.available_locales = available_locales
    config.i18n.fallbacks = [I18n.default_locale, {
      "ca" => "es",
      "es-PE" => "es",
      "eu" => "es",
      "fr" => "es",
      "gl" => "es",
      "it" => "es",
      "oc" => "fr",
      "pt-BR" => "es",
      "val" => "es"
    }]

    initializer :exclude_custom_locales_automatic_loading, before: :add_locales do
      paths.add "config/locales", glob: "**[^custom]*/*.{rb,yml}"
    end
    config.i18n.load_path += Dir[Rails.root.join("config", "locales", "custom", "**", "*.{rb,yml}")]

    config.after_initialize do
      Globalize.set_fallbacks_to_all_available_locales
    end

    config.assets.paths << Rails.root.join("app", "assets", "fonts")
    config.assets.paths << Rails.root.join("vendor", "assets", "fonts")
    config.assets.paths << Rails.root.join("node_modules", "jquery-ui", "themes", "base")
    config.assets.paths << Rails.root.join("node_modules", "leaflet", "dist")
    config.assets.paths << Rails.root.join("node_modules")

    config.active_job.queue_adapter = :delayed_job

    # CONSUL DEMOCRACY specific custom overrides
    # Read more on documentation:
    # * English: https://github.com/consuldemocracy/consuldemocracy/blob/master/CUSTOMIZE_EN.md
    # * Spanish: https://github.com/consuldemocracy/consuldemocracy/blob/master/CUSTOMIZE_ES.md
    #

    [
      "app/components/custom",
      "app/controllers/custom",
      "app/form_builders/custom",
      "app/graphql/custom",
      "app/lib/custom",
      "app/mailers/custom",
      "app/models/custom",
      "app/models/custom/concerns"
    ].each do |path|
      config.autoload_paths << Rails.root.join(path)
      config.eager_load_paths << Rails.root.join(path)
    end

    config.paths["app/views"].unshift(Rails.root.join("app", "views", "custom"))

    # Set to true to enable user authentication log
    config.authentication_logs = Rails.application.secrets.authentication_logs || false

    # Set to true to enable devise user lockable feature
    config.devise_lockable = Rails.application.secrets.devise_lockable

    # Set to true to enable managing different tenants using the same application
    config.multitenancy = Rails.application.secrets.multitenancy
    # Set to true if you want that the default tenant only to be used to manage other tenants
    config.multitenancy_management_mode = Rails.application.secrets.multitenancy_management_mode

    def multitenancy_management_mode?
      config.multitenancy && Tenant.default? && config.multitenancy_management_mode
    end
  end
end

class Rails::Engine
  initializer :prepend_custom_assets_path, group: :all do |app|
    if self.class.name == "Consul::Application"
      %w[images fonts].each do |asset|
        app.config.assets.paths.unshift(Rails.root.join("app", "assets", asset, "custom").to_s)
      end
    end
  end
end

require "./config/application_custom"
