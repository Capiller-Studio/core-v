require 'rails_helper'

RSpec.describe Emails::TemplateCompilerService do
  describe '.compile' do
    context 'when mjml_content is blank' do
      it 'returns an empty string' do
        expect(described_class.compile(nil)).to eq('')
        expect(described_class.compile('')).to eq('')
      end
    end

    context 'when mjml_content is valid' do
      let(:mjml) { '<mjml><mj-body><mj-text>Hello</mj-text></mj-body></mjml>' }

      it 'returns compiled HTML' do
        result = described_class.compile(mjml)
        expect(result).to include('Hello')
        expect(result).to include('html')
      end
    end

    context 'when compilation fails' do
      let(:invalid_mjml) { '<mjml><mj-body><invalid></mj-body></mjml>' }

      before do
        allow(MRML).to receive(:to_html).and_raise(StandardError, 'Parse error')
      end

      context 'when strict is false' do
        it 'logs error and returns empty string' do
          expect(Rails.logger).to receive(:error).with(/MJML compilation failed: Parse error/)
          expect(described_class.compile(invalid_mjml, strict: false)).to eq('')
        end
      end

      context 'when strict is true' do
        it 'raises CompilationError' do
          expect {
            described_class.compile(invalid_mjml, strict: true)
          }.to raise_error(Emails::TemplateCompilerService::CompilationError, /Failed to compile MJML: Parse error/)
        end
      end
    end
  end

  describe '.compile_with_layout' do
    context 'when layout_body is blank' do
      it 'calls compile with template_body' do
        expect(described_class).to receive(:compile).with('template').and_return('html')
        expect(described_class.compile_with_layout('template')).to eq('html')
      end
    end

    context 'when layout_body is present' do
      let(:layout) { '<mjml><mj-body><mj-wrapper>[[CONTENT_FOR_LAYOUT]]</mj-wrapper></mj-body></mjml>' }
      
      it 'extracts mj-body content and injects into layout' do
        template = '<mjml><mj-body><mj-text>Inner content</mj-text></mj-body></mjml>'
        expected_mjml = '<mjml><mj-body><mj-wrapper><mj-text>Inner content</mj-text></mj-wrapper></mj-body></mjml>'

        expect(described_class).to receive(:compile).with(expected_mjml).and_return('html')
        
        expect(described_class.compile_with_layout(template, layout_body: layout)).to eq('html')
      end

      it 'uses full template if no mj-body is found' do
        template = '<mj-text>Just text</mj-text>'
        expected_mjml = '<mjml><mj-body><mj-wrapper><mj-text>Just text</mj-text></mj-wrapper></mj-body></mjml>'

        expect(described_class).to receive(:compile).with(expected_mjml).and_return('html')
        
        expect(described_class.compile_with_layout(template, layout_body: layout)).to eq('html')
      end
    end
  end
end
