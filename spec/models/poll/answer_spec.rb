require "rails_helper"

describe Poll::Answer do
  describe "validations" do
    let(:answer) { build(:poll_answer) }

    it "is valid" do
      expect(answer).to be_valid
    end

    it "is not valid wihout a question" do
      answer.question = nil
      expect(answer).not_to be_valid
    end

    it "is not valid without an author" do
      answer.author = nil
      expect(answer).not_to be_valid
    end

    it "is not valid without an author when multiple answers are allowed" do
      answer.author = nil
      answer.question = create(:poll_question_multiple)

      expect(answer).not_to be_valid
    end

    it "is not valid without an answer" do
      answer.answer = nil
      expect(answer).not_to be_valid
    end

    it "is not valid if there's already an answer to that question" do
      author = create(:user)
      question = create(:poll_question, :yes_no)

      create(:poll_answer, author: author, question: question)

      answer = build(:poll_answer, author: author, question: question)

      expect(answer).not_to be_valid
    end

    it "is not valid when user already reached multiple answers question max votes" do
      author = create(:user)
      question = create(:poll_question_multiple, :abc, max_votes: 2)
      create(:poll_answer, author: author, question: question, answer: "Answer A")
      create(:poll_answer, author: author, question: question, answer: "Answer B")
      answer = build(:poll_answer, author: author, question: question, answer: "Answer C")

      expect(answer).not_to be_valid
    end

    it "is not valid when there are two identical answers" do
      author = create(:user)
      question = create(:poll_question_multiple, :abc)
      option = question.question_options.first

      create(:poll_answer, author: author, question: question, option: option, answer: "Answer A")

      answer = build(:poll_answer, author: author, question: question, option: option, answer: "Answer A")

      expect(answer).not_to be_valid
      expect { answer.save(validate: false) }.to raise_error ActiveRecord::RecordNotUnique
    end

    it "is not valid when there are two answers with the same option and different answer" do
      author = create(:user)
      question = create(:poll_question_multiple, :abc)
      option = question.question_options.first

      create(:poll_answer, author: author, question: question, option: option, answer: "Answer A")

      answer = build(:poll_answer, author: author, question: question, option: option, answer: "Answer B")

      expect(answer).not_to be_valid
      expect { answer.save(validate: false) }.to raise_error ActiveRecord::RecordNotUnique
    end

    it "is valid when there are two identical answers and the option is nil" do
      author = create(:user)
      question = create(:poll_question_multiple, :abc)

      create(:poll_answer, author: author, question: question, option: nil, answer: "Answer A")

      answer = build(:poll_answer, author: author, question: question, option: nil, answer: "Answer A")

      expect(answer).to be_valid
      expect { answer.save }.not_to raise_error
    end

    it "is valid for answers included in the Poll::Question's question_options list" do
      question = create(:poll_question)
      create(:poll_question_option, title: "One", question: question)
      create(:poll_question_option, title: "Two", question: question)
      create(:poll_question_option, title: "Three", question: question)

      expect(build(:poll_answer, question: question, answer: "One")).to be_valid
      expect(build(:poll_answer, question: question, answer: "Two")).to be_valid
      expect(build(:poll_answer, question: question, answer: "Three")).to be_valid

      expect(build(:poll_answer, question: question, answer: "Four")).not_to be_valid
    end

    context "creating answers at the same time", :race_condition do
      it "validates max votes on single-answer questions" do
        author = create(:user)
        question = create(:poll_question, :yes_no)

        answer = build(:poll_answer, author: author, question: question, answer: "Yes")
        other_answer = build(:poll_answer, author: author, question: question, answer: "No")

        [answer, other_answer].map do |poll_answer|
          Thread.new { poll_answer.save }
        end.each(&:join)

        expect(Poll::Answer.count).to be 1
      end

      it "validates max votes on multiple-answer questions" do
        author = create(:user, :level_two)
        question = create(:poll_question_multiple, :abc, max_votes: 2)
        create(:poll_answer, question: question, answer: "Answer A", author: author)
        answer = build(:poll_answer, question: question, answer: "Answer B", author: author)
        other_answer = build(:poll_answer, question: question, answer: "Answer C", author: author)

        [answer, other_answer].map do |poll_answer|
          Thread.new { poll_answer.save }
        end.each(&:join)

        expect(Poll::Answer.count).to be 2
      end
    end
  end

  describe "#save_and_record_voter_participation" do
    let(:author) { create(:user, :level_two) }
    let(:poll) { create(:poll) }
    let(:question) { create(:poll_question, :yes_no, poll: poll) }

    it "creates a poll_voter with user and poll data" do
      answer = create(:poll_answer, question: question, author: author, answer: "Yes")
      expect(answer.poll.voters).to be_blank

      answer.save_and_record_voter_participation
      expect(poll.reload.voters.size).to eq(1)
      voter = poll.voters.first

      expect(voter.document_number).to eq(answer.author.document_number)
      expect(voter.poll_id).to eq(answer.poll.id)
      expect(voter.officer_id).to be nil
    end

    it "updates a poll_voter with user and poll data" do
      answer = create(:poll_answer, question: question, author: author, answer: "Yes")
      answer.save_and_record_voter_participation

      expect(poll.reload.voters.size).to eq(1)

      updated_answer = answer.question.find_or_initialize_user_answer(
        answer.author,
        answer.question.question_options.excluding(answer.option).sample.id
      )
      updated_answer.save_and_record_voter_participation

      expect(poll.reload.voters.size).to eq(1)

      voter = poll.voters.first
      expect(voter.document_number).to eq(updated_answer.author.document_number)
      expect(voter.poll_id).to eq(updated_answer.poll.id)
    end

    it "does not save the answer if the voter is invalid" do
      allow_any_instance_of(Poll::Voter).to receive(:valid?).and_return(false)
      answer = build(:poll_answer)

      expect do
        answer.save_and_record_voter_participation
      end.to raise_error(ActiveRecord::RecordInvalid)

      expect(answer).not_to be_persisted
    end

    it "does not create two voters when creating two answers at the same time", :race_condition do
      answer = build(:poll_answer, question: question, author: author, answer: "Yes")
      other_answer = build(:poll_answer, question: question, author: author, answer: "No")

      [answer, other_answer].map do |poll_answer|
        Thread.new do
          poll_answer.save_and_record_voter_participation
        rescue ActiveRecord::RecordInvalid
        end
      end.each(&:join)

      expect(Poll::Voter.count).to be 1
    end

    it "does not create two voters when calling the method twice at the same time", :race_condition do
      answer = create(:poll_answer, question: question, author: author, answer: "Yes")

      2.times.map do
        Thread.new { answer.save_and_record_voter_participation }
      end.each(&:join)

      expect(Poll::Voter.count).to be 1
    end
  end
end
