require 'rails_helper'

describe LocalCensus do
  let(:api) { described_class.new }

  describe '#get_document_number_variants' do
    it "trims and cleans up entry" do
      expect(api.get_document_number_variants(2, '  1 2@ 34')).to eq(['1234'])
    end

    it "returns only one try for passports & residence cards" do
      expect(api.get_document_number_variants(2, '1234')).to eq(['1234'])
      expect(api.get_document_number_variants(3, '1234')).to eq(['1234'])
    end

    it 'takes only the last 8 digits for dnis and resicence cards' do
      expect(api.get_document_number_variants(1, '543212345678')).to eq(%w(12345678 12345678z 12345678Z))
    end

    it 'tries all the dni variants padding with zeroes' do
      expect(api.get_document_number_variants(1, '0123456')).to eq(%w(123456 0123456 00123456 123456s 123456S 0123456s 0123456S 00123456s 00123456S))
      expect(api.get_document_number_variants(1, '00123456')).to eq(%w(123456 0123456 00123456 123456s 123456S 0123456s 0123456S 00123456s 00123456S))
    end

    it 'adds upper and lowercase letter when the letter is present' do
      expect(api.get_document_number_variants(1, '1234567L')).to eq(%w(1234567 01234567 1234567l 1234567L 01234567l 01234567L))
    end

    it 'adds letter if not present' do
      expect(api.get_document_number_variants(1, '1234567')).to eq(%w(1234567 01234567 1234567l 1234567L 01234567l 01234567L))
    end

    it 'uses the correct letter for a spanish document number' do
      expect(api.get_document_number_variants(1, '1234567B')).to eq(%w(1234567 01234567 1234567l 1234567L 01234567l 01234567L))
    end
  end

  describe '#call' do
    let(:invalid_body) { nil }
    let(:valid_body) { create(:local_census_record) }

    it "returns the response for the first valid variant" do
      allow(api).to receive(:get_record).with(1, "00123456").and_return(invalid_body)
      allow(api).to receive(:get_record).with(1, "123456").and_return(invalid_body)
      allow(api).to receive(:get_record).with(1, "0123456").and_return(valid_body)

      response = api.call(1, "123456")

      expect(response).to be_valid
      expect(response.date_of_birth).to eq(Date.new(1970, 1, 31))
    end

    it "returns the last failed response" do
      allow(api).to receive(:get_response_body).with(1, "00123456").and_return(invalid_body)
      allow(api).to receive(:get_response_body).with(1, "00123456s").and_return(invalid_body)
      allow(api).to receive(:get_response_body).with(1, "00123456S").and_return(invalid_body)
      allow(api).to receive(:get_response_body).with(1, "123456").and_return(invalid_body)
      allow(api).to receive(:get_response_body).with(1, "123456s").and_return(invalid_body)
      allow(api).to receive(:get_response_body).with(1, "123456S").and_return(invalid_body)
      allow(api).to receive(:get_response_body).with(1, "0123456").and_return(invalid_body)
      allow(api).to receive(:get_response_body).with(1, "0123456s").and_return(invalid_body)
      allow(api).to receive(:get_response_body).with(1, "0123456S").and_return(invalid_body)
      response = api.call(1, "123456")

      expect(response).not_to be_valid
    end
  end

end
