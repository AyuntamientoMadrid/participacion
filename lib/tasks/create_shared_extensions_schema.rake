require Rails.root.join("db/migrate/20200602233844_create_shared_extensions_schema.rb")

Rake::Task["db:schema:load"].enhance do
  at_exit { CreateSharedExtensionsSchema.new.up }
end

Rake::Task["db:test:purge"].enhance do
  at_exit { CreateSharedExtensionsSchema.new.up }
end
