RSpec::Matchers.define :have_avatar do |text, **options|
  match do |page|
    page.has_css?("svg.initialjs-avatar", **{ exact_text: text }, **options)
  end

  failure_message do
    "expected to find avatar with text #{text} but there were no matches."
  end
end
