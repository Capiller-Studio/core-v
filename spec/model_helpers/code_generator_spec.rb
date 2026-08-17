# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CodeGenerator do
  let(:dummy_class) do
    Class.new do
      include ActiveModel::Model
      include ActiveModel::Validations
      include ActiveModel::Validations::Callbacks

      attr_accessor :identifier, :code

      def self.exists?(_condition)
        false
      end

      def self.count
        0
      end
    end
  end

  describe '#initialize' do
    it 'sets configuration attributes' do
      generator = described_class.new(prefix: 'TEST', length: 6, letters: false, column: :code)

      expect(generator.prefix).to eq('TEST')
      expect(generator.length).to eq(6)
      expect(generator.letters).to be(false)
      expect(generator.column).to eq(:code)
    end
  end

  describe 'inclusion in model' do
    it 'generates a code before validation if column is blank' do
      generator = described_class.new(prefix: 'INV', column: :identifier)
      dummy_class.include(generator)

      instance = dummy_class.new
      instance.valid?

      expect(instance.identifier).to be_present
      expect(instance.identifier).to start_with('INV')
      expect(instance.identifier.length).to eq(12) # 3 prefix + 9 default length
    end

    it 'does not overwrite an existing code' do
      generator = described_class.new(prefix: 'INV', column: :identifier)
      dummy_class.include(generator)

      instance = dummy_class.new(identifier: 'EXISTING_123')
      instance.valid?

      expect(instance.identifier).to eq('EXISTING_123')
    end
  end

  describe '#new_candidate' do
    it 'generates candidate matching configured prefix and length' do
      generator = described_class.new(prefix: 'AFF', length: 8, letters: true)
      candidate = generator.new_candidate(8)

      expect(candidate).to start_with('AFF')
      expect(candidate.length).to eq(11)
    end

    it 'generates numbers only when letters is false' do
      generator = described_class.new(prefix: 'NUM', length: 5, letters: false)
      candidate = generator.new_candidate(5)

      expect(candidate).to match(/\ANUM\d{5}\z/)
    end
  end
end
