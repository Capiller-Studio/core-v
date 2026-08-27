# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Accounts::DefaultCustomFieldsCreator do
  let(:account) { create(:account) }
  let(:service) { described_class.new(account: account) }

  describe '#call' do
    before do
      account.with_shard do
        account.custom_fields.destroy_all
      end
    end

    it 'creates the default custom fields for the account' do
      account.with_shard do
        expect { service.call }.to change { account.custom_fields.count }.by(5)
      end
    end

    it 'sets the correct attributes and translations across all supported locales' do
      service.call

      account.with_shard do
        name_field = account.custom_fields.find_by(key: 'name')
        expect(name_field.entity_type).to eq('customer')
        expect(name_field.field_type).to eq('text')
        expect(name_field.required).to be true
        expect(name_field.mapped_to).to eq('customer.name')
        expect(name_field.system_provided).to be true
        expect(name_field.translations.count).to eq(7)

        name_en = name_field.translations.find_by(locale: 'en')
        expect(name_en.label).to eq('Full Name')
        expect(name_en.placeholder).to eq('e.g. Jane Doe')

        name_ar = name_field.translations.find_by(locale: 'ar')
        expect(name_ar.label).to eq('الاسم الكامل')

        name_es = name_field.translations.find_by(locale: 'es')
        expect(name_es.label).to eq('Nombre completo')

        priority_field = account.custom_fields.find_by(key: 'priority')
        expect(priority_field.entity_type).to eq('conversation')
        expect(priority_field.field_type).to eq('select')
        expect(priority_field.required).to be false
        expect(priority_field.mapped_to).to eq('conversation.priority')
        expect(priority_field.translations.count).to eq(7)

        priority_en = priority_field.translations.find_by(locale: 'en')
        expect(priority_en.label).to eq('Priority')
        expect(priority_en.options).to eq([
          { "value" => "low", "label" => "Low" },
          { "value" => "medium", "label" => "Medium" },
          { "value" => "high", "label" => "High" },
          { "value" => "urgent", "label" => "Urgent" }
        ])

        priority_fr = priority_field.translations.find_by(locale: 'fr')
        expect(priority_fr.label).to eq('Priorité')
        expect(priority_fr.options.map { |o| o['label'] }).to eq(%w[Basse Moyenne Haute Urgente])

        priority_ko = priority_field.translations.find_by(locale: 'ko')
        expect(priority_ko.label).to eq('우선순위')
        expect(priority_ko.options.map { |o| o['label'] }).to eq(%w[낮음 보통 높음 긴급])
      end
    end

    it 'is idempotent and does not recreate existing fields' do
      service.call
      account.with_shard do
        expect { service.call }.not_to change { account.custom_fields.count }
      end
    end
  end
end
