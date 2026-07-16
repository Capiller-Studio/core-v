require 'rails_helper'

RSpec.describe Channels::FacebookPages::TokenExchangeService do
  let(:account) { double('Account') }
  let(:service) { described_class.new(short_lived_token: 'short_token', account: account) }

  describe '#call' do
    let(:oauth_mock) { instance_double(Koala::Facebook::OAuth) }
    let(:api_mock) { instance_double(Koala::Facebook::API) }

    before do
      allow(Koala::Facebook::OAuth).to receive(:new).with(anything, anything).and_return(oauth_mock)
      allow(Koala::Facebook::API).to receive(:new).with('long_token').and_return(api_mock)
      
      allow(oauth_mock).to receive(:exchange_access_token_info).with('short_token').and_return({ "access_token" => "long_token" })
    end

    it 'exchanges token and fetches normalized pages' do
      pages_data = [
        {
          "id" => "123",
          "name" => "Test Page",
          "access_token" => "page_token",
          "category" => "Business",
          "picture" => { "data" => { "url" => "http://avatar.com/1" } },
          "instagram_business_account" => { "id" => "ig1" }
        }
      ]

      expect(api_mock).to receive(:get_connections).with(
        "me", "accounts",
        fields: "id,name,access_token,category,picture{url},instagram_business_account{id,username,profile_picture_url}"
      ).and_return(pages_data)

      result = service.call

      expect(result[:user_access_token]).to eq('long_token')
      expect(result[:pages].first).to eq({
        id: "123",
        name: "Test Page",
        access_token: "page_token",
        category: "Business",
        avatar_url: "http://avatar.com/1",
        instagram_business_account: { "id" => "ig1" }
      })
    end
  end
end
