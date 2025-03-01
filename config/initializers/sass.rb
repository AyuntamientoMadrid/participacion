# TODO: we could remove it once we upgrade Font Awesome, although
# we might need to add it again if we upgrade Sass
SassC::Engine.class_eval do
  alias_method :original_initialize, :initialize

  def initialize(template, options = {})
    original_initialize(template, options.merge(quiet_deps: true))
  end
end
