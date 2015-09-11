require 'rails_helper'

describe Verification::Residence do

  let(:residence) { build(:verification_residence) }

  describe "validations" do

    it "should be valid" do
      expect(residence).to be_valid
    end

    describe "dates" do
      it "should be valid with a valid date of birth" do
        residence = Verification::Residence.new({"date_of_birth(3i)"=>"1", "date_of_birth(2i)"=>"1", "date_of_birth(1i)"=>"1980"})
        expect(residence.errors[:date_of_birth].size).to eq(0)
      end

      it "should not be valid without a date of birth" do
        residence = Verification::Residence.new({"date_of_birth(3i)"=>"", "date_of_birth(2i)"=>"", "date_of_birth(1i)"=>""})
        residence.valid?
        expect(residence.errors[:date_of_birth]).to include("can't be blank")
      end
    end

    it "should validate uniquness of document_number" do
      user = create(:user)
      residence.user = user
      residence.save

      residence2 = build(:verification_residence)

      residence.valid?
      expect(residence.errors[:document_number]).to include("Already in use")
    end

    it "should validate census terms" do
      residence.terms_of_service = nil
      expect(residence).to_not be_valid
    end
  end

  describe "new" do
    it "should upcase document number" do
      residence = Verification::Residence.new({document_number: "x1234567z"})
      expect(residence.document_number).to eq("X1234567Z")
    end
  end

  describe "save" do

    it "should store document number and type" do
      user = create(:user)
      residence.user = user
      residence.save

      user.reload
      expect(user.document_number).to eq('12345678Z')
      expect(user.document_type).to eq("1")
    end

  end

  describe "tries" do
    it "should increase tries after a call to the Census" do
      residence.postal_code = "12345"
      residence.valid?
      expect(residence.user.lock.tries).to eq(1)
    end

    it "should not increase tries after a validation error" do
      residence.postal_code = ""
      residence.valid?
      expect(residence.user.lock).to be nil
    end
  end

  describe "Failed census call" do
    it "stores failed census API calls" do
      residence = build(:verification_residence, :invalid)
      residence.save

      expect(FailedCensusCall.count).to eq(1)
      expect(FailedCensusCall.first).to have_attributes({
        user_id:         residence.user.id,
        document_number: "12345678Z",
        document_type:   "1",
        date_of_birth:   Date.new(1980, 12, 31),
        postal_code:     "12345"
      })
    end
  end

end