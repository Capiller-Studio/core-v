# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AccessToken, type: :model do
  let(:user) { create(:user) }

  describe 'Associations and Enums' do
    it { is_expected.to belong_to(:owner) }
    it { is_expected.to define_enum_for(:token_type).with_values(api_key: 0, magic_link: 1) }
  end

  describe 'creation' do
    it 'creates an access token for a user owner' do
      token = described_class.create!(
        owner: user,
        token: SecureRandom.hex(16),
        token_type: :api_key
      )

      expect(token).to be_persisted
      expect(token.owner).to eq(user)
      expect(token.api_key?).to be(true)
    end
  end
end
