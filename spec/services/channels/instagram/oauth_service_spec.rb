require 'rails_helper'

RSpec.describe Channels::Instagram::OauthService do
  let(:account) { double('Account') }
  let(:service) { described_class.new(account: account) }

  describe '#authorization_url' do
    it 'generates auth url' do
      url = service.authorization_url(redirect_uri: 'http://redirect', state: 'abc')
      expect(url).to include("https://api.instagram.com/oauth/authorize?")
      expect(url).to include("redirect_uri=http%3A%2F%2Fredirect")
      expect(url).to include("state=abc")
    end
  end

  describe '#exchange_code' do
    let(:short_lived) { double('Response', success?: true, body: '{"access_token": "short", "user_id": 123}') }
    let(:long_lived) { double('Response', success?: true, body: '{"access_token": "long", "expires_in": 3600}') }
    let(:user_details) { double('Response', success?: true, body: '{"id": 123, "user_id": 123, "username": "iguser", "name": "IG User", "profile_picture_url": "http://img"}') }

    before do
      allow(described_class).to receive(:post).and_return(short_lived)
      allow(described_class).to receive(:get).with(/access_token/, anything).and_return(long_lived)
      allow(described_class).to receive(:get).with(/me/, anything).and_return(user_details)
    end

    it 'exchanges tokens and returns user' do
      result = service.exchange_code(code: 'code123', redirect_uri: 'http://redirect')
      
      expect(result[:access_token]).to eq("long")
      expect(result[:user][:username]).to eq("iguser")
    end
  end
end
