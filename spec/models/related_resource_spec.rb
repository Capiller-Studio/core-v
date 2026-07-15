require 'rails_helper'

RSpec.describe RelatedResource, type: :model do
  describe 'Associations' do
    it { is_expected.to belong_to(:linked_resource) }
    it { is_expected.to belong_to(:resource) }
  end

end
