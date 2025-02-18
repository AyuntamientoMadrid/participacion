require "rails_helper"

describe "Emails" do
  before do
    reset_mailer
  end

  context "On Staging Environment" do
    scenario "emails are delivered to configured recipient" do
      interceptor = RecipientInterceptor.new("recipient@consul.dev", subject_prefix: "[staging]")
      Mail.register_interceptor(interceptor)

      sign_up

      email = open_last_email
      expect(email).to have_subject("[staging] Confirmation instructions")
      expect(email).to deliver_to("recipient@consul.dev")
      expect(email).not_to deliver_to("manuela@consul.dev")

      Mail.unregister_interceptor(interceptor)
    end
  end

  scenario "Signup Email" do
    sign_up

    email = open_last_email
    expect(email).to have_subject("Confirmation instructions")
    expect(email).to deliver_to("manuela@consul.dev")
    expect(email).to have_body_text(user_confirmation_path)
  end

  scenario "Reset password" do
    reset_password

    email = open_last_email
    expect(email).to have_subject("Instructions for resetting your password")
    expect(email).to deliver_to("manuela@consul.dev")
    expect(email).to have_body_text(edit_user_password_path)
  end

  context "Proposal comments" do
    let(:user)     { create(:user, email_on_comment: true) }
    let(:proposal) { create(:proposal, author: user) }

    scenario "Send email on proposal comment" do
      comment_on(proposal)

      email = open_last_email
      expect(email).to have_subject("Someone has commented on your citizen proposal")
      expect(email).to deliver_to(proposal.author)
      expect(email).to have_body_text(proposal_path(proposal))
      expect(email).to have_body_text("To unsubscribe from these emails, visit")
      expect(email).to have_body_text(edit_subscriptions_path(token: proposal.author.subscriptions_token))
      expect(email).to have_body_text('and uncheck "Notify me by email when someone comments on my contents"')
    end

    scenario "Do not send email about own proposal comments" do
      comment_on(proposal, user)
      expect { open_last_email }.to raise_error("No email has been sent!")
    end

    scenario "Do not send email about proposal comment unless set in preferences" do
      user.update!(email_on_comment: false)
      comment_on(proposal)
      expect { open_last_email }.to raise_error("No email has been sent!")
    end
  end

  context "Debate comments" do
    let(:user)   { create(:user, email_on_comment: true) }
    let(:debate) { create(:debate, author: user) }

    scenario "Send email on debate comment" do
      comment_on(debate)

      email = open_last_email
      expect(email).to have_subject("Someone has commented on your debate")
      expect(email).to deliver_to(debate.author)
      expect(email).to have_body_text(debate_path(debate))
      expect(email).to have_body_text("To unsubscribe from these emails, visit")
      expect(email).to have_body_text(edit_subscriptions_path(token: debate.author.subscriptions_token))
      expect(email).to have_body_text('and uncheck "Notify me by email when someone comments on my contents"')
    end

    scenario "Do not send email about own debate comments" do
      comment_on(debate, user)
      expect { open_last_email }.to raise_error("No email has been sent!")
    end

    scenario "Do not send email about debate comment unless set in preferences" do
      user.update!(email_on_comment: false)
      comment_on(debate)
      expect { open_last_email }.to raise_error("No email has been sent!")
    end
  end

  context "Budget investments comments" do
    let(:user)       { create(:user, email_on_comment: true) }
    let(:investment) { create(:budget_investment, author: user, budget: create(:budget)) }

    scenario "Send email on budget investment comment" do
      comment_on(investment)

      email = open_last_email
      expect(email).to have_subject("Someone has commented on your investment")
      expect(email).to deliver_to(investment.author)
      expect(email).to have_body_text(budget_investment_path(investment, budget_id: investment.budget_id))
      expect(email).to have_body_text("To unsubscribe from these emails, visit")
      expect(email).to have_body_text(edit_subscriptions_path(token: investment.author.subscriptions_token))
      expect(email).to have_body_text('and uncheck "Notify me by email when someone comments on my contents"')
    end

    scenario "Do not send email about own budget investments comments" do
      comment_on(investment, user)
      expect { open_last_email }.to raise_error("No email has been sent!")
    end

    scenario "Do not send email about budget investment comment unless set in preferences" do
      user.update!(email_on_comment: false)
      comment_on(investment)
      expect { open_last_email }.to raise_error("No email has been sent!")
    end
  end

  context "Topic comments" do
    let(:user)     { create(:user, email_on_comment: true) }
    let(:proposal) { create(:proposal) }
    let(:topic)    { create(:topic, author: user, community: proposal.community) }

    scenario "Send email on topic comment" do
      comment_on(topic)

      email = open_last_email
      expect(email).to have_subject("Someone has commented on your topic")
      expect(email).to deliver_to(topic.author)
      expect(email).to have_body_text(community_topic_path(topic, community_id: topic.community_id))
      expect(email).to have_body_text("To unsubscribe from these emails, visit")
      expect(email).to have_body_text(edit_subscriptions_path(token: topic.author.subscriptions_token))
      expect(email).to have_body_text('and uncheck "Notify me by email when someone comments on my contents"')
    end

    scenario "Do not send email about own topic comments" do
      comment_on(topic, user)
      expect { open_last_email }.to raise_error("No email has been sent!")
    end

    scenario "Do not send email about topic comment unless set in preferences" do
      user.update!(email_on_comment: false)
      comment_on(topic)
      expect { open_last_email }.to raise_error("No email has been sent!")
    end
  end

  context "Poll comments" do
    let(:user) { create(:user, email_on_comment: true) }
    let(:poll) { create(:poll, author: user) }

    scenario "Send email on poll comment" do
      comment_on(poll)

      email = open_last_email
      expect(email).to have_subject("Someone has commented on your poll")
      expect(email).to deliver_to(poll.author)
      expect(email).to have_body_text(poll_path(poll))
      expect(email).to have_body_text("To unsubscribe from these emails, visit")
      expect(email).to have_body_text(edit_subscriptions_path(token: poll.author.subscriptions_token))
      expect(email).to have_body_text('and uncheck "Notify me by email when someone comments on my contents"')
    end

    scenario "Do not send email about own poll comments" do
      comment_on(poll, user)
      expect { open_last_email }.to raise_error("No email has been sent!")
    end

    scenario "Do not send email about poll question comment unless set in preferences" do
      user.update!(email_on_comment: false)
      comment_on(poll)
      expect { open_last_email }.to raise_error("No email has been sent!")
    end
  end

  context "Comment replies" do
    let(:user) { create(:user, email_on_comment_reply: true) }
    let(:debate) { create(:debate) }
    let!(:comment) { create(:comment, commentable: debate, user: user) }

    scenario "Send email on comment reply" do
      reply_to(comment)

      email = open_last_email
      expect(email).to have_subject("Someone has responded to your comment")
      expect(email).to deliver_to(user)
      expect(email).not_to have_body_text(debate_path(debate))
      expect(email).to have_body_text(comment_path(Comment.last))
      expect(email).to have_body_text("To unsubscribe from these emails, visit")
      expect(email).to have_body_text(edit_subscriptions_path(token: user.subscriptions_token))
      expect(email).to have_body_text('and uncheck "Notify me by email when someone replies to my comments"')
    end

    scenario "Do not send email about own replies to own comments" do
      reply_to(comment, replier: user)
      expect { open_last_email }.to raise_error("No email has been sent!")
    end

    scenario "Do not send email about comment reply unless set in preferences" do
      user.update!(email_on_comment_reply: false)
      reply_to(comment)
      expect { open_last_email }.to raise_error("No email has been sent!")
    end
  end

  scenario "Email depending on user's locale" do
    visit root_path(locale: :es)

    click_link "Registrarse"
    fill_in_signup_form
    click_button "Registrarse"

    expect(page).to have_content "visita el enlace para activar tu cuenta."

    email = open_last_email
    expect(email).to deliver_to("manuela@consul.dev")
    expect(email).to have_body_text(user_confirmation_path)
    expect(email).to have_subject("Instrucciones de confirmación")
  end

  context "Direct Message" do
    scenario "Receiver email" do
      sender   = create(:user, :level_two)
      receiver = create(:user, :level_two)

      direct_message = create_direct_message(sender, receiver)

      email = unread_emails_for(receiver.email).first

      expect(email).to have_subject("You have received a new private message")
      expect(email).to have_body_text(receiver.name)
      expect(email).to have_body_text(direct_message.title)
      expect(email).to have_body_text(direct_message.body)
      expect(email).to have_body_text(direct_message.sender.name)
      expect(email).to have_body_text(user_path(direct_message.sender_id))
      expect(email).to have_body_text(edit_subscriptions_path(token: receiver.subscriptions_token))
    end

    scenario "Sender email" do
      sender   = create(:user, :level_two)
      receiver = create(:user, :level_two)

      direct_message = create_direct_message(sender, receiver)

      email = unread_emails_for(sender.email).first

      expect(email).to have_subject("You have sent a new private message")
      expect(email).to have_body_text(sender.name)
      expect(email).to have_body_text(direct_message.title)
      expect(email).to have_body_text(direct_message.body)
      expect(email).to have_body_text(direct_message.receiver.name)
    end
  end

  context "Proposal notification digest" do
    scenario "notifications for proposals that I'm following", :no_js do
      Setting["org_name"] = "CONSUL"
      user = create(:user, email_digest: true)

      proposal1 = create(:proposal, followers: [user])
      proposal2 = create(:proposal, followers: [user])
      proposal3 = create(:proposal)

      reset_mailer

      notification1 = create_proposal_notification(proposal1)
      notification2 = create_proposal_notification(proposal2)

      email_digest = EmailDigest.new(user)
      email_digest.deliver(Time.current)
      email_digest.mark_as_emailed

      email = open_last_email
      expect(email).to have_subject("Proposal notifications in CONSUL")
      expect(email).to deliver_to(user.email)

      expect(email).to have_body_text(proposal1.title)
      expect(email).to have_body_text(notification1.notifiable.title)
      expect(email).to have_body_text(notification1.notifiable.body)
      expect(email).to have_body_text(proposal1.author.name)

      expect(email).to have_body_text(proposal_path(proposal1, anchor: "tab-notifications"))
      expect(email).to have_body_text(proposal_path(proposal1, anchor: "comments"))
      expect(email).to have_body_text(proposal_path(proposal1, anchor: "social-share"))

      expect(email).to have_body_text(proposal2.title)
      expect(email).to have_body_text(notification2.notifiable.title)
      expect(email).to have_body_text(notification2.notifiable.body)
      expect(email).to have_body_text(proposal_path(proposal2, anchor: "tab-notifications"))
      expect(email).to have_body_text(proposal_path(proposal2, anchor: "comments"))
      expect(email).to have_body_text(proposal_path(proposal2, anchor: "social-share"))
      expect(email).to have_body_text(proposal2.author.name)

      expect(email).not_to have_body_text(proposal3.title)
      expect(email).to have_body_text(edit_subscriptions_path(token: user.subscriptions_token))
      expect(email).to have_body_text("Visit this proposal and unfollow it to stop receiving notifications.")

      notification1.reload
      notification2.reload
      expect(notification1.emailed_at).to be
      expect(notification2.emailed_at).to be
      expect(email_digest.notifications).to be_empty
    end

    scenario "notifications moderated are not sent" do
      user = create(:user, email_digest: true)
      notification = create(:notification, :for_proposal_notification)

      reset_mailer

      notification.notifiable.moderate_system_email(create(:administrator).user)

      email_digest = EmailDigest.new(user)
      email_digest.deliver(Time.current)
      email_digest.mark_as_emailed

      expect { open_last_email }.to raise_error "No email has been sent!"
    end
  end

  context "User invites" do
    scenario "Send an invitation" do
      Setting["org_name"] = "CONSUL"
      login_as_manager
      visit new_management_user_invite_path

      fill_in "Emails", with: " john@example.com, ana@example.com,isable@example.com "
      click_button "Send invitations"

      expect(page).to have_content "3 invitations have been sent."

      expect(unread_emails_for("john@example.com").count).to eq 1
      expect(unread_emails_for("ana@example.com").count).to eq 1
      expect(unread_emails_for("isable@example.com").count).to eq 1

      email = open_last_email
      expect(email).to have_subject("Invitation to CONSUL")
      expect(email).to have_body_text(new_user_registration_path)
    end
  end

  context "Budgets" do
    let(:author) { create(:user, :level_two) }
    let(:budget) { create(:budget) }
    before { create(:budget_heading, name: "More hospitals", budget: budget) }

    scenario "Investment created" do
      login_as(author)
      visit new_budget_investment_path(budget_id: budget.id)

      fill_in_new_investment_title with: "Build a hospital"
      fill_in_ckeditor "Description", with: "We have lots of people that require medical attention"
      check "budget_investment_terms_of_service"

      click_button "Create Investment"
      expect(page).to have_content "Budget Investment created successfully"

      email = open_last_email

      expect(email).to have_subject("Thank you for creating an investment!")
      expect(email).to deliver_to(author.email)
      expect(email).to have_body_text(author.name)
      expect(email).to have_body_text("Build a hospital")
      expect(email).to have_body_text(budget.name)
      expect(email).to have_body_text(budget_path(budget))
    end

    scenario "Unfeasible investment" do
      budget.update!(phase: "valuating")
      valuator = create(:valuator)
      investment = create(:budget_investment, author: author, budget: budget, valuators: [valuator])

      login_as(valuator.user)
      visit edit_valuation_budget_budget_investment_path(budget, investment)

      within_fieldset("Feasibility") { choose "Unfeasible" }
      fill_in "Feasibility explanation", with: "This is not legal as stated in Article 34.9"
      accept_confirm { check "Valuation finished" }
      click_button "Save changes"

      expect(page).to have_content "Dossier updated"

      email = open_last_email
      expect(email).to have_subject "Your investment project '#{investment.code}' " \
                                    "has been marked as unfeasible"
      expect(email).to deliver_to investment.author.email
      expect(email).to have_body_text "This is not legal as stated in Article 34.9"
    end

    scenario "Selected investment" do
      author1 = create(:user)
      author2 = create(:user)
      author3 = create(:user)

      investment1 = create(:budget_investment, :selected,   author: author1, budget: budget)
      investment2 = create(:budget_investment, :selected,   author: author2, budget: budget)
      investment3 = create(:budget_investment, :unselected, author: author3, budget: budget)

      reset_mailer
      budget.email_selected

      expect(find_email(investment1.author.email)).to be
      expect(find_email(investment2.author.email)).to be
      expect(find_email(investment3.author.email)).not_to be

      email = open_last_email
      investment = investment2
      expect(email).to have_subject("Your investment project '#{investment.code}' has been selected")
      expect(email).to deliver_to(investment.author.email)
    end

    scenario "Unselected investment" do
      author1 = create(:user)
      author2 = create(:user)
      author3 = create(:user)

      investment1 = create(:budget_investment, :unselected, author: author1, budget: budget)
      investment2 = create(:budget_investment, :unselected, author: author2, budget: budget)
      investment3 = create(:budget_investment, :selected,   author: author3, budget: budget)

      reset_mailer
      budget.email_unselected

      expect(find_email(investment1.author.email)).to be
      expect(find_email(investment2.author.email)).to be
      expect(find_email(investment3.author.email)).not_to be

      email = open_last_email
      investment = investment2
      expect(email).to have_subject("Your investment project '#{investment.code}' has not been selected")
      expect(email).to deliver_to(investment.author.email)
    end
  end

  context "Polls" do
    scenario "Send email on poll comment reply" do
      user1 = create(:user, email_on_comment_reply: true)
      user2 = create(:user)
      poll = create(:poll, author: create(:user))
      comment = create(:comment, commentable: poll, author: user1)

      login_as(user2)
      visit poll_path(poll)

      click_link "Reply"

      within "#js-comment-form-comment_#{comment.id}" do
        fill_in "Leave your comment", with: "It will be done next week."
        click_button "Publish reply"
      end

      within "#comment_#{comment.id}" do
        expect(page).to have_content "It will be done next week."
      end

      email = open_last_email
      expect(email).to have_subject("Someone has responded to your comment")
      expect(email).to deliver_to(user1)
      expect(email).not_to have_body_text(poll_path(poll))
      expect(email).to have_body_text(comment_path(Comment.last))
      expect(email).to have_body_text("To unsubscribe from these emails, visit")
      expect(email).to have_body_text(edit_subscriptions_path(token: user1.subscriptions_token))
      expect(email).to have_body_text('and uncheck "Notify me by email when someone replies to my comments"')
    end
  end

  context "Newsletter", :admin do
    scenario "Send newsletter email to selected users" do
      user_with_newsletter_in_segment_1 = create(:user, :with_proposal, newsletter: true)
      user_with_newsletter_in_segment_2 = create(:user, :with_proposal, newsletter: true)
      user_with_newsletter_not_in_segment = create(:user, newsletter: true)
      user_without_newsletter_in_segment = create(:user, :with_proposal, newsletter: false)

      visit new_admin_newsletter_path
      fill_in_newsletter_form(segment_recipient: "Proposal authors")
      click_button "Create Newsletter"

      expect(page).to have_content "Newsletter created successfully"

      accept_confirm { click_button "Send" }

      expect(page).to have_content "Newsletter sent successfully"

      expect(unread_emails_for(user_with_newsletter_in_segment_1.email).count).to eq 1
      expect(unread_emails_for(user_with_newsletter_in_segment_2.email).count).to eq 1
      expect(unread_emails_for(user_with_newsletter_not_in_segment.email).count).to eq 0
      expect(unread_emails_for(user_without_newsletter_in_segment.email).count).to eq 0

      email = open_last_email
      expect(email).to have_subject("This is a different subject")
      expect(email).to deliver_from("no-reply@consul.dev")
      expect(email.body.encoded).to include("This is a different body")
      expect(email).to have_body_text("To unsubscribe from these emails, visit")
      expect(email).to have_body_text(
                        edit_subscriptions_path(token: user_with_newsletter_in_segment_2.subscriptions_token)
                      )
      expect(email).to have_body_text('and uncheck "Receive relevant information by email"')
    end
  end

  context "Users without email" do
    scenario "should not receive emails" do
      user = create(:user, :verified, email_on_comment: true)
      proposal = create(:proposal, author: user)

      user_commenting = create(:user)
      comment = create(:comment, commentable: proposal, user: user_commenting)
      user.update!(email: nil)

      Mailer.comment(comment).deliver_now

      expect { open_last_email }.to raise_error "No email has been sent!"
    end
  end
end
