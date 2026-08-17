# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Publishable, type: :model do
  let(:account) { create(:account) }
  let(:template) do
    account.with_shard do
      create(:email_template, account: account, name: 'Welcome', template_type: :welcome_email)
    end
  end

  before do
    allow(Emails::TemplateCompilerService).to receive(:compile_with_layout).and_return('<html>Welcome</html>')
  end

  describe '#save_draft! and #has_unpublished_changes?' do
    it 'saves draft fields without changing published fields' do
      account.with_shard do
        template.save_draft!(draft_subject_content: 'Draft Welcome', draft_body_content: 'Draft Body')

        expect(template.draft_subject).to eq('Draft Welcome')
        expect(template.draft_body).to eq('Draft Body')
        expect(template.subject).to be_nil
        expect(template.has_unpublished_changes?).to be(true)
      end
    end
  end

  describe '#publish!' do
    it 'copies draft content into published fields and marks changes resolved' do
      account.with_shard do
        template.save_draft!(draft_subject_content: 'Official Subject', draft_body_content: 'Official Body')
        template.publish!

        expect(template.subject).to eq('Official Subject')
        expect(template.body).to eq('Official Body')
        expect(template.compiled_html).to eq('<html>Welcome</html>')
        expect(template.has_unpublished_changes?).to be(false)
      end
    end

    it 'raises an error if there is no draft content to publish' do
      account.with_shard do
        expect {
          template.publish!
        }.to raise_error(StandardError)
      end
    end
  end

  describe '#discard_draft!' do
    it 'resets draft fields back to published content' do
      account.with_shard do
        template.save_draft!(draft_subject_content: 'Published Subject', draft_body_content: 'Published Body')
        template.publish!

        template.save_draft!(draft_subject_content: 'Unwanted Edits')
        expect(template.has_unpublished_changes?).to be(true)

        template.discard_draft!
        expect(template.draft_subject).to eq('Published Subject')
        expect(template.has_unpublished_changes?).to be(false)
      end
    end
  end

  describe '#copy_draft_locale!' do
    it 'copies draft content from one locale to another' do
      account.with_shard do
        I18n.with_locale(:en) do
          template.save_draft!(draft_subject_content: 'English Subject', draft_body_content: 'English Body')
        end

        template.copy_draft_locale!(from: :en, to: :es)

        I18n.with_locale(:es) do
          expect(template.draft_subject).to eq('English Subject')
          expect(template.draft_body).to eq('English Body')
        end
      end
    end
  end
end
