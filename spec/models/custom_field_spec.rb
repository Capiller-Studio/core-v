require 'rails_helper'

RSpec.describe CustomField, type: :model do
  describe 'Associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to have_many(:translations).class_name('CustomFieldTranslation').dependent(:destroy) }
    it { is_expected.to have_many(:field_resources).class_name('CustomFieldResource').dependent(:destroy) }
  end

  describe 'Nested Attributes' do
    it { is_expected.to accept_nested_attributes_for(:translations).allow_destroy(true) }
  end

  describe 'Enums' do
    it { is_expected.to define_enum_for(:field_type).with_values(text: 0, email: 1, phone: 2, number: 3, textarea: 4, select: 5, multi_select: 6, checkbox: 7, file: 8, date: 9, url: 10).with_prefix(true) }
    it { is_expected.to define_enum_for(:entity_type).with_values(customer: 0, conversation: 1).with_prefix(true) }
  end

  describe 'Flags' do
    it { is_expected.to respond_to(:searchable) }
    it { is_expected.to respond_to(:filterable) }
    it { is_expected.to respond_to(:hidden) }
    it { is_expected.to respond_to(:is_readonly) }
  end

  describe 'Validations' do
    subject { create(:custom_field) }

    it { is_expected.to validate_presence_of(:key) }
    it { is_expected.to validate_uniqueness_of(:key).scoped_to(:account_id).with_message(:taken_in_account) }
    it { is_expected.to validate_inclusion_of(:mapped_to).in_array(CustomField::MAPPING_TARGETS).allow_blank }

    it 'validates format of key' do
      expect(build(:custom_field, key: 'valid_key')).to be_valid
      expect(build(:custom_field, key: 'invalid-key')).not_to be_valid
      expect(build(:custom_field, key: 'INVALID_KEY')).not_to be_valid
    end

    describe '#validate_default_value' do
      it 'validates number format' do
        cf = build(:custom_field, field_type: :number, default_value: 'abc')
        expect(cf).not_to be_valid
        expect(cf.errors[:default_value]).to include('must be a valid number')

        cf.default_value = '123.45'
        expect(cf).to be_valid
      end

      it 'validates email format' do
        cf = build(:custom_field, field_type: :email, default_value: 'not-an-email')
        expect(cf).not_to be_valid
        expect(cf.errors[:default_value]).to include('must be a valid email format')

        cf.default_value = 'test@example.com'
        expect(cf).to be_valid
      end

      it 'validates url format' do
        cf = build(:custom_field, field_type: :url, default_value: 'not-a-url')
        expect(cf).not_to be_valid
        expect(cf.errors[:default_value]).to include('must be a valid URL')

        cf.default_value = 'https://example.com'
        expect(cf).to be_valid
      end
    end
  end

  describe 'Callbacks' do
    describe '#assign_entity_type_from_mapped_to' do
      it 'assigns customer for customer mappings' do
        cf = build(:custom_field, mapped_to: 'customer.name', entity_type: nil)
        cf.valid?
        expect(cf.entity_type).to eq('customer')
      end

      it 'assigns conversation for conversation or message mappings' do
        cf1 = build(:custom_field, mapped_to: 'conversation.title', entity_type: nil)
        cf1.valid?
        expect(cf1.entity_type).to eq('conversation')

        cf2 = build(:custom_field, mapped_to: 'message.content', entity_type: nil)
        cf2.valid?
        expect(cf2.entity_type).to eq('conversation')
      end
    end
  end

  describe 'Instance Methods' do
    describe '#localized_options' do
      let(:cf) { create(:custom_field, validations: { 'allowed_values' => ['val1', 'val2'] }) }
      let!(:translation_en) { create(:custom_field_translation, custom_field: cf, locale: 'en', options: [{ 'value' => 'val1', 'label' => 'Value 1 EN' }]) }

      it 'returns exact locale translation options if present' do
        expect(cf.reload.localized_options('en')).to eq([{ 'value' => 'val1', 'label' => 'Value 1 EN' }])
      end

      it 'falls back to validations allowed_values if no options present' do
        cf2 = create(:custom_field, validations: { 'allowed_values' => ['val1', 'val2'] })
        expected_fallback = [{ 'value' => 'val1', 'label' => 'Val1' }, { 'value' => 'val2', 'label' => 'Val2' }]
        expect(cf2.localized_options('fr')).to eq(expected_fallback)
      end
    end
  end
end
