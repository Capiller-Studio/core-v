require 'rails_helper'

RSpec.describe HelpCenter::CategoryResource, type: :model do
  describe 'Associations' do
    it { is_expected.to belong_to(:category) }
    it { is_expected.to belong_to(:resource) }
  end

  describe 'Callbacks' do
    let(:category) { HelpCenter::Category.new(id: SecureRandom.uuid) }
    let(:category_resource) { described_class.new(category: category) }

    before do
      allow(category).to receive(:update_stats!)
    end

    it 'calls update_stats! on the associated category after commit' do
      category_resource.send(:update_category_stats)
      expect(category).to have_received(:update_stats!)
    end
  end

end
