# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Security::UrlValidator do
  describe '.validate' do
    it 'accepts legitimate external HTTPS URLs' do
      result = described_class.validate('https://example.com/webhook')
      expect(result[:valid]).to be true
    end

    it 'rejects blank URLs' do
      result = described_class.validate('')
      expect(result[:valid]).to be false
      expect(result[:error]).to include('cannot be blank')
    end

    it 'rejects localhost' do
      result = described_class.validate('http://localhost:3000/api')
      expect(result[:valid]).to be false
      expect(result[:error]).to include('localhost or internal network')
    end

    it 'rejects 127.0.0.1' do
      result = described_class.validate('http://127.0.0.1:8080')
      expect(result[:valid]).to be false
      expect(result[:error]).to include('localhost or internal network')
    end

    it 'rejects link-local cloud metadata IP (169.254.169.254)' do
      result = described_class.validate('http://169.254.169.254/latest/meta-data')
      expect(result[:valid]).to be false
      expect(result[:error]).to include('internal or private IP')
    end

    it 'rejects RFC 1918 private IP ranges' do
      expect(described_class.validate('http://10.0.0.1/test')[:valid]).to be false
      expect(described_class.validate('http://172.16.0.1/test')[:valid]).to be false
      expect(described_class.validate('http://192.168.1.1/test')[:valid]).to be false
    end

    it 'rejects .internal and .local domains' do
      expect(described_class.validate('http://service.internal/hook')[:valid]).to be false
      expect(described_class.validate('http://printer.local/hook')[:valid]).to be false
    end

    it 'allows local URLs when allow_local is true in test/development' do
      result = described_class.validate('http://localhost:3000/hook', allow_local: true)
      expect(result[:valid]).to be true
    end

    context 'with internationalization (i18n)' do
      it 'translates error messages to Spanish' do
        I18n.with_locale(:es) do
          result = described_class.validate('http://localhost:3000')
          expect(result[:valid]).to be false
          expect(result[:error]).to eq('no puede apuntar a localhost o espacios de red internos')
        end
      end

      it 'translates error messages to German' do
        I18n.with_locale(:de) do
          result = described_class.validate('http://10.0.0.1')
          expect(result[:valid]).to be false
          expect(result[:error]).to eq('darf nicht auf interne oder private IP-Adressen verweisen')
        end
      end

      it 'translates error messages across all Core::SUPPORTED_LOCALES' do
        Core::SUPPORTED_LOCALES.each do |locale|
          I18n.with_locale(locale) do
            blank_result = described_class.validate('')
            expect(blank_result[:valid]).to be false
            expect(blank_result[:error]).to eq(I18n.t('security.url_validator.cannot_be_blank', locale: locale))

            format_result = described_class.validate('not-a-url')
            expect(format_result[:valid]).to be false
            expect(format_result[:error]).to eq(I18n.t('security.url_validator.invalid_format', locale: locale))

            local_result = described_class.validate('http://localhost:3000')
            expect(local_result[:valid]).to be false
            expect(local_result[:error]).to eq(I18n.t('security.url_validator.localhost_blocked', locale: locale))
          end
        end
      end
    end
  end
end
