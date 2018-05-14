module CommonActions

  def sign_up(email = 'manuela@consul.dev', password = 'judgementday')
    visit '/'

    click_link 'Register'

    fill_in 'user_username',              with: "Manuela Carmena #{rand(99999)}"
    fill_in 'user_email',                 with: email
    fill_in 'user_password',              with: password
    fill_in 'user_password_confirmation', with: password
    check 'user_terms_of_service'

    click_button 'Register'
  end

  def sign_up_as_organization(email="organization@consul.dev", password='thepeoples')
    visit new_organization_registration_path

    fill_in 'user_organization_attributes_name',  with: 'Greenpeace'
    fill_in 'user_organization_attributes_responsible_name', with: 'Dorothy Stowe'
    fill_in 'user_email',                         with: 'green@peace.com'
    fill_in 'user_password',                      with: 'greenpeace'
    fill_in 'user_password_confirmation',         with: 'greenpeace'
    check 'user_terms_of_service'

    click_button 'Register'
  end

  def fill_in_signup_form(email='manuela@consul.dev', password='judgementday')
    fill_in 'user_username',              with: "Manuela Carmena #{rand(99999)}"
    fill_in 'user_email',                 with: email
    fill_in 'user_password',              with: password
    fill_in 'user_password_confirmation', with: password
    check 'user_terms_of_service'
  end

  def login_through_form_with_email_and_password(email='manuela@consul.dev', password='judgementday')
    visit root_path
    click_link 'Sign in'

    fill_in 'user_login', with: email
    fill_in 'user_password', with: password

    click_button 'Enter'
  end

  def login_through_form_as(user)
    visit root_path
    click_link 'Sign in'

    fill_in 'user_login', with: user.email
    fill_in 'user_password', with: user.password

    click_button 'Enter'
  end

  def login_through_form_as_officer(user)
    visit root_path
    click_link 'Sign in'

    fill_in 'user_login', with: user.email
    fill_in 'user_password', with: user.password

    click_button 'Enter'
    visit new_officing_residence_path
  end

  def login_as_authenticated_manager
    expected_response = {login: login, user_key: user_key, date: date}.with_indifferent_access
    login, user_key, date = "JJB042", "31415926", Time.current.strftime("%Y%m%d%H%M%S")
    allow_any_instance_of(ManagerAuthenticator).to receive(:auth).and_return(expected_response)
    visit management_sign_in_path(login: login, clave_usuario: user_key, fecha_conexion: date)
  end

  def login_as_manager
    manager = create(:manager)
    login_as(manager.user)
    visit management_sign_in_path
  end

  def login_managed_user(user)
    allow_any_instance_of(Management::BaseController).to receive(:managed_user).and_return(user)
  end

  def fill_in_proposal
    fill_in 'proposal_title', with: 'Help refugees'
    fill_in 'proposal_summary', with: 'In summary what we want is...'
    fill_in 'proposal_description', with: 'This is very important because...'
    fill_in 'proposal_external_url', with: 'http://rescue.org/refugees'
    fill_in 'proposal_video_url', with: 'https://www.youtube.com/watch?v=yPQfcG-eimk'
    fill_in 'proposal_responsible_name', with: 'Isabel Garcia'
    check 'proposal_terms_of_service'
  end

  def fill_in_debate
    fill_in 'debate_title', with: 'A title for a debate'
    fill_in 'debate_description', with: 'This is very important because...'
    check 'debate_terms_of_service'
  end

  def confirm_email
    body = ActionMailer::Base.deliveries.last.try(:body)
    expect(body).to be_present

    sent_token = /.*confirmation_token=(.*)".*/.match(body.to_s)[1]
    visit user_confirmation_path(confirmation_token: sent_token)

    expect(page).to have_content "Your account has been confirmed"
  end

  def reset_password
    create(:user, email: 'manuela@consul.dev')

    visit '/'
    click_link 'Sign in'
    click_link 'Forgotten your password?'

    fill_in 'user_email', with: 'manuela@consul.dev'
    click_button 'Send instructions'
  end

  def comment_on(commentable, user = nil)
    user ||= create(:user)

    comment = create(:comment, commentable: commentable, user: user)
    CommentNotifier.new(comment: comment).process
  end

  def reply_to(original_user, manuela = nil)
    manuela ||= create(:user)

    debate  = create(:debate)
    comment = create(:comment, commentable: debate, user: original_user)

    login_as(manuela)
    visit debate_path(debate)

    click_link "Reply"
    within "#js-comment-form-comment_#{comment.id}" do
      fill_in "comment-body-comment_#{comment.id}", with: 'It will be done next week.'
      click_button 'Publish reply'
    end
    expect(page).to have_content 'It will be done next week.'
  end

  def avatar(name)
    "img.initialjs-avatar[data-name='#{name}']"
  end

  # Used to fill ckeditor fields
  # @param [String] locator label text for the textarea or textarea id
  def fill_in_ckeditor(locator, params = {})
    # Find out ckeditor id at runtime using its label
    locator = find('label', text: locator)[:for] if page.has_css?('label', text: locator)
    # Fill the editor content
    page.execute_script <<-SCRIPT
        var ckeditor = CKEDITOR.instances.#{locator}
        ckeditor.setData('#{params[:with]}')
        ckeditor.focus()
        ckeditor.updateElement()
    SCRIPT
  end

  def error_message(resource_model = nil)
    resource_model ||= "(.*)"
    field_check_message = 'Please check the marked fields to know how to correct them:'
    /\d errors? prevented this #{resource_model} from being saved. #{field_check_message}/
  end

  def expect_to_be_signed_in
    expect(find('.top-bar-right')).to have_content 'My account'
  end

  def expect_to_not_be_signed_in
    expect(find('.top-bar-right')).not_to have_content 'My account'
  end

  def select_date(values, selector)
    selector = selector[:from]
    day, month, year = values.split("-")
    select day,   from: "#{selector}_3i"
    select month, from: "#{selector}_2i"
    select year,  from: "#{selector}_1i"
  end

  def verify_residence
    select 'DNI', from: 'residence_document_type'
    fill_in 'residence_document_number', with: "12345678Z"
    select_date '31-December-1980', from: 'residence_date_of_birth'
    fill_in 'residence_postal_code', with: '28013'
    check 'residence_terms_of_service'

    click_button 'Verify residence'
    expect(page).to have_content 'Residence verified'
  end

  def officing_verify_residence
    select 'DNI', from: 'residence_document_type'
    fill_in 'residence_document_number', with: "12345678Z"
    fill_in 'residence_year_of_birth', with: "1980"

    click_button 'Validate document'

    expect(page).to have_content 'Document verified with Census'
  end

  def validate_officer
    allow_any_instance_of(Officing::BaseController).
    to receive(:verify_officer_assignment).and_return(true)
  end

  def set_officing_booth(booth=nil)
    booth = create(:poll_booth) if booth.blank?

    allow_any_instance_of(Officing::BaseController).
    to receive(:current_booth).and_return(booth)
  end

  def vote_for_poll(poll)
    expect(page).to have_content poll.name

    first(".opt.ng-binding").click

    click_button "Continuar"

    if poll.nvotes_poll_id == "128"
      expect(page).to have_content "La opción que seleccionaste es: Sí"
    elsif poll.nvotes_poll_id == "136"
      expect(page).to have_content "La opción que seleccionaste es: A"
    end

    click_button "Enviar el voto"

    expect(page).to have_content "Voto emitido con éxito"
  end

  def valid_authorization_hash(nvote)
    message = "1:AuthEvent:1:RegisterSuccessfulLogin:1"
    signature = Poll::Nvote.generate_hash(message)

    "khmac:///sha-256;#{signature}/#{message}"
  end

  def simulate_nvotes_callback(nvote, poll)
    message = "#{nvote.voter_hash}:AuthEvent:#{poll.nvotes_poll_id}:RegisterSuccessfulLogin:#{Time.now.to_i}"
    signature = Poll::Nvote.generate_hash(message)

    authorization_hash = "khmac:///sha-256;#{signature}/#{message}"

    page.driver.header 'Authorization', authorization_hash
    page.driver.header 'ACCEPT', "application/json"
    page.driver.post polls_nvotes_success_path
  end

  def use_digital_booth
    allow_any_instance_of(Officing::VotersController).
    to receive(:physical_booth?).and_return(false)
  end

  def use_physical_booth
    allow_any_instance_of(Officing::VotersController).
    to receive(:physical_booth?).and_return(true)
  end

  def confirm_phone(user = nil)
    user ||= User.last

    fill_in 'sms_phone', with: "611111111"
    click_button 'Send'

    expect(page).to have_content 'Enter the confirmation code sent to you by text message'

    fill_in 'sms_confirmation_code', with: user.reload.sms_confirmation_code
    click_button 'Send'

    expect(page).to have_content 'Code correct'
  end

  def expect_message_you_need_to_sign_in
    expect(page).to have_content 'You must Sign in or Sign up to continue'
    expect(page).to have_link("Sign in", href: new_user_session_path)
    expect(page).to have_link("Sign up", href: new_user_registration_path)
    expect(page).to have_selector('.in-favor', visible: false)
  end

  def expect_message_you_need_to_sign_in_to_vote_comments
    expect(page).to have_content 'You must Sign in or Sign up to vote'
    expect(page).to have_selector('.participation-allowed', visible: false)
    expect(page).to have_selector('.participation-not-allowed', visible: true)
  end

  def expect_message_to_many_anonymous_votes
    expect(page).to have_content 'Too many anonymous votes to admit vote'
    expect(page).to have_selector('.in-favor a', visible: false)
  end

  def expect_message_only_verified_can_vote_proposals
    expect(page).to have_content 'Only verified users can vote on proposals'
    expect(page).to have_link("verify your account", href: verification_path)
    expect(page).to have_selector('.in-favor', visible: false)
  end

  def expect_message_organizations_cannot_vote
    expect(page).to have_content 'Organisations are not permitted to vote.'
    expect(page).to have_selector('.in-favor a', visible: false)
  end

  def expect_message_voting_not_allowed
    expect(page).to have_content 'Voting phase is closed'
    expect(page).not_to have_selector('.in-favor a')
  end

  def expect_message_already_voted_in_another_geozone(geozone)
    expect(page).to have_content 'You have already supported other district proposals.'
    expect(page).to have_link(geozone.name, href: spending_proposals_path(geozone: geozone))
    expect(page).to have_selector('.in-favor a', visible: false)
  end

  def expect_message_insufficient_funds
    expect(page).to have_content "This proposal's price is more than the available amount left"
  end

  def expect_message_selecting_not_allowed
    expect(page).to have_content 'No Selecting Allowed'
    expect(page).not_to have_selector('.in-favor a')
  end

  def expect_message_organizations_cannot_vote
    #expect(page).to have_content 'Organisations are not permitted to vote.'
    expect(page).to have_content 'Organization'
    expect(page).to have_selector('.in-favor a', visible: false)
  end

  def create_featured_proposals
    [create(:proposal, :with_confidence_score, cached_votes_up: 100),
     create(:proposal, :with_confidence_score, cached_votes_up: 90)]
  end

  def create_featured_debates
    [create(:debate, :with_confidence_score, cached_votes_up: 100),
     create(:debate, :with_confidence_score, cached_votes_up: 90),
     create(:debate, :with_confidence_score, cached_votes_up: 80)]
  end

  def create_successful_proposals
    [create(:proposal, title: "Winter is coming", question: "Do you speak it?",
                       cached_votes_up: Proposal.votes_needed_for_success + 100),
     create(:proposal, title: "Fire and blood", question: "You talking to me?",
                       cached_votes_up: Proposal.votes_needed_for_success + 1)]
  end

  def create_archived_proposals
    months_to_archive_proposals = Setting["months_to_archive_proposals"].to_i
    [
      create(:proposal, title: "This is an expired proposal",
                        created_at: months_to_archive_proposals.months.ago),
      create(:proposal, title: "This is an oldest expired proposal",
                        created_at: (months_to_archive_proposals + 2).months.ago)
    ]
  end

  def tag_names(tag_cloud)
    tag_cloud.tags.map(&:name)
  end

  def add_to_ballot(spending_proposal)
    within("#spending_proposal_#{spending_proposal.id}") do
      find('.add a').click
    end
  end

  def create_proposal_notification(proposal)
    login_as(proposal.author)
    visit root_path

    click_link "My activity"

    within("#proposal_#{proposal.id}") do
      click_link "Send notification"
    end

    fill_in 'proposal_notification_title', with: "Thanks for supporting proposal: #{proposal.title}"
    fill_in 'proposal_notification_body', with: "Please share it with others! #{proposal.summary}"
    click_button "Send message"

    expect(page).to have_content "Your message has been sent correctly."
    Notification.last
  end

  def create_direct_message(sender, receiver)
    login_as(sender)
    visit user_path(receiver)

    click_link "Send private message"

    expect(page).to have_content "Send private message to #{receiver.name}"

    fill_in 'direct_message_title', with: "Hey #{receiver.name}!"
    fill_in 'direct_message_body',  with: "How are you doing? This is #{sender.name}"

    click_button "Send message"

    expect(page).to have_content "You message has been sent successfully."
    DirectMessage.last
  end

  def expect_badge_for(resource_name, resource)
    within("##{resource_name}_#{resource.id}") do
      expect(page).to have_css ".label.round"
      expect(page).to have_content "Employee"
    end
  end

  def expect_no_badge_for(resource_name, resource)
    within("##{resource_name}_#{resource.id}") do
      expect(page).not_to have_css ".label.round"
      expect(page).not_to have_content "Employee"
    end
  end

  def create_spending_proposal_for(*users)
    users.each do |user|
      create(:spending_proposal, :finished, :feasible, author: user)
    end
  end

  def create_vote_for(*users)
    sp = first_or_create_spending_spending_proposal
    users.each do |user|
      create(:vote, votable: sp, voter: user)
    end
  end

  def create_ballot_for(*users)
    sp = first_or_create_spending_spending_proposal
    users.each do |user|
      create(:ballot, spending_proposals: [sp], user: user)
    end
  end

  def create_delegation_for(*users)
    forum = create(:forum)
    users.each do |user|
      user.update(representative: forum)
    end
  end

  def first_or_create_spending_spending_proposal
    if SpendingProposal.any?
      return SpendingProposal.first
    else
      return create(:spending_proposal, :finished, :feasible)
    end
  end

  def send_user_invite
    visit new_management_user_invite_path

    fill_in "emails", with: "john@example.com, ana@example.com, isable@example.com"
    click_button "Send invites"

    expect(page).to have_content "3 invitations have been sent."
  end

  def add_spending_proposal_to_ballot(spending_proposal)
    within("#spending_proposal_#{spending_proposal.id}") do
      find('.add a').click
      expect(page).to have_content "Remove"
    end
  end

  def add_to_ballot(budget_investment)
    within("#budget_investment_#{budget_investment.id}") do
      find('.add a').click
      expect(page).to have_content "Remove"
    end
  end

  def csv_path_for(table)
    "system/api/#{table}.csv"
  end

  def vote_for_poll_via_web(poll, question, answer)
    visit poll_path(poll)

    within("#poll_question_#{question.id}_answers") do
      click_link answer.to_s
      expect(page).not_to have_link(answer.to_s)
    end
  end

  def vote_for_poll_via_booth
    visit new_officing_residence_path
    officing_verify_residence

    expect(page).to have_content poll.name

    first(:button, "Confirm vote").click
    expect(page).to have_content "Vote introduced!"

    expect(Poll::Voter.count).to eq(1)
  end

  def remove_token_from_vote_link
    page.execute_script("$('.js-question-answer')[0]['href'] = $('.js-question-answer')[0]['href'].match(/.+?(?=token)/)[0] + 'token='")
  end

  def model_name(described_class)
    return :proposal_notification if described_class == ProposalNotification

    described_class.name.gsub("::", "_").downcase.to_sym
  end

  def comment_body(resource)
    "comment-body-#{resource.class.name.parameterize('_').to_sym}_#{resource.id}"
  end

  def path_for(resource)
    nested_path_for(resource) || url_for([resource, only_path: true])
  end

  def nested_path_for(resource)
    case resource.class.name
    when "Legislation::Question"
      legislation_process_question_path(resource.process, resource)
    when "Legislation::Proposal"
      legislation_process_proposal_path(resource.process, resource)
    when "Budget::Investment"
      budget_investment_path(resource.budget, resource)
    else
      false
    end
  end

  def fill_in_newsletter_form(options = {})
    fill_in "newsletter_subject", with: (options[:subject] || "This is a different subject")
    select (options[:segment_recipient] || 'All users'), from: 'newsletter_segment_recipient'
    fill_in "newsletter_from", with: (options[:from] || "no-reply@consul.dev")
    fill_in "newsletter_body", with: (options[:body] || "This is a different body")
  end

  def click_notifications_icon
    find("#notifications a").click
  end

  def fill_in_admin_notification_form(options = {})
    select (options[:segment_recipient] || 'All users'), from: :admin_notification_segment_recipient
    fill_in :admin_notification_title, with: (options[:title] || 'This is the notification title')
    fill_in :admin_notification_body, with: (options[:body] || 'This is the notification body')
    fill_in :admin_notification_link, with: (options[:link] || 'https://www.decide.madrid.es/vota')
  end

end
