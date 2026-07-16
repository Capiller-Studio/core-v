require 'rails_helper'

RSpec.describe Accounts::DefaultCustomFieldsCreator do
  let(:account) { create(:account) }
  let(:service) { described_class.new(account: account) }

  describe '#call' do
    before { account.custom_fields.destroy_all }

    it 'creates the default custom fields for the account' do
      expect { service.call }.to change { account.custom_fields.count }.by(5)
    end

    it 'sets the correct attributes for the created fields' do
      service.call

      name_field = account.custom_fields.find_by(key: 'name')
      expect(name_field.entity_type).to eq('customer')
      expect(name_field.field_type).to eq('text')
      expect(name_field.required).to be true
      expect(name_field.mapped_to).to eq('customer.name')
      expect(name_field.system_provided).to be true
      
      name_translation = name_field.translations.find_by(locale: 'en')
      expect(name_translation.label).to eq('Full Name')
      expect(name_translation.options).to eq([])

      priority_field = account.custom_fields.find_by(key: 'priority')
      expect(priority_field.entity_type).to eq('conversation')
      expect(priority_field.field_type).to eq('select')
      expect(priority_field.required).to be false
      expect(priority_field.mapped_to).to eq('conversation.priority')
      
      priority_translation = priority_field.translations.find_by(locale: 'en')
      expect(priority_translation.label).to eq('Priority')
      expect(priority_translation.options).to eq([
        { "value" => "low", "label" => "Low" },
        { "value" => "medium", "label" => "Medium" },
        { "value" => "high", "label" => "High" },
        { "value" => "urgent", "label" => "Urgent" }
      ])
    end

    it 'is idempotent and does not recreate existing fields' do
      service.call
      expect { service.call }.not_to change { account.custom_fields.count }
    end
  end
end
