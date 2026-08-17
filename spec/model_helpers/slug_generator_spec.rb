# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SlugGenerator do
  let(:dummy_class) do
    Class.new do
      include ActiveModel::Model
      include ActiveModel::Validations
      include ActiveModel::Validations::Callbacks

      attr_accessor :id, :name, :identifier, :account_id

      def persisted?
        id.present?
      end

      def self.where(conditions)
        @dummy_query ||= Class.new do
          attr_accessor :conditions

          def initialize(conds)
            @conditions = conds
          end

          def where(conds)
            @conditions.merge!(conds)
            self
          end

          def where_not(conds)
            self
          end

          def not(conds)
            self
          end

          def exists?
            # Simulate collision for 'support-team'
            @conditions[:identifier] == 'support-team'
          end
        end
        @dummy_query.new(conditions)
      end
    end
  end

  describe '#initialize' do
    it 'sets source, column, and scope options' do
      generator = described_class.new(source: :name, column: :slug, scope: :account_id)

      expect(generator.source).to eq(:name)
      expect(generator.column).to eq(:slug)
      expect(generator.scope).to eq(:account_id)
    end
  end

  describe 'inclusion in model' do
    it 'generates a parameterized slug from the source attribute before validation' do
      generator = described_class.new(source: :name, column: :identifier)
      dummy_class.include(generator)

      instance = dummy_class.new(name: 'Billing & Payments')
      instance.valid?

      expect(instance.identifier).to eq('billing-payments')
    end

    it 'resolves collisions by appending a counter' do
      generator = described_class.new(source: :name, column: :identifier)
      dummy_class.include(generator)

      instance = dummy_class.new(name: 'Support Team')
      instance.valid?

      expect(instance.identifier).to eq('support-team-2')
    end

    it 'does not overwrite an existing slug' do
      generator = described_class.new(source: :name, column: :identifier)
      dummy_class.include(generator)

      instance = dummy_class.new(name: 'Custom Team', identifier: 'custom-slug')
      instance.valid?

      expect(instance.identifier).to eq('custom-slug')
    end
  end
end
