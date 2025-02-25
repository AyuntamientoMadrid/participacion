class Admin::AllowedTableActionsComponent < ApplicationComponent
  attr_reader :record, :options
  use_helpers :can?
  delegate :action, to: :table_actions_component

  def initialize(record, **options)
    @record = record
    @options = options
  end

  private

    def actions
      (options[:actions] || [:edit, :destroy]).select { |action| can?(action, record) }
    end

    def table_actions_component
      @table_actions_component ||= Admin::TableActionsComponent.new(record, actions: actions, **options)
    end
end
