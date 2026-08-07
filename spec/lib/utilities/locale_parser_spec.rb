require 'rails_helper'

RSpec.describe Utilities::LocaleParser do
  describe '.parse' do
    it 'returns nil for blank inputs' do
      expect(described_class.parse(nil)).to be_nil
      expect(described_class.parse('')).to be_nil
      expect(described_class.parse('   ')).to be_nil
    end

    it 'maps full language names to 2-letter codes' do
      expect(described_class.parse('english')).to eq('en')
      expect(described_class.parse('Spanish')).to eq('es')
      expect(described_class.parse('FRENCH')).to eq('fr')
      expect(described_class.parse('  japanese  ')).to eq('ja')
    end

    it 'preserves 2-letter codes and normalizes case' do
      expect(described_class.parse('en')).to eq('en')
      expect(described_class.parse('ES')).to eq('es')
      expect(described_class.parse('  fr  ')).to eq('fr')
    end

    it 'formats locale and region codes correctly with hyphens' do
      expect(described_class.parse('en-us')).to eq('en-US')
      expect(described_class.parse('pt-BR')).to eq('pt-BR')
      expect(described_class.parse('FR-ca')).to eq('fr-CA')
    end

    it 'converts underscores to hyphens and formats correctly' do
      expect(described_class.parse('en_us')).to eq('en-US')
      expect(described_class.parse('PT_BR')).to eq('pt-BR')
      expect(described_class.parse('zh_cn')).to eq('zh-CN')
    end

    it 'truncates locales with more than two parts' do
      expect(described_class.parse('en-us-1996')).to eq('en-US')
      expect(described_class.parse('es-ES-traditional')).to eq('es-ES')
    end

    it 'handles unknown full names by returning them downcased as valid custom locales' do
      expect(described_class.parse('Klingon')).to eq('klingon')
      expect(described_class.parse('Dothraki')).to eq('dothraki')
    end

    it 'handles symbols gracefully' do
      expect(described_class.parse(:english)).to eq('en')
      expect(described_class.parse(:en_us)).to eq('en-US')
    end
  end
end
